#!/bin/bash
# Detect which version of SSL that can be connected to. Defaults for IP is
# 127.0.0.1 and port is 8084 if no options are specified on command line.
#
# usage:
# ./check_ssl.sh <ip> <port>
# Example:
# ./check_ssl.sh 192.168.122.161 8084

host=${1:-127.0.0.1};
port=${2:-8084};
timeout_bin=`which timeout 2>/dev/null`;

for protocal in "ssl2" "ssl3" "tls1_1" "tls1_2"; do
    out="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -$protocal -connect "${host}:${port}" 2>/dev/null`"
    if [ $? -eq 124 ]; then
	echo "ERROR: Timeout connecting to \"$host:$port\" to check protocal: $protocal.";
    else
	connected=`echo "$out" | grep '^CONNECTED'`;
	if [ $? -eq 0 ]; then
	    proto=`echo "$out" | grep '^ *Protocol *:' | awk '{ print $3 }'`;
	    cipher=`echo "$out" | grep '^ *Cipher *:' | awk '{ print $3 }'`;
	    echo "$host:$port | Protocal: $proto Cipher: $cipher";
	    if [ "$cipher" = '0000'  -o  "$cipher" = '(NONE)' ]; then
		echo "  Connected with \""${protocal^^}"\" but no ciphers were found.";
	    else
		echo "  Connected with \""${protocal^^}"\" and using cipher: $cipher.";
	    fi
	else
	    echo "$host:$port | Protocal: ${protocal^^}";
	    echo "  Failed to establish a \""${protocal^^}"\" connection.";
	fi
	echo "";
    fi
done
exit;
