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
import textwrap

# #####################################################################
# Global vars:
# #####################################################################
VERSION = "0.1-1"
MAIN_LOGGER_NAME = "%s" %(os.path.basename(sys.argv[0]).split(".")[1])



# #####################################################################
# Helper File Functions
# ####################################################################

def write_to_file(path_to_filename, data, append_to_file=True, create_file=False):
    if (os.path.isfile(path_to_filename)):
        os.remove(path_to_filename)
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
            message = "There was a unicode encode error writing to the file: %s." %(path_to_filename)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        except IOError:
            message = "There was an error writing to the file: %s." %(path_to_filename)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
    return False

def get_data_from_file(path_to_filename) :
    lines = get_data_from_file(path_to_filename)
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

def truncate_rows(rows, max_item_length=120):
    # This function will take a list of lists and remove any whitespaces at
    # start or end of items in each list. It will also truncate any item that is
    # longer than max_item_length and will insert into new rows the text longer
    # than max_item_length.

    # Strip out any white spaces when copying the list into a new list.
    rows_copy = []
    for row in rows:
        new_row = []
        for i in row:
            try:
                new_row.append(i.strip())
            except AttributeError:
                new_row.append(i)
        rows_copy.append(new_row)
    rindex = 0
    for row in rows_copy:
        iindex = 0;
        index_with_long_lines = {}
        for item in row:
            if (len(str(item)) > max_item_length):
                index_with_long_lines[iindex] = textwrap.wrap(str(item), max_item_length, break_long_words=False)
            iindex += 1
        for key in index_with_long_lines:
            # Modify the current and change to the shorten version.
            row[key] = index_with_long_lines.get(key).pop(0)
        # Look over what is left and add new row. Could have multiple items in
        # new row.
        insert_after_row = rindex + 1
        while (index_with_long_lines):
            new_row = ["-"] * (len(row))
            for key in index_with_long_lines.keys():
                # If there is item in list then add to new row.
                # if the list is empty then remove they key.
                items = index_with_long_lines.get(key)
                if (items):
                    new_row[key] = index_with_long_lines.get(key).pop(0)
                    if (not items):
                        # Delete the key if nothing is in list.
                        del index_with_long_lines[key]
            if (new_row):
                rows_copy.insert(insert_after_row, new_row)
                insert_after_row += 1
        # Increment the row index
        rindex += 1
    return rows_copy

def tableize(rows, header, colorize=True):
    """
    Prints out a table using the data in `rows`, which is assumed to be a
    sequence of sequences with the 0th element being the header.
    https://gist.github.com/lonetwin/4721748
    """
    # Formatted string of table data returned.
    formatted_table = ""
    if (not rows):
        return formatted_table

    # Truncate any data in columns.
    rows_copy = truncate_rows(rows)
    # Insert the header
    rows_copy.insert(0, header)
    def __format_item(item):
        import locale
        locale.setlocale(locale.LC_NUMERIC, "")
        try:
            return str(item)
        except UnicodeEncodeError:
            return item.encode("utf-8")

    # Convert all values in rows to strings.
    if (len(rows_copy) > 0):
        converted_rows_to_str = []
        for row in rows_copy:
            current_row = []
            for item in row:
                current_row.append(__format_item(item))
            if (len(current_row) > 0):
                converted_rows_to_str.append(current_row)
        # Figure out each column widths which is max column size for all rows.
        widths = [ len(max(columns, key=len)) for columns in zip(*converted_rows_to_str) ]
        # Add seperator
        formatted_table += '-+-'.join( '-' * width for width in widths) + "\n"
        # Add the header
        header, data = converted_rows_to_str[0], converted_rows_to_str[1:]
        formatted_table += ' | '.join(format(title, "%ds" % width)
                                      for width, title in zip(widths, header) ) + "\n"

        # Add seperator from first row and header.
        formatted_table += '-+-'.join( '-' * width for width in widths) + "\n"
        count = 0
        for row in data:
            row_string = " | ".join(format(cdata, "%ds" % width) for width, cdata in zip(widths, row))
            if (not row_string.startswith("-")):
                count = count + 1
            formatted_table += row_string + "\n"
    return formatted_table



# ##############################################################################
# helpers
# ##############################################################################
def human_size(size_bytes):
    """
    format a size in bytes into a 'human' file size, e.g. bytes, KB, MB, GB, TB, PB
    Note that bytes/KB will be reported in whole numbers but MB and above will have greater precision
    e.g. 1 byte, 43 bytes, 443 KB, 4.3 MB, 4.43 GB, etc
    """
    if size_bytes == 1:
        # because I really hate unnecessary plurals
        return "1 byte"

    suffixes_table = [('bytes',0),('KB',0),('MB',1),('GB',2),('TB',2), ('PB',2)]

    num = float(size_bytes)
    for suffix, precision in suffixes_table:
        if num < 1024.0:
            break
        num /= 1024.0

    if precision == 0:
        formatted_size = "%d" % num
    else:
        formatted_size = str(round(num, ndigits=precision))

    return "%s %s" % (formatted_size, suffix)

