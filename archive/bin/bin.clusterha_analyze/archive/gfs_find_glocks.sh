#~/bin/sh
# Useful to show glock with holder/waiters for gfs2_lockcapture.
# Run when inside run directory, so pass path of runX to script.
path=$1;
host1=$(/bin/ls $path | awk '{print $1}' | head -n 1);

for glock_table in $(ls $path/$host1/gfs2); do
    echo "---------------------------------------------------";
    echo "        $glock_table        ";
    echo "---------------------------------------------------";
    for host in $(ls $path); do
	echo "$host - $glock_table";
	egrep -ri 'f:h|f:w|f:aw|f:cw|f:ew|f:tw' "$path/$host/gfs2/$glock_table/glocks" -B 1 -A 1;
	echo "";
    done;
    echo "";
done;
exit;


