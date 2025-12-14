#!/bin/bash
#
# Description:
#   Extract and prepare a source RPM for building.
#   Installs a source RPM, extracts its contents, and prepares the build
#   environment in ~/redhat/<name>/<version>/ directory.
#
# Usage:
#   rpm-source.sh [-h] <source_rpm_file>
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   source_rpm_file    Path to source RPM file (.src.rpm) or URL
#
# Examples:
#   $ ./rpm-source.sh ~/conga-0.12.src.rpm
#   $ ./rpm-source.sh http://example.com/package-1.0.src.rpm
#   $ ./rpm-source.sh /path/to/source.rpm
#
# Dependencies:
#   - rpm
#   - rpmbuild
#
# Notes:
#   - Creates directory structure in ~/redhat/<name>/<version>/
#   - Subdirectories: RPMS, SRPMS, SPECS, SOURCES, BUILD
#   - Cleans up temporary BUILD directories after extraction
#
# Exit Codes:
#   0    Success
#   1    Error - missing argument or file not found
#

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] <source_rpm_file>

Description:
  Extract and prepare a source RPM for building.

Options:
  -h    Show this help message and exit

Arguments:
  source_rpm_file    Path to source RPM file (.src.rpm) or URL

Examples:
  $ $(basename "$0") ~/conga-0.12.src.rpm
  $ $(basename "$0") http://example.com/package-1.0.src.rpm
  $ $(basename "$0") /path/to/source.rpm
EOF
}

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: $message" >&2
    exit "$exit_code"
}

################################################################################
# Parse Command-Line Options
################################################################################
while getopts ":h" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        \?)
            echo "ERROR: Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

################################################################################
# Input Validation
################################################################################
[[ -n "$1" ]] || error_exit "Missing required argument: source_rpm_file"
rpm_file="$1"

################################################################################
# Main Execution
################################################################################
echo "Installing the RPM: $rpm_file"

# Extract package name and version from RPM
package_name=$(rpm -qp --qf '%{NAME}' "$rpm_file")
package_version=$(rpm -qp --qf '%{VERSION}' "$rpm_file")
spec_file=$(rpm -qlp "$rpm_file" | grep ".spec$")

# Create build directory structure
mkdir -p ~/redhat/"$package_name"/"$package_version"/{RPMS,SRPMS,SPECS,SOURCES,BUILD}

# Install the source RPM
rpm -ivh "$rpm_file"

# Change to build directory
cd ~/redhat/"$package_name"/"$package_version"/ || error_exit "Failed to change to build directory"

# Prepare the build (extract sources, apply patches)
rpmbuild -bp --target=x86_64 SPECS/"$spec_file" --nodeps

# Clean up temporary directories
rm -rf ~/redhat/%\{name\}/
rm -rf ~/redhat/BUILD ~/redhat/RPMS ~/redhat/SRPMS ~/redhat/SPECS ~/redhat/SOURCES

exit 0
