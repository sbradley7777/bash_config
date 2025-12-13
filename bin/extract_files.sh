#!/bin/sh
for i in *; do
    if [ -d $i ]; then
	cd $i
	for i in *.bz2; do
            echo Extracting $i; tar xvf $i ;
	done;
	cd ..
    fi
done
