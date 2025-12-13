#!/usr/bin/python -tt
# This script simple logs into a ssh device. It is based on
# /usr/share/fence/fencing.py and /usr/sbin/fence_ilo4_ssh.
#
# Contains some code that is specific to ilo devices.
#
# - The option values has to be set in variables that are listed in main().
# - Currently requries ssh keys in order to login as function that can login
#   with passwords was not ported over.

import sys, getopt, time, os, uuid, pycurl, stat
import pexpect, re, syslog
import logging
import os.path

######################################################################
# Helper functions and global vars
######################################################################
EC_OK = 0
EC_GENERIC_ERROR = 1
EC_BAD_ARGS = 2
EC_LOGIN_DENIED = 3
EC_CONNECTION_LOST = 4
EC_TIMED_OUT = 5
EC_WAITING_ON = 6
EC_WAITING_OFF = 7
EC_STATUS = 8
EC_STATUS_HMC = 9
EC_PASSWORD_MISSING = 10
EC_INVALID_PRIVILEGES = 11

LOG_FORMAT = "%(asctime)-15s %(levelname)s: %(message)s"

def fail(error_code):
    message = {
        EC_LOGIN_DENIED : "Unable to connect/login to fencing device",
        EC_CONNECTION_LOST : "Connection lost",
        EC_TIMED_OUT : "Connection timed out",
        EC_WAITING_ON : "Failed: Timed out waiting to power ON",
        EC_WAITING_OFF : "Failed: Timed out waiting to power OFF",
        EC_STATUS : "Failed: Unable to obtain correct plug status or plug is not available",
        EC_STATUS_HMC : "Failed: Either unable to obtain correct plug status, partition is not available or incorrect HMC version used",
        EC_PASSWORD_MISSING : "Failed: You have to set login password",
        EC_INVALID_PRIVILEGES : "Failed: The user does not have the correct privileges to do the requested action."
    }[error_code] + "\n"
    logging.error("%s\n", message)
    sys.exit(EC_GENERIC_ERROR)

######################################################################
# Classes
######################################################################
class fspawn(pexpect.spawn):
    def __init__(self, options, command, **kwargs):
        if sys.version_info[0] > 2:
            kwargs.setdefault('encoding', 'utf-8')
        logging.info("Running command: %s", command)
        pexpect.spawn.__init__(self, command, **kwargs)
        self.opt = options

    def log_expect(self, pattern, timeout):
        if (pattern):
            print("\nThe list of patterns that pexcept will try to match.")
            for p in pattern:
                print("\t %s" %(p))
        result = self.expect(pattern, timeout)
        if (pattern):
            # The result will be the index into the list of patterns for the first match encountered."
            print("pexcept result of match: %s" %(str(result)))
            print

        if (self.before):
            # Print the output received BEFORE a match was found.
            print "pexcept.before:"
            for line in self.before.splitlines():
                print "\t %s" % (line)
            print

        if (self.after):
            # Print the output received AFTER a match is found. The first line
            # printed should include the line that had the match.
            print "pexcept.after:"
            for line in self.after.splitlines():
                print "\t %s" % (line)
            print
        # logging.debug("Received: %s", self.before + self.after)
        return result

    def send(self, message):
        logging.debug("Sent: %s", message)
        return pexpect.spawn.send(self, message)

    # send EOL according to what was detected in login process (telnet)
    def send_eol(self, message):
        return self.send(message + self.opt["eol"])

######################################################################
# login with ssh
######################################################################
def _login_ssh_with_identity_file(options):
    if "--inet6-only" in options:
        force_ipvx = "-6 "
    elif "--inet4-only" in options:
        force_ipvx = "-4 "
    else:
        force_ipvx = ""

    command = '%s %s %s@%s -i %s -p %s' % \
              (options["--ssh-path"], force_ipvx, options["--username"], options["--ip"], \
               options["--identity-file"], options["--ipport"])
    if "--ssh-options" in options:
        command += ' ' + options["--ssh-options"]

    conn = fspawn(options, command)

    result = conn.log_expect(["Enter passphrase for key '" + options["--identity-file"] + "':", \
                              "Are you sure you want to continue connecting (yes/no)?"] + \
                             options["--command-prompt"], int(options["--login-timeout"]))
    if result == 1:
        conn.sendline("yes")
        result = conn.log_expect(
            ["Enter passphrase for key '" + options["--identity-file"]+"':"] + \
            options["--command-prompt"], int(options["--login-timeout"]))
    if result == 0:
        if "--password" in options:
            conn.sendline(options["--password"])
            conn.log_expect(options["--command-prompt"], int(options["--login-timeout"]))
        else:
            # Change this so do not have to include that function.
            # fail_usage("Failed: You have to enter passphrase (-p) for identity file")
            fail(EC_PASSWORD_MISSING)
    return conn

