#!/bin/sh
# Description: Extracts all the .gz files in the /var/log/ and /var/log/cluster
# directories in an extracted sosreport.
# Author: Shane Bradley(sbradley@redhat.com)

for i in *; do
    # skip the "reports" directories if found.
    if [ -d "$i/var/log" ]; then
	for gzip_file in `find $i/var/log/ -name "*.gz"`; do
	    gunzip -d $gzip_file
	done
    fi
done

