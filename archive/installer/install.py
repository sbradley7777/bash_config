#!/usr/bin/env python
"""This script will install all the required files on the host.

@author    :  Shane Bradley
@contact   :  sbradley@redhat.com
@version   :  0.05
@copyright :  GPLv2

TODO: * Need to code in a way to know which files failed to installed and which
        configuration files were not overwritten when they already exist.

Example configuration file to modify or add to configuration installer:
# cat ~/.dot.config
[bin.clusterha]
src_path = bin/bin.clusterha
dst_path = ~/bin/bin.clusterha
platform = Linux

[bin.clusterha_probe]
src_path = bin/bin.clusterha_probe
dst_path = ~/bin/bin.clusterha_probe
platform = Linux

[test_script.sh]
src_path = dot.config/etc/cluster/scripts/test_script.sh
dst_path = /etc/cluster/scripts/test_script.sh
platform = Linux

"""
import sys
import os
import os.path
import logging
import logging.handlers
from optparse import OptionParser, Option, SUPPRESS_HELP
import time
import platform
import shutil
from copy import deepcopy
import configparser
# #####################################################################
# Global vars:
# #####################################################################
VERSION_NUMBER = "1.0"
MAIN_LOGGER_NAME = "Configs_Installer"
PATH_TO_INSTALL_CONFIGURATION_FILE = os.path.join(os.environ['HOME'],".dot.config")

class InstallerConfigurationFile:
    SECTION_ITEMS = ["src_path", "dst_path", "platform"]

    def __init__(self, path_to_config_file) :
		# Valid Platforms are: Darwin(OSX), Linux, or empty string for stands for any OS.
        self.__path_to_config_file = path_to_config_file

    def __get_sections(self):
        config_parser = configparser.ConfigParser()
        config_parser.read(self.__path_to_config_file)
        return config_parser.sections()

    def __get_section_map(self, section_name):
        config_parser = configparser.ConfigParser()
        config_parser.read(self.__path_to_config_file)
        if (config_parser.has_section(section_name)):
            section_map = {}
            for item in InstallerConfigurationFile.SECTION_ITEMS:
                try:
                    section_map[item] = config_parser.get(section_name, item)
                except configparser.NoOptionError:
                    section_map[item] = ""
            return ConfigurationFile(section_map.get("src_path"),
                                     section_map.get("dst_path"),
                                     section_map.get("platform"))
        return None

    def list(self):
        installer_configuration_file_list = []
        sections = self.__get_sections()
        for section in sections:
            configuration_file = self.__get_section_map(section)
            if (not configuration_file == None):
                installer_configuration_file_list.append(configuration_file)
        return installer_configuration_file_list

class ConfigurationFile:
    def __init__(self, path_to_src, path_to_dst, platform=""):
        # If self.__path_to_src is empty string then the file will be created if
        # it does not exist. The path to source is a relative path to the
        # location f the git repo.
        self.__path_to_src = path_to_src
        self.__path_to_dst = path_to_dst
        if (self.__path_to_dst.startswith("~")):
            self.__path_to_dst = os.path.expanduser(self.__path_to_dst)
        # If empty string then it does not require a specific OS platform. The
        # nost commond platform strings are: "", "Linux", "Darwin".
        self.__platform = platform
        # This variable will be set after the file attempts to be installed. If
        # install fails then set to False, if successfully installed then set to
        # True.
        self.__installed = False

    def __eq__(self, configuration_file):
        if (configuration_file == None):
            return False
        return (self.get_path_to_src() == configuration_file.get_path_to_src())

    def __str__(self):
        r_string =  "path to src: %s\n" %(self.get_path_to_src())
        r_string += "path to dst: %s\n" %(self.get_path_to_dst())
        r_string += "platform:    %s\n" %(self.get_platform())
        return r_string

    def get_path_to_src(self):
        return self.__path_to_src

    def get_path_to_dst(self):
        return self.__path_to_dst

    def get_platform(self):
        return self.__platform

    def set_installed(self, installed):
        self.__installed = installed

    def is_installed(self):
        return self.__installed

    def valid_platform(self):
        return ((len(self.get_platform()) == 0) or
                (self.get_platform().lower() == platform.system().lower()))

