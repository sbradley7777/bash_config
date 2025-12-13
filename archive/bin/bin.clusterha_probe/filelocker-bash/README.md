#Introduction
The two files are used for testing the [`flock`](http://linux.die.net/man/2/flock) system call to demostrate locking.

#Usage
~~~
# ./flockholder.sh <path to a file>
# ./flockwriter.sh <path to a file>
~~~

#How to Run
Run the script that will hold the lock on 1 host and remove existing file if one
exists. The console will hold the `flock` on the file until `contol-c` is
inputted by a user. Once `control-c` has been detected the lock on the file will be
released and another process can then lock the file.
~~~
# rm -f /mnt/gfs2vol1/testfile; ./flockholder.sh /mnt/gfs2vol1/testfile;
~~~

Run the script on another host after the `flockholder.sh` is running on another
host. The script `flockwriter.sh` will wait till the other node releases the
`flock` before it can get an `flock` to write to the file.
~~~
# ./flockwriter.sh /mnt/gfs2vol1/testfile;
~~~

After both scripts are running, input `control-c` on the host that is running
`flockholder.sh` which should cause that host to exit the script and allow the
other host to get the `flock` to write to the file.
