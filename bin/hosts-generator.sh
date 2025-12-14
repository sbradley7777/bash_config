#!/bin/bash
######################################################################
# gethostip.sh
#
# Author: Shane Bradley

# Description: This script will ssh into a host to get the ip address for eth0.

# usage:
# $ gethostip.sh -n <hostname>
######################################################################

host_file=$HOME/.hosts
usage() {
    cat <<EOF
usage: $0 -n <hostname>

This script will ssh into a host to get the ip address for eth0.

OPTIONS:
   -h      Show this message
   -n      Hostname that will be ssh into to get the ip address for eth0.

EXAMPLE:
$ $0 -n <hostname>

EOF
}

declare -a nargs=()

read_n_args() {
    while (($#)) && [[ $1 != -* ]]; do
        nargs+=("$1")
        shift
    done
}

# Verify that the parameter passed is an IP Address:
valid_ip() {
    if [[ $(echo "$1" | grep -o '\.' | wc -l) -ne 3 ]]; then
        exit 1
    elif [[ $(echo "$1" | tr '.' ' ' | wc -w) -ne 4 ]]; then
        exit 1
    else
        for octet in $(echo "$1" | tr '.' ' '); do
            if ! [[ $octet =~ ^[0-9]+$ ]]; then
                exit 1
            elif [[ $octet -lt 0 || $octet -gt 255 ]]; then
                exit 1
            fi
        done
    fi
    return 0
}

while getopts "hn:v" opt; do
    case $opt in
        h)
            usage
            exit 1
            ;;
        n)
            read_n_args "${@:2}"
            ;;
        ?)
            usage
            exit
            ;;
    esac
done

if [[ ${#nargs[@]} -eq 0 ]]; then
    usage
    exit 1
fi

######################################################################
# Main
######################################################################
if [[ -f $host_file ]]; then
    mv "$host_file" "$host_file.bk"
fi

for h in "${nargs[@]}"; do
    if ping -q -c 1 "$h" &>/dev/null; then
        dst_ip=$(ssh -q "$h" "\$HOME/bin/bin.utils/getdstip.sh $h")
        if valid_ip "$dst_ip"; then
            echo "$h $dst_ip" >> "$host_file"
        fi
    #else
    #    echo "WARNING: The host could not be reached: $h."
    fi
done

exit 0
