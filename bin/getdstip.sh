#!/bin/bash
#
# Description:
#   Get the IP address for an ethernet device on a remote host via SSH.
#   Tries multiple common network interface names (eth0, ens3, ens10).
#
# Usage:
#   getdstip.sh [-h] <hostname>
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   hostname    Remote host to query for IP address
#
# Examples:
#   $ ./getdstip.sh server1.example.com
#   192.168.1.100
#   $ ./getdstip.sh 10.0.0.5
#   10.0.0.5
#
# Dependencies:
#   - ssh
#   - ping
#
# Exit Codes:
#   0    Success - IP address found
#   1    Error - host unreachable or no valid IP found
#

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] <hostname>

Description:
  Get the IP address for an ethernet device on a remote host via SSH.
  Tries multiple common network interface names (eth0, ens3, ens10).

Options:
  -h    Show this help message and exit

Arguments:
  hostname    Remote host to query for IP address

Examples:
  $ $(basename "$0") server1.example.com
  192.168.1.100
EOF
}

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    echo "ERROR: $message" >&2
    exit "$exit_code"
}

# Validate IP address format and range
valid_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        read -ra ip <<< "$ip"
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
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
[[ -n "$1" ]] || error_exit "Missing required argument: hostname"
host="$1"

################################################################################
# Main Execution
################################################################################
# Check if host is reachable
if ! ping -q -c 1 "$host" &>/dev/null; then
    echo ""
    exit 1
fi

# Try different network interface names
for ethernet_device in eth0 ens3 ens10; do
    ip_addr=$(ssh -o ForwardX11=no "$host" "/usr/sbin/ip addr show dev $ethernet_device 2>/dev/null | sed -e's/^.*inet \([^ ]*\)\/.*$/\1/;t;d' 2>/dev/null" | head -n 1)

    if valid_ip "$ip_addr"; then
        echo "$ip_addr"
        exit 0
    fi
done

# No valid IP found
echo ""
exit 1
