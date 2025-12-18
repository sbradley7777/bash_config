#!/bin/bash
#
# Description:
#   Search a directory and all files under it for one or more regex patterns.
#   Finds files matching a name pattern, then searches within those files for
#   the specified regex patterns.
#
# Usage:
#   findregexs.sh [-h] <directory> <filename_pattern> <search_pattern> [additional_patterns...]
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   directory           Path to directory to search
#   filename_pattern    Pattern for files to search (e.g., "*.log", "messages")
#   search_pattern      Regex pattern to search for within files
#   additional_patterns Additional regex patterns (optional)
#
# Examples:
#   $ ./findregexs.sh $(pwd) "messages" "error" "warning"
#   $ ./findregexs.sh /var/log "*.log" "failed" "timeout"
#
# Notes:
#   Equivalent to: find <dir> -iname <pattern> -exec grep -ie <regex1> -ie <regex2> {} \;
#
# Exit Codes:
#   0    Success
#   1    Error - invalid arguments or missing required parameters
#

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] <directory> <filename_pattern> <search_pattern> [additional_patterns...]

Description:
  Search a directory and all files under it for one or more regex patterns.

Options:
  -h    Show this help message and exit

Arguments:
  directory           Path to directory to search
  filename_pattern    Pattern for files to search (e.g., "*.log", "messages")
  search_pattern      Regex pattern to search for within files
  additional_patterns Additional regex patterns (optional)

Examples:
  $ $(basename "$0") $(pwd) "messages" "error" "warning"
  $ $(basename "$0") /var/log "*.log" "failed" "timeout"
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
[[ -n "$1" ]] || error_exit "Missing required argument: directory"
directory_path="$1"

[[ -d "$directory_path" ]] || error_exit "Directory does not exist: $directory_path"

[[ -n "$2" ]] || error_exit "Missing required argument: filename_pattern"
filename_pattern="$2"

[[ -n "$3" ]] || error_exit "Missing required argument: search_pattern"

################################################################################
# Main Execution
################################################################################
# Build grep arguments from all search patterns (skip first two arguments)
skipped_first_argument=0
skipped_second_argument=0
grep_args=()

for arg in "$@"; do
    if (( skipped_first_argument == 0 )); then
        skipped_first_argument=1
    elif (( skipped_second_argument == 0 )); then
        skipped_second_argument=1
    else
        grep_args+=(-ie "$arg")
    fi
done

# Execute find with grep and sort results
find "$directory_path" -iname "$filename_pattern" -exec grep "${grep_args[@]}" {} \; | sort

exit 0
