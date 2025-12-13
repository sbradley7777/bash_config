#!/bin/sh
# flockholder.sh
# Description: An exclusive flock will be taken out on a file preventing other
# processes from using it.
# Author: Shane Bradley(sbradley AT redhat.com)
#
# Save to ~/bin directory and then set the permissions on the file.
# $ chmod 700 ./flockholder.sh
#
# Usage:
# $ ./flockholder.sh /mnt/gfs2vol1/testfile.txt


# Log message with syslog. $1 is the message.
function syslog_msg() {
    bname=$(basename $0);
    bname=${bname%%.*};
    logger -t test "$1";
}
# Print message to console. $1 is the priority and $2 is the message.
function print_msg() {
    echo "$1: $2";
}
# Print message to console and log with syslog. $1 is the priority and $2 is the message.
function log_msg() {
    print_msg $1 "$2";
    syslog_msg "$2";
}

######################################################################
# Main
######################################################################
filename=$1
if [ ! -f $filename ]; then
    log_msg "WARNING" "The file does not exist and will be created: $filename.";
    touch $filename;
fi

log_msg "INFO" "Starting the lock test on $(hostname) with the file and will hold the lock: $1.";
log_msg "INFO" "Attempting to get exclusive lock on the file.";
(
    trap exit SIGINT

    # The -e will open in exclusive mode and int is the file descriptor
    # number that will be used.
    flock -e 200;
    log_msg "INFO" "The exclusive lock has been acquired.";
    timestamp=$(date -d "today" +"%b %d %H:%M:%N");
    echo "$timestamp: $(hostname) has acquired an exclusive lock." >> $filename
    release_lock=0
    while [ ! $release_lock -eq 1 ]; do
        sleep 1;
    done
) 200>>$filename;
log_msg "INFO" "Releasing the exclusive lock on the file.";

# Exit the script.
exit;
