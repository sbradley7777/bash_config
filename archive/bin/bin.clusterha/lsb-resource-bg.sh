#!/bin/sh
# This script will loop forever until a signal is caught. 

# If the $PATH_TO_SCRIPT is set in /etc/sysconfig/lsb-resource to this script
# then this script will be ran. The service script /etc/init.d/lsb-resource will
# send a SIGINT to kill the process (via kill command). This script is currently
# set to exit() on caught SIGINT and SIGTERM signals.

# If you want to it to ignore SIGINT signals then change the function that will
# be ran on trap signal to signal_ignore().

signal_exit() {
    logger "The script caught a signal and will exit."
    exit 0;
}
signal_ignore() {
    logger "The script caught a signal and will do nothing."
}
# Trap keyboard interrupt (control-c)
trap signal_exit SIGINT
# trap signal_ignore SIGTERM
trap signal_exit SIGTERM
# Cannot catch a SIGKILL.

while true; do
    nothing=0;
done
exit;
