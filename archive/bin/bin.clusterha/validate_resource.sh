#!/bin/bash

# Run tests on lsb scripts to see if they are compatible with pacemaker.
# http://www.linux-ha.org/wiki/LSB_Resource_Agents

# This scrip tdoes not test all aspects of validality of lsb resource when
# managed by pacemaker.

# If you import "/etc/init.d/functions" in your lsb script then it will error
# out.

lsb_script=$1
path_to_lsb_script=/etc/init.d/$lsb_script;
if [ -z "$lsb_script" ]; then
    echo "ERROR: The name of the lsb script located in the /etc/init.d directory is required.";
    echo "Usage: $0 myscript.sh";
    exit 1;
elif [ ! -f "$path_to_lsb_script" ]; then
    echo "ERROR: The path to lsb script does not exist in /etc/init.d: $lsb_script.";
    echo "Usage: $0 myscript.sh";
    exit 1;

fi

echo "Testing the lsb script: $path_to_lsb_script";

# Did start successfully start?
$path_to_lsb_script start;  echo "start result:  $? (Should be zero if started successfully)";
# Is status 0 if running?
$path_to_lsb_script status; echo "status result: $? (Should be zero if running)";
# Did start successfully start?
$path_to_lsb_script start;  echo "start result:  $? (Should be zero if started successfully)";
# Is status 0 if running?
$path_to_lsb_script status; echo "status result: $? (Should be zero if running)";
# Did start successfully stop?
$path_to_lsb_script stop;   echo "stop result:   $? (Should be zero if stopped successfully)";
# Is status 0 if not running?
$path_to_lsb_script status; echo "status result: $? (Should be non-zero if not running)";
# Is status 0 if not running?
$path_to_lsb_script stop;   echo "stop result:   $? (Should be zero if stopped successfully)";

echo "DONE";
echo "This does not test all aspects of validality of lsb resource when managed by pacemaker.";
exit;
