#!/bin/bash
#
# Description:
#   Install bash configuration files from the repository to the user's home directory.
#   Removes existing configuration files and copies new ones from the repository.
#
# Usage:
#   install.sh [-h] [-n]
#
# Options:
#   -h    Show this help message and exit
#   -n    Dry run - show what would be done without making changes
#
# Examples:
#   $ ./install.sh
#   $ ./install.sh -n
#
# Notes:
#   This script will automatically create timestamped backups of existing bash
#   configuration files before removing them. Backups are saved to:
#   ~/.bash_backup_<timestamp>/ (e.g., ~/.bash_backup_20251215_103045/)
#   It will then install new files from the repository's bash/ directory.
#   Also creates a symlink from ~/bin/bin.github to the repository's bin/ directory.
#   Script should be run from the repository's scripts/ directory.
#
# Exit Codes:
#   0    Success
#   1    General error (source directory not found, copy failed, etc.)
#

################################################################################
# Constants
################################################################################
readonly EXPECTED_PROJECT_NAME="bash_config"

# Configuration file patterns to backup and remove
readonly CONFIG_FILE_PATTERNS=(
    ".bash_profile"
    ".bashrc"
    ".aliases"
    ".aliases.*"
    ".functions*"
)

################################################################################
# Functions
################################################################################
# Display usage information and help text
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] [-n] [-p <project_root>]

Install bash configuration files from repository to home directory.
Automatically creates timestamped backups of existing configuration files.

Options:
  -h              Show this help message and exit
  -n              Dry run - show what would be done without making changes
  -p <path>       Specify project root directory (auto-detected if not provided)

Examples:
  • Run with auto-detected project root:
    $ ./$(basename "$0")

  • Preview changes without making modifications:
    $ ./$(basename "$0") -n

  • Specify project root directory explicitly:
    $ ./$(basename "$0") -p ~/github/bash_config

  • Dry run with explicit project root:
    $ ./$(basename "$0") -n -p ~/github/bash_config

Backups are saved to: ~/.bash_backup_<timestamp>/ (e.g., ~/.bash_backup_20251215_103045/)
EOF
}

# Print error message to stderr and exit with specified code
# Arguments:
#   $1 - Error message to display
#   $2 - Exit code (optional, defaults to 1)
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: $message" >&2
    exit "$exit_code"
}

# Convert absolute path to tilde notation for display
# Arguments:
#   $1 - Absolute path to convert
# Output:
#   Path with $HOME replaced by ~ (or ~/ if path equals $HOME)
display_path() {
    local path="$1"
    local result

    # macOS and Linux handle tilde escaping differently in variable substitution
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS - use unescaped tilde
        result="${path/$HOME/~}"
    else
        # Linux and others - use escaped tilde
        result="${path/$HOME/\~}"
    fi

    # If result is just ~, append /
    if [[ "$result" == "~" ]]; then
        # shellcheck disable=SC2088
        result="~/"
    fi

    printf '%s\n' "$result"
}

# Extract filename from full path
# Arguments:
#   $1 - Full file path
# Output:
#   Base filename without directory path
get_basename() {
    local path="$1"
    basename "$path"
}

