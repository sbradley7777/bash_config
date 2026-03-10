#!/bin/bash
#
# Description:
#   Add whitespace prefix before each line in a file or stdin while filtering out noise.
#   Reads a log file or piped input and adds configurable whitespace prefix to each line,
#   with optional filtering to exclude common system log messages (ssh, systemd, etc).
#
# Usage:
#   prefix_space.sh [-h] [-E] [-G] [-w <count>] [file]
#
# Options:
#   -h    Show this help message and exit
#   -w    Prefix whitespace count (default: 2)
#   -E    Disable optional grep ignores (podman, ansible, CROND, etc.)
#   -G    Disable all grep ignores
#
# Arguments:
#   file  Path to the file to process (optional, reads from stdin if omitted)
#
# Examples:
#   $ ./prefix_space.sh /var/log/messages
#   $ ./prefix_space.sh ~/log.txt -w 4
#   $ cat /tmp/test.txt | ./prefix_space.sh -w 2
#   $ tail -f /var/log/messages | ./prefix_space.sh -E
#   $ ./prefix_space.sh /var/log/messages -G
#
# Notes:
#   - Default filters exclude common noise: sshd, systemd-logind, sudo, etc.
#   - Use -E to keep podman/ansible/cron messages
#   - Use -G to disable all filtering
#   - Useful for cleaning up log files before analysis
#
# Exit Codes:
#   0    Success
#   1    Error - missing required arguments or file not found
#

################################################################################
# Constants
################################################################################
readonly DEFAULT_PREFIX_COUNT=2

# Default list of strings to ignore (common system noise)
readonly GREP_IGNORES_DEFAULT=(
    "sshd"
    "snmpd"
    "goferd"
    "sudo"
    "xinetd"
    "automount"
    "adclient"
    "adinfo"
    "cupsd"
    "sssd"
    "org.freedesktop"
    "systemd-logind"
    "rate-limiting"
    "Audit daemon rotating log files"
    "www.rsyslog.com"
    "journal reloaded"
    "journal\: Suppressed"
    "of user *."
    "of root"
    "User Slice of"
    "Started Session"
    "Removed session"
    "su[:[]"
    "is marked world-inaccessible"
    "is marked executable"
    "martian source"
    "ll header"
    "net_ratelimit"
    "nfsidmap"
    "system activity accounting tool"
    "sysstat-collect.service"
    "pmlogger"
    "pmie"
)

# Extra filters that can be disabled with -E option
readonly GREP_IGNORES_EXTRAS=(
    "podman\["
    "healthcheck"
    "dnsmasq"
    "node_exporter"
    "kernel\: IN\="
    "ansible-"
    "CROND"
)

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] [-E] [-G] [-w <count>] [file]

Description:
  Add whitespace prefix before each line in a file or stdin while filtering out noise.

Options:
  -h    Show this help message and exit
  -w    Prefix whitespace count (default: 2)
  -E    Disable optional grep ignores (podman, ansible, CROND, etc.)
  -G    Disable all grep ignores

Arguments:
  file  Path to the file to process (optional, reads from stdin if omitted)

Examples:
  $ $(basename "$0") /var/log/messages
  $ $(basename "$0") ~/log.txt -w 4
  $ cat /tmp/test.txt | $(basename "$0") -w 2
  $ tail -f /var/log/messages | $(basename "$0") -E
  $ $(basename "$0") /var/log/messages -G
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
prefix_count=$DEFAULT_PREFIX_COUNT
disable_extras=false
disable_all=false

while getopts ":hw:EG" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        w)
            prefix_count=$OPTARG
            ;;
        E)
            disable_extras=true
            ;;
        G)
            disable_all=true
            ;;
        \?)
            echo "ERROR: Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
        :)
            echo "ERROR: Option -$OPTARG requires an argument" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

################################################################################
# Input Validation
################################################################################
# Determine input source: file argument or stdin
if [[ -n "$1" ]]; then
    file_path="$1"
    [[ -f "$file_path" ]] || error_exit "File does not exist: $file_path"
    input_source="$file_path"
else
    # No file specified, check if stdin has data
    if [[ -t 0 ]]; then
        error_exit "No input provided. Provide a file path or pipe data to stdin"
    fi
    input_source="-"
fi

# Validate prefix_count is numeric
if ! [[ "$prefix_count" =~ ^[0-9]+$ ]]; then
    error_exit "Prefix count must be a non-negative integer, got: $prefix_count"
fi

################################################################################
# Main Execution
################################################################################
# Create prefix string with specified number of spaces
prefix=$(printf "%*s" "$prefix_count" "")

# If all filters disabled, just add prefix and exit
if [[ "$disable_all" = true ]]; then
    awk -v prefix="$prefix" '{print prefix $0}' "$input_source"
    exit 0
fi

# Build grep ignore arguments
grep_args=""
for pattern in "${GREP_IGNORES_DEFAULT[@]}"; do
    grep_args+="-e '$pattern' "
done

# Add extra filters unless -E was specified
if [[ "$disable_extras" = false ]]; then
    for pattern in "${GREP_IGNORES_EXTRAS[@]}"; do
        grep_args+="-e '$pattern' "
    done
fi

# Filter and add prefix
# Note: eval is needed to properly handle the quoted patterns
eval "grep -ai -v $grep_args $input_source" | awk -v prefix="$prefix" '{print prefix $0}'
exit 0
