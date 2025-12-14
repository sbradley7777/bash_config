#!/bin/sh
# Appends the epoch timestamp in human readable format to start of each line.

if [ -z $1 ]; then
   echo "Usage: $0 <filename>"
   exit 1
fi
path_to_source="$(readlink -f $1)"
path_to_output_file=$path_to_source.mod
if [ -f $path_to_output_file ]; then
    rm -rf $path_to_output_file;
fi

while read -r line; do
    time=`echo $line | sed 's/.*audit(\([0-9]*\).*/\1/'`;
    echo `date -d @$time "+%b %d %H:%M:%S"` $line >> $path_to_output_file;
done < $path_to_source
exit;
