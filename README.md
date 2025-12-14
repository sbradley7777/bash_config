# Bash Configuration and Utility Scripts

A collection of well-organized bash configuration files and utility scripts for Linux and macOS systems.

## Overview

This repository provides:
- **Modular bash configuration** - Organized into platform-specific and universal components
- **Utility scripts** - A collection of 15+ production-ready bash scripts
- **Code quality standards** - All scripts follow strict bash coding standards
- **Cross-platform support** - Works seamlessly on Linux and macOS

## Repository Structure

```
bash_config/
├── bash/               # Bash configuration files
│   ├── .bash_profile   # Login shell configuration
│   ├── .bashrc         # Interactive shell configuration
│   ├── .aliases.linux  # Linux-specific aliases
│   ├── .aliases.macos  # macOS-specific aliases
│   ├── .functions.sh   # Universal shell functions
│   └── .functions-macos.sh  # macOS-specific functions
├── bin/                # Utility scripts (15 scripts)
└── README.md           # This file
```

See **[bash/README.md](https://github.com/sbradley7777/bash_config/blob/master/bash/README.md)** for detailed information about the bash configuration files.

## Quick Start

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/sbradley7777/bash_config.git ~/github/bash_config
   ```

2. Copy the configuration files to your home directory:
   ```bash
   cp ~/github/bash_config/bash/{.aliases.linux,.aliases.macos,.bash_profile,.bashrc,.functions.sh,.functions-macos.sh} ~/
   ```

3. Link the bin directory:
   ```bash
   ln -s ~/github/bash_config/bin ~/bin/bin.github
   ```

4. Reload your shell:
   ```bash
   source ~/.bash_profile
   ```

### Usage

After installation, the bash configuration will automatically:
- Source platform-specific aliases (Linux or macOS)
- Load universal and platform-specific functions
- Configure shell history, prompt, and environment variables

Utility scripts will be available at `~/bin/bin.github/`.

## Featured Utility Scripts

The **[bin/](https://github.com/sbradley7777/bash_config/tree/master/bin)** directory includes 15+ utility scripts for common tasks:

**File Operations:**
- **[dusize.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/dusize.sh)** - Display directory sizes in human-readable format
- **[convert-bytes.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/convert-bytes.sh)** - Convert bytes to human-readable units

**Network Tools:**
- **[check_ssl.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/check_ssl.sh)** - Test SSL/TLS protocol versions on remote servers
- **[gethostip.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/gethostip.sh)** - Resolve hostname to IP address
- **[getdstip.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/getdstip.sh)** - Get destination IP from network routes
- **[ping-test.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/ping-test.sh)** - Advanced ping testing utility

**Development Tools:**
- **[findregexs.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/findregexs.sh)** - Search for regex patterns across files
- **[prefix_space.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/prefix_space.sh)** - Add leading spaces to file lines
- **[today.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/today.sh)** - Display current date and time information

**System Administration:**
- **[convert-audit_timestamps.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/convert-audit_timestamps.sh)** - Convert audit log timestamps
- **[convert-blocks_to_gigabytes.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/convert-blocks_to_gigabytes.sh)** - Convert disk blocks to GB
- **[hosts-generator.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/hosts-generator.sh)** - Generate /etc/hosts entries

**Package Management (RPM):**
- **[rpm-source.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/rpm-source.sh)** - Download RPM source packages
- **[rpmxtract.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/rpmxtract.sh)** - Extract files from RPM packages

**Documentation:**
- **[convert-manpages.sh](https://github.com/sbradley7777/bash_config/blob/master/bin/convert-manpages.sh)** - Convert man pages to text format

All scripts include comprehensive help documentation accessible with the `-h` flag.

## Code Quality

This repository maintains high code quality standards:

- ✅ **ShellCheck compliant** - All scripts pass ShellCheck with no errors
- ✅ **bashate verified** - Enforces consistent bash style
- ✅ **Pre-commit hooks** - Automated quality checks before commits
- ✅ **Comprehensive documentation** - Every script includes usage examples
- ✅ **Standard structure** - Consistent organization across all scripts

### Pre-commit Hooks

The repository includes **[pre-commit hooks](https://github.com/sbradley7777/bash_config/blob/master/.pre-commit-config.yaml)** for:
- Shell script validation (shellcheck)
- Bash style enforcement (bashate)
- Trailing whitespace removal
- End-of-file fixing

To enable pre-commit hooks:
```bash
pip install pre-commit
pre-commit install
```

## Platform Support

Tested and working on:
- **Linux** - Red Hat Enterprise Linux, CentOS, Fedora, Ubuntu
- **macOS** - macOS 10.14+

The configuration automatically detects your platform and loads the appropriate aliases and functions.

## Contributing

When contributing scripts or configuration:
1. Follow the repository coding standards
2. Run ShellCheck and bashate on all bash scripts
3. Include proper header documentation with usage examples
4. Test on both Linux and macOS when possible
5. Add appropriate error handling and input validation

## License

This project is open source and available for personal and commercial use.

## References

- [ShellCheck](https://www.shellcheck.net/) - Shell script analysis tool
- [bashate](https://github.com/openstack/bashate) - Bash style checker
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)
