#!/bin/bash
#
# Description:
#   Convert all man pages from a specified section to HTML format.
#   Processes compressed (.gz) man pages and generates HTML files.
#
# Usage:
#   convert-manpages.sh [-h] <section>
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   section    Man page section number (1-8, L, or M)
#              1 = User commands
#              2 = System calls
#              3 = Library functions
#              4 = Special files
#              5 = File formats
#              6 = Games
#              7 = Miscellaneous
#              8 = System administration
#              L = Local
#              M = Manual
#
# Examples:
#   $ ./convert-manpages.sh 1
#   $ ./convert-manpages.sh 5
#   $ ls /tmp/man/man1/*.html
#
# Dependencies:
#   - find
#   - zcat
#   - groff
#   - basename
#
# Notes:
#   - Output files are created in /tmp/man/man<section>/
#   - All man pages in the section will be converted
#   - This may take some time for large sections like section 1
#   - Requires read access to /usr/share/man/man<section>/
#
# Exit Codes:
#   0    Success
#   1    Invalid section number or missing argument
#   2    Man section directory does not exist
#

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] <section>

Description:
  Convert all man pages from a specified section to HTML format.

Options:
  -h    Show this help message and exit

Arguments:
  section    Man page section number (1-8, L, or M)

Examples:
  $ $(basename "$0") 1
  $ ls /tmp/man/man1/*.html
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
[[ -n "$1" ]] || error_exit "Missing required argument: section"

man_section="$1"

# Validate section number is valid
if [[ ! "$man_section" == [1-8] ]] && [[ "$man_section" != "L" ]] && [[ "$man_section" != "M" ]]; then
    error_exit "$man_section is not a valid section (1-8, L, or M)"
fi

################################################################################
# Main Execution
################################################################################
path_to_output_dir="/tmp/man/man$(basename "$man_section")"
if [[ ! -d "$path_to_output_dir" ]]; then
    mkdir -p "$path_to_output_dir"
fi

path_to_man_section="/usr/share/man/man$man_section"
[[ -d "$path_to_man_section" ]] || error_exit "The man section $man_section does not exist at $path_to_man_section" 2

cd "$path_to_man_section" || error_exit "Failed to change directory to $path_to_man_section" 2

find . -name '*.gz' -print0 | while IFS= read -r -d '' i; do
    basename_html_file="${i%.*}"
    basename_html_file="$(basename "$basename_html_file")"
    echo "$path_to_output_dir/$basename_html_file.html"
    zcat "$i" | groff -mandoc -Thtml > "$path_to_output_dir/$basename_html_file.html"
done
exit 0
