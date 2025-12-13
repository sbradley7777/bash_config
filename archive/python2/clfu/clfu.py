#!/usr/bin/env python
# This script queries commandlinefu.com for command examples.
# https://gist.github.com/tuxfight3r/f5543df35a5099bd3451

# Should try this way of building the url string.
# https://github.com/rlgomes/clifu/blob/master/src/clifu.py

import urllib2
import base64
import json
import os
import sys
import re

def sort_by_match(command):
    bestmatch = re.compile(r' ')
    search = bestmatch.sub('+', command)
    b64_encoded = base64.b64encode(search)
    url = "http://www.commandlinefu.com/commands/matching/" + search + "/" + b64_encoded + "/json"
    request = urllib2.Request(url, headers={ 'User-Agent': 'Mozilla/5.0' })
    response = json.load(urllib2.urlopen(request))
    print_result(response, search)

def search_by_tags(command):
    bestmatch = re.compile(r' ')
    search = bestmatch.sub('+', command)
    url = "http://www.commandlinefu.com/commands/tagged/163" + search + "/" + search + "/json"
    request = urllib2.Request(url, headers={ 'User-Agent': 'Mozilla/5.0' })
    response = json.load(urllib2.urlopen(request))
    print_result(response, search)

def print_result(rjson, command):
    for c in rjson:
        votes = c['votes']
        summary = c['summary']
        cmd = c['command']

        cmd = cmd.replace(command, ansi("cyan")+command+ansi("off"))
        cmd = re.sub(r'([!O>=(<>+@^)$*`#&{}\\\'":/|;,.?-])', ansi("yellow") + r'\1' + ansi("off"), cmd)
        cmd = cmd.replace("|", ansi("yellow")+ "|"+ ansi("off"))
        print "%sVotes: %s |  %s%s\n  %s" % (ansi("red"), votes, summary, ansi("off"), cmd)
        print "-" * 60
        
def ansi(name):
    colors = {
        "off"       :0,
        "bold"      :1,
        "italic"    :3,
        "underline" :4,
        "blink"     :5,
        "inverse"   :7,
        "hidden"    :8,
        "black"     :30,
        "red"       :31,
        "green"     :32,
        "yellow"    :33,
        "blue"      :34,
        "magenta"   :35,
        "cyan"      :36,
        "white"     :37,
        "black_bg"  :40,
        "red_bg"    :41,
        "green_bg"  :42,
        "yellow_bg" :43,
        "blue_bg"   :44,
        "magenta_bg":45,
        "cyan_bg"   :46,
        "white_bg"  :47
    }
    return "\033[%dm" % (colors[name])

# ###############################################################################
# Main Function
# ###############################################################################
if __name__ == "__main__":
    command = ""
    if (len(sys.argv) > 1):
        command = sys.argv[1]
    else:
        command = raw_input("Please enter a search command: ")

    print ""
    print "-" * 60
    print "Matched"
    print "-" * 60
    sort_by_match(command)
    print ""
    print "-" * 60
    print "Tagged"
    print "-" * 60
    search_by_tags(command)
