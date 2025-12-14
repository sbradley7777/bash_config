#!/bin/sh
######################################################################
#######################USE AT YOUR RISK###############################
######################################################################

######################################################################
# archive-files.sh                                                   #
#                                                                    #
# Author: Shane Bradley(sbradley@redhat.com)                         #
# Creation Date: 12-30-2006                                          #
# Version: 1.0                                                       #
# Last Modified: February 2, 2010                                    #
#                                                                    #
# usage:                                                             #
# $ archive-files.sh                                                 #
######################################################################

######################################################################
# Variables and aliases                                              #
######################################################################
# Current data for unique backups
TODAY=`date '+%F_%s'`;
# The root of archive
ROOT_DIR="/pub/archive/$(hostname)";
# The root of archive with subdirectory of today var.
# Files will be archive here.
ARCHIVE_DIR=$ROOT_DIR/$TODAY;

# List the directories/files you want to backup.  In OSX if you
# include trailing slash only contents copied like with *.
ARCHIVE_ARRAY=( "/home"
    "/root" \
    "/etc");

# Command aliases
alias cp4backup="cp -R -p -P ";

######################################################################
# ARCHIVE DIRECTORIES                                                #
######################################################################
# Setup archive directory
if [ -d $ARCHIVE_DIR ]
then
    echo "ERROR: Archive directory already exists: \n\t $ARCHIVE_DIR";
    echo "INFO:  Please manually deleted this directory or try re-running $0."
    exit 1;
fi
echo "Starting the backup: $ARCHIVE_DIR";
mkdir -p $ARCHIVE_DIR;

# Archive files/directories in the array
for i in ${!ARCHIVE_ARRAY[@]}
  do
  archive_item=${ARCHIVE_ARRAY[i]};
  if [ -d $archive_item ]
    then
      # Process directories
      echo "Copying directory $archive_item --> $ARCHIVE_DIR";
      cp4backup $archive_item $ARCHIVE_DIR/
  else
      if [ -f $archive_item ]
          then
          # Process files
          echo "Copying file $archive_item --> $ARCHIVE_DIR";
          cp4backup $archive_item $ARCHIVE_DIR/
      else
          # The current file/directory does not exist.
          echo "ERROR: $archive_item directory or file does not exit";
      fi
  fi
done
######################################################################
# POST COMMANDS                                                      #
######################################################################
du -sh $ARCHIVE_DIR/ > $ARCHIVE_DIR/backup_size.txt;
echo "";
echo "Size of archive directory:";
cat $ARCHIVE_DIR/backup_size.txt;
echo "";

######################################################################
# Compress and backup                                                #
######################################################################
echo "INFO: Compressing  $ARCHIVE_DIR to $ROOT_DIR/archive_tgz/$TODAY.tgz";
cd $ROOT_DIR

# Compress file will be located in its own special dir.
if [ ! -d $ROOT_DIR/archive_tgz ]
then
    mkdir -p $ROOT_DIR/archive_tgz;
fi
tar -zcpf $ROOT_DIR/archive_tgz/$TODAY.tgz  $TODAY/
echo "";
echo "Size of compressed archive directory:";
du -sh $ROOT_DIR/archive_tgz/$TODAY.tgz;
echo "";

######################################################################
# Finish
######################################################################
echo "Done!";
exit;
######################################################################
