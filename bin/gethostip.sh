#!/bin/sh
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

usage()
{
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

SRC_HOST=
DST_HOST=
while getopts “hs:m:v” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         s)
             SRC_HOST=$OPTARG
             ;;
         m)
             DST_HOST=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z $SRC_HOST ]] || [[ -z $DST_HOST ]] ; then
    usage
    exit 1
fi

######################################################################
# Main
######################################################################
dstIP=$(ssh $SRC_HOST "~/bin/bin.utils/getdstip.sh $DST_HOST 2> /dev/null")
echo $dstIP
exit 0;
