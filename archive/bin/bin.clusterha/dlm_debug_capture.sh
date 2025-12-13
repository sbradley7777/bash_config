#!/bin/bash
# This script grabs DLM debugging data.
#
# Make sure that dlm debugging is enabled in the cluster.conf:
#   - 10.13. Debug Logging for Distributed Lock Manager (DLM) Needs to be Enabled Red Hat Enterprise Linux 6
#     https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/cluster_administration/s1-dlm-debug-ca
#
# After making the change, then propagate the cluster.conf and reboot the
# cluster nodes or restart cluster stack.
#
#  - How to provide files to Red Hat Support (vmcore, rhev logcollector, sosreports, heap dumps, log files, etc.)
#    https://access.redhat.com/solutions/2112
#
# ************************************
# This script has had limited testing.
# ************************************
#
# NOTE: I spoke with engineering and they verified this script captures all the information
#       required to debug a dlm issue (ex. dlm hung, dlm not recovering, etc).
#
# TODO:
# * ticket number: TODO ADD ability to pass ticket number as ARG to command and
#   include ticket number in the tarball and DLM debug directory filename.
# * Check if RHEL 6 (cluster.conf) or RHEL 7,8 (cib.xml) and only run or capture
#   files that are related to that version.
# * Verify works on RHEL 7,8.

# Path to debug directory that will be used.
path_to_debug_dir=/tmp/$(hostname)-$(date +%F)-dlm_debug;

logger "Capturing DLM debugging data.";

# Remove any existing debug directory.
if [ -d $path_to_debug_dir ]; then
    rm -rf $path_to_debug_dir;
    if [ -d $path_to_debug_dir ]; then
	echo "ERROR: The directory could not be removed: $path_to_debug_dir";
	exit 2;
    fi
fi

# Mount the debug directory and make sure it is mounted.
mount -t debugfs none /sys/kernel/debug &> /dev/null;
mount | grep /sys/kernel/debug  &> /dev/null;
ret_val=$?
if [ $ret_val -ne 0 ]; then
    echo "ERROR: The debugfs directory was not mounted: /sys/kernel/debug"
    exit 2;
fi

# Create the dir used to store the debug data.
mkdir $path_to_debug_dir &> /dev/null;
if [ ! -d $path_to_debug_dir ]; then
    echo "ERROR: Could not created the directory:  $path_to_debug_dir";
    exit 2;
fi
mkdir $path_to_debug_dir/cluster &> /dev/null;
if [ ! -d $path_to_debug_dir/cluster ]; then
    echo "ERROR: Could not created the directory:  $path_to_debug_dir/cluster";
    exit 2;
fi
mkdir -p $path_to_debug_dir/sys/kernel/debug &> /dev/null;
if [ ! -d $path_to_debug_dir/sys/kernel/debug ]; then
    echo "ERROR: Could not created the directory:  $path_to_debug_dir/sys/kernel/debug";
    exit 2;
fi

# Capture output of the following commands.
hostname > $path_to_debug_dir/hostname;
date > $path_to_debug_dir/date;
mount > $path_to_debug_dir/mount;
cp /etc/cluster/cluster.conf $path_to_debug_dir/cluster.conf;
cp /var/log/messages $path_to_debug_dir/messages;
cp -r /var/log/cluster/*.log $path_to_debug_dir/cluster/
dmesg > $path_to_debug_dir/dmesg
ps -eo user,pid,ppid,%cpu,%mem,vsz,rss,tty,stat,start,wchan:32,time,args > $path_to_debug_dir/ps_eo;
cman_tool service > $path_to_debug_dir/cman_tool_service 2>&1;
fence_tool ls > $path_to_debug_dir/fence_tool_ls 2>&1;
dlm_tool ls -n > $path_to_debug_dir/dlm_tool_ls_n 2>&1;
dlm_tool dump > $path_to_debug_dir/dlm_tool_dump 2>&1;

# Capture dlm id, recover_nodeid, recover_status and misc items.
cp -r /sys/kernel/dlm/ $path_to_debug_dir/sys/kernel/ &> /dev/null;
# Capture lockdumps and waiters.
cp -r /sys/kernel/debug/dlm/ $path_to_debug_dir/sys/kernel/debug/;
cp -r /sys/kernel/debug/gfs2/ $path_to_debug_dir/sys/kernel/debug/;

echo "The debug data is located in the directory: $path_to_debug_dir";
logger "DLM debugging data was captured successfully.";
echo "Creating archive of the directory: $path_to_debug_dir";
tar jcf $path_to_debug_dir.tar.bz2 $path_to_debug_dir &> /dev/null;
echo "Archive created and is located at: $path_to_debug_dir.tar.bz2";
exit
