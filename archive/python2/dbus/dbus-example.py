#!/usr/bin/env python
"""

@author   :  Shane Bradley
@contact  :  sbradley@redhat.com
@version  :  2.01
"""
import sys
import dbus
import gobject
from dbus import glib

class DBuser :
    def __init__(self) :
        gobject.threads_init()
        glib.init_threads()
        # Create a session bus.
        self.__bus = dbus.SessionBus()

    def run(self) :
        # Connection name --> "org.freedesktop.DBus"
        # Object's path   --> "/org/freedesktop/DBus"
        remote_object = self.__bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus")

        # Create an object that will proxy for a particular remote
        # object.
        # Get a particular interface
        # iface = dbus.Interface(remote_object, 'org.freedesktop.DBus')
        # ifaceNames = iface.ListNames()
        # for name in ifaceNames:
        #     if (name == "org.gnome.Terminal.Display_0_0") :
        #         print "FOUND --> ",  name

        terminalObject = self.__bus.get_object("org.gnome.Terminal.Display_0_0", "/org/gnome/Terminal/Factory")
        # Introspection returns an XML document containing information
        # about the methods supported by an interface.
        print ("Introspection data:\n")
        print terminalObject.Introspect()

        print
        ifaceTO = dbus.Interface(terminalObject, "org.gnome.Terminal.Display_0_0.GetAll")
        for to in ifaceTO:
            print to


################################################################################
#Run script
################################################################################
if __name__ == "__main__":
    dbuser = DBuser()
    dbuser.run()
    sys.exit()
################################################################################
