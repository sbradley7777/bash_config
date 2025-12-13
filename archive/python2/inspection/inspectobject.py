#!/usr/bin/env python

# http://www.diveintopython.net/power_of_introspection/index.html
myObject = dict()
methodList = [method for method in dir(myObject) if callable(getattr(myObject, method))]
for method in methodList:
    print method
