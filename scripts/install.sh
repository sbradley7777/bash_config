#!/bin/bash
#
# Description:
#   Install bash configuration files from the repository to the user's home directory.
#   Removes existing configuration files and copies new ones from the repository.
#
# Usage:
#   install.sh [-h] [-n] [-p <project_root>]
#
# Options:
#   -h              Show this help message and exit
#   -n              Dry run - show what would be done without making changes
#   -p <path>       Specify project root directory (auto-detected if not provided)
#
# Examples:
#   $ ./install.sh
#   $ ./install.sh -n
#   $ ./install.sh -p ~/github/bash_config
#
# Dependencies:
#   - bash 4.0 or later (for associative arrays)
#   - git
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

# Wildcard patterns to catch additional configuration files to backup and remove
# Specific files are automatically derived from FILES_TO_INSTALL keys
readonly CONFIG_FILE_PATTERNS=(
    "$HOME/.aliases"*      # Matches .aliases, .aliases.linux, .aliases.macos, etc.
    "$HOME/.functions"*    # Matches .functions.sh, .functions-macos.sh, etc.
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
  - Run with auto-detected project root:
    $ ./$(basename "$0")

  - Preview changes without making modifications:
    $ ./$(basename "$0") -n

  - Specify project root directory explicitly:
    $ ./$(basename "$0") -p ~/github/bash_config

  - Dry run with explicit project root:
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
# Includes files from FILES_TO_INSTALL keys and CONFIG_FILE_PATTERNS wildcards
# Arguments:
#   None (uses FILES_TO_INSTALL and CONFIG_FILE_PATTERNS globals)
# Output:
#   Sets global array: config_files_to_process
# Returns:
#   0 if files found, 1 if no files found
build_config_file_list() {
    local -A seen_files
    config_files_to_process=()

    # Add files from FILES_TO_INSTALL (specific files we're installing)
    for dest_file in "${!FILES_TO_INSTALL[@]}"; do
        if [[ -e "$dest_file" ]] && [[ -z "${seen_files[$dest_file]}" ]]; then
            config_files_to_process+=("$dest_file")
            seen_files["$dest_file"]=1
        fi
    done

    # Add files matching wildcard patterns (catches additional files)
    # Note: pattern is intentionally unquoted to allow glob expansion
    for pattern in "${CONFIG_FILE_PATTERNS[@]}"; do
        for file in $pattern; do
            if [[ -e "$file" ]] && [[ -z "${seen_files[$file]}" ]]; then
                config_files_to_process+=("$file")
                seen_files["$file"]=1
            fi
        done
    done

    [[ ${#config_files_to_process[@]} -gt 0 ]] && return 0 || return 1
}

# Backup a single file or directory to backup directory
# Arguments:
#   $1 - Full path to file or directory to backup
# Globals:
#   BACKUP_DIR - Backup directory path
# Output:
#   Prints backup confirmation message
backup_file() {
    local file_path="$1"
    local filename
    filename="$(get_basename "$file_path")"

    if [[ -d "$file_path" ]]; then
        cp -r "$file_path" "$BACKUP_DIR/" || error_exit "Failed to backup directory $filename"
    else
        cp "$file_path" "$BACKUP_DIR/" || error_exit "Failed to backup $filename"
    fi
    echo "  Backed up: $filename"
}

# Remove a single file, directory, or symlink
# Arguments:
#   $1 - Full path to file/directory/symlink to remove
# Globals:
#   enable_dry_run - If true, only show what would be done
# Output:
#   Prints removal confirmation message
remove_file() {
    local file_path="$1"

    if [[ "$enable_dry_run" == true ]]; then
        echo "  [DRY RUN] Removed: $(display_path "$file_path")"
    else
        rm -rf "$file_path" || error_exit "Failed to remove $(display_path "$file_path")"
        echo "  Removed: $(display_path "$file_path")"
    fi
}

# Copy a single file or directory with formatted display
# Arguments:
#   $1 - Source file or directory path
#   $2 - Destination file or directory path
# Globals:
#   enable_dry_run - If true, only show what would be done
#   FILES_TO_INSTALL - Used to calculate max path length for alignment
# Output:
#   Prints copy confirmation message with arrow notation
copy_file() {
    local source_file="$1"
    local dest_file="$2"
    local filename
    filename="$(get_basename "$source_file")"

    # Calculate max length for arrow alignment
    local max_length
    max_length="$(get_max_display_path_length "${FILES_TO_INSTALL[@]}")"

    # Get display paths
    local source_display
    source_display="$(display_path "$source_file")"
    local dest_display
    dest_display="$(display_path "$dest_file")"

    # Pad source path to align arrows
    local padded_source
    printf -v padded_source "%-${max_length}s" "$source_display"

    if [[ "$enable_dry_run" == true ]]; then
        echo "  [DRY RUN] Copy: $padded_source  ->  $dest_display"
    else
        if [[ -d "$source_file" ]]; then
            cp -r "$source_file" "$dest_file" || error_exit "Failed to copy directory $filename"
        else
            cp "$source_file" "$dest_file" || error_exit "Failed to copy $filename"
        fi
        echo "  Installed: $padded_source  ->  $dest_display"
    fi
}

# Create a directory
# Arguments:
#   $1 - Directory path to create
# Globals:
#   enable_dry_run - If true, only show what would be done
# Output:
#   Prints directory creation confirmation message
create_directory() {
    local dir_path="$1"

    if [[ "$enable_dry_run" == true ]]; then
        echo "  [DRY RUN] Create directory: $(display_path "$dir_path")"
    else
        mkdir -p "$dir_path" || error_exit "Failed to create directory: $(display_path "$dir_path")"
        echo "  Created directory: $(display_path "$dir_path")"
    fi
}

# Create a symbolic link
# Arguments:
#   $1 - Target path (what the symlink points to)
#   $2 - Symlink path (the symlink itself)
# Globals:
#   enable_dry_run - If true, only show what would be done
# Output:
#   Prints symlink creation confirmation message
create_symlink() {
    local target="$1"
    local link_path="$2"

    if [[ "$enable_dry_run" == true ]]; then
        echo "  [DRY RUN] Create symlink: $(display_path "$link_path") -> $(display_path "$target")"
    else
        ln -s "$target" "$link_path" || error_exit "Failed to create symlink $(display_path "$link_path")"
        echo "  Created symlink: $(display_path "$link_path") -> $(display_path "$target")"
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
# Builds list from FILES_TO_INSTALL keys and CONFIG_FILE_PATTERNS wildcards
# Arguments:
#   None (uses FILES_TO_INSTALL and CONFIG_FILE_PATTERNS globals)
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

# Remove existing items at symlink paths
# No backup needed - symlinks contain no data
# Arguments:
#   None (uses SYMLINKS global)
# Globals:
#   SYMLINKS - Associative array of symlink paths to targets
#   enable_dry_run - If true, only show what would be removed
remove_symlinks() {
    # Filter to only items that exist
    local -a items_to_remove=()
    for link_path in "${!SYMLINKS[@]}"; do
        [[ -e "$link_path" ]] || [[ -L "$link_path" ]] && items_to_remove+=("$link_path")
    done

    # Return if nothing to remove
    [[ ${#items_to_remove[@]} -eq 0 ]] && return 0

    echo "Removing existing items at symlink paths..."
    for link_path in "${items_to_remove[@]}"; do
        remove_file "$link_path"
    done
}

# Create symlinks from repository directories to home directory
# Uses associative array SYMLINKS (key: destination path, value: source path)
# All sources are pre-validated to exist
# Ensures parent directories exist before creating symlinks
# Respects dry-run mode when enabled
install_symlinks() {
    echo "Creating symlinks..."

    local symlink_count=0

    for link_path in "${!SYMLINKS[@]}"; do
        local target="${SYMLINKS[$link_path]}"
        local parent_dir
        parent_dir="$(dirname "$link_path")"

        # Ensure parent directory exists
        if [[ ! -d "$parent_dir" ]]; then
            create_directory "$parent_dir"
        fi

        # Create the symlink
        create_symlink "$target" "$link_path"
        ((symlink_count++))
    done

    if [[ "$enable_dry_run" == false ]]; then
        echo ""
        echo "Symlink creation complete: $symlink_count symlinks created"
    else
        echo ""
        echo "[DRY RUN] Create $symlink_count symlinks"
    fi
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
# Copies files defined in FILES_TO_INSTALL associative array
# Uses associative array (key: destination path, value: source path)
# All files are pre-validated to exist
# Respects dry-run mode when enabled
install_files() {
    echo "Installing configuration files from repository..."

    local installed_count=0

    for dest_file in "${!FILES_TO_INSTALL[@]}"; do
        local source_file="${FILES_TO_INSTALL[$dest_file]}"

        copy_file "$source_file" "$dest_file"
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

################################################################################
# File Configuration
################################################################################
# Define constants now that paths are validated
BACKUP_DIR="$HOME/.bash_backup_$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR

# Files to copy (associative array)
# Key: destination path, Value: source path
declare -A FILES_TO_INSTALL
FILES_TO_INSTALL["$HOME/.aliases"]="$PATH_TO_REPO_BASH_DIR/.aliases"
FILES_TO_INSTALL["$HOME/.aliases.linux"]="$PATH_TO_REPO_BASH_DIR/.aliases.linux"
FILES_TO_INSTALL["$HOME/.aliases.macos"]="$PATH_TO_REPO_BASH_DIR/.aliases.macos"
FILES_TO_INSTALL["$HOME/.bash_profile"]="$PATH_TO_REPO_BASH_DIR/.bash_profile"
FILES_TO_INSTALL["$HOME/.bashrc"]="$PATH_TO_REPO_BASH_DIR/.bashrc"
FILES_TO_INSTALL["$HOME/.functions.sh"]="$PATH_TO_REPO_BASH_DIR/.functions.sh"
FILES_TO_INSTALL["$HOME/.functions-macos.sh"]="$PATH_TO_REPO_BASH_DIR/.functions-macos.sh"
readonly FILES_TO_INSTALL

# Validate that all source files exist
for source_file in "${FILES_TO_INSTALL[@]}"; do
    [[ -e "$source_file" ]] || error_exit "Required source not found for \"$PROJECT_NAME\" git project: $(display_path "$source_file")"
done

################################################################################
# Symlink Configuration
################################################################################
# Symlinks to create (associative array)
# Key: destination path (symlink location), Value: source path (target)
declare -A SYMLINKS
SYMLINKS["$HOME/bin/bin.github"]="$PROJECT_ROOT/bin"
readonly SYMLINKS

# Validate that all symlink sources exist
for target in "${SYMLINKS[@]}"; do
    [[ -e "$target" ]] || error_exit "Symlink source not found: $(display_path "$target")"
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

# Remove and recreate symlinks (no backup needed)
remove_symlinks
echo ""

install_symlinks

if [[ "$enable_dry_run" == false ]]; then
    echo ""
    echo "Installation successful!"
    echo ""
    echo "IMPORTANT: Please exit your terminal or SSH session and log back in"
    echo "           for the new configuration to take effect."
fi
exit 0
