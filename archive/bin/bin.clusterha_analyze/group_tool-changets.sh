#!/bin/sh
# This script will convert the epoch timestamp to a human readable version. The
# new human readable timestamp version will be written to a new file in same
# directory.

if [ -z "$1" ]; then
    echo "ERROR: Path to the file.";
    echo "Usage: $0 <path to the file>";
    exit 1;
fi

path_to_filename="$1";
path_to_filename_tsmod=$path_to_filename.tsmod;

if [ ! -f $path_to_filename ]; then
    echo "File does not exist: $path_to_filename";
    exit 1;
fi

# Remove any existing version.
if [ ! -f "$path_to_filename_tsmod" ]; then
    rm -f $path_to_filename_tsmod;
fi

while IFS= read -r line; do
        # display $line or do somthing with $line
    ts=$(printf '%s\n' "$line" | awk -F\| '{sub(/ /,"|");$1=$1;print $1}');
    msg=$(printf '%s\n' "$line" | awk -F\| '{sub(/ /,"|");$1=$1;print $2}');

    # Do not know how to get correct TIMEZONE to use so time could be incorrect
    # by whatever their tz offset is.
    ts_human=$(date -d "@$ts" "+%b %d %H:%M:%S")
    echo $ts_human $msg >> $path_to_filename_tsmod
done <"$path_to_filename"

if [  -f "$path_to_filename_tsmod" ]; then
    echo -e "The human friendly timestamp version was created: \n\t$path_to_filename_tsmod";
else
    echo "ERROR: The human friendly timestamp version was not created.";
fi
exit;
