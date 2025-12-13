#!/bin/sh
# Author: sbradley@redhat.com
# Description: The scripts uses /etc/hosts to get a list of hosts (that match a
# regex) that will have a configuration file uploaded for installer that is
# included in a git repo. The installer installs certain configuration files and
# scripts to the remote host.
# Version: 1.1
#
# Usage: ./configs-install_remote.sh

configuration_file_upload="$HOME/.dot.config.rhel_cluster";

# Script will exit if this function is executed.
control_c() {
  # Run if user hits control-c so clean exit.
  echo -en "\n*** Control-c caught and script will exit.***\n"
  exit 1
}
# Trap keyboard interrupt (control-c)
trap control_c SIGINT

# If the configuration file is successfully uploaded then it will be added to
# the string so that it will have files installed, if failed it will not be
# added and will not have files installed.
while read -r line
do
    # Only hostnames with starting with "rh" and does not include "alt" will
    # have files uploaded to them and skip lines that start with #.
    hosti=`echo $line | grep " rh" | grep -v "alt" | grep -v -ie "^#" | awk '{print $3}'`;
    if [ ! -z $hosti ]; then
	ping -q -c 1 $hosti &>/dev/null
	if [ $? -eq 0 ] ; then
	    echo "Uploading the configuration file $configuration_file_upload file to $hosti:~/.dot.config.";
	    scp -q  "$configuration_file_upload" root@$hosti:~/.dot.config 2>/dev/null
	    if [[ ! "$?" -eq "0" ]]; then
		echo "ERROR: Uploading the configuration file failed. The $hosti will be skipped.";
	    else
		hosts_to_install+="$hosti ";
	    fi

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

if [[ ! -z $hosts_to_install ]]; then
    echo "";
    ~/github/dot.config/install_on_hosts.sh -p /root/github/dot.config -m "$hosts_to_install" 2>/dev/null;
else
    echo "ERROR: There was no hosts that successfully uploaded the configuration file, so installation was skipped."
    exit 1;
fi
exit;

