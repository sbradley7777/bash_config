#!/bin/bash

################################################################################
# Color Constants
################################################################################
# ANSI color codes for use with cecho() function
# Usage: cecho "message" "$red"
# shellcheck disable=SC2034  # Variables used by external callers of cecho()
black='\033[0;30m'
white='\033[0;37m'
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'

# Print colored text to stdout
# Arguments:
#   $1 - Message to print
#   $2 - Color code (use color constants above)
# Example:
#   cecho "Error occurred" "$red"
cecho() {
    echo "${2}${1}"
    Reset # Reset to normal.
    return
}

#  Reset text attributes to normal + without clearing screen.
alias Reset="tput sgr0"

# Remove timestamp from history output
# Output:
#   Prints history without timestamp columns to stdout
history_no_timestamp() {
    history | awk '{$1=$2=$3=$4=$5=""}1' | sed -e 's/^[[:space:]]*//'
}

emacsro() {
    if [[ -n "$1" ]]; then
        emacs -nw "$1" --eval '(setq buffer-read-only t)'
    else
        echo "Error: A filename is required."
    fi
}


# Check to see if command exists
command_exists() {
    type "$1" &> /dev/null
}

# Create a new directory and enter it
# Arguments:
#   $@ - Directory path to create
mkd() {
    mkdir -p "$@" && cd "$@" || return
}

# Remove leading and trailing whitespace from text
# Arguments:
#   $* - Text to trim
# Output:
#   Prints trimmed text to stdout
trim_whitespaces() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# Determine size of a file or total size of a directory
# Arguments:
#   $@ - Files or directories to measure (optional, defaults to current directory)
# Output:
#   Prints human-readable sizes to stdout
filesize() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    if [[ $# -gt 0 ]]; then
        du $arg -- "$@"
    else
        du $arg .[^.]* ./*
    fi
}

# Use Git's colored diff when available
if hash git &>/dev/null; then
    diff() {
        git diff --no-index --color-words "$@"
    }
fi

################################################################################
# Git Functions
################################################################################

# Format multiple git patches to stdout
# Arguments:
#   $@ - Git revision range (e.g., HEAD~3..HEAD)
# Output:
#   Formatted patches to stdout
# Example:
#   formpatches HEAD~3..HEAD > my-patches.patch
formpatches() {
    git format-patch --stdout "$@"
}

# Format a single git commit as a patch
# Arguments:
#   $1 - Commit hash
# Output:
#   Formatted patch to stdout
# Example:
#   formp 79984402303b01c81eb5a6825350d030e4022edd > my-patch.patch
formp() {
    git format-patch --stdout "$1~1..$1"
}

# Add bash completion for ssh: it tries to complete the host to which you
# want to connect from the list of the ones contained in ~/.ssh/known_hosts
# http://en.newinstance.it/2011/06/30/ssh-bash-completion/
# http://en.newinstance.it/2011/06/30/ssh-bash-completion/#comment-506408
_complete_hosts() {
    # http://surniaulula.com/2012/09/20/autocomplete-ssh-hostnames/
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    host_list=$({
        for c in /etc/ssh_config /etc/ssh/ssh_config ~/.ssh/config; do
            [[ -r "$c" ]] && sed -n -e 's/^Host[[:space:]]//p' -e 's/^[[:space:]]*HostName[[:space:]]//p' "$c"
        done
        for k in /etc/ssh_known_hosts /etc/ssh/ssh_known_hosts ~/.ssh/known_hosts; do
            [[ -r "$k" ]] && grep -v '^[#\[]' "$k" | cut -f 1 -d ' ' | sed -e 's/[,:].*//g'
        done
        sed -n -e 's/^[0-9][0-9\.]*//p' /etc/hosts
    } | tr ' ' '\n' | grep -v '\*')
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "${host_list}" -- "$cur"))
    return 0
}