# ##############################################################################
# The list of configuration files to install
# ##############################################################################
CONFIGURATION_FILES_TO_INSTALL = [ConfigurationFile("bash/.bash_profile", os.path.join(os.getenv("HOME"), ".bash_profile")),
                                  ConfigurationFile("bash/.bashrc", os.path.join(os.getenv("HOME"), ".bashrc")),
                                  ConfigurationFile("", os.path.join(os.getenv("HOME"), ".bash_profile.priv")),
                                  ConfigurationFile("", os.path.join(os.getenv("HOME"), ".bashrc.priv")),
                                  ConfigurationFile("bash/.aliases.all", os.path.join(os.getenv("HOME"), ".aliases.all")),
                                  ConfigurationFile("bash/.aliases.devel", os.path.join(os.getenv("HOME"), ".aliases.devel")),
                                  ConfigurationFile("bash/.aliases.osx", os.path.join(os.getenv("HOME"), ".aliases.osx"), platform="Darwin"),
                                  ConfigurationFile("bash/.aliases.redhat", os.path.join(os.getenv("HOME"), ".aliases.redhat"), platform="Linux"),
                                  ConfigurationFile("bash/.aliases.sx", os.path.join(os.getenv("HOME"), ".aliases.sx"), platform="Linux"),
                                  ConfigurationFile("bash/.functions.sh", os.path.join(os.getenv("HOME"), ".functions.sh")),
                                  ConfigurationFile("bin/bin.utils", os.path.join(os.getenv("HOME"), "bin/bin.utils")),
                                  ConfigurationFile("bin/bin.clusterha_analyze", os.path.join(os.getenv("HOME"), "bin/bin.clusterha_analyze"), platform="Linux"),
                                  ConfigurationFile("bash/.functions-osx.sh", os.path.join(os.getenv("HOME"), ".functions-osx.sh"), platform="Darwin"),
                                  ConfigurationFile("python", os.path.join(os.getenv("HOME"), "python"))]


# ##############################################################################
# Functions for directories
# ##############################################################################
def mkdirs(path_to_dst_dir):
    """
    This function will attempt to create a directory with the path of the value of path_to_dst_dir.

    @return: Returns True if the directory was created or already exists.
    @rtype: Boolean

    @param path_to_dst_dir: The path to the directory that will be created.
    @type path_to_dst_dir: String
    """
    if (os.path.isdir(path_to_dst_dir)):
        return True
    elif ((not os.access(path_to_dst_dir, os.F_OK)) and (len(path_to_dst_dir) > 0)):
        try:
            os.makedirs(path_to_dst_dir)
        except (OSError, os.error):
            message = "Could not create the directory: %s." %(path_to_dst_dir)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        except (IOError, os.error):
            message = "Could not create the directory with the path: %s." %(path_to_dst_dir)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
    return os.path.isdir(path_to_dst_dir)

def copy_directory(path_to_src_dir, path_to_dst_dir):
    """
    This function will copy a src dir to dst dir.

    @return: Returns True if the dir was copied successfully.
    @rtype: Boolean

    @param path_to_src_dir: The path to the source dir that will be copied.
    @type path_to_src_dir: String
    @param path_to_dst_dir: The path to the destination of the dir.
    @type path_to_dst_dir: String
    """
    if(not os.path.exists(path_to_src_dir)):
        message = "The directory does not exist with the path: %s." %(path_to_src_dir)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        return False
    elif (not os.path.isdir(path_to_src_dir)):
        message = "The path to the source directory is not a directory: %s." %(path_to_src_dir)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        return False
    elif (path_to_src_dir == path_to_dst_dir):
        message = "The path to the source directory and path to destination directory cannot be the same: %s." %(path_to_dst_dir)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        return False
    else:
        result = remove_directory(path_to_dst_dir)
        [parent_dir, filename] = os.path.split(path_to_dst_dir)
        if (mkdirs(parent_dir)):
            try:
                shutil.copytree(path_to_src_dir, path_to_dst_dir)
            except shutil.Error:
                message = "Cannot copy the directory %s to %s." %(path_to_src_dir, path_to_dst_dir)
                logging.getLogger(MAIN_LOGGER_NAME).error(message)
                return False
            except OSError:
                message = "Cannot copy the directory %s to %s." %(path_to_src_dir, path_to_dst_dir)
                logging.getLogger(MAIN_LOGGER_NAME).error(message)
                return False
            except IOError:
                message = "Cannot copy the directory %s to %s." %(path_to_src_dir, path_to_dst_dir)
                logging.getLogger(MAIN_LOGGER_NAME).error(message)
                return False
        else:
            message = "The parent directory could not be created: %s." %(parent_dir)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        return (os.path.exists(path_to_dst_dir))

def remove_directory(path_to_directory):
    if (os.path.isdir(path_to_directory)):
        try:
            shutil.rmtree(path_to_directory)
        except shutil.Error:
            message = "An error occurred removing the file: %s." %(path_to_directory)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        except OSError:
            message = "An error occurred removing the file: %s." %(path_to_directory)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        except IOError:
            message = "An error occurred removing the file: %s." %(path_to_directory)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
    return (os.path.exists(path_to_directory))


