#!/bin/bash
######################################################################
# gethostip.sh
#
# Author: Shane Bradley

# Description: This script will ssh into a host, then will ssh into another host
#              to print to console the ip. This is useful to query a host of
#              virtual machines on internal lan then have the external ip of the
#              virtual machine returned. This makes ssh'ing into virtual machine
#              automated where the internal ip is static and external ip is
#              dynamic.

# usage:
# $ gethostip.sh -s somehost -m somevm
######################################################################

usage() {
    cat <<EOF
usage: $0 -s <host of vms> -m <vm host>

This script will clone the git repo or update the git repo, then it will reinstall configuration.

OPTIONS:
   -h      Show this message
   -s      Host that will query for a ip of another hosts on its internal lan
   -m      The host that will be queried.

EXAMPLE:
$ $0 -s somehost -m somevm

EOF
}

src_host=
dst_host=
while getopts "hs:m:v" opt; do
    case $opt in
        h)
            usage
            exit 1
            ;;
        s)
            src_host=$OPTARG
            ;;
        m)
            dst_host=$OPTARG
            ;;
        ?)
            usage
            exit
            ;;
    esac
done

if [[ -z $src_host ]] || [[ -z $dst_host ]]; then
    usage
    exit 1
fi

######################################################################
# Main
######################################################################
# shellcheck disable=SC2029
dst_ip=$(ssh "$src_host" "\$HOME/bin/bin.utils/getdstip.sh $dst_host 2> /dev/null")
echo "$dst_ip"
exit 0
