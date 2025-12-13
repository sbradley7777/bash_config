#!/usr/bin/env python
# Used this file as skeleton: https://gist.github.com/leandrosilva/3651640

# ###############################################################################

import sys
from time import strftime
from pyparsing import Word, alphas, Suppress, Combine, nums, string, Optional, Regex,ParseException

class Parser(object):
  def __init__(self):
    ints = Word(nums)

    # timestamp
    month = Word(string.uppercase, string.lowercase, exact=3)
    day   = ints
    hour  = Combine(ints + ":" + ints + ":" + ints)
    timestamp = month + day + hour
    # hostname
    hostname = Word(alphas + nums + "_" + "-" + ".")
    # appname
    appname = Word(alphas + "/" + "-" + "_" + ".") + Optional(Suppress("[") + ints + Suppress("]")) + Suppress(":")
    # message
    message = Regex(".*")
    # pattern build
    self.__pattern = timestamp + hostname + appname + message

  def parse(self, line):
    line = line.strip().rstrip()
    payload = {}
    try:
      parsed = self.__pattern.parseString(line)
      if (len(parsed) == 7):
        payload["timestamp"] = strftime("%Y-%m-%d %H:%M:%S")
        payload["hostname"]  = parsed[3]
        payload["appname"]   = parsed[4]
        payload["pid"]       = parsed[5]
        payload["message"]   = parsed[6]
      elif (len(parsed) == 6):
        payload["timestamp"] = strftime("%Y-%m-%d %H:%M:%S")
        payload["hostname"]  = parsed[3]
        payload["appname"]   = parsed[4]
        payload["pid"]       = ""
        payload["message"]   = parsed[5]
        print "Only 6 items, most likely no pid: %s" %(line)
      else:
        print "ERROR: Uknown log message type: %s" %(line)
        print parsed
    except ParseException, e:
      print "ERROR: There was error parsing this line: %s." %(line)
      print e
    return payload

################################################################################
# Main
################################################################################
if __name__ == "__main__":
  parser = Parser()

  parsedLines = []
  with open('./sample.log') as syslogFile:
    for line in syslogFile:
      parsedLine = parser.parse(line)
      if (len(parsedLine.keys()) > 0):
        parsedLines.append(parsedLine)

  print "------"
  print "There was %d lines that were successfully parsed." %(len(parsedLines))
  #for parsedLine in parsedLines:
  #  print parsedLine

  sys.exit()
