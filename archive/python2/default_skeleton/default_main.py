#!/usr/bin/python
"""

Used the following python code style to verify:
  $ pycodestyle --ignore="E302,E305,E501" ~/path/to/file/default_main.py

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
import argparse
import copy

# #####################################################################
# Global vars:
# #####################################################################
VERSION_NUMBER = "0.1-1"
MAIN_LOGGER_NAME = "%s" % (os.path.basename(sys.argv[0]))

# #####################################################################
# Helper File Functions
# ####################################################################
def write_to_file(path_to_filename, data, append_to_file=True, create_file=False):
    [parent_dir, filename] = os.path.split(path_to_filename)
    if (os.path.isfile(path_to_filename) or (os.path.isdir(parent_dir) and create_file)):
        try:
            file_mode = "w"
            if (append_to_file):
                file_mode = "a"
            fout = open(path_to_filename, file_mode)
            fout.write(data + "\n")
            fout.close()
            return True
        except UnicodeEncodeError, e:
            message = "There was a unicode encode error writing to the file: %s." % (path_to_filename)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        except IOError:
            message = "There was an error writing to the file: %s." % (path_to_filename)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
    return False

def mkdirs(path_to_dir):
    if (os.path.isdir(path_to_dir)):
        return True
    elif ((not os.access(path_to_dir, os.F_OK)) and (len(path_to_dir) > 0)):
        try:
            os.makedirs(path_to_dir)
        except (OSError, os.error):
            message = "Could not create the directory: %s." % (path_to_dir)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        except (IOError, os.error):
            message = "Could not create the directory with the path: %s." % (path_to_dir)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
    return os.path.isdir(path_to_dir)

def get_data_from_file(path_to_filename):
    lines = get_data_from_file_as_list(path_to_filename)
    if (lines is not None):
        data = ""
        for line in lines:
            data = "%s%s" % (data, line)
        return data
    return None

def get_data_from_file_as_list(path_to_filename):
    if (len(path_to_filename) > 0):
        try:
            fin = open(path_to_filename, "r")
            data = fin.readlines()
            fin.close()
            return data
        except (IOError, os.error):
            message = "An error occured reading the file: %s." % (path_to_filename)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
    return None

# ##############################################################################
# Get user selected options
# ##############################################################################
class ActionAppend(argparse._AppendAction):
    # Append items to a single list. If error checking is needed like making
    # sure that items in list are integer, string, absolute path to a file and
    # if file exists then a new AppendAction should be created as this will add
    # anything to a list.
    def __call__(self, parser, namespace, values, option_string=None):
        items = copy.copy(argparse._ensure_value(namespace, self.dest, []))
        valid_items = []
        for value in values.split(","):
            # Do validation.
            if (value):
                valid_items.append(value)
        items += valid_items
        setattr(namespace, self.dest, items)

def __get_options(version):
    command_name = os.path.basename(__file__)
    version = "%s %s\n This program was written by Shane Bradley(sbradley@redhat.com)\n" % (command_name, version)
    description = "%s will download and list attachments for Red Hat Customer Portal.\n" % (command_name)
    epilog = "\n\nExamples:\n\n"

    cmd_parser = argparse.ArgumentParser(prog=command_name,
                                         description=description,
                                         epilog=epilog,
                                         formatter_class=argparse.RawDescriptionHelpFormatter)

    cmd_parser.add_argument("-d", "--debug",
                            action="store_true",
                            dest="enable_debug",
                            help="enables debug logging",
                            default=False)
    cmd_parser.add_argument("-q", "--quiet",
                            action="store_true",
                            dest="disable_logging",
                            help="disables logging to console",
                            default=False)
    cmd_parser.add_argument("-u", "--username",
                            type=str,
                            action="store",
                            dest="username",
                            help="the username for Red Hat login",
                            metavar="<username>",
                            default="")
    cmd_parser.add_argument("-p", "--password",
                            type=str,
                            action="store",
                            dest="password",
                            help="the password for Red Hat login",
                            metavar="<password>",
                            default="")
    cmd_parser.add_argument("-f", "--path_to_src_file",
                            type=str,
                            action="store",
                            dest="path_to_src_file",
                            help="Path to the src file",
                            metavar="<path to src file>",
                            default="%s" % (os.path.join(os.environ['HOME'], "myfile")))
    cmd_parser.add_argument("-n", "--number",
                            type=int,
                            action="store",
                            dest="number",
                            help="the number",
                            metavar="<a number>",
                            default=-1)
    cmd_parser.add_argument("-i", "--list_of_items",
                            action=ActionAppend,
                            dest="list_of_items",
                            help="some list of items",
                            metavar="<item>",
                            default=[])
    return cmd_parser.parse_args()

# ###############################################################################
# Main Function
# ###############################################################################
if __name__ == "__main__":
    try:
        # #######################################################################
        # Get the options from the commandline.
        # #######################################################################
        parseargs_ns = __get_options(VERSION_NUMBER)
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
        # sysLogHandler = logging.handlers.SysLogHandler(address = '/dev/log')
        # logger.addHandler(sysLogHandler)
        # logger.info("The script has started running.")
        # logger.removeHandler(sysLogHandler)

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
        if ((parseargs_ns.enable_debug) and (not parseargs_ns.disable_logging)):
            logging.getLogger(MAIN_LOGGER_NAME).setLevel(logging.DEBUG)
            stream_handler.setLevel(logging.DEBUG)
            message = "Debugging has been enabled."
            logging.getLogger(MAIN_LOGGER_NAME).debug(message)
        if (parseargs_ns.disable_logging):
            stream_handler.setLevel(logging.CRITICAL)

        # #######################################################################
        # Run main
        # #######################################################################
        message = "The script ran."
        logging.getLogger(MAIN_LOGGER_NAME).info(message)
        print "Username:         %s" % (parseargs_ns.username)
        print "Password:         %s" % (parseargs_ns.password)
        if (os.path.isfile(parseargs_ns.path_to_src_file)):
            print "Path to src file: %s" % (parseargs_ns.path_to_src_file)
        else:
            print "Path to src file: %s (File not found)" % (parseargs_ns.path_to_src_file)
        print "Number:           %d" % (parseargs_ns.number)
        print ""
        # Validate and remove duplicates for a list of integers for attachment indexes.
        # This could go here or in new ActionAppend class that just handles integers.
        # list_of_items = list(set(parseargs_ns.list_of_items))
        # list_of_items = [int(s) for s in list_of_items if s.isdigit()]
        # list_of_items = [int(i) for i in list_of_items if i > 0]
        print "List of items:"
        for integer in parseargs_ns.list_of_items:
            print "\t%s" % (str(integer))

    except KeyboardInterrupt:
        print ""
        message = "This script will exit since control-c was executed by end user."
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        sys.exit(1)
    # #######################################################################
    # Exit the application with zero exit code since we cleanly exited.
    # #######################################################################
    sys.exit()
