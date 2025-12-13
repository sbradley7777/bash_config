#!/bin/sh
# Author: sbradley@redhat.com
# Description: The scripts uses /etc/hosts to get a list of hosts (that match a
# regex) that will have a configuration files uploaded to the remote host.
# Version: 1.1
#
# Usage: ./configs-copy_local_to_remote.sh

# NOTE: If the file does not start with "/" then assume it is an config file for
# user that will go into the root directory for the remote host.

files=( ".ssh/config" "/etc/hosts" );

# Script will exit if this function is executed.
control_c() {
  # Run if user hits control-c so clean exit.
  echo -en "\n*** Control-c caught and script will exit.***\n"
  exit 1
}
# Trap keyboard interrupt (control-c)
trap control_c SIGINT

while read -r line
do
    # Only hostnames with starting with "rh" and does not include "alt" will
    # have files uploaded to them and skip lines that start with #.
    hosti=`echo $line | grep " rh" | grep -v "alt" | grep -v -ie "^#" | awk '{print $3}'`;
    if [ ! -z $hosti ]; then
	ping -q -c 1 $hosti &>/dev/null
	if [ $? -eq 0 ] ; then
	    for f in ${!files[@]}; do
		src=${files[f]};
		dst=${files[f]};
		echo "Uploading the file $src to $hosti.";
         	# Change the src/dst values, where src is for path to user home
	        # directory and dst is path to root directory.
		if [[ ! "$src" =~ ^/.* ]]; then
		    dst=/root/$src;
		    src=$HOME/$src;
		fi
		scp -q  "$src" root@$hosti:$dst #2>/dev/null
		if [[ ! "$?" -eq "0" ]]; then
		    echo "ERROR: Uploading the configuration file: $src";
		fi
	    done
	else
	    echo "WARNING: The host $hosti is unreachable. Skipping.";
	fi
    fi
done < "/etc/hosts"
exit;
