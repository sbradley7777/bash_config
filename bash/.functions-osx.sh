#!/bin/bash
# Functions that are for osx.

# Manually remove a downloaded app or file from the quarantine
unquarantine() {
    for attribute in com.apple.metadata:kMDItemDownloadedDate com.apple.metadata:kMDItemWhereFroms com.apple.quarantine; do
        xattr -r -d "$attribute" "$@"
    done
}

# Change working directory to the top-most Finder window location
cdf() { # short for `cdfinder`
    cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')" || return
}

# iterm coloring
tab-color() {
    local red_value
    local green_value
    local blue_value
    local hex_color

    if [[ $# == 1 ]]; then
        # convert hex to decimal
        hex_color=$1
        if [[ ${hex_color:0:1} == "#" ]]; then
            # strip leading hash sign
            hex_color=${hex_color:1:6}
        fi
        if [[ ${#hex_color} == 3 ]]; then
            # handle 3-letter hex codes
            hex_color="${hex_color:0:1}${hex_color:0:1}${hex_color:1:1}${hex_color:1:1}${hex_color:2:1}${hex_color:2:1}"
        fi
        red_value=$(printf "%d" "0x${hex_color:0:2}")
        green_value=$(printf "%d" "0x${hex_color:2:2}")
        blue_value=$(printf "%d" "0x${hex_color:4:2}")
    else
        red_value=$1
        green_value=$2
        blue_value=$3
    fi
    echo -ne "\033]6;1;bg;red;brightness;$red_value\a"
    echo -ne "\033]6;1;bg;green;brightness;$green_value\a"
    echo -ne "\033]6;1;bg;blue;brightness;$blue_value\a"
}

# Functions for changing iterm2 tab colors.
# http://kendsnyder.com/tab-colors-in-iterm2-v10/
tab-red() { tab-color 203 111 111; }
tab-red-dark() { tab-color "#FF0000"; }
tab-green() { tab-color 6cc276; }
tab-yellow() { tab-color "#e8e9ac"; }
tab-blue() { tab-color 6f8ccc; }
tab-purple() { tab-color a789d4; }
tab-orange() { tab-color fbbc79; }
tab-white() { tab-color fff; }
tab-gray() { tab-color c3c3c3c; }
tab-default() { tab-color c3c3c3c; }
