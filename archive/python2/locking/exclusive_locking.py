#!/usr/bin/python 
'''
bz: https://bugzilla.redhat.com/show_bug.cgi?id=1151180

Example rough implementation of exclusive lock in python uisng
:py:class:`common.LockFile`. This is written to test nfs exclusive locking and
locks persistence accross nfs server restarts.

It will work from different processes (terminals) on one host or from different
nodes locking the same file on the same nfs mount.

Usage:
    nfs-client1> python lock.py /nfs/testfile
    Trying to acquire lock of file /nfs/testfile...
    Lock acquired
    Press Enter to unlock.
    ...
            nfs-client2> python lock.py /nfs/testfile
            nfs-client2> Trying to acquire lock of file /nfs/testfile...
            <waiting>
            ...
    <Enter pressed>
    Trying to release lock of file /nfs/testfile...
    Lock released for file /nfs/testfile.
    nfs-client1>
            ...
            Lock acquired.
            Press Enter to unlock.
            <Enter pressed>
            Trying to release lock of file /nfs/testfile...
            Lock released for file /nfs/testfile.
            nfs-client2>

'''

import sys
import time
import os

sys.path.append('../') # where common.py lives when run as ./lock.py
sys.path.append('.') # where common.py lives when run as ./tests/lock.py

from common import LockFile
from optparse import OptionParser

#this is overwritten at build of rpm with commit and time if available
version = 'not versioned'

parser = OptionParser(version=version)
parser.add_option("-f", "--file", dest="filename", metavar='FILENAME',
    default='/tmp/testfile', nargs=1,
    help="File that will be locked. Default: /tmp/testfile"
)
parser.add_option("-m", "--mode", dest='mode', default='lockf',
    help="Mode of the lock one of: lockf, flock. Default: lockf"
)
parser.add_option("-w", "--wait", dest='wait', default=False,
    action='store_true',
    help="Keep waiting until the lock can be obtained."+\
            "Default is to raise exception if the lock cannot be "+\
            "obtained immediately."
)
parser.add_option("-t", "--timeout", dest='timeout', default=None,
    metavar='TIMEOUT', type='int',
    help='Do not expect user input. Unlock automagically after TIMEOUT seconds'
)
(options, args) = parser.parse_args()

if not options.mode in ['lockf','flock']:
    print "--mode must be one of: lockf, flock not %s" % options.mode
    sys.exit(1)

if os.path.isfile(options.filename):
    fd = open(options.filename,'r+')
else:
    print "File %s must exist." % options.filename
    sys.exit(1)

lock = LockFile(fd, mode=options.mode)

print "Trying to acquire lock of file %s with %s (wait=%s)..."\
    % (options.filename, options.mode, options.wait)
if lock.acquire(wait=options.wait):
    print "Lock acquired."

if options.timeout is not None:
    sys.stdout.write("Holding lock for %s seconds... " % options.timeout)
    seconds = options.timeout
    while seconds > 0:
        time.sleep(1)
        seconds -= 1
        sys.stdout.write('%s ' % seconds)
        sys.stdout.flush()
    print
else:
    raw_input("Press Enter to unlock.")

print "Trying to release lock of file %s..." % options.filename
if lock.release():
    print "Lock released for file %s" % options.filename

fd.close()
print fd
