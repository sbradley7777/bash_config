#!/bin/bash
#
# Description:
#   Generate a hosts file by querying multiple remote hosts for their IP addresses.
#   SSH into each specified host to get its IP address and write hostname/IP
#   mappings to ~/.hosts file. Backs up existing file before overwriting.
#
# Usage:
#   hosts-generator.sh [-h] -n <hostname1> [hostname2 ...]
#
# Options:
#   -h    Show this help message and exit
#   -n    Hostname(s) to query (can specify multiple)
#
# Examples:
#   $ ./hosts-generator.sh -n server1
#   $ ./hosts-generator.sh -n server1 server2 server3
#   $ ./hosts-generator.sh -n vm1 vm2 vm3
#
# Dependencies:
#   - ssh
#   - ping
#   - getdstip.sh (must be available in PATH on each target host)
#
# Notes:
#   - Creates/overwrites ~/.hosts file
#   - Existing ~/.hosts is backed up to ~/.hosts.bk
#   - Only includes hosts that are reachable and have valid IP addresses
#
# Exit Codes:
#   0    Success
#   1    Error - missing arguments
#

################################################################################
# Constants
################################################################################
readonly HOST_FILE="$HOME/.hosts"

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] -n <hostname1> [hostname2 ...]

Description:
  Generate a hosts file by querying multiple remote hosts for their IP addresses.

Options:
  -h    Show this help message and exit
  -n    Hostname(s) to query (can specify multiple)

Examples:
  $ $(basename "$0") -n server1
  $ $(basename "$0") -n server1 server2 server3
  $ $(basename "$0") -n vm1 vm2 vm3
EOF
}

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: $message" >&2
    exit "$exit_code"
}

# Read multiple arguments after -n option
read_n_args() {
    while (($#)) && [[ $1 != -* ]]; do
        hostnames+=("$1")
        shift
    done
}

# Validate IP address format and range
valid_ip() {
    local ip="$1"

    # Check for exactly 3 dots
    if [[ $(echo "$ip" | grep -o '\.' | wc -l) -ne 3 ]]; then
        return 1
    fi

    # Check for exactly 4 octets
    if [[ $(echo "$ip" | tr '.' ' ' | wc -w) -ne 4 ]]; then
        return 1
    fi

    # Validate each octet
    for octet in $(echo "$ip" | tr '.' ' '); do
        if ! [[ $octet =~ ^[0-9]+$ ]]; then
            return 1
        fi
        if [[ $octet -lt 0 || $octet -gt 255 ]]; then
            return 1
        fi
    done

    return 0
}

################################################################################
# Parse Command-Line Options
################################################################################
declare -a hostnames=()

while getopts ":hn:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        n)
            read_n_args "${@:2}"
            ;;
        \?)
            echo "ERROR: Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

################################################################################
# Input Validation
################################################################################
[[ ${#hostnames[@]} -gt 0 ]] || error_exit "Missing required option: -n <hostname>"

################################################################################
# Main Execution
################################################################################
# Backup existing hosts file if it exists
if [[ -f "$HOST_FILE" ]]; then
    mv "$HOST_FILE" "$HOST_FILE.bk"
fi

# Query each host for its IP address
for hostname in "${hostnames[@]}"; do
    if ping -q -c 1 "$hostname" &>/dev/null; then
        ip_address=$(ssh -q "$hostname" "source ~/.bash_profile &>/dev/null && getdstip.sh $hostname 2>/dev/null")

        if valid_ip "$ip_address"; then
            echo "$hostname $ip_address" >> "$HOST_FILE"
        fi
    fi
done

exit 0
