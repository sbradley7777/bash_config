#!/usr/bin/env python
"""

@author   :  Shane Bradley
@contact  :  sbradley@redhat.com
@version  :
"""
import sys
import MySQLdb
import logging
import random
from optparse import OptionParser, Option

from sx.logwriter import LogWriter

class MysqlConnect:
    MAIN_LOGGER_NAME = "sx"
    MAIN_LOGGER_FORMAT = "%(levelname)s %(message)s"

    def __init__(self, hostname, username, password, databaseName) :
        self.__hostname = hostname
        self.__username = username
        self.__password = password
        self.__databaseName = databaseName

    def connect(self) :
        message = "Connecting to the mysql server with these args:"
        message += "\n\thostname: %s\n\tdatabase: %s \n\tusername: %s\n\tpassword: %s" %(self.__hostname,
                                                                                        self.__databaseName,
                                                                                        self.__username,
                                                                                        self.__password)
        logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).info(message)
        conn = None
        try:
            conn = MySQLdb.connect(host = self.__hostname,
                                   port = 3306,
                                   user = self.__username,
                                   passwd = self.__password,
                                   db = self.__databaseName)
        except MySQLdb.Error, e:
            message = "%d: %s" % (e.args[0], e.args[1])
            logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).error(message)
        return conn

    def getServerVersion(self, conn) :
        cursor = conn.cursor()
        cursor.execute("SELECT VERSION()")
        version = cursor.fetchone()[0]
        # close the connection
        cursor.close()
        return version

    def dropTablesAll(self, conn) :
        message = "Destroying all tables for this database."
        logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).log(LogWriter.STATUS_LEVEL, message)
        cursor = conn.cursor()
        result = cursor.execute("SHOW TABLES");
        print result
        cursor.close()

    def dropTable(self, conn, tableName) :
        message = "Destroying table if it exists: %s" %(tableName)
        logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).log(LogWriter.STATUS_LEVEL, message)
        cursor = conn.cursor()
        cursor.execute("DROP TABLE IF EXISTS %s" %(tableName))
        cursor.close()

    def createTable(self, conn, tableName, numOfCols) :
        self.dropTable(conn, tableName)
        message = "Creating the table: %s" %(tableName)
        logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).log(LogWriter.STATUS_LEVEL, message)
        cursor = conn.cursor()
        cursor.execute("CREATE TABLE %s (id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT)" %(tableName))
        for i in range(0, numOfCols) :
            cursor.execute("ALTER TABLE %s ADD (randomNumber%s INT)" %(tableName, i))
        # close the connection
        cursor.close()

    def populateTable(self, conn, tableName, numOfRows, numOfCols, statusInterval):
        message = "Populating the table: %s" %(tableName)
        logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).log(LogWriter.STATUS_LEVEL, message)
        cursor = conn.cursor()
        columnNames = ""
        columnValues = ""
        for i in range(0,numOfCols) :
            columnNames += "randomNumber%s" %(str(i))
            columnValues += "%s" %(str(random.randint(1, 1000)))
            if (i < numOfCols - 1) :
                columnNames += ", "
                columnValues += ", "
        for i in range(0, numOfRows) :
            if (not ( i % statusInterval)) :
                message = "Creating entry %s" %(i)
                logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).log(LogWriter.STATUS_LEVEL, message)
            cursor.execute("INSERT INTO %s (%s) VALUES (%s)" %(tableName, columnNames, columnValues))
        # close the connection
        cursor.close()
        message= "Finished creating table that has %s Cols and %s Rows called: %s" %(numOfCols, numOfRows, tableName)
        logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).info(message)


################################################################################
# Get user selected options
################################################################################
def getOptions() :
    """
    This function creates the OptionParser and returns the commandline
    option dictionary and commadline args array.

    @return: Returns commandline option and command args. Returns 2
    variables.
    @rtype: Dictionary
    """
    cmdParser = OptionParser()
    cmdParser.add_option("-a", "--address",
                         action="store",
                         dest="address",
                         help="The address or hostname of the mysql server(Default: localhost).",
                         type="string",
                         default="localhost")
    cmdParser.add_option("-u", "--username",
                         action="store",
                         dest="username",
                         help="The username for the mysql server(Default: root).",
                         type="string",
                         default="")
    cmdParser.add_option("-p", "--password",
                         action="store",
                         dest="password",
                         help="The password for the mysql server(Default: redhat).",
                         type="string",
                         default="")
    cmdParser.add_option("-d", "--database_name",
                         action="store",
                         dest="databaseName",
                         help="Name of the database that will be usedand created if it does not exist(Default: test).",
                         type="string",
                         default="test")
    cmdParser.add_option("-t", "--table_name",
                         action="store",
                         dest="tableName",
                         help="The name that will be the prefix for each table create(Default: Gozilla).",
                         type="string",
                         default="Gozilla")
    cmdParser.add_option("-T", "--num_tables",
                         action="store",
                         dest="numOfTables",
                         help="The number of tables that will be created(Default: 5).",
                         type="int",
                         default=5)
    cmdParser.add_option("-C", "--num_cols",
                         action="store",
                         dest="numOfCols",
                         help="The number of columns that will be created for each tables(Default: 100).",
                         type="int",
                         default=100)
    cmdParser.add_option("-R", "--num_rows",
                         action="store",
                         dest="numOfRows",
                         help="The number of rows that will be created for each tables(Default: 100).",
                         type="int",
                         default=100)
    cmdParser.add_option("-S", "--status_interval",
                         action="store",
                         dest="statusInterval",
                         help="This is the interval that a status message will be logged after X number of rows is created, where X is status interval(Default: 10).",
                         type="int",
                         default=10)

    (cmdLineOpts, cmdLineArgs) = cmdParser.parse_args()
    return (cmdLineOpts, cmdLineArgs)


################################################################################
#Run script
################################################################################
if __name__ == "__main__":
    # #######################################################################
    # Setup the logger and get options
    # #######################################################################
    lwObjMC = LogWriter(MysqlConnect.MAIN_LOGGER_NAME,
                         logging.INFO,
                         MysqlConnect.MAIN_LOGGER_FORMAT,
                         disableConsoleLog=False)

    # #######################################################################
    # TODO:
    # #######################################################################
    # create new db
    # clean db option

    # #######################################################################
    # Get the options from the cmdline
    # #######################################################################
    (cmdLineOpts, cmdLineArgs) = getOptions()
    address = cmdLineOpts.address
    username = cmdLineOpts.username
    password = cmdLineOpts.password

    databaseName = cmdLineOpts.databaseName
    tableName = cmdLineOpts.tableName
    numOfTables = cmdLineOpts.numOfTables
    numOfCols = cmdLineOpts.numOfCols
    numOfRows = cmdLineOpts.numOfRows
    statusInterval = cmdLineOpts.statusInterval
    # #######################################################################

    mc = MysqlConnect(address, username, password, databaseName)
    conn = mc.connect()
    message = "MySQL Server Version:  %s" %(mc.getServerVersion(conn))
    logging.getLogger(MysqlConnect.MAIN_LOGGER_NAME).info(message)

    mc.dropTablesAll(conn)
    for i in range(0, numOfTables) :
        currentTableName = "%s%s" %(tableName, str(i))
        mc.createTable(conn, currentTableName, numOfCols)
        mc.populateTable(conn, currentTableName, numOfRows, numOfCols, statusInterval)

    # Close the connection to the MySQL database
    conn.close()

