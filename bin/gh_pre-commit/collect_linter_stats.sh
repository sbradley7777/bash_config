#!/bin/bash
#
# Generate raw statistics files from pre-commit hooks for git-tracked Python files
# Output: /tmp/linter_report-<project_name>/*.txt
#
# Usage:
#   collect_linter_stats.sh -p <git-project-path> [-l]
#
# Options:
#   -p <path> : Path to git project (required)
#   -l        : List files only (don't run linters)
#
# Examples:
#   collect_linter_stats.sh -p ~/projects/my-python-app -l
#   collect_linter_stats.sh -p /path/to/project
#

set -e

# Tool paths will be set dynamically by discover_tool_paths() function
# These are fallback defaults (DO NOT EDIT - use precommit_tool_finder.py instead)
FLAKE8_BIN="${HOME}/.cache/pre-commit/repoc5n23huj/py_env-python3.12/bin/flake8"
RUFF_BIN="${HOME}/.cache/pre-commit/repoaxkqxs_f/py_env-python3.12/bin/ruff"
MYPY_BIN="${HOME}/.cache/pre-commit/repopkcn158x/py_env-python3.12/bin/mypy"

# Mypy error code descriptions
# shellcheck disable=SC2034  # Used by linter_stats_to_json.py via environment
declare -A MYPY_DESCRIPTIONS=(
    ["no-untyped-def"]="Function is missing a type annotation"
    ["attr-defined"]="Attribute does not exist on type"
    ["arg-type"]="Argument has incompatible type"
    ["import-not-found"]="Cannot find implementation or library stub"
    ["var-annotated"]="Variable needs type annotation"
    ["union-attr"]="Item 'None' of 'Optional[...]' has no attribute"
    ["import-untyped"]="Import is not typed or missing type hints"
    ["assignment"]="Incompatible types in assignment"
    ["call-overload"]="No overload variant matches argument types"
    ["return-value"]="Incompatible return value type"
    ["type-arg"]="Type argument is incompatible"
    ["misc"]="Miscellaneous type error"
)

# Function to show usage
show_usage() {
    echo "Usage: $0 -p <git-project-path> [-o <output-dir>] [-l]"
    echo ""
    echo "Options:"
    echo "  -p <path>  Path to git project (required)"
    echo "  -o <dir>   Output directory (default: /tmp/linter_report-<project_name>)"
    echo "  -l         List files only (don't run linters)"
    echo ""
    echo "Examples:"
    echo "  $0 -p ~/projects/my-python-app"
    echo "  $0 -p ~/projects/my-python-app -o /tmp/custom_output"
    echo "  $0 -p ~/projects/my-python-app -l"
    echo ""
    echo "Output files:"
    echo "  <output-dir>/*.txt         Raw linter stats"
    echo "  <output-dir>/*.json        Combined JSON data"
    exit 1
}

# Function to replace home directory with ~ for display
format_path_display() {
    local path="$1"
    echo "${path/#$HOME/\~}"
}

# Function to discover tool paths dynamically using Python module
discover_tool_paths() {
    local project_path="$1"
    local script_dir
    script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local finder_script="${script_dir}/precommit_tool_finder.py"

    # Check if finder script exists
    if [ ! -f "$finder_script" ]; then
        echo "Warning: precommit_tool_finder.py not found, using fallback paths" >&2
        echo "         Expected: $(format_path_display "$finder_script")" >&2
        return 1
    fi

    # Run Python script to get tool paths (output format: TOOL_BIN="path")
    local tool_paths
    if ! tool_paths=$(python3 "$finder_script" -p "$project_path" 2>&1); then
        echo "Error: Failed to discover tool paths" >&2
        echo "$tool_paths" >&2
        return 1
    fi

    # Extract paths from output
    RUFF_BIN=$(echo "$tool_paths" | grep "RUFF_BIN=" | cut -d'"' -f2)
    FLAKE8_BIN=$(echo "$tool_paths" | grep "FLAKE8_BIN=" | cut -d'"' -f2)
    MYPY_BIN=$(echo "$tool_paths" | grep "MYPY_BIN=" | cut -d'"' -f2)

    # Validate that we got all paths
    if [ -z "$RUFF_BIN" ] || [ -z "$FLAKE8_BIN" ] || [ -z "$MYPY_BIN" ]; then
        echo "Error: Failed to find all tool paths" >&2
        echo "  RUFF_BIN: ${RUFF_BIN:-NOT FOUND}" >&2
        echo "  FLAKE8_BIN: ${FLAKE8_BIN:-NOT FOUND}" >&2
        echo "  MYPY_BIN: ${MYPY_BIN:-NOT FOUND}" >&2
        return 1
    fi

    return 0
}

