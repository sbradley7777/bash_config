#!/bin/sh
######################################################################
# install_configs.sh
#
# Author: Shane Bradley
# Description: This script will clone or update the git repository on multiple
#              hosts. This script will need ssh keys to installed on all
#              hosts.
# usage:
# $ install_configs.sh -p /root/github/dot.config -m "rh50 rh53"
######################################################################

usage()
{
cat <<EOF
usage: $0 -p <PATH TO GIT REPO> -m <LIST OF HOSTS>

This script will clone the git repo or update the git repo, then it will reinstall configuration.

OPTIONS:
   -h      Show this message
   -p      Path to where the git repository will be installed or is installed.
   -m      List of hosts that will have the git repository installed or updated.
   -v      Verbose

EXAMPLE:
$ $0 -p /root/github/dot.config -m "rh50 rh53"

EOF
}

PATH_TO_GIT_REPO_DIR=
LIST_OF_HOSTS=
VERBOSE=
while getopts “hp:m:v” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         p)
             PATH_TO_GIT_REPO_DIR=$OPTARG
             ;;
         m)
             LIST_OF_HOSTS=(${OPTARG// / })
             ;;
         v)
             VERBOSE=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z $PATH_TO_GIT_REPO_DIR ]] || [[ -z $LIST_OF_HOSTS ]] ; then
    usage
    exit 1
fi

######################################################################
# All options were specified and the hosts will either have a repo cloned or
# updated. Then installed.
######################################################################
echo "-----------------------------------------------------------------";
echo "Downloading and Installing configuration for the following hosts:";
echo "-----------------------------------------------------------------";
for i in ${!LIST_OF_HOSTS[@]}
  do
    currentHostname=${LIST_OF_HOSTS[i]};
    ping -q -c 1 $currentHostname &>/dev/null
    if [ $? -eq 0 ] ; then
        if [ $VERBOSE ]; then
            echo "Analyzing $currentHostname to see if the repo exists.";
        fi
        searchString="No such file or directory"
        repo_exists=$(ssh $currentHostname  "ls $PATH_TO_GIT_REPO_DIR;" 2>&1);
        # If directory does not exists then we need to create and clone dir, else just update git repo.
        case $repo_exists in
            # MATCH: At end of the string.
            #*"$searchString") echo "MATCH AT END OF STRING" ;;
            *"$searchString"*)
                # MATCH: Anywhere in the string.
                if [ $VERBOSE ]; then
                    echo "The git repo $PATH_TO_GIT_REPO_DIR on $currentHostname does not exists and will be created.";
                fi
                ssh $currentHostname  "mkdir -p $PATH_TO_GIT_REPO_DIR; git clone --quiet git://github.com/sbradley7777/dot.config.git $PATH_TO_GIT_REPO_DIR; python $PATH_TO_GIT_REPO_DIR/install.py -y -q;";
                if [ "$?" == "0" ] ; then
                    echo "$currentHostname: SUCCESS";
                else
                    echo "$currentHostname: FAILED";
                fi ;;
            *)
                if [ $VERBOSE ]; then
                    echo "The git repo $PATH_TO_GIT_REPO_DIR on $currentHostname does exists and will be updated.";
                fi
                ssh $currentHostname  "cd $PATH_TO_GIT_REPO_DIR; git reset --quiet --hard origin/master; git pull --quiet; python $PATH_TO_GIT_REPO_DIR/install.py -y -q;"
                if [ "$?" == "0" ] ; then
                    echo "$currentHostname: SUCCESS";
                else
                    echo "$currentHostname: FAILED";
                fi ;;
        esac
    else
        echo "$currentHostname: FAILED (ping of host failed)";
    fi
done
exit 0;
