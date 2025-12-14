#!/bin/bash
# .bash_profile

################################################################################
# Environment Variables
################################################################################
export VISUAL="emacs -nw"
export EDITOR="$VISUAL"

TODAY=$(date '+%F_%s')
export TODAY

# GREP_OPTIONS no longer supported on fedora and have to use aliases.
export GREP_COLOR='0;31'

################################################################################
# History preferences
################################################################################
# Set to empty variable to have unlimited size.
export HISTSIZE=
export HISTFILESIZE="$HISTSIZE"
export HISTCONTROL=ignoredups
if [[ $(id -u) -eq 0 ]]; then
    export HISTTIMEFORMAT="%h %d %H:%M:%S | # "
else
    export HISTTIMEFORMAT="%h %d %H:%M:%S | $ "
fi

# Make some commands not show up in history
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# Append to the Bash history file, rather than overwriting it.
shopt -s histappend
# The second line calls history -a every time the prompt is shown, which
# essentially appends the last command to the history file.
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

################################################################################
# Man preferences
################################################################################
# Highlight section titles in manual pages
export LESS_TERMCAP_md="$ORANGE"
# Don't clear the screen after quitting a manual page
export MANPAGER="less -X"

################################################################################
# Variables used in loading of bash configuration
################################################################################
# The variable used for OS detection.
unamestr=$(uname)

################################################################################
# Bash shell preferences and function import
################################################################################
source "$HOME/.functions.sh"

# Autocorrect typos in path names when using `cd`.
shopt -s cdspell

if [[ "$unamestr" == 'Darwin' ]]; then
    # Case-insensitive globbing (used in pathname expansion).
    shopt -s nocaseglob
    source "$HOME/.functions-osx.sh"
fi

################################################################################
# Change PS prompt if root, else set as normal user
################################################################################
if [[ $(id -u) -eq 0 ]]; then
    # tput sgr0 - turns off attributes and returns text to normal state.
    # export PS1='\[\033[01;36m\]\u@\h\[\033[00m\]:\[\033[01;33m\]\W\[\033[00m\]\$ '
    PS1="\[\033[01;36m\]\u@\h\[\033[00m\] [\t]:\[\033[01;33m\]\w\[\033[00m\]\n\\$ \[$(tput sgr0)\]"
    export PS1
else
    # export PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;33m\]\W\[\033[00m\]\$ '
    PS1="\[\033[01;31m\]\u@\h\[\033[00m\] [\t]:\[\033[01;33m\]\w\[\033[00m\]\n\\$ \[$(tput sgr0)\]"
    export PS1
fi
################################################################################
# Set color variables
################################################################################
# Enable color output
export CLICOLOR=1
# Linux uses LS_COLORS -  http://www.arwin.net/tech/bash.php but we can use
# dircolors to make it easier to manage.
dircolors_config=/etc/DIR_COLORS
if [[ -f "$dircolors_config" ]]; then
    test -r "$dircolors_config" && eval "$(dircolors "$dircolors_config")"
else
    export LS_COLORS='no=00:fi=00:di=01;36:ln=01;34:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
fi
# OSX uses LSCOLORS - http://softwaregravy.wordpress.com/2010/10/16/ls-colors-for-mac/
export LSCOLORS="GxExcxdxcxegedabagacad"

################################################################################
# PATH variable
################################################################################
if [[ -d "$HOME/bin" ]]; then
    # export all directories under ~/bin that are symbolic links. There is no
    # error checking for if link is file or directory.
    export PATH="$PATH:$HOME/bin"
    for dir in "$HOME"/bin/*; do
        if [[ -d "$dir" ]]; then
            case "$dir" in
                *.org) continue;;
                *)PATH="$PATH:$dir";;
            esac
        fi
    done
fi
# Ensure user-installed binaries take precedence, for stuff like brew on osx.
if [[ "$unamestr" == 'Darwin' ]]; then
    export PATH="/usr/local/bin:$PATH"
fi

################################################################################
# Use bash-completion, if available
################################################################################
if [[ "$unamestr" == 'Linux' ]]; then
    if [[ -f /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
    if [[ -f /usr/bin/src-hilite-lesspipe.sh ]]; then
        # yum -y install source-highlight
        export LESSOPEN="| /usr/bin/src-hilite-lesspipe.sh %s"
        export LESS=' -R '
        # -J adds extra line to start which is problem with copy/paste.
        alias less_nl='less -m -N -g -i --underline-special --SILENT'
        alias less='less -m -g -i --SILENT'
        # Use "highlight" in place of "cat"
        alias cathl='/usr/bin/src-hilite-lesspipe.sh'
    fi
elif [[ "$unamestr" == 'Darwin' ]]; then
    # !!! bash-completion takes too long to build index, so disabling for now. !!!
    #
    # The package bash-completion will need to be installed with brew and the
    # configuration files will be located here /usr/local/etc/bash_completion.d
    # on OSX.
    #if [[ $(type brew &> /dev/null) -eq "0" ]] ; then
    #    if [[ -f $(brew --prefix)/etc/bash_completion ]]; then
    #        source "$(brew --prefix)/etc/bash_completion"
            # Add tab completion for `defaults read|write NSGlobalDomain`.
    #        complete -W "NSGlobalDomain" defaults
            # Add `killall` tab completion for common apps
    #        complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall
    #    fi
    #fi
    if [[ -f "$(brew --prefix)/bin/src-hilite-lesspipe.sh" ]]; then
        # yum -y install source-highlight. May have to create a symlink for
        LESSOPEN="| $(brew --prefix)/bin/src-hilite-lesspipe.sh %s"
        export LESSOPEN
        export LESS=' -R '
        alias less_nl='less -m -N -g -i -J --underline-special --SILENT'
        alias less='less -m -g -i -J --SILENT'
        # Use "highlight" in place of "cat"
        brew_prefix=$(brew --prefix)
        # shellcheck disable=SC2139
        alias cathl="${brew_prefix}/bin/src-hilite-lesspipe.sh"
    fi
fi

################################################################################
# Build own hosts file and auto completion
################################################################################
# Build hostname autocomplete
if [[ ! -d "$HOME/.ssh" ]]; then
    mkdir "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi
if [[ ! -f "$HOME/.ssh/known_hosts" ]]; then
    touch "$HOME/.ssh/known_hosts"
fi

complete -o bashdefault -o default -o nospace -F _complete_hosts ssh 2>/dev/null \
    || complete -o default -o nospace -F _complete_hosts ssh

################################################################################
# Create the global hook tempate directory
################################################################################
if [[ ! -d "$HOME/.git-templates/hooks" ]]; then
    mkdir -p "$HOME/.git-templates/hooks"  &> /dev/null
fi

################################################################################
# Source in the .bash_profile.priv for private configuration
################################################################################
if [[ -f "$HOME/.bash_profile.priv" ]]; then
    source "$HOME/.bash_profile.priv"
fi

################################################################################
# Source in the .bashrc for alias and such
################################################################################
if [[ -f "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi
# For iterm2
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

################################################################################
# Print uptime to console.
echo ""
echo "uptime: $(uptime)"
