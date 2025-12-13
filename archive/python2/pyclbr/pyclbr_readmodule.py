#!/usr/bin/python
# Code is from: http://pymotw.com/2/pyclbr/

import pyclbr
import os
from operator import itemgetter

def show_class(name, class_data):
    print 'Class:', name
    print '\tFile: {0} [{1}]'.format(os.path.basename(class_data.file), class_data.lineno)
    show_super_classes(name, class_data)
    show_methods(name, class_data)
    print
    return

def show_methods(class_name, class_data):
    for name, lineno in sorted(class_data.methods.items(), key=itemgetter(1)):
        print '\tMethod: {0} [{1}]'.format(name, lineno)
    return

def show_super_classes(name, class_data):
    super_class_names = []
    for super_class in class_data.super:
        if super_class == 'object':
            continue
        if isinstance(super_class, basestring):
            super_class_names.append(super_class)
        else:
            super_class_names.append(super_class.name)
    if super_class_names:
        print '\tSuper classes:', super_class_names
    return

def summarize(module_name):
    data = pyclbr.readmodule(module_name)
    # Need to do some error checking and catch exception on not finding module_name.
    print "Module Name: %s" %(module_name)
    for name, class_data in sorted(data.items(), key=lambda x:x[1].lineno):
        show_class(name, class_data)
# ###############################################################################
# Main Function
# ###############################################################################
if __name__ == "__main__":
    # Need to make sure in python path or pyclbr will not see it.
    module_name = "sos.plugins"
    summarize(module_name)

    print "\n-----------------------------\n"

    module_name = "sos.policies"
    summarize(module_name)

    print "\n-----------------------------\n"
    module_name = "sos.policies.redhat"
    summarize(module_name)

    """
    import sos
    import sos.plugins
    import os
    import os.path
    (basename, filename) = os.path.split(sos.__file__)

    for i in os.listdir(basename):
        print i
        # strip ext off and skip __init__.py and dirs
    """
