#!/bin/sh
# ###############################################################################
# Author: Shane Bradley(sbradley AT redhat.com)
# Version: 1.0
# Description: This script will output the size of all files and directories for
# a path then sort them.
#
# usage:
# $ ./dusize.sh <path to some directory>
# ###############################################################################
#
if [ -z "$1" ]; then
    echo "ERROR: A path was not given."
    echo "Usage: $0 /pub"
    exit 1
elif [ ! -d "$1" ]; then
    echo "ERROR: A path to a directory that exists is required."
    echo "Usage: $0 /pub"
    exit 1

fi

echo "Path: $1"
# Remove double backslashes
PATH_TO_SUM_SIZE="$1/*"
PATH_TO_SUM_SIZE=$(echo "$PATH_TO_SUM_SIZE" | sed s#//*#/#g)
sudo du -s -B1 "$PATH_TO_SUM_SIZE" | sort -nr  | awk '{sum=$1;
hum[1024**3]=" GB";hum[1024**2]=" MB";hum[1024]=" KB";
for (x=1024**3; x>=1024; x/=1024){
        if (sum>=x) { printf "%.1f%s\t\t",sum/x,hum[x];print $2;break
}}}'

exit