# ##############################################################################
# Functions for files
# ##############################################################################
def copy_file(path_to_src_file, path_to_dst_file):
    """
    This function will copy a src file to dst file.

    @return: Returns True if the file was copied successfully.
    @rtype: Boolean

    @param path_to_src_file: The path to the source file that will be copied.
    @type path_to_src_file: String
    @param path_to_dst_file: The path to the destination of the file.
    @type path_to_dst_file: String
    """
    if(not os.path.exists(path_to_src_file)):
        message = "The file does not exist with the path: %s." %(path_to_src_file)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        return False
    elif (not os.path.isfile(path_to_src_file)):
        message = "The path to the source file is not a regular file: %s." %(path_to_src_file)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        return False
    elif (path_to_src_file == path_to_dst_file):
        message = "The path to the source file and path to destination file cannot be the same: %s." %(path_to_dst_file)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        return False
    else:
        # Create the directory structure if it does not exist.
        (head, tail) = os.path.split(path_to_dst_file)
        if (not mkdirs(head)) :
            # The path to the directory was not created so file
            # could not be copied.
            return False
        # Copy the file to the dst path.
        try:
            shutil.copy(path_to_src_file, path_to_dst_file)
        except shutil.Error:
            message = "Cannot copy the file %s to %s." %(path_to_src_file, path_to_dst_file)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        except OSError:
            message = "Cannot copy the file %s to %s." %(path_to_src_file, path_to_dst_file)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        except IOError:
            message = "Cannot copy the file %s to %s." %(path_to_src_file, path_to_dst_file)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            return False
        return (os.path.exists(path_to_dst_file))

def write_to_file(path_to_filename, data="", append_to_file=False):
    """
    This function will write a string to a file.

    @return: Returns True if the string was successfully written to the file,
    otherwise False is returned.
    @rtype: Boolean

    @param path_to_filename: The path to the file that will have a string written
    to it.
    @type path_to_filename: String
    @param data: The string that will be written to the file.
    @type data: String
    @param append_to_file: If True then the data will be appened to the file, if
    False then the data will overwrite the contents of the file.
    @type append_to_file: Boolean
    """
    [parent_dir, filename] = os.path.split(path_to_filename)
    if (not mkdirs(parent_dir)):
        return False
    else:
        if (os.path.isfile(path_to_filename) or os.path.isdir(parent_dir)):
            try:
                filemode = "w"
                if (append_to_file):
                    filemode = "a"
                fout = open(path_to_filename, filemode)
                fout.write(data + "\n")
                fout.close()
                return True
            except UnicodeEncodeError as e:
                message = "There was a unicode encode error writing to the file: %s." %(path_to_filename)
                logging.getLogger(MAIN_LOGGER_NAME).error(message)
                return False
            except IOError:
                message = "There was an error writing to the file: %s." %(path_to_filename)
                logging.getLogger(MAIN_LOGGER_NAME).error(message)
                return False
    return False

# ##############################################################################
# Installation Functions
# ##############################################################################
def install(path_to_config_files, files_to_install):
    if (os.path.isdir(path_to_config_files)):
        # Copy files to their location on the host.
        message = "The files in the following directory will be installed: %s." %(path_to_config_files)
        logging.getLogger(MAIN_LOGGER_NAME).info(message)
        for configuration_file in files_to_install:
            path_to_src_file = os.path.join(path_to_config_files, configuration_file.get_path_to_src())
            if (configuration_file.valid_platform()):
                if (not len(configuration_file.get_path_to_src()) > 0):
                    if (not os.path.exists(configuration_file.get_path_to_dst())):
                        message = "Creating an empty file %s." %(configuration_file.get_path_to_dst())
                        logging.getLogger(MAIN_LOGGER_NAME).debug(message)
                        configuration_file.set_installed(write_to_file(configuration_file.get_path_to_dst(), "", append_to_file=False))
                    else:
                        # File already exists so do not override it.
                        configuration_file.set_installed(True)
                        message = "The configuration file will not be overridden %s." %(configuration_file.get_path_to_dst())
                        logging.getLogger(MAIN_LOGGER_NAME).debug(message)
                elif (os.path.isfile(path_to_src_file)):
                    message = "Copying the file %s to %s." %(path_to_src_file, configuration_file.get_path_to_dst())
                    logging.getLogger(MAIN_LOGGER_NAME).debug(message)
                    configuration_file.set_installed(copy_file(path_to_src_file, configuration_file.get_path_to_dst()))
                elif (os.path.isdir(path_to_src_file)):
                    message = "Copying the directory %s to %s." %(path_to_src_file, configuration_file.get_path_to_dst())
                    logging.getLogger(MAIN_LOGGER_NAME).debug(message)
                    configuration_file.set_installed(copy_directory(path_to_src_file, configuration_file.get_path_to_dst()))
    else:
        message = "The path to the configuration files is invalid so installation will not continue: %s" %(path_to_config_files)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
    # Loop over list and find any that did not install.
    configuration_files_failed_install = []
    for configuration_file in files_to_install:
        if ((not configuration_file.is_installed() and (configuration_file.valid_platform()))):
            configuration_files_failed_install.append(configuration_file)
    if (len(configuration_files_failed_install) > 0):
        message = "The following files failed to installed or was not overridden:\n"
        for configuration_file in configuration_files_failed_install:
            message += "\t%s --> %s\n" %(configuration_file.get_path_to_src(), configuration_file.get_path_to_dst())
        logging.getLogger(MAIN_LOGGER_NAME).error(message.rstrip())
    return (not len(configuration_files_failed_install) > 0)

