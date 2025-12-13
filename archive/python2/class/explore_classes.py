#!/usr/bin/env python
"""

@author   :  Shane Bradley
@contact  :  sbradley@redhat.com
@version  :  1.00
"""
import sys
import locale
locale.setlocale(locale.LC_NUMERIC, "")


def dump(obj):
    for attr in dir(obj):
        print "obj.%s = %s" % (attr, getattr(obj, attr))

class Test():
    def __init__(self, private_var, public_var):
        self.__private_var = private_var
        self.public_var = public_var

    def __get_private_var(self):
        return self.__private_var

    def get_public_var(self):
        return self.__public_var

################################################################################
#Run script
################################################################################
if __name__ == "__main__":
    test = Test("x", "y")
    dump(test)
    sys.exit()
