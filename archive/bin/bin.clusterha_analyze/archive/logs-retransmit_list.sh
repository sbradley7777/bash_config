#!/bin/sh
# Description: Counts the number of logs for each node that has the string "Retransmit List" in it.
# Author: Shane Bradley(sbradley@redhat.com)
msg_count_total=0;
for i in *; do
    # skip the "reports" directories if found.
    if [[ ! $i =~ ^reports ]]; then
	msg_count=$(grep "Retransmit List" $i/var/log/messages | wc -l);
	printf "Retransmit List count for node %s: %'d\n" $i $msg_count;
	(( msg_count_total+=msg_count ));
    fi
done
printf "The total for all nodes that had log event: %'d\n\n" $msg_count_total;
echo "For information about this log event then see the following article:";
echo "  \"[TOTEM] Retransmit List\" messages repeatedly seen in RHEL 5, 6, or 7 High Availability cluster node logs";
echo "  - https://access.redhat.com/knowledge/solutions/38510";

