#!/bin/bash
#
# Description:
#   Convert bytes to human-readable format (bytes, KB, MB, GB, TB, PB, EB, ZB, YB).
#   Automatically selects the appropriate unit based on the input size.
#
# Usage:
#   convert-bytes.sh [-h] <bytes>
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   bytes    Number of bytes to convert (must be a non-negative integer)
#
# Examples:
#   $ ./convert-bytes.sh 500
#   500.00bytes
#   $ ./convert-bytes.sh 51200
#   50.00KB
#   $ ./convert-bytes.sh 52428800
#   50.00MB
#   $ stat -c%s /bin/bash | xargs ./convert-bytes.sh
#
# Dependencies:
#   - bc
#   - cut
#
# Notes:
#   Based on: http://www.kossboss.com/linux---bytes-to-human-readable-command
#
# Exit Codes:
#   0    Success
#   1    Invalid argument (not an integer)
#
################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] <bytes>

Description:
  Convert bytes to human-readable format.

Options:
  -h    Show this help message and exit

Arguments:
  bytes    Number of bytes to convert (must be a non-negative integer)

Examples:
  $ $(basename "$0") 500
  500.00bytes
  $ $(basename "$0") 52428800
  50.00MB
EOF
}

# Error handling function
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: $message" >&2
    exit "$exit_code"
}

# Converts bytes to human-readable format with appropriate unit
# Arguments:
#   $1 - Number of bytes (must be non-negative integer)
# Output:
#   Prints formatted size to stdout (e.g., "5.00GB", "50.00KB")
bytes_to_human_readable() {
    local size_list="bytes,KB,MB,GB,TB,PB,EB,ZB,YB"
    local power=1
    local value
    local value_int

    value=$(echo "scale=2; $1 / 1" | bc)
    value_int=$(echo "$value / 1024" | bc)

    while [[ "$value_int" -gt 0 ]]; do
        power=$(( power + 1 ))
        value=$(echo "scale=2; $value / 1024" | bc)
        value_int=$(echo "$value / 1024" | bc)
    done

    echo "${value}$(echo "$size_list" | cut -f"$power" -d,)"
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
[[ -n "$1" ]] || error_exit "Missing required argument: bytes"

# Validate that argument is a number
re='^[0-9]+$'
[[ $1 =~ $re ]] || error_exit "Argument must be a non-negative integer, got: $1"

################################################################################
# Main Execution
################################################################################
bytes_to_human_readable "$1"
exit 0
