#!/bin/sh
# umount-submount.sh

# Author: Shane Bradley(sbradley@redhat.com
# Description: This script will mount 2 filesystems, the 2nd filesystem mounted
# will be a submount of the first filesystem mounted. Then the filesystems will
# be unmounted, the 2nd filesystem will be unmounted first and then 1st
# filesystem mounted will be unmounted last.
#
# If the filesystems were mounted succssfully and unmounted successfully then
# the script ran successfully, otherwise fail.
#
# * Before doing the recreation set the variables for the devices, mount points,
#   and filesystem type.
#
# * Before doing the recreation the filesystem must be created. For example a GFS2
#   filesystem below:
#     mkfs.gfs2 -t rh6cluster:gfs2-lvol1 -p lock_dlm -j 4 /dev/mapper/vgShared1-lvol1 -O
#     mkfs.gfs2 -t rh6cluster:gfs2-lvol2 -p lock_dlm -j 4 /dev/mapper/vgShared1-lvol2 -O
# ###############################################################################
# Set these variables before doing the recreation.
# ###############################################################################
filesystem_type="gfs2";
path_to_device_a="/dev/mapper/vgShared1-lvol1";
path_to_device_b="/dev/mapper/vgShared1-lvol2";
path_to_mount_a="/mnt/01167467/mnt/a";
path_to_mount_b="$path_to_mount_a/b";
# ###############################################################################
hostname;
uname -a;
date;
echo -e "\n----------------------------------\n";
echo "Starting the recreation.";
# Create the directory if does not exist and mount parent filesystem.
mkdir -p $path_to_mount_a &> /dev/null;
mount -t $filesystem_type $path_to_device_a $path_to_mount_a;
if [ $? -eq 0 ]; then
    echo "The filesystem $path_to_mount_a is mounted."
    # Create the submount directory for the other filesystem on the previous
    # filesystem that was mounted.
    mkdir -p $path_to_mount_b &> /dev/null;
else
    echo "There was an error mounting the filesystem: $path_to_mount_a";
    echo "The script will exit.";
    exit 1;
fi
# Create the directory if does not exist and mount child or submount filesystem.
if [ -d $path_to_mount_b ]; then
    mount -t $filesystem_type $path_to_device_b $path_to_mount_b;
    if [ $? -eq 0 ]; then
	echo "The filesystem $path_to_mount_b is mounted."
    else
	echo "There was an error mounting the filesystem: $path_to_mount_b";
	echo "The script will exit.";
	exit 1;
    fi
fi
# Print to console what is mounted and sleep for 5 seconds.
df -Ph | grep -ie $path_to_mount_a;
grep $path_to_mount_a /proc/mounts;
sleep 5;
# Unmount the child or submoutn filesystem first and print to console some
# filesystem information.
echo -e "\n----------------------------------\n";
umount $path_to_mount_b;
if [ $? -eq 0 ]; then
    echo "The unmounting of $path_to_mount_b: SUCCESS";
else
    df -Ph | grep -ie $path_to_mount_a;
    grep $path_to_mount_a /proc/mounts;
    echo -e "\nThe unmounting of $path_to_mount_b: FAILED";
    exit 1;
fi
df -Ph | grep -ie $path_to_mount_a;
grep $path_to_mount_a /proc/mounts;
# Unmount the parent filesystem last and print to console some filesystem
# information.
echo -e "\n----------------------------------\n";
umount $path_to_mount_a
if [ $? -eq 0 ]; then
    echo "The unmounting of $path_to_mount_a: SUCCESS";
else
    df -Ph | grep -ie $path_to_mount_a;
    grep $path_to_mount_a /proc/mounts;
    echo -e "\nThe unmounting of $path_to_mount_a: FAILED";
    exit 1;
fi
df -Ph | grep -ie $path_to_mount_a;
grep $path_to_mount_a /proc/mounts;
# Print the results of test. If no filesystem was found with grep search then
# the test was a success.
if [  $? -eq 0 ]; then
    echo -e "\nThe recreation FAILED since there are still mounted filesystems.";
    exit 1;
else
    echo -e "\nThe recreation was a SUCCESS since there are no filesystem still mounted.";
fi
exit;
