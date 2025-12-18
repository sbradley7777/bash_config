#!/bin/bash
#
# Description:
#   Add whitespace prefix before each line in a file while filtering out noise.
#   Reads a log file and adds configurable whitespace prefix to each line, with
#   optional filtering to exclude common system log messages (ssh, systemd, etc).
#
# Usage:
#   prefix_space.sh [-h] [-E] [-G] -p <file> [-w <count>]
#
# Options:
#   -h    Show this help message and exit
#   -p    Path to the file to process (required)
#   -w    Prefix whitespace count (default: 2)
#   -E    Disable optional grep ignores (podman, ansible, CROND, etc.)
#   -G    Disable all grep ignores
#
# Examples:
#   $ ./prefix_space.sh -p /var/log/messages
#   $ ./prefix_space.sh -p ~/log.txt -w 4
#   $ ./prefix_space.sh -p /var/log/messages -E
#   $ ./prefix_space.sh -p /var/log/messages -G
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
Usage: $(basename "$0") [-h] [-E] [-G] -p <file> [-w <count>]

Description:
  Add whitespace prefix before each line in a file while filtering out noise.

Options:
  -h    Show this help message and exit
  -p    Path to the file to process (required)
  -w    Prefix whitespace count (default: 2)
  -E    Disable optional grep ignores (podman, ansible, CROND, etc.)
  -G    Disable all grep ignores

Examples:
  $ $(basename "$0") -p /var/log/messages
  $ $(basename "$0") -p ~/log.txt -w 4
  $ $(basename "$0") -p /var/log/messages -E
  $ $(basename "$0") -p /var/log/messages -G
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
file_path=""
prefix_count=$DEFAULT_PREFIX_COUNT
disable_extras=false
disable_all=false

while getopts ":hp:w:EG" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        p)
            file_path=$OPTARG
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

################################################################################
# Input Validation
################################################################################
[[ -n "$file_path" ]] || error_exit "Missing required option: -p <file>"
[[ -f "$file_path" ]] || error_exit "File does not exist: $file_path"

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
    awk -v prefix="$prefix" '{print prefix $0}' "$file_path"
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
eval "grep -ai -v $grep_args $file_path" | awk -v prefix="$prefix" '{print prefix $0}'
exit 0
