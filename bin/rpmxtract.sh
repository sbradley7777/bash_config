#!/bin/bash
#
# Description:
#   Extract an RPM package to the current working directory.
#   Converts RPM to cpio archive and extracts all files while preserving
#   directory structure.
#
# Usage:
#   rpmxtract.sh [-h] <rpm_file>
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   rpm_file    Path to RPM file to extract
#
# Examples:
#   $ ./rpmxtract.sh package-1.0.rpm
#   $ ./rpmxtract.sh /path/to/some-package.rpm
#
# Dependencies:
#   - rpm2cpio
#   - cpio
#
# Notes:
#   - Extracts to current working directory
#   - Preserves directory structure from RPM
#   - Use -ivd flags: interactive, verbose, create directories
#
# Exit Codes:
#   0    Success
#   1    Error - missing argument or extraction failed
#

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] <rpm_file>

Description:
  Extract an RPM package to the current working directory.

Options:
  -h    Show this help message and exit

Arguments:
  rpm_file    Path to RPM file to extract

Examples:
  $ $(basename "$0") package-1.0.rpm
  $ $(basename "$0") /path/to/some-package.rpm
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
[[ -n "$1" ]] || error_exit "Missing required argument: rpm_file"
rpm_file="$1"

################################################################################
# Main Execution
################################################################################
# Convert RPM to cpio and extract
rpm2cpio "$rpm_file" | cpio -ivd

exit 0
