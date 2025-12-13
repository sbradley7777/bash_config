#!/usr/bin/awk -f
# Find all waiters in dlm lockdump.
# For example:
#   $ for f in *; do echo $f; show_dlm_waiters.awk < $f/clvmd; echo "----"; done
#   $ show_dlm_waiters.awk < /sys/kernel/debug/dlm/clvmd
/^Resource/ {
    if (waiters) print resinfo;
    resinfo=$0; waiters=0; waiting=0;
             next
}
/.*/        {
    resinfo = resinfo  "\n"  $0;

    if (waiting &&
	($0 != "" && $1 != "Waiting"))
	waiters = 1;
    else
                waiting = 0
}
/^Waiting/  { waiting = 1 }
/^Conversion/  { waiting = 1 }
END         {
    if (waiters) print resinfo;
}
