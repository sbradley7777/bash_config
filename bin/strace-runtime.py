#!/usr/bin/python
"""
This script prints the total time of the command that was ran by analyzing the strace output.

# NOTE: Assumes the strace files starts and ends on the same date as there is no
# date provided in the output of when strace starts and ends.

@author    : Shane Bradley
@contact   : sbradley@redhat.com
@version   : 0.1
@copyright : GPLv2

"""
import sys
import logging
import logging.handlers
import os
import os.path
from optparse import OptionParser, Option, SUPPRESS_HELP

# #####################################################################
# Global vars:
# #####################################################################
VERSION_NUMBER = "0.1-1"
MAIN_LOGGER_NAME = "%s" %(os.path.basename(sys.argv[0]))


def get_strace_runtime(path_to_filename):
    lines = get_data_from_file_as_list(path_to_filename)
    line  = lines[0]
    start_time = line.split()[1]
    line  = lines[-1]
    end_time = line.split()[1]

    from datetime import datetime
    fmt = '%Y-%m-%d %H:%M:%S.%f'
    elapsed_ms = -1
    try:
        date_start = datetime.strptime('2010-01-01 %s' %(start_time), fmt)
        date_end = datetime.strptime('2010-01-01 %s' %(end_time), fmt)
        diff = date_end - date_start
        elapsed_ms = (diff.days * 86400000) + (diff.seconds * 1000) + (diff.microseconds / 1000)
    except ValueError:
        pass
    return elapsed_ms

def get_start_time(path_to_filename):
    lines = get_data_from_file_as_list(path_to_filename)
    line  = lines[0]
    start_time = line.split()[1]
    return start_time

# #####################################################################
# Helper File Functions
# ####################################################################
def get_data_from_file(path_to_filename) :
    lines = get_data_from_file_as_list(path_to_filename)
    if (not lines == None):
        data = ""
        for line in lines:
            data = "%s%s" %(data, line)
        return data
    return None

def get_data_from_file_as_list(path_to_filename) :
    if (len(path_to_filename) > 0) :
        try:
            fin = open(path_to_filename, "r")
            data = fin.readlines()
            fin.close()
            return data
        except (IOError, os.error):
            message = "An error occured reading the file: %s." %(path_to_filename)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
    return None

# ##############################################################################
# Get user selected options
# ##############################################################################
def __get_options(version) :
    cmd_parser = OptionParserExtended(version)
    cmd_parser.add_option("-d", "--debug",
                         action="store_true",
                         dest="enableDebugLogging",
                         help="enables debug logging",
                         default=False)
    cmd_parser.add_option("-q", "--quiet",
                         action="store_true",
                         dest="disableLoggingToConsole",
                         help="disables logging to console",
                         default=False)
    cmd_parser.add_option("-y", "--no_ask",
                        action="store_true",
                         dest="disableQuestions",
                         help="disables all questions and assumes yes",
                         default=False)
    cmd_parser.add_option("-p", "--path_to_filename",
                         action="store",
                         dest="path_to_src_file",
                         help="the path to the filename that will be parsed",
                         type="string",
                         metavar="<input filename>",
                         default="")
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
        OptionParser.print_help(self)
        #examples_message = "\n"
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
        # Create a new status function and level.
        logging.STATUS = logging.INFO + 2
        logging.addLevelName(logging.STATUS, "STATUS")

        # Log to main system logger that script has started then close the
        # handler before the other handlers are created.
        sysLogHandler = logging.handlers.SysLogHandler(address = '/dev/log')
        logger.addHandler(sysLogHandler)
        logger.info("The script has started running.")
        logger.removeHandler(sysLogHandler)

        # Create a function for the STATUS_LEVEL since not defined by python. This
        # means you can call it like the other predefined message
        # functions. Example: logging.getLogger("loggerName").status(message)
        setattr(logger, "status", lambda *args: logger.log(logging.STATUS, *args))
        stream_handler = logging.StreamHandler()
        stream_handler.setLevel(logLevel)
        stream_handler.setFormatter(logging.Formatter("%(levelname)s %(message)s"))
        logger.addHandler(stream_handler)

        # #######################################################################
        # Set the logging levels.
        # #######################################################################
        if ((cmdline_opts.enableDebugLogging) and (not cmdline_opts.disableLoggingToConsole)):
            logging.getLogger(MAIN_LOGGER_NAME).setLevel(logging.DEBUG)
            stream_handler.setLevel(logging.DEBUG)
            message = "Debugging has been enabled."
            logging.getLogger(MAIN_LOGGER_NAME).debug(message)
        if (cmdline_opts.disableLoggingToConsole):
            stream_handler.setLevel(logging.CRITICAL)

        # #######################################################################
        # Run main
        # #######################################################################
        path_to_strace_files = []
        if (os.path.isdir(cmdline_opts.path_to_src_file)):
            for filename in os.listdir(cmdline_opts.path_to_src_file):
                path_to_strace_files.append(os.path.join(cmdline_opts.path_to_src_file, filename))
        elif (os.path.isfile(cmdline_opts.path_to_src_file)):
            path_to_strace_files.append(cmdline_opts.path_to_src_file)
        for strace_file in path_to_strace_files:
            runtime = get_strace_runtime(strace_file)
            print "%s --> Start Time: %s | Total Runtime: %s (%d seconds)" %(os.path.basename(strace_file),
                                                                      get_start_time(strace_file),
                                                                      '{:06d}'.format(runtime),
                                                                      (int(runtime) / 1000))
    except KeyboardInterrupt:
        print ""
        message =  "This script will exit since control-c was executed by end user."
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        sys.exit(1)
    # #######################################################################
    # Exit the application with zero exit code since we cleanly exited.
    # #######################################################################
    sys.exit()
