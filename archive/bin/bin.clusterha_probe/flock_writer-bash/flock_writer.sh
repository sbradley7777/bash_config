#!/bin/bash
# ###############################################################################
# Author: Shane Bradley(sbradley AT redhat.com)
# Version: 1.0
# Description: This script will use `flock` to make sure that only 1 process can
# write to a file at a time which prevents corruption from occurring.
#
# usage:
# $ ./flock_writer -p <path_to_file> -i <number of iterations>
# ###############################################################################
bname=$(basename $0);

usage()
{
cat <<EOF
usage: $bname -p <path to the file> -i <number of iterations>

This script writes a string to a file for a set number of
iterations and uses flock to getexclusive access to the file.

OPTIONS:
   -h      Show this message
   -i      The number of iterations
   -p      Path to the file that will be written to

EXAMPLE:
$ $bname -p /mnt/gfs2/flocked-file.txt -i 300

EOF
}

# The path to the file that will be written to.
path_to_file="";
# The number of iterations that a string will be written to the file.
iterations=100;
# Get the values for options user enabled.
while getopts ":hi:p:" opt; do
    case $opt in
        h)
            usage;
            exit;
            ;;
	i)
            interations=$OPTARG;
            ;;
        p)
            path_to_file=$OPTARG;
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
# Check that values for options are valid.
if [ -z $path_to_file ]; then
    echo "ERROR: A path to a file is required.";
    echo "";
    usage;
    exit 1;
fi

if [[ ! $iterations =~ ^[0-9]+$ ]]; then
    echo "ERROR: The argument for -i is not an integer: $iterations";
    echo "";
    usage;
    exit 1;
fi

# Print a summary of what will be done.
echo "INFO: The host $(hostname) will do $iterations interations of writes to the file: $path_to_file.";
sleep 1;
for ((i=0;i<${iterations};i++)); do
    (
	# The -e will open in exclusive mode and int is the file descriptor
        # number that will be used and all enclosed in a block. If the lock
        # cannot be immediately acquired by flock, then flock waits until the
        # lock is available.
	flock -e 200;
	# Do all the work that needs exclusive acccess below here.
	echo "$(hostname)-$i" >> ${path_to_file};
    ) 200>>$path_to_file;
done;
echo "INFO: Completed.";
exit;
