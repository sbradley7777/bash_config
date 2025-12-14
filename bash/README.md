# Bash Configuration Files

This directory contains modular bash configuration files designed for cross-platform compatibility (Linux and macOS).

## Overview

The configuration is split into modular files for better organization and maintainability:

- **Core configuration** - `.bash_profile` and `.bashrc`
- **Platform-specific aliases** - Separate files for Linux and macOS
- **Shell functions** - Universal and platform-specific functions

This modular approach allows you to:
- Easily maintain configurations across multiple systems
- Keep platform-specific settings separate
- Share common configurations while customizing per-platform
- Version control your shell environment

## File Structure

```
bash/
├── .bash_profile          # Login shell configuration
├── .bashrc                # Interactive shell configuration
├── .aliases.linux         # Linux-specific aliases
├── .aliases.macos         # macOS-specific aliases
├── .functions.sh          # Universal shell functions
└── .functions-macos.sh    # macOS-specific functions
```

**Direct links:**
- **[`.bash_profile`](https://github.com/sbradley7777/bash_config/blob/master/bash/.bash_profile)** - Login shell configuration
- **[`.bashrc`](https://github.com/sbradley7777/bash_config/blob/master/bash/.bashrc)** - Interactive shell configuration
- **[`.aliases.linux`](https://github.com/sbradley7777/bash_config/blob/master/bash/.aliases.linux)** - Linux-specific aliases
- **[`.aliases.macos`](https://github.com/sbradley7777/bash_config/blob/master/bash/.aliases.macos)** - macOS-specific aliases
- **[`.functions.sh`](https://github.com/sbradley7777/bash_config/blob/master/bash/.functions.sh)** - Universal shell functions
- **[`.functions-macos.sh`](https://github.com/sbradley7777/bash_config/blob/master/bash/.functions-macos.sh)** - macOS-specific functions

## Core Configuration Files

### [`.bash_profile`](https://github.com/sbradley7777/bash_config/blob/master/bash/.bash_profile)

The login shell configuration file. Sourced when you log in to the system.

**What it configures:**
- Environment variables (`VISUAL`, `EDITOR`, `GREP_COLOR`)
- Shell history settings (unlimited history, ignore duplicates)
- Shell options (enable histappend)
- PATH configuration (adds `~/bin` if it exists)
- Sources `.bashrc` for interactive shell settings

**Key settings:**
```bash
export VISUAL="emacs -nw"          # Default visual editor
export EDITOR="$VISUAL"            # Default editor
export HISTSIZE=                   # Unlimited history
export HISTCONTROL=ignoredups      # Ignore duplicate commands
```

### [`.bashrc`](https://github.com/sbradley7777/bash_config/blob/master/bash/.bashrc)

The interactive shell configuration file. Sourced for every new interactive shell.

**What it configures:**
- Sources all alias files (platform-specific and universal)
- Loads shell functions (universal and platform-specific)
- Additional interactive shell settings

**How it works:**
```bash
# Sources all .aliases.* files automatically
# Sources .functions.sh and platform-specific function files
# Platform detection happens automatically via uname
```

## Alias Files

### [`.aliases.linux`](https://github.com/sbradley7777/bash_config/blob/master/bash/.aliases.linux)

Linux-specific aliases and settings.

**Includes:**
- `ls` with color support using `--color` flag
- Linux-specific command variations
- Platform-specific shortcuts

### [`.aliases.macos`](https://github.com/sbradley7777/bash_config/blob/master/bash/.aliases.macos)

macOS-specific aliases and settings.

**Includes:**
- `ls` with color support using `-G` flag (BSD `ls`)
- macOS-specific utilities (like `md5` vs `md5sum`)
- Homebrew-related shortcuts
- macOS system commands

**Note:** The configuration automatically detects your platform and sources the correct alias file.

## Function Files

### [`.functions.sh`](https://github.com/sbradley7777/bash_config/blob/master/bash/.functions.sh)

Universal shell functions that work on all platforms.

**Example functions:**
- File operations (create and navigate, directory sizing)
- Path manipulation utilities
- Common helper functions
- Platform-agnostic tools

### [`.functions-macos.sh`](https://github.com/sbradley7777/bash_config/blob/master/bash/.functions-macos.sh)

macOS-specific shell functions.

**Example functions:**
- Spotlight search helpers
- Homebrew utilities
- macOS system management
- Applications and preferences shortcuts

## How the Configuration Loads

When you start a shell, the files are loaded in this order:

1. **Login shell** (e.g., opening Terminal):
   ```
   .bash_profile
   └── sources .bashrc
       ├── sources .aliases.linux or .aliases.macos
       ├── sources .functions.sh
       └── sources .functions-macos.sh (if on macOS)
   ```

2. **Interactive shell** (e.g., running `bash`):
   ```
   .bashrc
   ├── sources .aliases.linux or .aliases.macos
   ├── sources .functions.sh
   └── sources .functions-macos.sh (if on macOS)
   ```

## Installation

### Backup Existing Configuration

If you have existing configuration files, back them up first:

```bash
mv ~/.bash_profile ~/.bash_profile.backup
mv ~/.bashrc ~/.bashrc.backup
```

### Copy Configuration Files

Copy the files to your home directory:

```bash
cp ~/github/bash_config/bash/{.aliases.linux,.aliases.macos,.bash_profile,.bashrc,.functions.sh,.functions-macos.sh} ~/
```

### Reload Your Shell

```bash
source ~/.bash_profile
```

## Customization

### Adding Personal Configuration

To add personal configuration that won't be tracked by git:

1. Create a `.bashrc.priv` or `.bash_profile.priv` file in your home directory
2. The main configuration files will automatically source these if they exist
3. Add your personal aliases, functions, and settings there

### Adding Platform-Specific Aliases

To add more aliases:

1. Edit the appropriate `.aliases.*` file
2. Follow the existing format and organization
3. Use section separators for clarity:
   ```bash
   ################################################################################
   # Section Name
   ################################################################################
   ```

### Adding Functions

To add new functions:

1. For universal functions - add to `.functions.sh`
2. For macOS-specific - add to `.functions-macos.sh`
3. Include docstring comments for complex functions
4. Use descriptive names with underscores (lowercase)

## Platform Detection

The configuration automatically detects your platform using `uname`:

```bash
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS-specific configuration
    source "$HOME/.aliases.macos"
    source "$HOME/.functions-macos.sh"
elif [[ "$(uname)" == "Linux" ]]; then
    # Linux-specific configuration
    source "$HOME/.aliases.linux"
fi
```

## Troubleshooting

### Configuration not loading

Check if the files are being sourced:

```bash
# Add debug output temporarily
echo "Loading .bash_profile"  # Add to .bash_profile
echo "Loading .bashrc"         # Add to .bashrc
```

### Aliases not working

Verify your platform is detected correctly:

```bash
uname  # Should output "Darwin" for macOS or "Linux"
```

### Functions not available

Check if function files are being sourced:

```bash
# In your shell
type function_name  # Should show the function definition
```

## References

- [Bash Startup Files](https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html)
- [.bash_profile vs .bashrc](https://apple.stackexchange.com/questions/51036/what-is-the-difference-between-bash-profile-and-bashrc)
- [Shell Configuration Best Practices](https://mywiki.wooledge.org/DotFiles)