################################################################################
# Configuration File Management
################################################################################
# Build array of full paths to configuration files
# Expands all patterns in CONFIG_FILE_PATTERNS into actual file paths
# Arguments:
#   None (uses CONFIG_FILE_PATTERNS global)
# Output:
#   Sets global array: config_files_to_process
# Returns:
#   0 if files found, 1 if no files found
build_config_file_list() {
    config_files_to_process=()

    for pattern in "${CONFIG_FILE_PATTERNS[@]}"; do
        if [[ "$pattern" != *"*"* ]] && [[ "$pattern" != *"?"* ]] && [[ "$pattern" != *"["* ]]; then
            # Specific file (e.g., ".bash_profile", ".bashrc")
            local file_path="$HOME/$pattern"
            [[ -e "$file_path" ]] && config_files_to_process+=("$file_path")
        else
            # Glob pattern (e.g., ".aliases.*", ".functions*")
            for file in "$HOME"/$pattern; do
                [[ -e "$file" ]] && config_files_to_process+=("$file")
            done
        fi
    done

    [[ ${#config_files_to_process[@]} -gt 0 ]] && return 0 || return 1
}

# Backup a single file to backup directory
# Arguments:
#   $1 - Full path to file to backup
# Globals:
#   BACKUP_DIR - Backup directory path
# Output:
#   Prints backup confirmation message
backup_file() {
    local file_path="$1"
    local filename
    filename="$(get_basename "$file_path")"

    cp "$file_path" "$BACKUP_DIR/" || error_exit "Failed to backup $filename"
    echo "  Backed up: $filename"
}

# Remove a single file
# Arguments:
#   $1 - Full path to file to remove
# Globals:
#   enable_dry_run - If true, only show what would be done
# Output:
#   Prints removal confirmation message
remove_file() {
    local file_path="$1"

    if [[ "$enable_dry_run" == true ]]; then
        echo "  [DRY RUN] Removed: $(display_path "$file_path")"
    else
        rm "$file_path" || error_exit "Failed to remove $(display_path "$file_path")"
        echo "  Removed: $(display_path "$file_path")"
    fi
}

################################################################################
# Git Project Detection and Validation
################################################################################
# Find project root directory by searching for .git directory
# Arguments:
#   $1 - Starting directory (optional, defaults to script directory)
# Output:
#   Absolute path to project root directory
# Returns:
#   0 if found, 1 if not found
find_git_project_root() {
    local search_dir="${1:-$SCRIPT_DIR}"
    local current_dir="$search_dir"

    # Search upward for .git directory (max 10 levels)
    for _ in {1..10}; do
        if [[ -d "$current_dir/.git" ]]; then
            echo "$current_dir"
            return 0
        fi

        # Move up one directory
        local parent_dir
        parent_dir="$(cd "$current_dir/.." && pwd)"

        # Stop if we've reached the root
        if [[ "$parent_dir" == "$current_dir" ]]; then
            break
        fi

        current_dir="$parent_dir"
    done

    return 1
}

# Get git project name from repository
# Arguments:
#   $1 - Project root directory path
# Output:
#   Project name extracted from git remote URL (e.g., "bash_config")
# Returns:
#   0 if successful, 1 if cannot determine
get_git_project_name() {
    local project_root="$1"

    # Get remote URL
    local remote_url
    remote_url="$(cd "$project_root" && git config --get remote.origin.url 2>/dev/null)"

    if [[ -z "$remote_url" ]]; then
        return 1
    fi

    # Extract project name from URL
    # Handles: https://github.com/user/project.git, git@github.com:user/project.git, etc.
    local project_name
    project_name="$(basename "$remote_url" .git)"

    if [[ -n "$project_name" ]]; then
        echo "$project_name"
        return 0
    fi

    return 1
}

# Validate project root directory using git commands
# Arguments:
#   $1 - Project root directory path
# Returns:
#   0 if valid expected project, 1 if not
validate_project_root() {
    local project_root="$1"

    # Check if .git directory exists
    if [[ ! -d "$project_root/.git" ]]; then
        return 1
    fi

    # Get project name from git
    local project_name
    project_name="$(get_git_project_name "$project_root")"

    # Check if this is the expected project
    if [[ "$project_name" == "$EXPECTED_PROJECT_NAME" ]]; then
        return 0
    fi

    return 1
}

# Get and validate project root directory
# Arguments:
#   $1 - User-provided project root path (optional, empty string if not provided)
# Output:
#   Absolute path to validated project root directory
# Exits with error if project root cannot be determined or validated
get_project_root() {
    local user_provided_path="$1"
    local project_root=""

    if [[ -n "$user_provided_path" ]]; then
        # User provided project root - validate it exists
        project_root="$(cd "$user_provided_path" && pwd 2>/dev/null)"
        [[ -n "$project_root" ]] || error_exit "Invalid path provided with -p option: $user_provided_path"
    else
        # Auto-detect project root by searching for .git directory
        # Start search from script's directory
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        [[ -n "$script_dir" ]] || error_exit "Failed to determine script directory"

        project_root="$(find_git_project_root "$script_dir")"
        if [[ -z "$project_root" ]]; then
            error_exit "Could not auto-detect \"$EXPECTED_PROJECT_NAME\" git project root. Please specify with -p option."
        fi
    fi

    # Validate that this is the expected project
    if ! validate_project_root "$project_root"; then
        local detected_name
        detected_name="$(get_git_project_name "$project_root")"
        if [[ -n "$detected_name" ]]; then
            error_exit "Git project validation failed: $(display_path "$project_root") is \"$detected_name\" git project, not \"$EXPECTED_PROJECT_NAME\""
        else
            error_exit "Git project validation failed: $(display_path "$project_root") is not the \"$EXPECTED_PROJECT_NAME\" git project"
        fi
    fi

    echo "$project_root"
}

# Backup and remove configuration files
# Builds list of files from CONFIG_FILE_PATTERNS, backs them up, then removes them
# Arguments:
#   None (uses CONFIG_FILE_PATTERNS global)
# Globals:
#   BACKUP_DIR - Directory where backups are saved
#   enable_dry_run - If true, skip backup and only show what would be removed
backup_and_remove_files() {
    # Build list of files to process
    local -a config_files_to_process
    build_config_file_list

    # Return if no files to process
    [[ ${#config_files_to_process[@]} -eq 0 ]] && return 0

    # STEP 1: Backup (skip in dry-run mode)
    if [[ "$enable_dry_run" == false ]]; then
        # Create backup directory
        echo "Creating backup directory: $(display_path "$BACKUP_DIR")"
        mkdir -p "$BACKUP_DIR" || \
            error_exit "Failed to create backup directory: $(display_path "$BACKUP_DIR")"

        # Backup each file
        for file_path in "${config_files_to_process[@]}"; do
            backup_file "$file_path"
        done

        echo "Backup completed: $(display_path "$BACKUP_DIR")"
        echo ""
    fi

    # STEP 2: Remove
    echo "Removing existing configuration files..."

    for file_path in "${config_files_to_process[@]}"; do
        remove_file "$file_path"
    done
}

################################################################################
# Installation Functions
################################################################################
# Find maximum display path length from array of file paths
# Arguments:
#   $@ - Array of file paths
# Output:
#   Maximum length of display paths (after tilde conversion)
get_max_display_path_length() {
    local max_length=0

    for file_path in "$@"; do
        local display_path_str
        display_path_str="$(display_path "$file_path")"
        local length=${#display_path_str}
        (( length > max_length )) && max_length=$length
    done

    echo "$max_length"
}

# Install bash configuration files from repository to home directory
# Copies files defined in FILES_TO_INSTALL array to home directory
# All files are pre-validated to exist
# Respects dry-run mode when enabled
install_files() {
    echo "Installing configuration files from repository..."

    local installed_count=0
    local max_length
    max_length="$(get_max_display_path_length "${FILES_TO_INSTALL[@]}")"

    for source_file in "${FILES_TO_INSTALL[@]}"; do
        local filename
        filename="$(get_basename "$source_file")"
        local dest_file="$HOME/$filename"
        local source_display
        source_display="$(display_path "$source_file")"
        local dest_display
        dest_display="$(display_path "$dest_file")"

        # Pad source path to align arrows
        printf -v padded_source "%-${max_length}s" "$source_display"

        if [[ "$enable_dry_run" == true ]]; then
            echo "  [DRY RUN] Copy: $padded_source  ->  $dest_display"
        else
            cp "$source_file" "$dest_file" || error_exit "Failed to copy $filename"
            echo "  Installed: $padded_source  ->  $dest_display"
        fi
        ((installed_count++))
    done

    if [[ "$enable_dry_run" == false ]]; then
        echo ""
        echo "Installation complete: $installed_count files installed"
    else
        echo ""
        echo "[DRY RUN] Install $installed_count files"
    fi
}

# Create symlink from ~/bin/bin.github to repository's bin directory
# Creates ~/bin directory if it doesn't exist
# Removes existing symlink/file before creating new one
# Respects dry-run mode when enabled
create_bin_symlink() {
    echo "Creating symlink for bin directory..."

    local target_dir="$HOME/bin"
    local symlink_path="$target_dir/bin.github"

    # Ensure target directory exists
    if [[ ! -d "$target_dir" ]]; then
        if [[ "$enable_dry_run" == true ]]; then
            echo "  [DRY RUN] Create directory: $(display_path "$target_dir")"
        else
            mkdir -p "$target_dir" || error_exit "Failed to create bin symlink target directory: $(display_path "$target_dir")"
            echo "  Created directory: $(display_path "$target_dir")"
        fi
    fi

    # Remove existing symlink or file if it exists
    if [[ -e "$symlink_path" ]] || [[ -L "$symlink_path" ]]; then
        if [[ "$enable_dry_run" == true ]]; then
            echo "  [DRY RUN] Remove existing: $(display_path "$symlink_path")"
        else
            rm -f "$symlink_path" || error_exit "Failed to remove existing $(display_path "$symlink_path")"
            echo "  Removed existing: $(display_path "$symlink_path")"
        fi
    fi

    # Create the symlink
    if [[ "$enable_dry_run" == true ]]; then
        echo "  [DRY RUN] Create symlink: $(display_path "$symlink_path") -> $(display_path "$PATH_TO_REPO_BIN_DIR")"
    else
        ln -s "$PATH_TO_REPO_BIN_DIR" "$symlink_path" || error_exit "Failed to create symlink $(display_path "$symlink_path")"
        echo "  Created symlink: $(display_path "$symlink_path") -> $(display_path "$PATH_TO_REPO_BIN_DIR")"
    fi
}

################################################################################
# Parse Command-Line Options
################################################################################
enable_dry_run=false
project_root=""

while getopts ":hnp:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        n)
            enable_dry_run=true
            ;;
        p)
            project_root="$OPTARG"
            ;;
        \?)
            echo "ERROR: Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
        :)
            echo "ERROR: Option -$OPTARG requires an argument" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

################################################################################
# Input Validation
################################################################################
# Get and validate project root directory
if ! PROJECT_ROOT="$(get_project_root "$project_root")"; then
    exit 1
fi
readonly PROJECT_ROOT

# Get project name from git
PROJECT_NAME="$(get_git_project_name "$PROJECT_ROOT")"
readonly PROJECT_NAME

# Build and validate all paths from project root
PATH_TO_REPO_BASH_DIR="$PROJECT_ROOT/bash"
[[ -d "$PATH_TO_REPO_BASH_DIR" ]] || error_exit "bash directory not found for \"$PROJECT_NAME\" git project: $(display_path "$PATH_TO_REPO_BASH_DIR")"
readonly PATH_TO_REPO_BASH_DIR

PATH_TO_REPO_BIN_DIR="$PROJECT_ROOT/bin"
[[ -d "$PATH_TO_REPO_BIN_DIR" ]] || error_exit "bin directory not found for \"$PROJECT_NAME\" git project: $(display_path "$PATH_TO_REPO_BIN_DIR")"
readonly PATH_TO_REPO_BIN_DIR

# Define constants now that paths are validated
BACKUP_DIR="$HOME/.bash_backup_$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR
readonly FILES_TO_INSTALL=(
    "$PATH_TO_REPO_BASH_DIR/.aliases"
    "$PATH_TO_REPO_BASH_DIR/.aliases.linux"
    "$PATH_TO_REPO_BASH_DIR/.aliases.macos"
    "$PATH_TO_REPO_BASH_DIR/.bash_profile"
    "$PATH_TO_REPO_BASH_DIR/.bashrc"
    "$PATH_TO_REPO_BASH_DIR/.functions.sh"
    "$PATH_TO_REPO_BASH_DIR/.functions-macos.sh"
)

# Validate that all source files exist
for source_file in "${FILES_TO_INSTALL[@]}"; do
    [[ -f "$source_file" ]] || error_exit "Required configuration file not found for \"$PROJECT_NAME\" git project: $(display_path "$source_file")"
done

################################################################################
# Main Execution
################################################################################
if [[ "$enable_dry_run" == true ]]; then
    echo "=== DRY RUN MODE - No changes will be made ==="
    echo ""
fi

echo "Bash Configuration Installer"
echo "============================="
echo "Source: $(display_path "$PATH_TO_REPO_BASH_DIR")"
echo "Target: $(display_path "$HOME")"
echo ""

# Backup and remove existing configuration files
backup_and_remove_files
echo ""

# Install new files
install_files
echo ""

# Create bin symlink
create_bin_symlink

if [[ "$enable_dry_run" == false ]]; then
    echo ""
    echo "Installation successful!"
    echo ""
    echo "IMPORTANT: Please exit your terminal or SSH session and log back in"
    echo "           for the new configuration to take effect."
fi
exit 0
