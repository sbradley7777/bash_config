#!/usr/bin/python
"""
This script will analyze logs for gfs2 messages and try to keep them sorted
by filesystem and time.

@author    : Shane Bradley
@contact   : sbradley@redhat.com
@version   : 0.2
@copyright : GPLv2

"""
import sys
import logging
import logging.handlers
import os
import os.path
import re
import time
from optparse import OptionParser, Option, SUPPRESS_HELP

# #####################################################################
# Global vars:
# #####################################################################
VERSION_NUMBER = "0.1-1"
MAIN_LOGGER_NAME = "%s" %(os.path.basename(sys.argv[0]))

RE_GFS2_FS ='.* (?P<hostname>.*) kernel: GFS2: fsid=(?P<cluster_name>[a-z0-9-_]*):(?P<filesystem_name>[a-z0-9-_]*).*'

class GFS2_Filesystem():
    def __init__(self, hostname, cluster_name, filesystem_name):
        self.__hostname = hostname
        self.__cluster_name = cluster_name
        self.__filesystem_name = filesystem_name
        # locking protocal can change so do not save that.
        self.__logs = []

    def __str__(self):
        return "%s (cluster name: %s hostname: %s)" %(self.__filesystem_name, self.__cluster_name,
                                                      self.__hostname)

    def __eq__(self, gfs2_filesystem):
        if (gfs2_filesystem == None):
            return False
        if ((self.__cluster_name == gfs2_filesystem.get_cluster_name()) and
            (self.__filesystem_name == gfs2_filesystem.get_filesystem_name())):
            return True
        return False

    def get_hostname(self):
        return self.__hostname

    def get_cluster_name(self):
        return self.__cluster_name

    def get_filesystem_name(self):
        return self.__filesystem_name

    def get_logs(self):
        return self.__logs

    def append(self, log_msg):
        self.__logs.append(log_msg)

# #####################################################################
# Helper File Functions
# ####################################################################
def get_data_from_file_as_list(path_to_filename) :
    if (len(path_to_filename) > 0) :
        try:
            if (os.path.isfile(path_to_filename)):
                fin = open(path_to_filename, "r")
                data = []
                for line in fin.readlines():
                    data.append(line.strip())
                fin.close()
                return data
            return None
        except (IOError, os.error):
            message = "An error occured reading the file: %s." %(path_to_filename)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
    return None

# #####################################################################
# Parsing functions
# ####################################################################
def find_gfs2_logs(file_contents):
    gfs2_filesystems = []
    rem_gfs2_fs = re.compile(RE_GFS2_FS, re.IGNORECASE|re.DOTALL)
    for line in file_contents:
        gfs2_filesystem = None
        mo = rem_gfs2_fs.match(line.lower())
        if mo:
            if (mo.group("hostname") and mo.group("cluster_name") and
                mo.group("filesystem_name")):
                gfs2_filesystem = GFS2_Filesystem(mo.group("hostname"),
                                                  mo.group("cluster_name"),
                                                  mo.group("filesystem_name"))
        if (not gfs2_filesystem == None):
            if (not gfs2_filesystem in gfs2_filesystems):
                gfs2_filesystems.append(gfs2_filesystem)
            for gfs2_fs in gfs2_filesystems:
                if (gfs2_filesystem == gfs2_fs):
                    if (not line.find("#012") >= 0):
                        gfs2_fs.append(line)
                    else:
                        clines = line.split("#012")
                        complete_line = clines.pop(0)
                        gfs2_fs.append(complete_line)
                        # Add missing text to the other line using complte line.
                        head = complete_line.split("GFS2: ")[0]
                        for cline in clines:
                            gfs2_fs.append("%s%s" %(head, cline))
    return gfs2_filesystems

# ##############################################################################
# Get user selected options
# ##############################################################################
def __get_options(version) :
    cmd_parser = OptionParserExtended(version)
    cmd_parser.add_option("-p", "--path_to_filename",
                         action="store",
                         dest="path_to_src_file",
                         help="the path to the filename that will be parsed or directory that will be searched for log files",
                         type="string",
                         metavar="<input filename>",
                         default="")
    cmd_parser.add_option("-a", "--search_all",
                          action="store_true",
                          dest="search_all",
                          help="searches all logs that are found instead of most recent log file",
                          default=False)

    # Get the options and return the result.
    (cmdLine_opts, cmdLine_args) = cmd_parser.parse_args()
    return (cmdLine_opts, cmdLine_args)