def fence_login(options, re_login_string=r"(login\s*: )|((?!Last )Login Name:  )|(username: )|(User Name :)"):
    #run_delay(options)

    if "eol" not in options:
        options["eol"] = "\r\n"

    if "--command-prompt" in options and type(options["--command-prompt"]) is not list:
        options["--command-prompt"] = [options["--command-prompt"]]

    try:
        if "--ssh" in options and "--identity-file" not in options:
            print("Logging into ssh with password.")
            conn = _login_ssh_with_password(options, re_login_string)
        elif "--ssh" in options and "--identity-file" in options:
            print("Logging into ssh with identity file.")
            conn = _login_ssh_with_identity_file(options)
        else:
            print "ERROR: could not figure out how to login."
    except pexpect.EOF as exception:
        logging.debug("%s", str(exception))
        fail(EC_LOGIN_DENIED)
    except pexpect.TIMEOUT as exception:
        logging.debug("%s", str(exception))
        fail(EC_LOGIN_DENIED)

    print("Successfully logged into: %s." %(options.get("--ip")))
    return conn

def fence_logout(conn, logout_string, sleep=0):
    # Logout is not required part of fencing but we should attempt to do it properly
    # In some cases our 'exit' command is faster and we can not close connection as it
    # was already closed by fencing device
    try:
        conn.send_eol(logout_string)
        time.sleep(sleep)
        conn.close()
    except OSError:
        pass
    except pexpect.ExceptionPexpect:
        pass

######################################################################
# Run
######################################################################
def main():
    print("Running: %s" % (os.path.basename(__file__)))
    # Tried to keep the main() close to what fence_ilo4_ssh has in it as it sets
    # some default values for some of the options.
    debug_file = "/tmp/fence_ilo4_ssh.debug"
    power_wait = 5

    # Options used by the functions and classes above.
    ip = ""
    username = ""
    password = ""
    ssh_options = "-c aes256-cbc"
    identity_file = "%s/.ssh/id_rsa" % (os.path.expanduser("~"))
    # Enabled when testing on a RHEL host.
    run_commmand_after_login = True

    # No need to run command after login on fence device.
    # run_commmand_after_login = False

    # For testing on ilo, then uncomment.
    cmd_prompt = ["MP>", "hpiLO->"]

    # For testing on my linux host. Change the username and ip if needed. 
    cmd_prompt = ["MP>", "%s@%s" % (username, ip), "hpiLO->"]


    options = {'--power-timeout': '20', '--retry-on': '1', '--method': 'ONOFF',
               '--telnet-path': '/usr/bin/telnet', 'eol': '\r', '--delay': '0', '--separator': ',',
               '--power-wait': power_wait, '--shell-timeout': '3', '--ssh': '',
               '--ip': ip, '--ipport': '22', '--command-prompt': cmd_prompt,
               '--ssh-path': '/usr/bin/ssh', '--username': username, '--password': password,
               '--ssh-options': ssh_options,'--identity-file': identity_file,
               '--debug-file': debug_file,
               '--login-timeout': '30', '--action': 'status'}
    # To enable verbose output, then uncomment this line.
    options['--verbose'] =  "1"
    # print (options)

    # #######################################################################
    # Setup the logger and create config directory
    # #######################################################################
    if "--verbose" in options:
        logging.getLogger().setLevel(logging.DEBUG)
    formatter = logging.Formatter(LOG_FORMAT)
    if "--quiet" not in options:
        stderrHandler = logging.StreamHandler(sys.stderr)
        stderrHandler.setFormatter(formatter)
        logging.getLogger().addHandler(stderrHandler)


    options["eol"] = "\r"
    # Login into the host.
    conn = fence_login(options)
    # Then run that command after logging in. I ran that command and errors out
    # as unrecongized command. Not sure the purpose, but we are erroring out
    # before this and including for completeness.
    conn.send_eol("SMCLP")

    # Run a command that logs a message.
    if (run_commmand_after_login):
        command = 'logger "%s has logged in."' % (os.path.basename(__file__))
        conn.send_eol(command)
        # Only need to do log_expect if we are wanting to parse some of the output.
        # conn.log_expect(options["--command-prompt"], int(options["--login-timeout"]))

    # Logout of the host.
    fence_logout(conn, "exit")
    sys.exit()

if __name__ == "__main__":
    main()
