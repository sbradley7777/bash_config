#!/bin/bash
#
# Description:
#   Query a remote host's IP address via an intermediate host.
#   SSH into a source host, then query that host for the IP address of a
#   destination host on its internal network. Useful for accessing VMs with
#   dynamic external IPs but static internal IPs.
#
# Usage:
#   gethostip.sh [-h] -s <source_host> -m <dest_host>
#
# Options:
#   -h    Show this help message and exit
#   -s    Source host to SSH into (the host that can reach the destination)
#   -m    Destination host whose IP address will be queried
#
# Examples:
#   $ ./gethostip.sh -s hypervisor.example.com -m vm1
#   192.168.122.100
#   $ ./gethostip.sh -s jumphost -m internal-server
#   10.0.1.50
#
# Dependencies:
#   - ssh
#   - getdstip.sh (must be available in PATH on source host)
#
# Exit Codes:
#   0    Success - IP address retrieved
#   1    Error - missing arguments or connection failed
#

################################################################################
# Functions
################################################################################
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] -s <source_host> -m <dest_host>

Description:
  Query a remote host's IP address via an intermediate host.
  SSH into a source host, then query that host for the IP address of a
  destination host on its internal network.

Options:
  -h    Show this help message and exit
  -s    Source host to SSH into (the host that can reach the destination)
  -m    Destination host whose IP address will be queried

Examples:
  $ $(basename "$0") -s hypervisor.example.com -m vm1
  192.168.122.100
  $ $(basename "$0") -s jumphost -m internal-server
  10.0.1.50
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
src_host=
dst_host=

while getopts ":hs:m:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        s)
            src_host=$OPTARG
            ;;
        m)
            dst_host=$OPTARG
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
[[ -n "$src_host" ]] || error_exit "Missing required option: -s <source_host>"
[[ -n "$dst_host" ]] || error_exit "Missing required option: -m <dest_host>"

################################################################################
# Main Execution
################################################################################
# shellcheck disable=SC2029
dst_ip=$(ssh "$src_host" "source ~/.bash_profile &>/dev/null && getdstip.sh $dst_host 2>/dev/null")
echo "$dst_ip"

exit 0
