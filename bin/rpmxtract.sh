#!/bin/sh
# Extracts an rpm to current working directory.
if [ -z "$1" ]; then
    echo "A path to an rpm file was not given."
    exit
fi
rpm2cpio "$1" | cpio -ivd

exit
