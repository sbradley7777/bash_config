#Introduction
This java file will test file locking between two hosts.

#Usage
~~~
# java -cp <path to parent dir of java file> FileLocker <path to file>
~~~

#Compile
~~~
# javac /tmp/FileLocker.java
~~~

#How to Run
Start this java file on 1 host and remove an existing file if there is one. The hit enter to lock the file when the user is prompted on the console.
~~~
# rm -f /mnt/gfs2vol1/testfile; java -cp /tmp/ FileLocker /mnt/gfs2vol1/testfile;
~~~

Start the java file on another host. Then hit enter on the console to *acquire*
the lock on the file when the user is prompted on the console. This host should
not be allowed to *acquire* the lock as long as the other host holds it.
~~~
# java -cp /tmp/ FileLocker
~~~

The lock can be released on the first host by hitting enter. Once the lock is
released, then the second host should obtain the lock. To exit the script hit
`control-c` when the host does not have the lock on the file.
