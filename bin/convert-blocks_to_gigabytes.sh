#!/bin/bash
#
# Description:
#   Convert 1K blocks to gigabytes in human-readable format.
#   Useful for converting df output which reports sizes in 1K blocks.
#
# Usage:
#   convert-blocks_to_gigabytes.sh [-h] <blocks>
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   blocks    Number of 1K blocks to convert to GB
#
# Examples:
#   $ ./convert-blocks_to_gigabytes.sh 1048576
#   1 GB
#   $ df -k / | tail -1 | awk '{print $2}' | xargs ./convert-blocks_to_gigabytes.sh
#
# Dependencies:
#   - bc (optional, uses bash arithmetic if not available)
#
# Exit Codes:
#   0    Success
#   1    Missing required argument
#

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] <blocks>

Description:
  Convert 1K blocks to gigabytes in human-readable format.

Options:
  -h    Show this help message and exit

Arguments:
  blocks    Number of 1K blocks to convert to GB

Examples:
  $ $(basename "$0") 1048576
  1 GB
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
[[ -n "$1" ]] || error_exit "Missing required argument: blocks"

################################################################################
# Main Execution
################################################################################
gigabytes=$(( $1 / (1024 * 1024) ))
echo "$gigabytes GB"
exit 0
