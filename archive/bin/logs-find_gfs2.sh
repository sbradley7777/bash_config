#!/bin/sh
# Description: Finds all the instances that gfs2 filesystem name in the logs.
# Author: Shane Bradley(sbradley@redhat.com)
for fsname in `grep gfs2 $(find . -name mount -print -quit) | awk '{print $7}' | cut -d ":" -f 2 | sed 's/]//'`; do
    echo "filesystem name: $fsname";
    find . -iname messages | xargs grep "GFS2\: fsid" -h | grep -v "\[CKPT  \] Checkpoint" | sort -k1M -k2n -k3 -k4 -s;
    echo "---------";
done
