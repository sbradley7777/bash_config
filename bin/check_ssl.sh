#!/bin/bash
#
# Description:
#   Detect which SSL/TLS protocol versions can be used to connect to a server.
#   Tests ssl2, ssl3, tls1_1, and tls1_2 protocols.
#
# Usage:
#   check_ssl.sh [-h] [host:port]
#
# Options:
#   -h    Show this help message and exit
#
# Arguments:
#   host:port    Target host/IP and port in format "host:port"
#                If port is omitted, defaults to 8084
#                If argument is omitted, defaults to 127.0.0.1:8084
#
# Examples:
#   $ ./check_ssl.sh
#   $ ./check_ssl.sh 192.168.122.161:8084
#   $ ./check_ssl.sh example.com:443
#   $ ./check_ssl.sh example.com
#
# Dependencies:
#   - openssl
#   - timeout (optional, for connection timeout handling)
#
# Exit Codes:
#   0      Success - at least one protocol connected successfully
#   1      Failure - no protocols connected or invalid arguments
#   124    Timeout - connection attempt timed out
#

# Constants
readonly DEFAULT_HOST="127.0.0.1"
readonly DEFAULT_PORT="8084"
readonly PROTOCOLS=("ssl2" "ssl3" "tls1_1" "tls1_2")

# Error handling function
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"

    echo "ERROR: $message" >&2
    exit "$exit_code"
}

# Usage function
usage() {
    cat << EOF
Usage: $(basename "$0") [-h] [host:port]

Description:
  Detect which SSL/TLS protocol versions can be used to connect to a server.
  Tests ssl2, ssl3, tls1_1, and tls1_2 protocols.

Options:
  -h    Show this help message and exit

Arguments:
  host:port     Target host/IP and port in format "host:port"
                If port is omitted, defaults to 8084
                If argument is omitted, defaults to 127.0.0.1:8084

Examples:
  $ $(basename "$0")
  $ $(basename "$0") 192.168.122.161:8084
  $ $(basename "$0") example.com:443
  $ $(basename "$0") example.com

Dependencies:
  - openssl (required)
  - timeout (optional, for connection timeout handling)

Exit Codes:
  0      Success - at least one protocol connected successfully
  1      Failure - no protocols connected or invalid arguments
  124    Timeout - connection attempt timed out
EOF
}

# Parse command-line options using getopts
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

# Shift past the options to get positional arguments
shift $((OPTIND - 1))

# Check for openssl dependency
command -v openssl &> /dev/null || error_exit "openssl is not installed or not in PATH"

# Parse host:port argument
target=${1:-${DEFAULT_HOST}:${DEFAULT_PORT}}

# Extract host and port
if [[ "$target" =~ : ]]; then
    host="${target%%:*}"
    port="${target##*:}"
else
    host="$target"
    port="${DEFAULT_PORT}"
fi

# Validate host is not empty
[[ -n "$host" ]] || error_exit "Host cannot be empty"

# Validate port is numeric and in valid range
[[ "$port" =~ ^[0-9]+$ ]] || error_exit "Port must be a number, got: $port"
[[ "$port" -ge 1 && "$port" -le 65535 ]] || error_exit "Port must be between 1 and 65535, got: $port"

timeout_bin=$(command -v timeout 2>/dev/null)

# Track if any protocol succeeded and if any timed out
any_success=false
any_timeout=false

for protocol in "${PROTOCOLS[@]}"; do
    out="$(echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -"$protocol" -connect "${host}:${port}" 2>/dev/null)"
    exit_code=$?

    if [[ $exit_code -eq 124 ]]; then
        echo "ERROR: Timeout connecting to \"$host:$port\" to check protocol: $protocol."
        any_timeout=true
    else
        if echo "$out" | grep -q '^CONNECTED'; then
            proto=$(echo "$out" | grep '^ *Protocol *:' | awk '{ print $3 }')
            cipher=$(echo "$out" | grep '^ *Cipher *:' | awk '{ print $3 }')
            echo "$host:$port | Protocol: $proto Cipher: $cipher"
            if [[ "$cipher" == '0000' ]] || [[ "$cipher" == '(NONE)' ]]; then
                echo "  Connected with \"${protocol^^}\" but no ciphers were found."
            else
                echo "  Connected with \"${protocol^^}\" and using cipher: $cipher."
                any_success=true
            fi
        else
            echo "$host:$port | Protocol: ${protocol^^}"
            echo "  Failed to establish a \"${protocol^^}\" connection."
        fi
        echo ""
    fi
done

# Exit with appropriate code
if [[ "$any_timeout" == true ]]; then
    exit 124
elif [[ "$any_success" == true ]]; then
    exit 0
else
    exit 1
fi
