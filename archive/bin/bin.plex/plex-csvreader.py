#!/usr/bin/python
"""
# This script will output a list of Movies or TV Show Episodes that are in a specific resolution or container.

# TODO:
# Color code on TV Shows by season instead of alt even/odd.

# Note: The color coding works best on black bg of terminal.

# https://forums.plex.tv/index.php/topic/103115-rel-plex2csv/
# https://forums.plex.tv/index.php/topic/115637-how-to-print-listing-of-all-tv-shows-episodes-resolution/

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
import string
from optparse import OptionParser, Option, SUPPRESS_HELP
import csv
from collections import defaultdict

# #####################################################################
# Global vars:
# #####################################################################
VERSION_NUMBER = "0.3-1"
MAIN_LOGGER_NAME = "%s" %(os.path.basename(sys.argv[0]))

METADATA_FIELDS = ["Year", "Height", "Width", "Video Resolution", "Video FrameRate",
                   "Aspect Ratio", "Video Codec", "Container", "Year"]

METADATA_FIELDS_TV_SHOW = ["Series Title", "Season", "Episode", "Episode Title"]
METADATA_FIELDS_MOVIE = ["Title"]

# ##############################################################################
# Containers for Metadata
# ##############################################################################
class Metadata:
    def __init__(self, year, height, width, resolution, framerate, aspectRatio, codec, container):
        self.__year = year
        self.__height = height
        self.__width = width
        self.__resolution = resolution
        self.__framerate = framerate
        self.__aspectRatio = aspectRatio
        self.__codec = codec
        self.__container = container

    def getYear(self):
        return self.__year

    def getHeight(self):
        return self.__height

    def getWidth(self):
        return self.__width

    def getResolution(self):
        return self.__resolution

    def getFrameRate(self):
        return self.__framerate

    def getAspectRatio(self):
        return self.__aspectRatio

    def getCodec(self):
        return self.__codec

    def getContainer(self):
        return self.__container

class Movie(Metadata):
    def __init__(self, title, year, height, width, resolution, framerate, aspectRatio, codec, container):
        self.__title = title
        Metadata.__init__(self,  year, height, width, resolution, framerate, aspectRatio, codec, container)

    def __str__(self):
        return "%s(%s)" %(self.getTitle(), self.getYear())

    def getTitle(self):
        return self.__title

class TVEpisode(Metadata):
    def __init__(self, season, episode, episodeTitle, year, height, width, resolution, framerate, aspectRatio, codec, container):
        # int
        self.__season = season
        # int
        self.__episode = episode
        self.__episodeTitle = episodeTitle

        Metadata.__init__(self,  year, height, width, resolution, framerate, aspectRatio, codec, container)

    def __str__(self):
        print self.getEpisodeTitle()
        return "Season %d Episode %d: %s" %(self.getSeason(), self.getEpisode(), self.getEpisodeTitle())

    def getSeason(self):
        return self.__season

    def getEpisode(self):
        return self.__episode

    def getEpisodeTitle(self):
        return self.__episodeTitle

class TVShow:
    def __init__(self, name, year):
        self.__name = name
        self.__year = year
        self.__listOfEpisodes = []

    def __str__(self):
        return"%s: %d episodes" %(self.getName(), self.count())

    def getName(self):
        return self.__name

    def getYear(self):
        return self.__year

    def list(self):
        return self.__listOfEpisodes

    # Need compare for sorting
    def sort(self):
        pass

    def count(self):
        return len(self.list())

    def add(self, tvEpisode):
        # Need to check if it already exists.
        self.__listOfEpisodes.append(tvEpisode)

# ##############################################################################
# Private Functions
# ##############################################################################
def __parseTVShows(pathToCSVFile):
    mapOfTVShows = {}
    try:
        with open(pathToCSVFile) as f:
            reader = csv.DictReader(f)
            for row in reader:
                seriesTitle = row.get("Series Title").replace("\n", " ")
                year = row.get("Year").strip()
                # Add add tv shows that have a series title, and skip if they do not.
                if (len(seriesTitle) > 0):
                    try:
                        tvEpisode = TVEpisode(int(row.get("Season").strip()), int(row.get("Episode").strip()), row.get("Episode Title").replace("\n", " ").strip(), year,
                                              row.get("Height").strip(),row.get("Width").strip(), row.get("Video Resolution").strip(),
                                              row.get("Video FrameRate").strip(), row.get("Aspect Ratio").strip(), row.get("Video Codec").strip(),
                                              row.get("Container").strip())
                        if (not mapOfTVShows.has_key(seriesTitle)):
                            mapOfTVShows[seriesTitle] = TVShow(seriesTitle, year)
                        mapOfTVShows[seriesTitle].add(tvEpisode)
                    except ValueError:
                        # If casting a string value to integer fails then skip the episode.
                        pass
    except IOError:
        message = "There was an error reading the file: %s" %(pathToCSVFile)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
    finally:
        f.close()
    return mapOfTVShows

def __parseMovies(pathToCSVFile):
    listOfMovies = []
    try:
        with open(pathToCSVFile) as f:
            reader = csv.DictReader(f)
            for row in reader:
                title = row.get("Title").replace("\n", " ")
                movie = Movie(title.strip(), row.get("Year").strip(), row.get("Height").strip(),
                              row.get("Width").strip(), row.get("Video Resolution").strip(), row.get("Video FrameRate").strip(),
                              row.get("Aspect Ratio").strip(), row.get("Video Codec").strip(), row.get("Container").strip())
                listOfMovies.append(movie)
                pass
    except IOError:
        message = "There was an error reading the file: %s" %(pathToCSVFile)
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
    finally:
        f.close()
    return listOfMovies

def __printTVShows(mapOfTVShows, listOfResolutions, listOfContainers, disableHighlightingRows):
    # Print TV Shows
    tvShows = mapOfTVShows.keys()
    tvShows.sort()
    for key in tvShows:
        tvShow = mapOfTVShows.get(key)
        tvShowTable = []
        for episode in tvShow.list():
            addVideoFile = False
            if ((not len(listOfResolutions) > 0) and (not len(listOfContainers) > 0)):
                addVideoFile = True
            elif (episode.getResolution() in listOfResolutions):
                addVideoFile = True
            elif (episode.getContainer() in listOfContainers):
                addVideoFile = True
            if (addVideoFile):
                tvShowTable.append([str(episode.getSeason()), str(episode.getEpisode()), episode.getContainer(),
                                    episode.getResolution(), episode.getHeight(), episode.getWidth(),
                                    episode.getEpisodeTitle()])
        if (len(tvShowTable) > 0):
            print "\n%s: %d episodes" %(tvShow.getName(), tvShow.count())
            previousSeason = ""
            index = 0
            stringUtil = StringUtil()
            for s in stringUtil.toTableStringsList(tvShowTable, ["season", "episode", "container", "resolution", "height", "width", "episode_title"]):
                currentSeason = s.split()[0]
                if (not currentSeason == previousSeason):
                    previousSeason = currentSeason
                    index += 1
                if (((index % 2) == 0) and (index > 3) and (not disableHighlightingRows)):
                    s = __colorizeBackground(s)
                print s

def __printMovies(listOfMovies, listOfResolutions, listOfContainers, disableHighlightingRows):
    moviesTable = []
    for movie in listOfMovies:
        addVideoFile = False
        if ((not len(listOfResolutions) > 0) and (not len(listOfContainers) > 0)):
            addVideoFile = True
        else:
            if (len(listOfResolutions) > 0):
                if (movie.getResolution() in listOfResolutions):
                    addVideoFile = True
            elif (len(listOfContainers) > 0):
                if (movie.getContainer() in listOfContainers):
                    addVideoFile = True
        if (addVideoFile):
            moviesTable.append([movie.getTitle(), movie.getYear(), movie.getContainer(), movie.getResolution(), movie.getHeight(), movie.getWidth()])
    if (len(moviesTable) > 0):
        index = 0
        stringUtil = StringUtil()
        for s in stringUtil.toTableStringsList(moviesTable, ["title", "year", "container", "resolution", "height", "width"]):
            if (((index % 2) == 0) and (index > 0) and (not disableHighlightingRows)):
                    s = __colorizeBackground(s)
            print s
            index += 1
# ##############################################################################
# Private functions of printing results
# ##############################################################################
class StringUtil:
    # #######################################################################
    # Functions for creating a formatted table from lists of lists:
    # #######################################################################
    def __getMaxColumnWidth(self, table, index):
        try:
            return max([len(str(row[index])) for row in table])
        except IndexError:
            return -1

    def formatStringListsToTable(self, table, headerList=None):
        # Copy the table so that we do not ref the orginal list and change it.
        copyOfTable = []
        for currentList in table:
            newList = []
            for item in currentList:
                newList.append(item)
            if (len(newList) > 0):
                copyOfTable.append(newList)

        # Return empty list and print error if all the rows in table
        # dont have same column count.
        if (len(copyOfTable) > 0):
            # Add header to the list if one was passed to it and table is not empty.
            if (not headerList == None):
                copyOfTable.insert(0, headerList)
            # Make sure that table and header contain the same number
            # of columns.
            colCount = len(copyOfTable[0])
            for currentRow in copyOfTable:
                currentColCount = len(currentRow)
                if (not (currentColCount == colCount)):
                    message = "The table continues columns with a different columns counts and will not be processed."
                    logging.getLogger(sx.MAIN_LOGGER_NAME).debug(message)
                    return []
        else:
            message = "The table continues no rows in the table and will not be processed."
            logging.getLogger(sx.MAIN_LOGGER_NAME).debug(message)
            return []
        # This function will append new rows if the item in the column
        # for a row is an array/list. If there is a None value or
        # empty string then replace with "-" for no value rep.
        currentRowIndex = 0
        for currentRow in copyOfTable:
            newRows = []
            currentColIndex = 0
            for currentCol in currentRow:
                if (currentCol == None):
                   currentRow[currentColIndex] = "-"
                elif (not (len(currentCol) > 0)):
                    currentRow[currentColIndex] = "-"
                elif (type(currentCol) == list):
                    currentColList = currentCol
                    if (len(currentCol) > 0):
                        currentRow[currentColIndex] = currentColList.pop(0)
                    for ccListIndex in range(0, len(currentColList)):
                        try:
                            newRows[ccListIndex][currentColIndex] = currentColList[ccListIndex]
                        except IndexError:
                            newRow = []
                            for i in range(len(currentRow)):
                                newRow[i] = ""
                            newRow[currentColIndex] = currentColList[ccListIndex]
                            newRows.append(newRow)
                currentColIndex = currentColIndex + 1
            for row in newRows:
                copyOfTable.insert(currentRowIndex + 1,row)
            currentRowIndex = currentRowIndex  + 1
        # Fix the max spacing for each column after iterating over
        # each row.
        tableStringsList = []
        col_paddings = []
        for i in range(len(copyOfTable[0])):
            maxColumnWidth = self.__getMaxColumnWidth(copyOfTable, i)
            if (maxColumnWidth >= 0):
                col_paddings.append(maxColumnWidth)
        # If header was given then use the max column size to build
        # the seperator.
        if (not headerList == None):
            headerSeperatorList = []
            for colMaxSize in col_paddings:
                currentHeaderSeperator = ""
                currentHeaderSeperator += "-" * colMaxSize
                headerSeperatorList.append(currentHeaderSeperator)
            copyOfTable.insert(1, headerSeperatorList)
        for row in copyOfTable:
            # Left col string has no spacing.
            tableStrings = []
            tableStrings.append( str(row[0].ljust(col_paddings[0] + 1)))
            # Add spacing to the rest of the columns.
            for i in range(1, len(row)):
                # Add spacing to to the right side with ljust.
                try:
                    tableStrings.append(str(str(row[i]).ljust(col_paddings[i] + 2)))
                except IndexError:
                    continue
            tableStringsList.append(tableStrings)
        return tableStringsList

    def toTableStringsList(self, table, headerList=None):
        tableOfStrings = []
        tableStringsList = self.formatStringListsToTable(table, headerList)
        for tableStrings in tableStringsList:
            currentLine = ""
            for ts in tableStrings:
                currentLine += ts
            tableOfStrings.append(currentLine)
        return tableOfStrings

# #######################################################################
# Helper Functions
# #######################################################################
def __dequote(s):
    """
    If a string has single or double quotes around it, remove them.
    If a matching pair of quotes is not found, return the string unchanged.
    """
    if (s.startswith(("'", '"')) and s.endswith(("'", '"')) and (s[0] == s[-1])):
        s = s[1:-1]
    return s

def __colorizeBackground(text):
    # Dark Gray
    # http://misc.flogisoft.com/bash/tip_colors_and_formatting
    bgColor = "100"
    opencol = "\033["
    closecol = "m"
    clear = opencol + "0" + closecol
    bg = opencol + bgColor + closecol
    return "%s%s%s" % (bg, text, clear)

# ##############################################################################
# Get user selected options
# ##############################################################################
def __getOptions(version) :
    """
    This function creates the OptionParser and returns commandline
    a tuple of the selected commandline options and commandline args.

    The cmdlineOpts which is the options user selected and cmdLineArgs
    is value passed and  not associated with an option.

    @return: A tuple of the selected commandline options and commandline args.
    @rtype: Tuple

    @param version: The version of the this script.
    @type version: String
    """
    cmdParser = OptionParserExtended(version)
    cmdParser.add_option("-d", "--debug",
                         action="store_true",
                         dest="enableDebugLogging",
                         help="enables debug logging",
                         default=False)
    cmdParser.add_option("-q", "--quiet",
                         action="store_true",
                         dest="disableLoggingToConsole",
                         help="disables logging to console",
                         default=False)
    cmdParser.add_option("-y", "--no_ask",
                        action="store_true",
                         dest="disableQuestions",
                         help="disables all questions and assumes yes",
                         default=False)
    cmdParser.add_option("-H", "--disable_highlight",
                        action="store_true",
                         dest="disableHighlightingRows",
                         help="disables table row highlighting of tv show seasons and movies",
                         default=False)
    cmdParser.add_option("-f", "--path_to_filename",
                         action="store",
                         dest="pathToCSVFile",
                         help="the path to the .csv file that will be parsed",
                         type="string",
                         metavar="<input filename>",
                         default="")
    cmdParser.add_option("-r", "--resolution",
                         action="extend",
                         dest="listOfResolutions",
                         help="query for metadata that has the following resolution for the video files(The valid values are: sd, 480, 720, 1080, if empty all resolutions are printed)",
                         type="string",
                         metavar="<resolution>",
                         default=[])
    cmdParser.add_option("-c", "--container",
                         action="extend",
                         dest="listOfContainers",
                         help="query for metadata that has the following container for the video files",
                         type="string",
                         metavar="<container>",
                         default=[])

 # Get the options and return the result.
    (cmdLineOpts, cmdLineArgs) = cmdParser.parse_args()
    return (cmdLineOpts, cmdLineArgs)

# ##############################################################################
# OptParse classes for commandline options
# ##############################################################################
class OptionParserExtended(OptionParser):
    def __init__(self, version) :
        self.__commandName = os.path.basename(sys.argv[0])
        versionMessage = "%s %s\n" %(self.__commandName, version)

        commandDescription  ="%s will list metadata information related to video file properties for a .csv file created by Plex2cvs with extreme(or higher) setting for Movies or TV Shows.\n"%(self.__commandName)

        OptionParser.__init__(self, option_class=ExtendOption,
                              version=versionMessage,
                              description=commandDescription)

    def print_help(self):
        self.print_version()
        OptionParser.print_help(self)
        examplesMessage = "\n"
        examplesMessage += "This example will list the metadata that has attribute for the resolution set to \"sd\" or \"480\".\n"
        examplesMessage += "$ %s -f ~/Documentaries-Extended-20141005-095915.csv  -r sd,480\n" %(self.__commandName)
        examplesMessage += "This example will list the metadata that has attribute for the container set to \"avi\" or \"mkv\".\n"
        examplesMessage += "$ %s -f ~/Documentaries-Extended-20141005-095915.csv  -r avi,mkv\n" %(self.__commandName)
        examplesMessage += "This example will list the metadata with no filtering and does no highlighting.\n"
        examplesMessage += "$ %s -f ~/Movies-Extreme-20141004-091106.csv -H\n" %(self.__commandName)
        print examplesMessage

class ExtendOption (Option):
    ACTIONS = Option.ACTIONS + ("extend",)
    STORE_ACTIONS = Option.STORE_ACTIONS + ("extend",)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ("extend",)

    def take_action(self, action, dest, opt, value, values, parser):
        if (action == "extend") :
            valueList = []
            try:
                for v in value.split(","):
                    newValue = v.strip().rstrip()
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
    """
    When the script is executed then this code is ran. If there was files(not
    directories) created then 0 will be returned, else a 1 is returned.
    """
    try:
        # #######################################################################
        # Get the options from the commandline.
        # #######################################################################
        (cmdLineOpts, cmdLineArgs) = __getOptions(VERSION_NUMBER)

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

        # Create a function for the STATUS_LEVEL since not defined by python. This
        # means you can call it like the other predefined message
        # functions. Example: logging.getLogger("loggerName").status(message)
        setattr(logger, "status", lambda *args: logger.log(logging.STATUS, *args))
        streamHandler = logging.StreamHandler()
        streamHandler.setLevel(logLevel)
        streamHandler.setFormatter(logging.Formatter("%(levelname)s %(message)s"))
        logger.addHandler(streamHandler)

        # #######################################################################
        # Set the logging levels based on user options.
        # #######################################################################
        if ((cmdLineOpts.enableDebugLogging) and (not cmdLineOpts.disableLoggingToConsole)):
            logging.getLogger(MAIN_LOGGER_NAME).setLevel(logging.DEBUG)
            streamHandler.setLevel(logging.DEBUG)
            message = "Debugging has been enabled."
            logging.getLogger(MAIN_LOGGER_NAME).debug(message)
        if (cmdLineOpts.disableLoggingToConsole):
            streamHandler.setLevel(logging.CRITICAL)
        # The option -c and -r cannot be used at the same time.
        if ((len(cmdLineOpts.listOfContainers) > 0) and (len(cmdLineOpts.listOfResolutions) > 0)):
            message = "The option \"-c\" and \"-r\" cannot be used at the same time."
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            sys.exit(1)
        # #######################################################################
        # Verfiy that a valid file was passed to it.
        # #######################################################################
        pathToCSVFile = cmdLineOpts.pathToCSVFile
        if (not len(pathToCSVFile) > 0):
            message = "There was no path given as an argument."
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            message = "A path to a exported .csv file of Plex metadata is required."
            logging.getLogger(MAIN_LOGGER_NAME).info(message)
            sys.exit(1)

        if (not os.path.isfile(pathToCSVFile)):
            message = "The argument %s is not a file." %(pathToCSVFile)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            message = "A path to a exported .csv file of Plex metadata is required."
            logging.getLogger(MAIN_LOGGER_NAME).info(message)
            sys.exit(1)

        # Verify the .cvs has a header with the required fields and set the type of metadata.
        metadataType = ""
        try:
            with open(pathToCSVFile, "r") as f:
                metadataFieldsInFile = f.readline().strip().replace("\"", "").split(",")
                # Verify the metadata fields are in the files and find out if movie or tvshow.
                missing_metadata_fields = ""
                if (not set(METADATA_FIELDS_TV_SHOW).isdisjoint(metadataFieldsInFile)):
                    metadataType = "tvshow"
                    for mf in (METADATA_FIELDS + METADATA_FIELDS_TV_SHOW):
                        if (not mf in metadataFieldsInFile):
                            missing_metadata_fields += "\"%s\", " %(mf)
                elif (not set(METADATA_FIELDS_MOVIE).isdisjoint(metadataFieldsInFile)):
                    metadataType = "movie"
                    for mf in (METADATA_FIELDS + METADATA_FIELDS_MOVIE):
                        if (not mf in metadataFieldsInFile):
                            missing_metadata_fields += "\"%s\", " %(mf)

                if (len(missing_metadata_fields) > 0):
                    message = "The following metadata fields were not in the file %s: %s." %(pathToCSVFile, missing_metadata_fields.rstrip(", "))
                    logging.getLogger(MAIN_LOGGER_NAME).error(message)
                    message = "A path to a exported .csv file of Plex metadata is required."
                    logging.getLogger(MAIN_LOGGER_NAME).info(message)
                    sys.exit(1)

        except IOError:
            message = "There was an error reading the file: %s" %(pathToCSVFile)
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            sys.exit(1)
        finally:
            f.close()
        # #######################################################################
        #  Read the file and create a map of objects.
        # #######################################################################
        message = "Analyzing the .csv file: %s" %(pathToCSVFile)
        logging.getLogger(MAIN_LOGGER_NAME).info(message)

        if (metadataType == "tvshow"):
            mapOfTVShows = __parseTVShows(pathToCSVFile)
            if (not len(mapOfTVShows) > 0):
                message = "There was no results to print."
                logging.getLogger(MAIN_LOGGER_NAME).info(message)
            else:
                __printTVShows(mapOfTVShows, cmdLineOpts.listOfResolutions, cmdLineOpts.listOfContainers, cmdLineOpts.disableHighlightingRows)
        elif (metadataType == "movie"):
            listOfMovies = __parseMovies(pathToCSVFile)
            if (not len(listOfMovies) > 0):
                message = "There was no results to print."
                logging.getLogger(MAIN_LOGGER_NAME).info(message)
            else:
                __printMovies(listOfMovies, cmdLineOpts.listOfResolutions, cmdLineOpts.listOfContainers, cmdLineOpts.disableHighlightingRows)
        else:
            message = "Unknown metadata type. Currently only supporting TV Shows metadata in a csv file."
            logging.getLogger(MAIN_LOGGER_NAME).error(message)
            sys.exit(1)
    except KeyboardInterrupt:
        print ""
        message =  "This script will exit since control-c was executed by end user."
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        sys.exit(1)
    # #######################################################################
    # Exit the application with zero exit code since we cleanly exited.
    # #######################################################################
    sys.exit()
