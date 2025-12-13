#!/bin/sh
# Author: sbradley@redhat.com
# Description: The scripts uses /etc/hosts to get a list of hosts (that match a
# regex) that will archive the ~/bin/bin.priv directory or any *.priv config
# file for each of the remote  hosts.
# Version: 1.1
#
# Usage: ./configs-bin_priv_archive.sh

# Current data for unique backups
TODAY=`date '+%F_%s'`;
# The path to directory that will contain archived files.
ARCHIVE_DIR="/tmp/`date '+%F_%s'`-bin.priv";
# The files that will be archived.
src_files=( "~/.dot.config" "/root/.bash_profile.priv" "/root/.bashrc.priv" "/root/bin/bin.priv" "/etc/cluster/" "~/recreation_scripts" );
# Script will exit if this function is executed.
control_c() {
  # Run if user hits control-c so clean exit.
  echo -en "\n*** Control-c caught and script will exit.***\n"
  exit 1
}
# Trap keyboard interrupt (control-c)
trap control_c SIGINT

echo "The files will be archived to directory: $ARCHIVE_DIR";
# Read /etc/hosts and do action on the remote hosts.
while read -r line
do
    # Only hostnames with starting with "rh" and does not include "alt" will
    # have files uploaded to them and skip lines that start with #.
    hosti=`echo $line | grep " rh" | grep -v "alt" | grep -v -ie "^#" | awk '{print $3}'`;
    if [ ! -z $hosti ]; then
        ping -q -c 1 $hosti &>/dev/null
        if [ $? -eq 0 ] ; then
    	    echo "Archiving the private files for the host: $hosti.";
	    dst_dir=$ARCHIVE_DIR/$hosti;
	    mkdir -p $dst_dir 2>/dev/null;
	    if [ -d $ARCHIVE_DIR ]; then
		for j in ${!src_files[@]}; do
		    src=${src_files[j]};
		    scp -q -r root@$hosti:$src $dst_dir/ 2>/dev/null;
		    if [[ ! "$?" -eq "0" ]]; then
			echo "ERROR: There was an archiving the file $src on $hosti.";
		    fi
		   # fi
		done
	    fi
        else
            echo "WARNING: The host $hosti is unreachable. Skipping.";
        fi
    fi
done < "/etc/hosts"
parent_dir=$(dirname $ARCHIVE_DIR);
path_to_tarball=$parent_dir/priv-$TODAY.tar.bz2;
echo "Creating a tarball of the archived files: $path_to_tarball";
tar jcf $path_to_tarball -C $ARCHIVE_DIR . 2>/dev/null;
exit;


