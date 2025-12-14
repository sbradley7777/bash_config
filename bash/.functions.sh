#!/bin/sh

# Set the colours you can use
black='\033[0;30m'
white='\033[0;37m'
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'

# Color-echo.
# arg $1 = message
# arg $2 = Color
cecho() {
  echo "${2}${1}"
  Reset # Reset to normal.
  return
}

#  Reset text attributes to normal + without clearing screen.
alias Reset="tput sgr0"

emacsro() {
  if [ ! -z $1 ]; then
      emacs -nw "$1" --eval '(setq buffer-read-only t)';
  else
      echo "Error: A filename is required.";
  fi
}


# Check to see if command exists
command_exists () {
    type "$1" &> /dev/null ;
}

# Create a new directory and enter it
function mkd() {
    mkdir -p "$@" && cd "$@"
}

function trim_whitespaces() {
    local var=$@
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# Determine size of a file or total size of a directory
function filesize() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    if [[ -n "$@" ]]; then
        du $arg -- "$@"
    else
        du $arg .[^.]* *
    fi
}

# Use Git’s colored diff when available
hash git &>/dev/null
if [ $? -eq 0 ]; then
    function diff() {
        git diff --no-index --color-words "$@"
    }
fi

# Add bash completion for ssh: it tries to complete the host to which you
# want to connect from the list of the ones contained in ~/.ssh/known_hosts
# http://en.newinstance.it/2011/06/30/ssh-bash-completion/
# http://en.newinstance.it/2011/06/30/ssh-bash-completion/#comment-506408
_complete_hosts () {
    # http://surniaulula.com/2012/09/20/autocomplete-ssh-hostnames/
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    host_list=`{
	for c in /etc/ssh_config /etc/ssh/ssh_config ~/.ssh/config
	do [ -r $c ] && sed -n -e 's/^Host[[:space:]]//p' -e 's/^[[:space:]]*HostName[[:space:]]//p' $c
	done
	for k in /etc/ssh_known_hosts /etc/ssh/ssh_known_hosts ~/.ssh/known_hosts
	do [ -r $k ] && egrep -v '^[#\[]' $k|cut -f 1 -d ' '|sed -e 's/[,:].*//g'
	done
	sed -n -e 's/^[0-9][0-9\.]*//p' /etc/hosts; }|tr ' ' '\n'|grep -v '*'`
    COMPREPLY=( $(compgen -W "${host_list}" -- $cur))
    return 0
}
