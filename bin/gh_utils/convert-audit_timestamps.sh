#!/bin/bash
#
# Description:
#   Convert audit log epoch timestamps to human-readable format.
#   Reads an audit log file and creates a new file with timestamps prepended
#   to each line in the format "Mon DD HH:MM:SS".
#
# Usage:
#   convert-audit_timestamps.sh [-h] <filename>
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   filename    Path to the audit log file to process
#
# Examples:
#   $ ./convert-audit_timestamps.sh /var/log/audit/audit.log
#   $ ./convert-audit_timestamps.sh ~/logs/audit.log
#
# Dependencies:
#   - readlink
#   - sed
#   - date
#
# Notes:
#   The output file will be created as <filename>.mod in the same directory.
#   If the output file already exists, it will be removed and recreated.
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
Usage: $(basename "$0") [-h] <filename>

Description:
  Convert audit log epoch timestamps to human-readable format.

Options:
  -h    Show this help message and exit

Arguments:
  filename    Path to the audit log file to process

Examples:
  $ $(basename "$0") /var/log/audit/audit.log
  $ $(basename "$0") ~/logs/audit.log

Notes:
  The output file will be created as <filename>.mod in the same directory.
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
[[ -n "$1" ]] || error_exit "Missing required argument: filename"

################################################################################
# Main Execution
################################################################################
path_to_source="$(readlink -f "$1")"
path_to_output_file=$path_to_source.mod

if [[ -f "$path_to_output_file" ]]; then
    rm -rf "$path_to_output_file"
fi

while read -r line; do
    # shellcheck disable=SC2001
    time=$(echo "$line" | sed 's/.*audit(\([0-9]*\).*/\1/')
    echo "$(date -d @"$time" "+%b %d %H:%M:%S")" "$line" >> "$path_to_output_file"
done < "$path_to_source"

exit 0
