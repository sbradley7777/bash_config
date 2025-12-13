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
from datetime import datetime,timedelta


try:
    import pygal
    from pygal.style import Style
except (ImportError, NameError):
    print "Error loading pygal."

################################################################################
#Run script
################################################################################
if __name__ == "__main__":
    # Then create a bar graph object
    bar_chart = pygal.Bar()
    # Add some values
    bar_chart.add('Fibonacci', [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55])
    # Save the svg to a file
    bar_chart.render_to_file("/redhat/html/misc/pygal/bar_chart.svg")

    funnel_chart = pygal.Funnel()
    funnel_chart.title = 'V8 benchmark results'
    funnel_chart.x_labels = ['Richards', 'DeltaBlue', 'Crypto', 'RayTrace', 'EarleyBoyer', 'RegExp', 'Splay', 'NavierStokes']
    funnel_chart.add('Opera', [3472, 2933, 4203, 5229, 5810, 1828, 9013, 4669])
    funnel_chart.add('Firefox', [7473, 8099, 11700, 2651, 6361, 1044, 3797, 9450])
    funnel_chart.add('Chrome', [6395, 8212, 7520, 7218, 12464, 1660, 2123, 8607])
    funnel_chart.render_to_file("/redhat/html/misc/pygal/funnel_chart.svg")

    line_chart = pygal.Line()
    line_chart.title = 'Browser usage evolution (in %)'
    line_chart.x_labels = map(str, range(2002, 2013))
    line_chart.add('Firefox', [None, None,    0, 16.6,   25,   31, 36.4, 45.5, 46.3, 42.8, 37.1])
    line_chart.add('Chrome',  [None, None, None, None, None, None,    0,  3.9, 10.8, 23.8, 35.3])
    line_chart.add('IE',      [85.8, 84.6, 84.7, 74.5,   66, 58.6, 54.7, 44.8, 36.2, 26.6, 20.1])
    line_chart.add('Others',  [14.2, 15.4, 15.3,  8.9,    9, 10.4,  8.9,  5.8,  6.7,  6.8,  7.5])
    line_chart.render_to_file("/redhat/html/misc/pygal/line_chart.svg")

    # DateY
    tuples = [(datetime(2016, 2, 9, 8, 10, 58), 3),
              (datetime(2016, 2, 9, 8, 11, 29), 1),
              (datetime(2016, 2, 9, 8, 11, 59), 10),
              (datetime(2016, 2, 9, 8, 12, 29), 1),
              (datetime(2016, 2, 9, 8, 12, 59), 3)]

    gstyle = Style(
        # http://www.pygal.org/en/latest/documentation/custom_styles.html
        background='white',
        plot_background='rgba(0, 0, 255, 0.03)',
        foreground='rgba(0, 0, 0, 0.8)',
        foreground_light='rgba(0, 0, 0, 0.9)',
        foreground_dark='rgba(0, 0, 0, 0.7)',
        colors=('#5DA5DA', '#FAA43A','#60BD68', '#F17CB0', '#4D4D4D', '#B2912F','#B276B2', '#DECF3F', '#F15854')
    )
    # human_readable is what introduce the strange Y data labels.
    graph = pygal.DateY(x_label_rotation=20, title="Test",
                        x_title="Time", y_title="Water Volume",
                        legend_at_bottom=True, human_readable=False,
                        style=gstyle, x_labels_major_every=5)
    # include_x_axis=True)
    graph.x_label_format = "%Y-%m-%d %I:%M:%S"
    #graph.add("graph1",list(zip(x,y))+[None,None])
    graph.add("graph1", tuples+[None,None])
    graph.render_to_file("/redhat/html/misc/pygal/datey-time.svg")

    sys.exit()
