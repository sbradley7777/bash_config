#!/bin/bash
#*
#*----------------------------------------------------------------------------------------
#*
#* All software provided below is unsupported and provided as-is, without warranty
#* of any kind.
#*
#* To the extent possible under law, Red Hat, Inc. has dedicated all copyright
#* to this software to the public domain worldwide, pursuant to the CC0 Public
#* Domain Dedication. This software is distributed without any warranty.
#* See <http://creativecommons.org/publicdomain/zero/1.0/>.
#*
#*----------------------------------------------------------------------------------------
#*
#
# This script is for debugging and has not been tested.

# The script will not run unless the "/sys/kernel/debug" directory is mounted
# and a GFS2 filesystem is mounted.
# mount -t debugfs debugfs /sys/kernel/debug/

# Make sure local.info and local.err messages will be logged to
# /var/log/messages so that we know if archived was created.

# The variables "archive_dir" and "archive_tmp_dir" can be modified if the
# directories need to be changed.

# Can be added to cron job to run by root user. Here is example that runs the
# script every minute which might be way too often in most use cases (Make sure
# that "crond" is started before or after adding entry to crontab):
# crontab -u root -e
# * * * * * /bin/bash /root/bin/bin.priv/copy-debug_gfs2.sh
#
# Note: You do not want to schedule in such a manner that you have multiple
# versions of these scripts running at same time. The minimal interval should be
# the time it takes this script to complete which will vary from configuration
# to confiugruation.
# #####################################################################

# The source directory to copy (Do not modify).
src_dir="/sys/kernel/debug/gfs2/";
# The location to archive all the data to (Can be modified).
archive_dir="/tmp/debug_gfs2";
# Number of minutes worth of archives to keep.
number_of_minutes_to_keep_archives=60;
if [ ! -d $src_dir ]; then
    error_msg="Error: The debugfs is not mounted: /sys/kernel/debug. The script $(basename $0) will exit.";
    echo $error_msg;
    logger -p local7.err $error_msg;
    exit 1;
fi

if [ ! -d $archive_dir ]; then
    mkdir -p $archive_dir &> /dev/null;
fi

if [ -d $archive_dir ]; then
    date_now=$(date '+%d-%m-%Y_%H-%M-%S');
    # Make sure and create a unique directory name.
    dst_dirname="debug_gfs2-$date_now";
    path_to_tmp_dir=$archive_dir/$dst_dirname;
    cp -r $src_dir $path_to_tmp_dir;
    if [ -d $path_to_tmp_dir ]; then
	path_to_archived_file="/tmp/debug_gfs2/debug_gfs2-$date_now.tar.bz2";
	tar jcvf $path_to_archived_file -C $archive_dir $dst_dirname &> /dev/null;
	if [ -f $path_to_archived_file ]; then
	    logger -p local7.info "The script $(basename $0) archived the debug data for the GFS2 filesystems: $path_to_archived_file.";
	    # Remove the copy of the debug data directory.
	    rm -rf $path_to_tmp_dir &> /dev/null;
	else
	    logger -p local7.err "Error: The script $(basename $0) failed to create the archive: $path_to_archived_file.";
	fi
    fi
fi

# Only keep $number_of_minutes_to_keep_archives in minutes archives and the rest
# will be deleted.
find $archive_dir/debug_gfs2*.bz2 -mmin +$number_of_minutes_to_keep_archives -exec rm {} \;
exit;
