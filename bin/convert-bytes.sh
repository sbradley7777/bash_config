#!/bin/bash
# Convert an integer that reprensents size in bytes to human readable format.
# URL: http://www.kossboss.com/linux---bytes-to-human-readable-command
bytestohr() {
    # Convert input parameter (number of bytes) to Human Readable form
    SLIST="bytes,KB,MB,GB,TB,PB,EB,ZB,YB";
    POWER=1;
    VAL=$( echo "scale=2; $1 / 1" | bc);
    VINT=$( echo $VAL / 1024 | bc );
    while [ $VINT -gt 0 ]
    do
        let POWER=POWER+1;
        VAL=$( echo "scale=2; $VAL / 1024" | bc);
        VINT=$( echo $VAL / 1024 | bc );
    done
    echo $VAL$( echo $SLIST | cut -f$POWER -d, );
}

re='^[0-9]+$';
if ! [[ $1 =~ $re ]] ; then
   echo "error: An integer is required." >&2;
   exit 1;
fi
bytestohr $1