# ##############################################################################
# OptParse classes for commandline options
# ##############################################################################
class OptionParserExtended(OptionParser):
    def __init__(self, version) :
        self.__command_name = os.path.basename(sys.argv[0])
        OptionParser.__init__(self, option_class=ExtendOption,
                              version="%s %s\n" %(self.__command_name, version),
                              description="%s \n"%(self.__command_name))

    def print_help(self):
        self.print_version()
        examples_message = "\n"
        OptionParser.print_help(self)
        #print examples_message

class ExtendOption (Option):
    ACTIONS = Option.ACTIONS + ("extend",)
    STORE_ACTIONS = Option.STORE_ACTIONS + ("extend",)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ("extend",)

    def take_action(self, action, dest, opt, value, values, parser):
        if (action == "extend") :
            valueList = []
            try:
                for v in value.split(","):
                    # Need to add code for dealing with paths if there is option for paths.
                    newValue = value.strip().rstrip()
                    if (len(newValue) > 0):
                        valueList.append(newValue)
            except:
                pass
            else:
                values.ensure_value(dest, []).extend(valueList)
        else:
            Option.take_action(self, action, dest, opt, value, values, parser)

# ###############################################################################
# Main Function
# ###############################################################################
if __name__ == "__main__":
    try:
        # #######################################################################
        # Get the options from the commandline.
        # #######################################################################
        (cmdline_opts, cmdline_args) = __get_options(VERSION_NUMBER)
        # #######################################################################
        # Setup the logger and create config directory
        # #######################################################################
        # Create the logger
        logLevel = logging.INFO
        logger = logging.getLogger(MAIN_LOGGER_NAME)
        logger.setLevel(logLevel)
        stream_handler = logging.StreamHandler()
        stream_handler.setLevel(logLevel)
        stream_handler.setFormatter(logging.Formatter("%(levelname)s %(message)s"))
        logger.addHandler(stream_handler)

        # #######################################################################
        # Run main
        # #######################################################################
        path_to_filenames = []
        if (os.path.isdir(cmdline_opts.path_to_src_file)):
            for (path, dirs, files) in os.walk(cmdline_opts.path_to_src_file):
                for fname in files:
                    path_to_filename = os.path.join(path, fname)
                    if (path_to_filename.find("var/log/messages") >= 0):
                        if (cmdline_opts.search_all):
                            path_to_filenames.append(path_to_filename)
                        elif (path_to_filename.endswith("messages")):
                            path_to_filenames.append(path_to_filename)
        elif (os.path.isfile(cmdline_opts.path_to_src_file)):
            path_to_filenames.append(cmdline_opts.path_to_src_file)

        # Parse the logs
        gfs2_filesystems = []
        # Hopefully this will sort everything out as timestamp can be relied on.
        path_to_filenames.sort(reverse=True)
        for path_to_filename in path_to_filenames:
            file_contents = get_data_from_file_as_list(path_to_filename)
            if (not file_contents == None):
                gfs2_fs = find_gfs2_logs(file_contents)
                gfs2_filesystems += gfs2_fs

        fatal_msgs = []
        for gfs2_fs in gfs2_filesystems:
            print gfs2_fs
            for line in gfs2_fs.get_logs():
                print "  %s" %(line)
                if (line.find("fatal") >= 0):
                    fatal_msgs.append(line)
            print

        if (fatal_msgs):
            print "Found %d fatal messages causing a withdrawal." %(len(fatal_msgs))
            fatal_msgs.sort()
            for msg in fatal_msgs:
                print "  %s" %(msg)

    except KeyboardInterrupt:
        print ""
        message =  "This script will exit since control-c was executed by end user."
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        sys.exit(1)
    # #######################################################################
    # Exit the application with zero exit code since we cleanly exited.
    # #######################################################################
    sys.exit()
