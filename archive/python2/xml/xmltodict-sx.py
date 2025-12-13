#!/usr/bin/env python
"""
I found this code at: http://code.activestate.com/recipes/410469-xml-as-dictionary/
@author   :  Shane Bradley
@contact  :  sbradley@redhat.com
@version  :  1.00
"""
import sys
import os.path
from xml.etree.ElementTree import ElementTree

def parse_xml_file(path_to_xml_file):

    tree = ElementTree()
    tree.parse(path_to_xml_file)
    results = tree.findall(".//Name")
    for item in results:
        print item
        print item.text

################################################################################
#Run script
################################################################################
if __name__ == "__main__":
    path_to_xml_file= "/home/sbradley/bin/bin.priv/example.xml"
    parse_xml_file(path_to_xml_file)
    sys.exit()
################################################################################



