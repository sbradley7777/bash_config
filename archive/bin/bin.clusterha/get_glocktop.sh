#!/bin/sh
# ####################################################################
# get_glocktop.sh
#
# Author: Shane Bradley(sbradley@redhat.com)

# Description: Downloads the latest glocktop and makes it executable in the
# ~/bin/bin.redhat directory. It will override an exisitng version of glocktop
# and then mounts the debug directory.
#
# After the file is downloaded then review the steps in the article:
# - https://access.redhat.com/articles/666533

# ####################################################################

PATH_TO_BIN_DIR=$HOME/bin/bin.clusterha;
PATH_TO_DEBUG_DIR=/sys/kernel/debug;

# Only download for supported OS versions.
major_version=$(lsb_release -rs | cut -f1 -d.);
if [ "$major_version" == "5" ] || [ "$major_version" == "6" ] || [ "$major_version" == "7" ]; then
    if [ ! -d $PATH_TO_BIN_DIR ]; then
	mkdir -p $PATH_TO_BIN_DIR > /dev/null 2>&1;
    fi
    # Remove the file if it already exists.
    if [ -f $PATH_TO_BIN_DIR/glocktop ]; then
	rm -f $PATH_TO_BIN_DIR/glocktop;
    fi
    wget --quiet -O $PATH_TO_BIN_DIR/glocktop http://people.redhat.com/rpeterso/Experimental/RHEL$major_version.x/glocktop
    if [ -f $PATH_TO_BIN_DIR/glocktop ]; then
	chmod 700 $PATH_TO_BIN_DIR/glocktop;
	echo "The file $PATH_TO_BIN_DIR/glocktop was successfully downloaded."
	if [ ! -d $PATH_TO_DEBUG_DIR ]; then
            mkdir -p $PATH_TO_DEBUG_DIR > /dev/null 2>&1;
	fi
	mount -t debugfs none $PATH_TO_DEBUG_DIR > /dev/null 2>&1;
	mountpoint -q $PATH_TO_DEBUG_DIR
	if [ $? == 0 ]; then
	    echo "The debug directory is mounted at $PATH_TO_DEBUG_DIR.";
	else
	    echo "ERROR: The debug directory could not be mounted at $PATH_TO_DEBUG_DIR.";
	    exit 1;
	fi

    else
	echo "ERROR: The file $PATH_TO_BIN_DIR/glocktop was not successfully downloaded."
	exit 1;
    fi
else
    echo "ERROR: The glocktop script is only supported on RHEL 5, RHEL 6, and RHEL 7".;
    exit 1;
fi
exit;
