#!/usr/bin/python
"""
This script is a wrapper for fence_vmware_soap to enable debugging of suds. This
script will create a file that contains all the regular debugging and include
the debugging of "suds". The suds debugging will look like XML.

The file "/tmp/fence_vmware_soap-debug.txt" will be created that will contain
all the debugging.

Usage:
# python ./fence_vmware_soap-wrapper.py -z -a 1.1.1.42 -l username -p password --action list

@author    :  Shane Bradley
@contact   :  sbradley@redhat.com
@version   :  1.0
@copyright :  GPLv2
"""
import sys
import logging
import os.path

# Path to the debug file.
PATH_TO_DEBUG_FILE = "/tmp/fence_vmware_soap-debug.txt"
# The name of the fencing agent.
FENCE_AGENT_NAME = "fence_vmware_soap"

def getPathToFencingAgent(fenceAgentName):
        if (os.path.exists("/usr/sbin/%s" %(fenceAgentName))):
                return "/usr/sbin/%s" %(fenceAgentName)
        elif (os.path.exists("/sbin/%s" %(fenceAgentName))):
                return "/sbin/%s" %(fenceAgentName)
        else:
                return ""

if __name__ == "__main__":
        # If no args then exit
        if (len(sys.argv) == 1):
                print "ERROR: The script requires args for the fencing agent \"%s\"." %(FENCE_AGENT_NAME)
                print "Example:"
                print "  # python ./fence_vmware_soap-wrapper.py -z -a 1.1.1.42 -l username -p password --action list"
                sys.exit(1)
        # Find the fencing agent and exit if not found.
        pathToFenceAgent = getPathToFencingAgent(FENCE_AGENT_NAME)
        if (not len(pathToFenceAgent) > 0):
                print "ERROR: The fencing agent \"%s\" was not found: %s." %(FENCE_AGENT_NAME, pathToFenceAgent)
                sys.exit(1)

        # Fencing agent was found.
        print "The fencing agent \"%s\" was found: %s." %(FENCE_AGENT_NAME, pathToFenceAgent)
        # Create a logger.
        logger = logging.getLogger()
        # Create a logger handler to write output to a file.
        if (os.path.isfile(PATH_TO_DEBUG_FILE)):
                try:
                        print "Removing the file: %s" %(PATH_TO_DEBUG_FILE)
                        os.remove(PATH_TO_DEBUG_FILE)
                except OSError:
                        print "ERROR: There was an error removing the file: %s" %(PATH_TO_DEBUG_FILE)
        hdlr = logging.FileHandler(PATH_TO_DEBUG_FILE)
        formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
        hdlr.setFormatter(formatter)
        logger.addHandler(hdlr)
        # Enable debugging for the various loggers.
        logging.getLogger('suds.client').setLevel(logging.DEBUG)
        logging.getLogger('suds.transport').setLevel(logging.DEBUG) # MUST BE THIS?
        #logging.getLogger('suds.xsd.schema').setLevel(logging.DEBUG)
        #logging.getLogger('suds.wsdl').setLevel(logging.DEBUG)
        #logging.getLogger('suds.resolver').setLevel(logging.DEBUG)
        #logging.getLogger('suds.xsd.query').setLevel(logging.DEBUG)
        #logging.getLogger('suds.xsd.basic').setLevel(logging.DEBUG)
        #logging.getLogger('suds.binding.marshaller').setLevel(logging.DEBUG)

        # All suds including children. This will log everything which will
        # create lots of debugging and should not be used if possible.
        #logging.getLogger('suds').setLevel(logging.DEBUG)

        # Call fence_vmware_soap and the args passed to this command will be
        # available to main(). Make sure to include globals.
        print "Executing %s with suds debugging enabled." %(pathToFenceAgent)
        execfile(pathToFenceAgent, globals())

        if (os.path.exists(PATH_TO_DEBUG_FILE)):
                print "The debug file is located at: %s" %(PATH_TO_DEBUG_FILE)
                sys.exit()
        else:
                print "There was an error and the debug file was not created: %s" %(PATH_TO_DEBUG_FILE)
                sys.exit(1)
