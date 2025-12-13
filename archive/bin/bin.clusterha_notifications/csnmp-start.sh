#!/bin/sh
service messagebus restart
service snmpd start
service foghorn start
service corosync-notifyd start
