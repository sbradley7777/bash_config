# Scripts Directory

This directory contains utility scripts for managing the bash configuration repository.

## Table of Contents

- [install.sh](#installsh)
  - [Overview](#overview)
  - [Features](#features)
  - [Usage](#usage)
  - [Options](#options)
  - [Examples](#examples)
  - [How It Works](#how-it-works)
  - [Error Handling](#error-handling)
  - [Testing](#testing)

---

## install.sh

### Overview

[`install.sh`](install.sh) is an intelligent installer that deploys bash configuration files from this repository to your home directory. It automatically detects the repository location, validates the environment, and safely installs configuration files with optional backup support.

### Features

- **Auto-detection**: Automatically finds the repository root by searching for the `.git` directory
- **Git validation**: Verifies you're installing from the correct repository using `git config`
- **Safe installation**: Validates all requirements before making any changes (fail-fast approach)
- **Automatic backups**: Creates timestamped backups of existing configuration files before removal
- **Dry-run mode**: Preview changes without modifying your system
- **Path display**: User-friendly path output with `~` notation
- **Comprehensive error handling**: Clear, contextual error messages with proper exit codes
- **Symlink management**: Creates `~/bin/bin.github` symlink to repository's [`bin/`](../bin) directory

### Usage

```bash
./install.sh [-h] [-n] [-p <project_root>]
```

### Options

| Option | Description |
|--------|-------------|
| `-h` | Show help message and exit |
| `-n` | Dry run - show what would be done without making changes |
| `-p <path>` | Specify project root directory (auto-detected if not provided) |

**Note**: The installer **always creates timestamped backups** of existing configuration files before removal (except in dry-run mode). Backups are saved to `~/.bash_backup_<timestamp>/` (e.g., `~/.bash_backup_20251215_103045/`).

### Examples

**Basic installation** (auto-detects repository and creates backups):
```bash
cd ~/github/bash_config/scripts
./install.sh
```

**Dry run to preview changes** (no backups created, no changes made):
```bash
./install.sh -n
```

**Specify project root manually**:
```bash
./install.sh -p ~/github/bash_config
```

### How It Works

#### 1. Project Root Detection

The script uses intelligent auto-detection to find the repository root:

1. Starts from the script's directory (`scripts/`)
2. Searches upward for `.git` directory (up to 10 levels)
3. Validates it's the correct repository using `git config --get remote.origin.url`
4. Extracts project name from git remote URL
5. Confirms project name matches `"bash_config"`

If auto-detection fails, you can manually specify the path with `-p`.

#### 2. Validation Phase (Fail-Fast)

Before making any changes, the script validates:

- ✓ Project root directory exists and is accessible
- ✓ Git repository is correct project (`bash_config`)
- ✓ [`bash/`](../bash) directory exists in repository
- ✓ [`bin/`](../bin) directory exists in repository
- ✓ All required configuration files exist:
  - [`bash/.aliases.linux`](../bash/.aliases.linux)
  - [`bash/.aliases.macos`](../bash/.aliases.macos)
  - [`bash/.bash_profile`](../bash/.bash_profile)
  - [`bash/.bashrc`](../bash/.bashrc)
  - [`bash/.functions.sh`](../bash/.functions.sh)
  - [`bash/.functions-macos.sh`](../bash/.functions-macos.sh)

If any validation fails, the script exits immediately with a clear error message.

#### 3. Backup Phase (Automatic)

The installer **always creates backups** before making changes (except in dry-run mode):

1. Creates timestamped backup directory: `~/.bash_backup_YYYYMMDD_HHMMSS`
2. Backs up existing files if they exist:
   - `~/.bash_profile`
   - `~/.bashrc`
   - `~/.aliases.*` (all alias files)
   - `~/.functions*` (all function files)
3. Displays backup location
4. If no files exist to backup, removes empty backup directory

#### 4. Installation Phase

1. **Remove existing files**:
   - Removes `~/.bash_profile`
   - Removes `~/.bashrc`
   - Removes all `~/.aliases.*` files
   - Removes all `~/.functions*` files

2. **Install new files**:
   - Copies all files from repository's [`bash/`](../bash) directory to `~/`
   - Preserves original filenames

3. **Create symlink**:
   - Creates `~/bin` directory if it doesn't exist
   - Removes existing `~/bin/bin.github` symlink/file if present
   - Creates symlink: `~/bin/bin.github` → repository's [`bin/`](../bin) directory

#### 5. Post-Installation

Displays success message and reminds user to:
- Exit terminal or SSH session
- Log back in for new configuration to take effect

### Error Handling

The script provides clear, contextual error messages:

**Invalid -p option path**:
```
ERROR: Invalid path provided with -p option: /nonexistent/path
```

**Auto-detection failure**:
```
ERROR: Could not auto-detect "bash_config" git project root. Please specify with -p option.
```

**Wrong git repository**:
```
ERROR: Git project validation failed: ~/wrong_repo is "other_project" git project, not "bash_config"
```

**Missing bash/ directory**:
```
ERROR: bash directory not found for "bash_config" git project: ~/project/bash
```

**Missing bin/ directory**:
```
ERROR: bin directory not found for "bash_config" git project: ~/project/bin
```

**Missing configuration file**:
```
ERROR: Required configuration file not found for "bash_config" git project: ~/project/bash/.bashrc
```

All errors:
- Print to stderr
- Exit with code 1
- Include full context (project name, file/directory path)
- Use `~` notation for paths

### Testing

The script has been tested with multiple scenarios:

1. ✓ Valid repository with all files present
2. ✓ Missing `.git` directory
3. ✓ Wrong git repository
4. ✓ Missing `bash/` directory
5. ✓ Missing `bin/` directory
6. ✓ Missing configuration files
7. ✓ Dry-run mode
8. ✓ Backup mode
9. ✓ ShellCheck compliance

**To test the script**:

```bash
# Dry run to preview changes
./install.sh -n

# Dry run with backup preview
./install.sh -b -n

# Run shellcheck
shellcheck install.sh
```

### Technical Details

**Constants**:
- `EXPECTED_PROJECT_NAME` - Expected git project name (`"bash_config"`)
- `CONFIG_FILE_PATTERNS` - Array of file patterns to backup/remove (readonly)
- `PROJECT_ROOT` - Validated project root directory (readonly)
- `PROJECT_NAME` - Actual project name from git (readonly)
- `PATH_TO_REPO_BASH_DIR` - Path to repository's `bash/` directory (readonly)
- `PATH_TO_REPO_BIN_DIR` - Path to repository's `bin/` directory (readonly)
- `BACKUP_DIR` - Timestamped backup directory (readonly)
- `FILES_TO_INSTALL` - Array of files to install with full paths (readonly)

**Functions**:
- `usage()` - Display help message
- `error_exit()` - Print error to stderr and exit
- `display_path()` - Convert `$HOME` to `~` in paths
- `get_basename()` - Extract filename from path
- `build_config_file_list()` - Build array of files from patterns (internal helper)
- `backup_file()` - Backup a single file (internal helper)
- `remove_file()` - Remove a single file (internal helper)
- `backup_and_remove_files()` - Build file list, backup and remove all configuration files
- `find_git_project_root()` - Search upward for `.git` directory
- `get_git_project_name()` - Extract project name from git remote URL
- `validate_project_root()` - Verify correct git repository
- `get_project_root()` - Get and validate project root (combines detection + validation)
- `install_files()` - Copy new configuration files
- `create_bin_symlink()` - Create `~/bin/bin.github` symlink

**Exit Codes**:
- `0` - Success
- `1` - General error (validation failed, file not found, copy failed, etc.)

---

## Contributing

When adding new scripts to this directory:

1. Follow the bash scripting standards defined in [`CLAUDE.md`](../CLAUDE.md)
2. Include comprehensive header documentation
3. Add error handling with `error_exit()` function
4. Use shellcheck to validate your script
5. Update this README with documentation for the new script
6. Test all error scenarios
