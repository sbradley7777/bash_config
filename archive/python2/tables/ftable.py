#!/usr/bin/env python
"""
This function returns a formatted table as a string.

Based on this function: http://ginstrom.com/scribbles/2007/09/04/pretty-printing-a-table-in-python/

@author   :  Shane Bradley
@contact  :  sbradley@redhat.com
@version  :  1.00
"""
import sys
import locale
locale.setlocale(locale.LC_NUMERIC, "")

def tableize(table, header):
    if (not len(table) > 0):
        return ""

    table.insert(0, header)
    def format_num(num):
        try:
            inum = int(num)
            return locale.format("%.*f", (0, inum), True)
        except (ValueError, TypeError):
            return str(num)

    def get_max_width(table, index):
        return max([len(format_num(row[index])) for row in table])
    col_paddings = []

    for i in range(len(table[0])):
        col_paddings.append(get_max_width(table, i))

    ftable = ""
    for row in table:
        # left col
        ftable += str(row[0].ljust(col_paddings[0] + 1))
        # rest of the cols
        for i in range(1, len(row)):
            col = format_num(row[i]).rjust(col_paddings[i] + 2)
            ftable += str(col)
        ftable += "\n"
    return ftable

################################################################################
#Run script
################################################################################
if __name__ == "__main__":
    table = [["shane", 13], ["bob", 12]]
    print tableize(table, ["name", "shoesize"])
    sys.exit()
