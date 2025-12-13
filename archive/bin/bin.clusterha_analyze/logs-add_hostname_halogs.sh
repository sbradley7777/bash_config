#!/bin/sh
# Description: Adds hostname to the log files that are found in $(pwd) with the
# following in there path "var/log/cluster/".
# Author: Shane Bradley(sbradley@redhat.com)

# first match(need to do first match
# $ cat var/log/cluster/corosync.log | sed 's/\([[:digit:]]\{2\}\:[[:digit:]]\{2\}\:[[:digit:]]\{2\}\)/\1 ghprodetl1/' | head
# global
# $ cat var/log/cluster/corosync.log | sed 's/\([[:digit:]]\{2\}\:[[:digit:]]\{2\}\:[[:digit:]]\{2\}\)/\1 ghprodetl1/g' | head


# If control-c is pressed then the script will exit.
function control_c() {
  log_msg "Control-C caught. The script will exit."
  exit;
}

######################################################################
# Main
######################################################################
# trap keyboard interrupt (control-c)
trap control_c SIGINT

for dir in *; do
    # skip the "reports" directories if found.
    hostname=`echo $dir | awk -F. '{ print $1 }'`;
    path_to_cluster_logs_dir=$(pwd)/$dir/var/log/cluster/;
    if [ -d "$path_to_cluster_logs_dir" ]; then
	for path_to_log_file in `find $path_to_cluster_logs_dir`; do
	    filename=$(basename $path_to_log_file);
	    # skip starts with ".", has "-" and is not a file.
	    if [[ $filename != *-* ]] && [ -f $path_to_log_file ] && [[ $filename != *.tmp ]] && [[ $filename != .* ]] &&  [ -s $path_to_log_file ]; then
		# Has hostname already been added and file should not be modified?
		message_4th_field=`head -n 1 $path_to_log_file | awk '{ print $4 }'`;
		if [[ $message_4th_field != $hostname ]]; then
		    file_size_mb=`du -m $path_to_log_file | awk '{ print $1 }'`;
       		    echo "Adding hostname \"$hostname\" to the log file (size: $file_size_mb MB): $path_to_log_file";
		    cp $path_to_log_file $path_to_cluster_logs_dir/.$filename;
		    cat $path_to_log_file |  sed "s/\([[:digit:]]\{2\}\:[[:digit:]]\{2\}\:[[:digit:]]\{2\}\)/\1 $hostname/" > $path_to_cluster_logs_dir/$filename.tmp;
		    mv $path_to_cluster_logs_dir/$filename.tmp $path_to_cluster_logs_dir/$filename;
		fi
	    fi
	done
    fi
done

