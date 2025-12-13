#!/bin/sh

# This script will get the ip for an ethernet device for some host.


function valid_ip() {
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}



host=$1;
ping -q -c 1 $host &>/dev/null
if [ $? -eq 0 ] ; then
    #ipAddr=$(ssh $host  "/sbin/ifconfig $ETHERNET_DEVICE | grep 'inet addr:' | cut -d: -f2 " | awk '{ print $1}');
    ethernet_device="eth0";
    ipAddr=$(ssh -o ForwardX11=no $host  "/usr/sbin/ip addr show dev $ethernet_device 2>/dev/null | sed -e's/^.*inet \([^ ]*\)\/.*$/\1/;t;d' 2>/dev/null" | head -n 1);
    if valid_ip $ipAddr; then
	echo "$ipAddr"
    else
	ethernet_device="ens3";
	ipAddr=$(ssh -o ForwardX11=no $host  "/usr/sbin/ip addr show dev $ethernet_device 2>/dev/null | sed -e's/^.*inet \([^ ]*\)\/.*$/\1/;t;d' 2>/dev/null" | head -n 1);
	if valid_ip $ipAddr; then
	    echo "$ipAddr"
	else
	    ethernet_device="ens10";
	    ipAddr=$(ssh -o ForwardX11=no $host  "/usr/sbin/ip addr show dev $ethernet_device 2>/dev/null | sed -e's/^.*inet \([^ ]*\)\/.*$/\1/;t;d' 2>/dev/null" | head -n 1);
	    if valid_ip $ipAddr; then
		echo "$ipAddr"
	    fi
	fi
    fi;
    exit;
else
    echo "";
    exit 1;
fi
exit