# ##############################################################################
# Misc Functions
# ##############################################################################
def exit_script(error_code=0):
    """
    This function will cause the script to exit or quit. It will return an error
    code and a message.

    @param error_code: The exit code that will be returned. The default value is 0.
    @type error_code: Int
    """
    message = "The script will exit."
    logging.getLogger(MAIN_LOGGER_NAME).info(message)
    sys.exit(error_code)
# ##############################################################################
# Get user selected options
# ##############################################################################
def __get_options(version) :
    """
    This function creates the OptionParser and returns commandline
    a tuple of the selected commandline options and commandline args.

    The cmdline_opts which is the options user selected and cmd_line_args
    is value passed and  not associated with an option.

    @return: A tuple of the selected commandline options and commandline args.
    @rtype: Tuple

    @param version: The version of the this script.
    @type version: String
    """
    cmd_parser = OptionParserExtended(version)
    cmd_parser.add_option("-d", "--debug",
                         action="store_true",
                         dest="enable_debug_logging",
                         help="enables debug logging",
                         default=False)
    cmd_parser.add_option("-q", "--quiet",
                         action="store_true",
                         dest="disable_logging_to_console",
                         help="disables logging to console",
                         default=False)
    cmd_parser.add_option("-y", "--no_ask",
                         action="store_true",
                         dest="disable_questions",
                         help="disables all questions and assumes yes",
                         default=False)
    cmd_parser.add_option("-p", "--path_to_configs",
                         action="store",
                         dest="path_to_config_files",
                         help="path to the root directory for the configuration files",
                         type="string",
                         default=os.path.join(os.getenv("HOME"), "github/dot.config"))
    (cmd_line_opts, cmd_line_args) = cmd_parser.parse_args()
    return (cmd_line_opts, cmd_line_args)

# ##############################################################################
# OptParse classes for commandline options
# ##############################################################################
class OptionParserExtended(OptionParser):
    """
    This is the class that gets the command line options the end user
    selects.
    """
    def __init__(self, version) :
        """
        @param version: The version of the this script.
        @type version: String
        """
        self.__command_name = os.path.basename(sys.argv[0])
        version_message = "%s %s\n" %(self.__command_name, version)

        command_description  ="%s will install the configuration files and scripts to the host.\n"%(self.__command_name)

        OptionParser.__init__(self, option_class=ExtendOption,
                              version=version_message,
                              description=command_description)

    def print_help(self):
        """
        Print examples at the bottom of the help message.
        """
        self.print_version()
        examples_message = "\n"
        OptionParser.print_help(self)
        print(examples_message)


