#!/bin/bash
#
# Description:
#   Temporarily block outgoing ping (ICMP echo-request) packets using firewalld.
#   Adds a firewall rule to drop ping packets, waits for specified duration,
#   then removes the rule. Useful for testing network timeout scenarios.
#
# Usage:
#   ping-test.sh [-h] [seconds]
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   seconds    Duration to block ping packets (default: 10)
#
# Examples:
#   $ ./ping-test.sh
#   $ ./ping-test.sh 30
#   $ ./ping-test.sh 5
#
# Dependencies:
#   - firewall-cmd
#   - systemctl
#   - firewalld.service (must be running)
#
# Notes:
#   - Requires firewalld.service to be active
#   - Blocks outgoing ping packets only (echo-request)
#   - Automatically removes the rule after the specified duration
#
# Exit Codes:
#   0    Success
#   1    Error - firewalld.service not running or invalid arguments
#

################################################################################
# Constants
################################################################################
readonly DEFAULT_SLEEP_TIME=10

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] [seconds]

Description:
  Temporarily block outgoing ping (ICMP echo-request) packets using firewalld.

Options:
  -h    Show this help message and exit

Arguments:
  seconds    Duration to block ping packets (default: 10)

Examples:
  $ $(basename "$0")
  $ $(basename "$0") 30
  $ $(basename "$0") 5
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
# Check Dependencies
################################################################################
if (! systemctl -q is-active firewalld.service); then
    error_exit "firewalld.service is not running - firewall rules cannot be modified"
fi

################################################################################
# Input Validation
################################################################################
sleep_time=${1:-$DEFAULT_SLEEP_TIME}

# Validate sleep_time is numeric
if ! [[ "$sleep_time" =~ ^[0-9]+$ ]]; then
    error_exit "Sleep time must be a positive integer, got: $sleep_time"
fi

################################################################################
# Main Execution
################################################################################
echo "The firewalld.service is running. Blocking ping (ICMP) packets for $sleep_time seconds."

# Add firewall rule to block outgoing ping
firewall-cmd --direct --add-rule ipv4 filter OUTPUT 0 -p icmp --icmp-type echo-request -j DROP &> /dev/null

# Wait for specified duration
sleep "$sleep_time"

# Remove firewall rule
firewall-cmd --direct --remove-rule ipv4 filter OUTPUT 0 -p icmp --icmp-type echo-request -j DROP &> /dev/null

echo "Removing the firewall rule for blocking ping (ICMP) packets."

exit 0
