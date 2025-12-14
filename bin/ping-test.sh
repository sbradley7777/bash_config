#!/bin/bash

# This script will block ping packets from leaving the host for X seconds and
# after waking from sleep will removing the blocking of ping packets.

# Amount of time to sleep after blocking ping packets.
sleep_time=10

if (! systemctl -q is-active firewalld.service); then
    echo "The systemd firewalld.service is not running so firewall rules cannot be modified."
    exit 1
fi

if [[ -n "$1" ]]; then
    sleep_time=$1
fi

echo "The systemd firewall.service is running. Blocking ping (icmp) packets for $sleep_time seconds."
firewall-cmd --direct --add-rule ipv4 filter OUTPUT 0 -p icmp --icmp-type echo-request -j DROP &> /dev/null
sleep "$sleep_time"
firewall-cmd --direct --remove-rule ipv4 filter OUTPUT 0 -p icmp --icmp-type echo-request -j DROP &> /dev/null
echo "Removing the firewall rule for blocking ping (icmp) packets."
