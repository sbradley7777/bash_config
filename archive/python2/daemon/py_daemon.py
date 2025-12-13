#!/usr/bin/env python
# Found code at: https://www.codyhiar.com/blog/python-2-7-daemon-example/

# Add some logging and use start dir for pid and outputs.
# Maybe use this example:
# - https://github.com/thornycrackers/python-daemon/blob/master/daemon_example.py

import time
import grp
import pwd
import time
from daemon import runner


class Daemon(object):

    def __init__(self):
        """Initialize Daemon."""
        self.stdin_path = '/dev/null'
        self.stdout_path = '/dev/null'
        self.stderr_path = '/dev/null'
        self.pidfile_path = '/tmp/pydaemon.pid'
        self.pidfile_timeout = 1

    def run(self):
        while True:
            time.sleep(1)

if __name__ == '__main__':
    pydaemon = Daemon()
    daemon_runner = runner.DaemonRunner(pydaemon)
    daemon_gid = grp.getgrnam('sbradley').gr_gid
    daemon_uid = pwd.getpwnam('sbradley').pw_uid
    daemon_runner.daemon_context.gid = daemon_gid
    daemon_runner.daemon_context.uid = daemon_uid
    daemon_runner.do_action()