# ##############################################################################
# Parsers
# ##############################################################################
def parse_proc_mounts(proc_mount_data) :
    parsed_mounts = []
    if (proc_mount_data == None):
        return parsed_mounts
    for line in proc_mount_data:
        line_split = line.split()
        parsed_mounts.append(ProcMounts(line_split[0].strip(),line_split[1].strip(),
                                        line_split[2].strip(),line_split[3].strip(),
                                        line_split[4].strip(),line_split[5].strip()))
    return parsed_mounts

class ProcMounts:
    def __init__(self, device, mount_point, type, options, filesystem_dump, filesystem_fsck_check_order):
        self.__device = device
        self.__mount_point = mount_point
        self.__type = type
        self.__options = options
        self.__filesystem_dump = int(filesystem_dump)
        self.__filesystem_fsck_check_order = int(filesystem_fsck_check_order)

    def get_device(self):
        return self.__device

    def get_mount_point(self):
        return self.__mount_point

    def get_type(self):
        return self.__type

    def get_options(self):
        return self.__options

    def get_filesystem_dump(self):
        return self.__filesystem_dump

    def getfilesystem_fsck_check_order(self):
        return self.__filesystem_fsck_check_order

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
    description = "Cleanup the df output from sosreport."
    command_name = "convert_df.py"
    epilog =  "Usage examples:\n"
    epilog += "$ %s -p /tmp/df-h.txt" %(command_name)

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
                        action=AbsolutePathAction,
                        dest="path_to_src_file",
                        help="the path to the filename that will be parsed",
                        metavar="<input filename>",
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

        # Check if valid file.
        if (not parseargs_ns.path_to_src_file):
            logging.getLogger(MAIN_LOGGER_NAME).error("A path to a filename with df output is required.")
            sys.exit(1)
        elif (not os.path.isfile(parseargs_ns.path_to_src_file)):
            logging.getLogger(MAIN_LOGGER_NAME).error("The file does not exist. A path to a filename with df output is required.")
            sys.exit(1)

        # #######################################################################
        # Run main
        # #######################################################################
        # Set path to dst if none provided.
        path_to_dst_file = "%s.converted" %(parseargs_ns.path_to_src_file)
        logging.getLogger(MAIN_LOGGER_NAME).status("Converting the file: %s" %(parseargs_ns.path_to_src_file))


        # Find filesystem type for mounted filesystems.
        path_to_proc_mount = os.path.join(os.path.split(parseargs_ns.path_to_src_file)[0], "proc/mounts")
        proc_mounts = []
        if (os.path.exists(path_to_proc_mount)):
            proc_mounts = parse_proc_mounts(get_data_from_file_as_list(path_to_proc_mount))

        # Parse the df output.
        lines = get_data_from_file_as_list(parseargs_ns.path_to_src_file)

        # Set the column names.
        df_column_count = 0
        column_names = ["Filesystem", "Type", "Mounted_On", "Size", "Usage"]
        if (lines):
            line_zero = lines[0].strip()
            if (line_zero.startswith("Filesystem")):
                line_zero = lines.pop(0)
            line_zero = line_zero.replace("Mounted on", "Mounted_On")
            df_column_count = len(line_zero.split())

        # Contains a list of list that will use the table string formatter i got.
        df_rows = []
        previous_line = ""
        #  Need to sort into lists first, then  take the list and format
        for line in lines:
            line = line.strip()
            # Need the case where mount point on seperate line and one when
            # device is on seperate line.
            if (((len(line.split())) == 1) and (not previous_line)):
                previous_line = line
            elif (previous_line):
                df_rows.append("%s %s" %(previous_line, line))
                previous_line = ""
            elif (len(line.split()) == (df_column_count)):
                df_rows.append(line)
        # Split into lines into column and add some additional columns.
        df_table = []
        for line in df_rows:
            line_split = line.strip().split()
            filesystem_type = "-"
            for pmount in proc_mounts:
                if (pmount.get_mount_point().strip() == line_split[-1].strip()):
                    filesystem_type = pmount.get_type()
            line_split.insert(1, filesystem_type)
            try:
                line_split.insert(2,  human_size(int(line_split[2]) * 1024))
            except ValueError:
                line_split.insert(2, "-")
            # Remove some of the information we do not want to include
            line_split.pop(5)
            line_split.pop(4)
            line_split.pop(3)
            # Change some columns to location.
            line_split.insert(2, line_split.pop(4))
            df_table.append(line_split)

        #  Below here do converting oto human size and add other other stuff ad all that jazz.
        wdata = tableize(df_table, column_names)
        if (wdata):
            print wdata
            write_to_file(path_to_dst_file, wdata, append_to_file=False, create_file=True)
        if (not os.path.isfile(path_to_dst_file)):
            logging.getLogger(MAIN_LOGGER_NAME).status("There was an error saving the data to the file: %s" %(path_to_dst_file))
            sys.exit(1)
        else:
            logging.getLogger(MAIN_LOGGER_NAME).status("The data was saved to the following file: %s" %(path_to_dst_file))
        sys.exit(0)
    except KeyboardInterrupt:
        print ""
        message =  "This script will exit since control-c was executed by end user."
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        sys.exit(1)
    # #######################################################################
    # Exit the application with zero exit code since we cleanly exited.
    # #######################################################################
    sys.exit()
