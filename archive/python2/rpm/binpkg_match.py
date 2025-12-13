#!/usr/bin/python

import sys
from rpm import TransactionSet
from rpm import RPMTAG_NAME
from rpm import RPMTAG_BASENAMES
def match_bin_with_pkg(binary):
    """
    Match given binary to its RPM package
    """
    ts = TransactionSet()
    mi = ts.dbMatch(RPMTAG_BASENAMES, binary)
    return [x[RPMTAG_NAME] for x in mi]

def print_packages(packages):
    if (not len(packages) > 0):
        print "No packages found for binary: %s" %(path_to_binary)
    else:
        for pkg in packages:
            print pkg

# ###############################################################################
# Main Function
# ###############################################################################
if __name__ == "__main__":
    path_to_binary = "/usr/bin/ls"
    print_packages(match_bin_with_pkg(path_to_binary))
    print
    path_to_binary = "/usr/bin/foobar"
    print_packages(match_bin_with_pkg(path_to_binary))
    sys.exit()