class ExtendOption (Option):
    """
    Allow to specify comma delimited list of entries for arrays
    and dictionaries.
    """
    ACTIONS = Option.ACTIONS + ("extend",)
    STORE_ACTIONS = Option.STORE_ACTIONS + ("extend",)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ("extend",)

    def take_action(self, action, dest, opt, value, values, parser):
        """
        This function is a wrapper to take certain options passed on command
        prompt and wrap them into an Array.

        @param action: The type of action that will be taken. For example:
        "store_true", "store_false", "extend".
        @type action: String
        @param dest: The name of the variable that will be used to store the
        option.
        @type dest: String/Boolean/Array
        @param opt: The option string that triggered the action.
        @type opt: String
        @param value: The value of opt(option) if it takes a
        value, if not then None.
        @type value:
        @param values: All the opt(options) in a dictionary.
        @type values: Dictionary
        @param parser: The option parser that was orginally called.
        @type parser: OptionParser
        """
        if (action == "extend") :
            value_list = []
            try:
                for v in value.split(","):
                    # Need to add code for dealing with paths if there is option for paths.
                    new_value = value.strip().rstrip()
                    if (len(new_value) > 0):
                        value_list.append(new_value)
            except:
                pass
            else:
                values.ensure_value(dest, []).extend(value_list)
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
        (cmd_line_opts, cmd_line_args) = __get_options(VERSION_NUMBER)
        # #######################################################################
        # Setup the logger and create config directory
        # #######################################################################
        # Create the logger
        log_level = logging.INFO
        logger = logging.getLogger(MAIN_LOGGER_NAME)
        logger.setLevel(log_level)
        # Create a new status function and level.
        logging.STATUS = logging.INFO + 2
        logging.addLevelName(logging.STATUS, "STATUS")
        # Create a function for the STATUS_LEVEL since not defined by python. This
        # means you can call it like the other predefined message
        # functions. Example: logging.getLogger("logger_name").status(message)
        setattr(logger, "status", lambda *args: logger.log(logging.STATUS, *args))
        stream_handler = logging.StreamHandler()
        stream_handler.setLevel(log_level)
        stream_handler.setFormatter(logging.Formatter("%(levelname)s %(message)s"))
        logger.addHandler(stream_handler)

        # #######################################################################
        # Set the logging levels.
        # #######################################################################
        if ((cmd_line_opts.enable_debug_logging) and (not cmd_line_opts.disable_logging_to_console)):
            logging.getLogger(MAIN_LOGGER_NAME).setLevel(logging.DEBUG)
            stream_handler.setLevel(logging.DEBUG)
            message = "Debugging has been enabled."
            logging.getLogger(MAIN_LOGGER_NAME).debug(message)
        if (cmd_line_opts.disable_logging_to_console):
            stream_handler.setLevel(logging.CRITICAL)

        # #######################################################################
        # Read in configuration file for installer if it exists.
        # #######################################################################
        files_to_install = []
        if (os.path.exists(PATH_TO_INSTALL_CONFIGURATION_FILE)):
            message = "Reading the configuration file: %s." %(PATH_TO_INSTALL_CONFIGURATION_FILE)
            logging.getLogger(MAIN_LOGGER_NAME).debug(message)
            files_to_install = InstallerConfigurationFile(PATH_TO_INSTALL_CONFIGURATION_FILE).list()
        # Add in the configuration files from the config file and do not add default
        # ones in if the configuration file already adds them in. NOTE: The comparison
        # only checks the source so that the dst and platform can be modified.
        for configuration_file in deepcopy(CONFIGURATION_FILES_TO_INSTALL):
            if (not configuration_file in files_to_install):
                files_to_install.append(configuration_file)

        # #######################################################################
        # Verify they want to continue because this script will trigger sysrq events.
        # #######################################################################
        message = "Installing of the configuration files will begin."
        logging.getLogger(MAIN_LOGGER_NAME).info(message)
        if (not cmd_line_opts.disable_questions):
            valid = {"yes":True, "y":True, "no":False, "n":False}
            question = "Are you sure you want to install the configuration files and scripts to this host?"
            prompt = " [y/n] "
            while True:
                sys.stdout.write(question + prompt)
                choice = input().lower()
                if (choice in valid):
                    if (valid.get(choice)):
                        # If yes, or y then exit loop and continue.
                        break
                    else:
                        message = "The script will not continue since you chose not to continue."
                        logging.getLogger(MAIN_LOGGER_NAME).error(message)
                        exit_script(remove_pid_file=True, error_code=1)
                else:
                    sys.stdout.write("Please respond with '(y)es' or '(n)o'.\n")
        # Do the install.
        if (install(cmd_line_opts.path_to_config_files, files_to_install)):
            message = "The installation was successful."
            logging.getLogger(MAIN_LOGGER_NAME).info(message)
            exit_script(0)
        else:
            message = "The installation was unsuccessful. There was errors detected during the installation of the files."
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            exit_script(1)
    except KeyboardInterrupt:
        message =  "This script will exit since control-c was executed by end user."
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        exit_script(1)
    #except Exception, e:
    #    message = "An unhandled error occurred and the script will exit."
    #    logging.getLogger(MAIN_LOGGER_NAME).error(message)
    #    exit_script(1)

    # #######################################################################
    # Exit the application with zero exit code since we cleanly exited.
    # #######################################################################
    exit_script(0)
