#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import sqlite3

import codecs

UTF8Writer = codecs.getwriter('utf8')
sys.stdout = UTF8Writer(sys.stdout)

conn = sqlite3.connect("memos.memobase")
#conn.row_factory = sqlite3.Row
cursor = conn.cursor()

sql = "SELECT pk,name FROM GROUPS"
cursor.execute(sql)
group_map = dict(cursor.fetchall())

sql = "SELECT name,body, groupid FROM MEMOS ORDER BY groupid DESC, name ASC"
cursor.execute(sql)
current_group_name = ""
for row in cursor.fetchall():
    group_name = "No Group Name"
    if (group_map.has_key(row[2])):
        group_name = group_map.get(row[2])
    if (not current_group_name == group_name):
        current_group_name = group_name
        print
        print "-------------------------------------------------------"
        print "               %s" %(group_name)
        print "-------------------------------------------------------"
        print
    print "%s: (group name: %s) " %(row[0], group_name)
    description = row[1]
    if (description.startswith("-")):
        description = description.replace("-", "- ")
    print description
    print
    print "--------"
    print
