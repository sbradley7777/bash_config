#!/bin/sh
######################################################################
# gethostip.sh
#
# Author: Shane Bradley

# Description: This script will ssh into a host to get the ip address for eth0.

# usage:
# $ gethostip.sh -n <hostname>
######################################################################

HOST_FILE=$HOME/.hosts;
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
    while (($#)) && [[ $1 != -* ]]; do nargs+=("$1"); shift; done
}

# Verify that the parameter passed is an IP Address:
function valid_ip() {
    if [ `echo $1 | grep -o '\.' | wc -l` -ne 3 ]; then
        exit 1;
    elif [ `echo $1 | tr '.' ' ' | wc -w` -ne 4 ]; then
        exit 1;
    else
        for OCTET in `echo $1 | tr '.' ' '`; do
            if ! [[ $OCTET =~ ^[0-9]+$ ]]; then
                exit 1;
            elif [[ $OCTET -lt 0 || $OCTET -gt 255 ]]; then
                exit 1;
            fi
        done
    fi
    return 0;
}

while getopts “hn:v” OPTION
do
    case $OPTION in
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

if [[ -z $nargs ]] ; then
    usage
    exit 1
fi

######################################################################
# Main
######################################################################
if [ -f $HOST_FILE ]; then
    mv $HOST_FILE $HOST_FILE.bk
fi

for h in "${nargs[@]}"; do
    ping -q -c 1 $h &>/dev/null
    if [ $? -eq 0 ] ; then
	dstIP=$(ssh -q $h "~/bin/bin.utils/getdstip.sh $h")
	if ( valid_ip $dstIP == 0 ); then
	    echo "$h $dstIP" >> $HOST_FILE
	fi
    #else
    #	echo "WARNING: The host could not be reached: $h.";
fi
done;

exit 0;
