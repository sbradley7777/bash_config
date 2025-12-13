#!/bin/sh
# This script converts timestamps in a file. 
if [ -z "$1" ]
then
    echo "A path to the file that will have it timestamps converted was not given.";
    exit;
elif [ ! -f "$1" ]
then
    echo "A path to the file that will have it timestamps converted does not exist.";
    exit;
fi

FILE=$1
while read line; do
    echo $line | awk '
        {printf("%s", strftime("%Y.%m.%d ",$1));
         printf("%s", strftime("%H:%M:%S \n",$1));
    }'
    echo  $line
done < "$FILE"

exit;

