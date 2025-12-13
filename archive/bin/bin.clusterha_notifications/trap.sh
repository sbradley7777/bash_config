#!/bin/sh

read host
read addr

echo "host=$host" >> /tmp/traps.log
echo "addr=$addr" >> /tmp/traps.log

while read oid val
do
    echo "$oid = $val" >> /tmp/traps.log
done
