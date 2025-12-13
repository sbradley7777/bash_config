#!/bin/sh
# This script will log fenced snmp traps.

# #####################################################################
# Global Vars:
# #####################################################################
# The log directory that will contain the snmp traps that are logged
# to a file if enabled.
LOG_DIR="/var/log/snmptrapd-traps";
# Path to the file that will be used to log the snmp trap if enabled.
PATH_TO_LOG_FILE="$LOG_DIR/fenced.log";
# If 0 this snmp trap will be log to a file, if 1 it will not be
# logged to a file.
ENABLE_LOGGING_TO_FILE=0;

# #####################################################################
# Define the vars that are in the snmp trap:
# #####################################################################
# All the default values in the trap.
sysUpTimeInstance="";
snmpMIBName="";
snmpTrapName="";

# All the the defined values in the trap. 
fenceNodeName="";
fenceNodeID=-1;
fenceResult=1;

# #####################################################################
# Process the snmp trap:
# #####################################################################
# Read in the hostname string.
read host;
srcHostname=$(echo $host | cut -d'=' -f 2);

# Read in the address string.
#               src                     dst 
#addr=UDP: [192.168.1.163]:54133->[192.168.1.161]
read addr;

while read oid val
do
    #logger $oid
    if [ "$oid" = "DISMAN-EVENT-MIB::sysUpTimeInstance" ]; then
        sysUpTimeInstance=$val
    elif [ "$oid" = "SNMPv2-MIB::snmpTrapOID.0" ]; then
        snmpMIBName=$(echo $val | cut -d':' -f 1);
        snmpTrapName=$(echo $val | cut -d':' -f 3);
    elif [ "$oid" = "$snmpMIBName::fenceNodeName.0" ]; then
          fenceNodeName=$val;
          fenceNodeName=$(echo ${fenceNodeName//[\"]/})
    elif [ "$oid" = "$snmpMIBName::fenceNodeID.0" ]; then
          fenceNodeID=$val
    elif [ "$oid" = "$snmpMIBName::fenceResult.0" ]; then
          fenceResult=$val
    fi
done

# Decode the meaning of the fencing result. 0 is success, -1 is
# failure, -2 is no fencing method defined for the cluster node that
# should be fenced.
fenceResultString="unknown";
if [ $fenceResult -eq 0 ]; then
    fenceResultString="Success";
elif [ $fenceResult -eq -1 ]; then
    fenceResultString="Failure";
elif [ $fenceResult -eq -2 ]; then
    fenceResultString="No fencing method defined";
fi

# Log to a file if that is enabled.
if [ $ENABLE_LOGGING_TO_FILE -eq 0 ]; then 
    # Create the log directory if it does not exist
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p $LOG_DIR;
    fi;
    echo "------------------------------------------------" >> $PATH_TO_LOG_FILE;
    echo "srcHostname = $srcHostname" >> $PATH_TO_LOG_FILE;
    echo "addr=$addr" >> $PATH_TO_LOG_FILE;
    echo "    fenceNodeName = $fenceNodeName" >> $PATH_TO_LOG_FILE;
    echo "    fenceNodeID   = $fenceNodeID" >> $PATH_TO_LOG_FILE;
    echo "    fenceResult   = $fenceResult($fenceResultString)" >> $PATH_TO_LOG_FILE;
    echo "------------------------------------------------" >> $PATH_TO_LOG_FILE;
    echo "" >> $PATH_TO_LOG_FILE;
fi

# Create a message.
message="$srcHostname sent the following trap $snmpMIBName::$snmpTrapName";
message="$message | A node has been fenced: $fenceNodeName. The result of the fencing of the node $fenceNodeName was $fenceResultString.";

# Mail the message.
echo "$message" | mail -s "$fenceNodeName was fenced." root@localhost

# Exit the script.
exit;
