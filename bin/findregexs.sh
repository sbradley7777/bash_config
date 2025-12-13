#!/bin/sh
# Description: Searches a directory and all files under it for 1 or
# more strings in the file.
# Author: Shane Bradley(sbradley@redhat.com)
#
# Save to ~/bin directory and then set the permissions on the file.
# $ chmod 700 ~/bin/findregexs.sh
#
# Usage:
# $ findregex.sh $(pwd) "linux version" "gcc" "syslog"
#
# The above is the same as running this command below:
# $ find $(pwd) -iname messages -exec grep -ie "gcc" -ie "syslog"  {} \;

path=$1
if [ -z "$path" ]
then
    echo "Please give a path to a file.";
    exit 1;
fi

if [ ! -d "$path" ]
then
    echo "That path does not exist: $path";
    exit 1;
fi

if [ -z "$2" ]
then
    echo "Please give a filename string to use to search those files.";
    exit 1;
fi

if [ -z "$3" ]
then
    echo "Please give a string to search for.";
    exit 1;
fi

skippedFirstArgument=0;
skippedSecondArgument=0;
grepRegexString="";
for var in "$@"
do
    if (( skippedFirstArgument == 0 ))
    then
        skippedFirstArgument=1;
    elif (( skippedSecondArgument == 0 ))
    then
        skippedSecondArgument=1;
    else
        grepRegexString="-ie \"$var\" $grepRegexString"
    fi
done
command="find "$path" -iname $2 -exec grep $grepRegexString {} \; | sort"
echo $command
sh -c "$command"
exit;
