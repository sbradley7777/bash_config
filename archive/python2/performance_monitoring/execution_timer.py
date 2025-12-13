#!/usr/bin/env python
"""

@author   :  Shane Bradley
@contact  :  sbradley@redhat.com
@version  :  1.00
"""
import sys
import logging
import logging.handlers
import time

VERSION_NUMBER = "0.1-1"
MAIN_LOGGER_NAME = "execution_timer"


class ExecutionTimer(object):
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.__secs = 0
        self.__start = None
        self.__end = None

    def __enter__(self):
        self.__start = time.time()
        return self

    def __exit__(self, *args):
        if (not self.__start == None):
            self.__end = time.time()
            self.__secs = self.__end - self.__start

    def get_seconds(self):
        return self.__secs

    def get_milliseconds(self):
        return (self.get_seconds() * 1000)

def get_primes(n, sleep_seconds=1):
    if n==2:
        return [2]
    elif n<2:
        return []
    s=range(3,n+1,2)
    mroot = n ** 0.5
    half=(n+1)/2-1
    i=0
    m=3
    while m <= mroot:
        if s[i]:
            j=(m*m-3)/2
            s[j]=0
            while j<half:
                s[j]=0
                j+=m
        i=i+1
        m=2*i+3
        time.sleep(sleep_seconds)
    return [2]+[x for x in s if x]

################################################################################
#Run script
################################################################################
if __name__ == "__main__":

    try:
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

        # Please note there will not be a global log file created. If a log file
        # is needed then redirect the output. There will be a log file created
        # for each run in the corresponding directory.
        primes = "\t"
        with ExecutionTimer() as t:
            listOfPrimes = get_primes(100)
            max_columns = 10
            counter = 1
            for prime in listOfPrimes:
                primes += " %s," %(prime)
                if ((counter % max_columns) == 0):
                    primes += "\n\t"
                    counter = 0
                counter += 1
        primes = primes.rstrip().rstrip(",")
        message = "Elasped time for printing prime numbers from 0 to %s: %s seconds" %(len(listOfPrimes), t.get_seconds())
        logging.getLogger(MAIN_LOGGER_NAME).info(message)
        print "The prime numbers from 0 to %s: \n%s" %(len(listOfPrimes), primes)
    # #######################################################################
    except KeyboardInterrupt:
        print ""
        message = "This script will exit since control-c was executed by end user."
        logging.getLogger(MAIN_LOGGER_NAME).error(message)
        sys.exit(1)
    # #######################################################################
    # Exit the application with zero exit code since we cleanly exited.
    # #######################################################################
    sys.exit()