# Function to validate git directory
validate_git_dir() {
    local project_path="$1"

    # Check if directory exists
    if [ ! -d "$project_path" ]; then
        echo "Error: Directory does not exist: $project_path" >&2
        exit 1
    fi

    # Check if it's a git repository
    if ! git -C "$project_path" rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not a git repository: $project_path" >&2
        exit 1
    fi

    # Get the git root
    git -C "$project_path" rev-parse --show-toplevel
}

# Function to find linter configuration file
find_config_file() {
    local git_root="$1"

    # List of config files to search for (in order of preference)
    local config_files=(
        "pyproject.toml"
        "ruff.toml"
        ".ruff.toml"
        "setup.cfg"
        "tox.ini"
    )

    # Search for config file
    for config_file in "${config_files[@]}"; do
        local config_path="${git_root}/${config_file}"
        if [ -f "$config_path" ]; then
            echo "$config_path"
            return 0
        fi
    done

    # No config file found
    return 1
}

# Function to find top-level Python paths (files in root + directories with Python files)
find_python_paths_to_filenames() {
    # Find all git-tracked Python files
    git ls-files | while read -r file; do
        local is_python=false

        # Check if .py file
        if [[ "$file" == *.py ]]; then
            is_python=true
        # Check if executable script with Python shebang (no extension)
        elif [[ -f "$file" && -x "$file" && ! "$file" =~ \. ]]; then
            if head -1 "$file" 2>/dev/null | grep -q python; then
                is_python=true
            fi
        fi

        if [ "$is_python" = true ]; then
            # Check if file is in root directory or subdirectory
            if [[ "$file" == */* ]]; then
                # File is in a subdirectory - extract top-level directory
                local top_dir="${file%%/*}"
                echo "DIR:$top_dir"
            else
                # File is in root directory
                echo "FILE:$file"
            fi
        fi
    done | sort -u | while read -r path_to_filename; do
        # Remove the prefix marker
        echo "${path_to_filename#*:}"
    done
}

# Function to display paths list
display_paths_to_filenames() {
    local -n paths_array=$1
    local count=${#paths_array[@]}

    echo "Found $count top-level Python paths (files/directories):"
    echo ""
    for path_to_filename in "${paths_array[@]}"; do
        if [ -d "$path_to_filename" ]; then
            echo "  - $path_to_filename/ (directory)"
        else
            echo "  - $path_to_filename (file)"
        fi
    done
    echo ""
    echo "Note: Linters will recursively scan directories"
}

# Function to run flake8
run_flake8() {
    local -n paths_array=$1
    local config_file="$2"
    local output_file="${RAW_DIR}/flake8_stats_raw.txt"

    echo "[1/3] Running flake8..."
    if [ -n "$config_file" ]; then
        echo "  Command: $(format_path_display "$FLAKE8_BIN") -qq --statistics --toml-config $(format_path_display "$config_file") [files...]"
        "$FLAKE8_BIN" -qq --statistics --toml-config "$config_file" "${paths_array[@]}" \
            > "$output_file" 2>&1 || true
    else
        echo "  Command: $(format_path_display "$FLAKE8_BIN") -qq --statistics [files...]"
        "$FLAKE8_BIN" -qq --statistics "${paths_array[@]}" \
            > "$output_file" 2>&1 || true
    fi

    echo "  → Saved to: $(format_path_display "$output_file")"
    echo "  → Lines: $(wc -l < "$output_file")"
    echo ""
}

# Function to run ruff
run_ruff() {
    local -n paths_array=$1
    local config_file="$2"
    local output_file="${RAW_DIR}/ruff_stats_raw.txt"

    echo "[2/3] Running ruff..."
    if [ -n "$config_file" ]; then
        echo "  Command: $(format_path_display "$RUFF_BIN") check --config $(format_path_display "$config_file") [files...] --statistics"
        "$RUFF_BIN" check --config "$config_file" "${paths_array[@]}" --statistics 2>&1 \
            | grep -v "^Found [0-9]* error" \
            | grep -v "^No fixes available" \
            > "$output_file" || true
    else
        echo "  Command: $(format_path_display "$RUFF_BIN") check [files...] --statistics"
        "$RUFF_BIN" check "${paths_array[@]}" --statistics 2>&1 \
            | grep -v "^Found [0-9]* error" \
            | grep -v "^No fixes available" \
            > "$output_file" || true
    fi

    echo "  → Saved to: $(format_path_display "$output_file")"
    echo "  → Lines: $(wc -l < "$output_file")"
    echo ""
}

# Function to run mypy
run_mypy() {
    local -n paths_array=$1
    local config_file="$2"
    local output_file="${RAW_DIR}/mypy_stats_raw.txt"

    echo "[3/3] Running mypy..."
    # Run mypy and extract error codes, then count them
    if [ -n "$config_file" ]; then
        echo "  Command: $(format_path_display "$MYPY_BIN") --config-file $(format_path_display "$config_file") [files...]"
        "$MYPY_BIN" --config-file "$config_file" "${paths_array[@]}" 2>&1 \
            | grep -oP '\[[\w-]+\]$' \
            | tr -d '[]' \
            | sort \
            | uniq -c \
            | sort -rn \
            | awk '{print $1, $2}' \
            > "$output_file" || true
    else
        echo "  Command: $(format_path_display "$MYPY_BIN") [files...]"
        "$MYPY_BIN" "${paths_array[@]}" 2>&1 \
            | grep -oP '\[[\w-]+\]$' \
            | tr -d '[]' \
            | sort \
            | uniq -c \
            | sort -rn \
            | awk '{print $1, $2}' \
            > "$output_file" || true
    fi

    echo "  → Saved to: $(format_path_display "$output_file")"
    echo "  → Lines: $(wc -l < "$output_file")"
    echo ""
}

# Function to convert raw stats to JSON
convert_to_json() {
    local script_dir
    script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local converter="${script_dir}/linter_stats_to_json.py"

    echo ""
    echo "Converting to JSON format..."

    if [ ! -f "$converter" ]; then
        echo "Warning: Converter script not found: $converter" >&2
        return 1
    fi

    python3 "$converter" -o "${output_dir}"
}

# Function to display summary
display_summary() {
    echo "================================"
    echo "Data collection complete!"
    echo ""
    echo "Generated files:"
    echo ""
    echo "Raw data:"
    ls -lh "${RAW_DIR}"/*.txt 2>/dev/null || echo "  No raw files generated"
    echo ""
    echo "JSON data:"
    ls -lh "${RAW_DIR}"/*.json 2>/dev/null || echo "  No JSON files generated"
}

# Main script execution
main() {
    local list_only=false
    local project_path=""
    local output_dir=""
    local git_root
    local python_paths_to_filenames
    local -a paths_to_filenames

    # Parse command line arguments
    while getopts "p:o:lh" opt; do
        case $opt in
            p)
                project_path="$OPTARG"
                ;;
            o)
                output_dir="$OPTARG"
                ;;
            l)
                list_only=true
                ;;
            h)
                show_usage
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                show_usage
                ;;
            :)
                echo "Option -$OPTARG requires an argument" >&2
                show_usage
                ;;
        esac
    done

    # Check if -p option was provided
    if [ -z "$project_path" ]; then
        echo "Error: -p <git-project-path> is required" >&2
        echo ""
        show_usage
    fi

    # Validate and get git root first (needed for project name)
    git_root=$(validate_git_dir "$project_path")

    # Extract project name from git root
    project_name=$(basename "$git_root")

    # Set default output directory if not provided
    if [ -z "$output_dir" ]; then
        output_dir="/tmp/linter_report-${project_name}"
    fi

    # Output directory IS the RAW_DIR (no nesting)
    RAW_DIR="${output_dir}"
    echo "Git repository root: $(format_path_display "$git_root")"
    cd "$git_root"

    # Discover tool paths dynamically from project's pre-commit config
    echo ""
    echo "Discovering pre-commit tool paths..."
    if discover_tool_paths "$git_root"; then
        echo "  ✓ Found ruff: $(format_path_display "$RUFF_BIN")"
        echo "  ✓ Found flake8: $(format_path_display "$FLAKE8_BIN")"
        echo "  ✓ Found mypy: $(format_path_display "$MYPY_BIN")"
    else
        echo "  ⚠ Using fallback tool paths (may be incorrect!)"
        echo "  RUFF: $(format_path_display "$RUFF_BIN")"
        echo "  FLAKE8: $(format_path_display "$FLAKE8_BIN")"
        echo "  MYPY: $(format_path_display "$MYPY_BIN")"
    fi

    # Find configuration file
    echo ""
    echo "Searching for linter configuration file..."
    config_file=""
    if config_file=$(find_config_file "$git_root"); then
        echo "  ✓ Found config: $(format_path_display "$config_file")"
    else
        echo "  ⚠ No configuration file found (using tool defaults)"
    fi

    # Find top-level Python paths
    echo ""
    echo "Finding git-tracked Python paths..."
    python_paths_to_filenames=$(find_python_paths_to_filenames)
    # shellcheck disable=SC2034  # Used via nameref in run_flake8, run_ruff, run_mypy
    readarray -t paths_to_filenames <<< "$python_paths_to_filenames"

    # Display paths
    display_paths_to_filenames paths_to_filenames

    # Exit if list-only mode
    if [ "$list_only" = true ]; then
        echo ""
        echo "List-only mode (-l). Exiting without running linters."
        exit 0
    fi

    # Create output directory
    mkdir -p "${RAW_DIR}"

    echo ""
    echo "================================"
    echo "Generating raw statistics files..."
    echo "Output directory: $(format_path_display "${RAW_DIR}")"
    echo ""

    # Run linters
    run_flake8 paths_to_filenames "$config_file"
    run_ruff paths_to_filenames "$config_file"
    run_mypy paths_to_filenames "$config_file"

    # Convert to JSON
    convert_to_json

    # Display summary
    display_summary
}

# Run main function
main "$@"
