#!/usr/bin/env python
"""

@author   :  Shane Bradley
@contact  :  sbradley@redhat.com
@version  :  2.01
"""
import sys
import logging
import logging.handlers

MAIN_LOGGER_NAME = "pylogger"
MAIN_LOGGER_LEVEL = logging.DEBUG
# MAIN_LOGGER_FORMAT = "%(filename)s: %(levelname)s - %(message)s"
MAIN_LOGGER_FORMAT = "%(filename)s: %(message)s"
MAIN_LOGGER_TIMESTAMP_FORMAT = "%(asctime)s %(levelname)s %(message)s"

class Syslogger :
    def __init__(self, name, logLevel) :
        self.__name = name
        self.__logLevel = logLevel

        self.__sysLogger = logging.getLogger(self.__name)
        self.setLogLevel(self.__logLevel)

        formatter = logging.Formatter(MAIN_LOGGER_FORMAT)
        handler = logging.handlers.SysLogHandler(address = '/dev/log')
        handler.setFormatter(formatter)
        self.__sysLogger.addHandler(handler)

    def getName(self):
        return self.__name

    def getLogLevel(self):
        return self.__logLevel

    def getLogger(self):
        return self.__sysLogger

    def setLogLevel(self, logLevel):
        self.__sysLogger.setLevel(logLevel)

    def log(self, message) :
        self.getLogger().log(message)
################################################################################
#Run script
################################################################################
if __name__ == "__main__":
    syslogger = Syslogger(MAIN_LOGGER_NAME, MAIN_LOGGER_LEVEL)
    import datetime
    now = datetime.datetime.now()
    message = "This is a test message from /home/sbradley/python/logger/syslogger.py at this time %s." %(now.strftime("%Y-%m-%d %H:%M"))
    logging.getLogger(MAIN_LOGGER_NAME).info(message)
    print message
    sys.exit()
################################################################################
