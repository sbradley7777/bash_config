#!/usr/bin/python
"""

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
import copy
import argparse

# #####################################################################
# Global vars:
# #####################################################################
VERSION = "0.1-1"
MAIN_LOGGER_NAME = "%s" %(os.path.basename(sys.argv[0]).split(".")[1])


# ##############################################################################
# parseargs helpers
# ##############################################################################
class AbsolutePathAction(argparse._AppendAction):
    def __call__(self, parser, namespace, values, option_string=None):
        path_to_filename = os.path.abspath(os.path.expanduser(values))
        setattr(namespace, self.dest, path_to_filename)

class AbsolutePathActionAppend(argparse._AppendAction):
    # Append path to files that exists to single list.
    def __call__(self, parser, namespace, values, option_string=None):
        print type(values)
        items = copy.copy(argparse._ensure_value(namespace, self.dest, []))
        items = [os.path.abspath(os.path.expanduser(item)) for item in items]
        valid_filenames = []
        # Split commas and do not paths that are not valid.
        for value in values.split(","):
            # Do validation.
            path_to_filename = os.path.abspath(os.path.expanduser(value))
            if (os.path.exists(path_to_filename) and os.path.isfile(path_to_filename)):
                valid_filenames.append(path_to_filename)
        items += valid_filenames
        setattr(namespace, self.dest, items)

class ActionAppend(argparse._AppendAction):
    # Append items to a single list.
    def __call__(self, parser, namespace, values, option_string=None):
        items = copy.copy(argparse._ensure_value(namespace, self.dest, []))
        valid_items = []
        for value in values.split(","):
            # Do validation.
            valid_items.append(value)
        items += valid_items
        setattr(namespace, self.dest, items)

# ##############################################################################
# Get user selected options
# ##############################################################################
def __get_args() :
    description = "My description"
    command_name = "glocktop_analyze.py"
    epilog =  "Usage examples:\n"
    epilog += " show example and description of example."

    # Passing RawDescriptionHelpFormatter as formatter_class= indicates that
    # description and epilog are already correctly formatted and should not be
    # line-wrapped:.
    parser = argparse.ArgumentParser(description=description,
                                     epilog=epilog,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    # Do not need to declare `type` for strings. All input is assumed to be
    # string unless attribute `type` set.
    parser.add_argument("-d", "--debug",
                        action="store_true",
                        dest="enable_debug",
                        help="enables debug logging",
                        default=False)
    parser.add_argument("-q", "--quiet",
                         action="store_true",
                         dest="disable_log_console",
                         help="disables logging to console",
                         default=False)
    parser.add_argument("-y", "--no_ask",
                        action="store_true",
                        dest="no_ask",
                        help="disables all questions and assumes yes",
                        default=False)
    parser.add_argument("-p", "--path_to_filename",
                        action=AbsolutePathActionAppend,
                        dest="path_to_src_file",
                        help="the path to the filename that will be parsed",
                        metavar="<input filename>",
                        default="")
    parser.add_argument("-o", "--path_to_output_filename",
                        action=AbsolutePathAction,
                        dest="path_to_dst",
                        help="the path to the output filename",
                        metavar="<output filename>",
                        default="")
    parser.add_argument("-e", "--enable_plugins",
                        action=ActionAppend,
                        dest="enable_plugins",
                        help="the plugins that are enabled",
                        metavar="<plugin name>",
                        default=[])
    parser.add_argument("-N", "--name",
                        action="store",
                        dest="name",
                        help="username",
                        metavar="<username>",
                        default="")
    return parser.parse_args()

# ###############################################################################
# Main Function
# ###############################################################################
if __name__ == "__main__":
    try:
        # #######################################################################
        # Get the options from the commandline.
        # #######################################################################
        parseargs_ns = __get_args()

        # #######################################################################
        # Set the logging levels.
        # #######################################################################
        # Create the logger
        logger = logging.getLogger(MAIN_LOGGER_NAME)
        logger.setLevel(logging.INFO)

        # Create a function for the STATUS_LEVEL since not defined by python. This
        # means you can call it like the other predefined message
        # functions. Example: logging.getLogger("loggerName").status(message)
        logging.STATUS = logging.INFO + 2
        logging.addLevelName(logging.STATUS, "STATUS")
        setattr(logger, "status", lambda *args: logger.log(logging.STATUS, *args))
        # Create handler for console logs.
        stream_handler = logging.StreamHandler()
        stream_handler.setLevel(logging.INFO)
        stream_handler.setFormatter(logging.Formatter("%(levelname)s %(message)s"))
        logger.addHandler(stream_handler)

        # If enabled then enable debug logging.
        if (parseargs_ns.enable_debug):
            logging.getLogger(MAIN_LOGGER_NAME).setLevel(logging.DEBUG)
            stream_handler.setLevel(logging.DEBUG)
            logging.getLogger(MAIN_LOGGER_NAME).debug("Debugging has been enabled.")

        # #######################################################################
        # Run main
        # #######################################################################
        logging.getLogger(MAIN_LOGGER_NAME).info("The script is about to start.")
        logging.getLogger(MAIN_LOGGER_NAME).status("The script is running.")
        print parseargs_ns
        enable_plugins = []
        for item in parseargs_ns.enable_plugins:
            enable_plugins += item.split(",")
        print enable_plugins

    except KeyboardInterrupt:
        print ""
        message =  "This script will exit since control-c was executed by end user."
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        sys.exit(1)
    # #######################################################################
    # Exit the application with zero exit code since we cleanly exited.
    # #######################################################################
    sys.exit()
