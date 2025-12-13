#!/bin/sh
# ####################################################################
# file_generator.sh
#
# Author: Shane Bradley

# Description:
# This script will creata a bunch of directories and files under those
# directories.

# ####################################################################
# The path to the directory where the directories and files will be created.
PATH_TO_DST_DIR="";
# The number of directories that will be created.
DIR_COUNT=2;
# The number of files that will be created under these directories.
FILE_COUNT=10;
# BlockSize of file
BLOCK_SIZE=1024;
# Number of blocks in a file
BLOCK_COUNT=4;
# Random directory shuffle
RANDOM_DIR=1;

usage() {
    echo "$0 -p <path to directory> -s <subdirectory count> -f <file count>";
}

while getopts “hp:s:f:vr” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         p)
             PATH_TO_DST_DIR=$OPTARG
             ;;
         s)
             DIR_COUNT=$OPTARG
             ;;
         f)
             FILE_COUNT=$OPTARG
             ;;
	 r) RANDOM_DIR=0
            ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ -z $PATH_TO_DST_DIR ]; then
    echo "There was no path to a directory given."
    usage;
    exit 1;
elif [ ! -d $PATH_TO_DST_DIR ]; then
    echo "The path given does not exist or is not a directory: $PATH_TO_DST_DIR";
    usage;
    exit 1;
fi

# Remove trailing backslash
PATH_TO_DST_DIR=${PATH_TO_DST_DIR%/}

echo "Creating the random files in the directory: $PATH_TO_DST_DIR";

# Create the directories first.
for dir_counter in $(seq -f "%07g" 1 $DIR_COUNT); do
    pathToDir=$PATH_TO_DST_DIR/$dir_counter
    if [ ! -d "$pathToDir" ]; then
	echo Creating the directory: $pathToDir;
	mkdir -p $pathToDir;
    fi
done;

# Randomly shuffle the array of dir paths.
dirs=( $(find $PATH_TO_DST_DIR/* -maxdepth 1 -type d) )
path_to_dirs=()
if [ $RANDOM_DIR -eq 0 ]; then
    path_to_dirs=()
    function checkArray {
	for item in ${path_to_dirs[@]}
	do
	    [[ "$item" == "$1" ]] && return 0 # Exists in path_to_dirs
	done
	# Not found.
	return 1
    }
    while [ "${#path_to_dirs[@]}" -ne "${#dirs[@]}" ]
    do
	rand=$[ $RANDOM % ${#dirs[@]} ]
	checkArray "${dirs[$rand]}" || path_to_dirs=(${path_to_dirs[@]} "${dirs[$rand]}")
    done
else
    path_to_dirs=(${dirs[*]})
fi
# Create the files in each of the subdirectories.
printf -v fc_ceiling "%07d" $FILE_COUNT

for i in "${path_to_dirs[@]}"; do
  if [ -d $i ]; then
      echo "Creating $FILE_COUNT random files for $i if they do not exist."
      for file_counter in $(seq -f "%07g" 1 $FILE_COUNT); do
	  pathToRandomFile=$i/$file_counter.txt;
	  if [ ! -f "$pathToRandomFile" ]; then
	      dd bs=$BLOCK_SIZE count=$BLOCK_COUNT if=/dev/zero of=$pathToRandomFile 2> /dev/null;
	      if [ -f $pathToRandomFile ]; then
		  echo "  Created file $file_counter/$fc_ceiling for directory $i.";
	      fi
	  fi
      done;
  fi
done;
# Application Exit.
exit;
