#!/bin/sh
# Usage is for converting df block data to human readable form.
if [ -z $1 ]; then
   echo "Usage: $0 <Number of 1K Blocks>"
   exit 1
fi

let "m = $1 / (1024 * 1024)"; echo $m GB;
