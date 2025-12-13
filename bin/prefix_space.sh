#!/bin/bash
######################################################################
# prefix-space.sh                                                    #
#                                                                    #
# Author: Shane Bradley(sbradley@redhat.com)                         #
# Creation Date: 3-15-2024                                           #
# Version: 2.0                                                       #
#                                                                    #
# usage:                                                             #
# $ prefix-space.sh -p <path to file> -w <whitespace count>          #
######################################################################

# Example Articles
# - https://phoenixnap.com/kb/grep-regex

# Examples
#   "htt.*://www.rsyslog.com"
#   "su[:[]" replaces
#        "su\:"
#        "su\["

######################################################################
# Global Variables
######################################################################
# A list of strings to ignore.
GREP_IGNORES_DEFAULT=( "sshd" \
		       "snmpd" \
		       "goferd" \
		       "sudo" \
		       "xinetd" \
		       "automount" \
		       "adclient" \
		       "adinfo" \
		       "cupsd" \
		       "sssd" \
		       "org.freedesktop" \
		       "systemd-logind" \
		       "rate-limiting" \
		       "Audit daemon rotating log files" \
		       "www.rsyslog.com" \
		       "journal reloaded" \
		       "journal\: Suppressed" \
		       "of user *." \
		       "of root" \
		       "User Slice of" \
		       "Started Session" \
		       "Removed session" \
		       "su[:[]" \
		       "is marked world-inaccessible" \
		       "is marked executable" \
		       "martian source" \
		       "ll header" \
		       "net_ratelimit" \
		       "nfsidmap" \
		       "system activity accounting tool" \
 		       "sysstat-collect.service" \
		       "pmlogger" \
		       "pmie" );

# A list of strings to ignore that can be disabled with -E option.
GREP_IGNORES_EXTRAS=( "podman\[" \
		      "healthcheck" \
		      "dnsmasq" \
		      "node_exporter" \
		      "kernel\: IN\="
		      "ansible-" \
		      "CROND");

######################################################################
# Usage
######################################################################
usage() {
    bname=$(basename $0);
    echo -e "usage: $bname -s <path to file> -w <prefix whitespace count>";
    echo -e "This script adds a whitespace prefix before each line in the file and ignores lines that contain certain strings.\n";
    echo "OPTIONS:";
    echo "   -h      show this message";
    echo "   -p      path to the file that will be analyzed";
    echo "   -w      prefix whitespace count (default: 2)";
    echo "   -E      disables optional grep ignores";
    echo "   -G      disable all grep ignores";
    echo -e "\nEXAMPLE:";
    echo "$ $bname -s ~/somefile.txt -w  5";
}

######################################################################

path_to_file="";
prefix_whitespace_count=2;

disable_grep_ignores_extras=false;
disable_grep_ignores=false;
while getopts ":hp:w:EG" opt; do
    case $opt in
    h)
        usage;
        exit;
        ;;
    p)
        path_to_file=$OPTARG;
        ;;
    w)
        prefix_whitespace_count=$OPTARG;
        ;;
    E)
        disable_grep_ignores_extras=true;
        ;;
    G)
        disable_grep_ignores=true;
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2;
        exit 1;
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2;
        exit 1;
        ;;
    esac
done;

if [ -z $path_to_file ]; then
    echo -e "ERROR: A path to the file that will be read is required with -p option.\n";
    usage;
    exit 1;
fi;
if [ ! -n $path_to_file ]; then
    echo -e "ERROR: A path to the file that will be read is required with the -p option.\n";
    usage;
    exit 1;
fi;
if [ ! -f $path_to_file ]; then
    echo -e "ERROR: The file does not exist: $1\n";
    usage;
    exit 1;
fi;

# Create a string that contains the number of spaces that will be prefixed for each line.
prefix=$(printf "%*s" $prefix_whitespace_count);
# Enable bash debugging by uncommenting this line.
# set -x

# Build a list of grep -e <string> options to exclude from the results.
grep_ignore_regexs="";
for i in ${!GREP_IGNORES_DEFAULT[@]}; do
    grep_ignore_regexs+="-e '${GREP_IGNORES_DEFAULT[i]}' ";
done;

# If grep_ignores_extras is enabled then add these to the list.
if [ "$disable_grep_ignores_extras" = false ]; then
    for i in ${!GREP_IGNORES_EXTRAS[@]}; do
	grep_ignore_regexs+="-e '${GREP_IGNORES_EXTRAS[i]}' ";
    done;
fi;

# Disable grep ignores
if [ "$disable_grep_ignores" = true ]; then
    cat $path_to_file | awk -v prefix="$prefix" '{print prefix $0}';
else
    # Command to add spacing, then strip lines of strings that should be ignored.
    # Had to use "eval" as if ran direct it would add lots of escape quotes.
    eval "grep -ai -v $grep_ignore_regexs $path_to_file" | awk -v prefix="$prefix" '{print prefix $0}';
 fi;
exit;
