#!/bin/bash

source /etc/profile;
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin;
export PATH;
export TERM=${TERM:-dumb};

# Set the following variable that is conna seperated.
# eg:path="/root/test/path1,/root/test/path2"
path="$HOME/gitlab/insights-plugins/";
#----------------------------------------

# Check if user is root
#[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must run this script as root.${CEND}"; exit 1; } 2>&1

# Check if directory path exists
if [[ "${path}" = "" ]]; then
    echo "${CFAILURE}Error: You must set the correct directory path.Exit.${CEND}" 2>&1;
    exit 1;
fi

# Check if command git exists
if ! [ -x "$(command -v git)" ]; then
    echo "${CFAILURE}Error: You may not install the git.Exit.${CEND}" 2>&1;
    exit 1;
fi

# Check where is command git
git_path=`which git`;

# Start to deal the set dir
OLD_IFS="$IFS";
IFS=",";
dir=($path);
IFS="$OLD_IFS";

logger "Updating gitlab repos."
for git_dir in ${dir[@]}; do
    cd ${git_dir};
    work_dir=`pwd`;
    echo "---------------------------------" 2>&1;
    echo "git pull for " ${git_dir} 2>&1;
    ${git_path} pull;
    echo "---------------------------------" 2>&1;
done

echo "Done." 2>&1;
logger "Updated gitlab repos."
exit;
