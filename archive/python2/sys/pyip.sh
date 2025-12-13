#!/usr/bin/env python
"""
This classes are for cluster nodes in the sosreport/sysreport. They
represnet configs files paths and other items that are needed for all
cluster tools.

@author    :  Shane Bradley
@contact   :  sbradley@redhat.com
@version   :  1.02
@copyright :  GPL
"""
import re
import os.path

import sx

import sys
class ClusterNode:
    def getNetworkMap(self, pathToIfconfig) :
        if (not len(pathToIfconfig) > 0):
            return {}
        networkArray = []
        currentInterface = {}
        try:
            fin = open(pathToIfconfig, "r")
            #remIface = re.compile ("(^.*).*Link encap.*")
            #remIface = re.compile ("(^.*).*Link encap.*")
            remIface = re.compile ("(^.*)\sLink encap:Ethernet\s\sHWaddr\s([0-9a-z\:].*)")
            # remAddr  = re.compile(".*inet addr:([0-9\.]*)\s.*Mask:([0-9\.]*)")
            remAddr  = re.compile(".*inet addr:([\d\.]*)\s.*Mask:([\d\.]*)")
            for line in fin.readlines() :
                moIface = remIface.match(line)
                if moIface:
                    print line.strip()
                    print "MATCH IFACE : %s" % moIface.group(1)
                    print "MATCH HWADDR: %s" % moIface.group(2)

                moAddr  = remAddr.match(line)
                if moAddr:
                    #print line.strip()
                    print "MATCH ADDR  : %s" % moAddr.group(1)
                    print "MATCH MASK  : %s" % moAddr.group(2)
                    print
        except (IOError, os.error):
            message = "An i/o error occured in reading the file getting the file: \n\t%s" %(pathToIfconfig)
            logging.getLogger(sx.MAIN_LOGGER_NAME).error(message)

        else:
            fin.close()

################################################################################
#Run script
################################################################################
if __name__ == "__main__":
    pathToIfconfig = ""

    cn = ClusterNode()
    cn.getNetworkMap(pathToIfconfig)
    sys.exit()
################################################################################
