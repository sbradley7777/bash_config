#!/bin/bash
#
# Description:
#   Output the size of all files and directories for a path, then sort them.
#   Displays sizes in human-readable format (GB, MB, KB).
#
# Usage:
#   dusize.sh [-h] <directory_path>
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   directory_path    Path to directory to analyze
#
# Examples:
#   $ ./dusize.sh /var/log
#   $ ./dusize.sh /home/user/documents
#
# Dependencies:
#   - du
#   - awk
#   - sed
#
# Exit Codes:
#   0    Success
#   1    Error - invalid arguments or directory not found
#

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] <directory_path>

Description:
  Output the size of all files and directories for a path, then sort them.
  Displays sizes in human-readable format (GB, MB, KB).

Options:
  -h    Show this help message and exit

Arguments:
  directory_path    Path to directory to analyze

Examples:
  $ $(basename "$0") /var/log
  $ $(basename "$0") /home/user/documents
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
[[ -n "$1" ]] || error_exit "Missing required argument: directory_path"
directory_path="$1"

[[ -d "$directory_path" ]] || error_exit "Directory does not exist: $directory_path"

################################################################################
# Main Execution
################################################################################
echo "Path: $directory_path"

# Remove double slashes
path_to_sum_size="$directory_path/*"
path_to_sum_size="${path_to_sum_size//\/\//\/}"

sudo du -s -B1 "$path_to_sum_size" | sort -nr | awk '{sum=$1;
hum[1024**3]=" GB";hum[1024**2]=" MB";hum[1024]=" KB";
for (x=1024**3; x>=1024; x/=1024){
        if (sum>=x) { printf "%.1f%s\t\t",sum/x,hum[x];print $2;break
}}}'

exit 0
