#!/bin/bash

# Aliases are not expanded when the shell is not interactive, unless the
# expand_aliases shell option is set using shopt. This is useful if having ssh
# execute a command.
shopt -s expand_aliases

################################################################################
# Source universal aliases
################################################################################
if [[ -f "$HOME/.aliases" ]]; then
    source "$HOME/.aliases"
fi

################################################################################
# Source platform-specific aliases
################################################################################
if [[ "$OS_TYPE" == "Linux" ]] && [[ -f "$HOME/.aliases.linux" ]]; then
    source "$HOME/.aliases.linux"
elif [[ "$OS_TYPE" == "Darwin" ]] && [[ -f "$HOME/.aliases.macos" ]]; then
    source "$HOME/.aliases.macos"
fi

################################################################################
# Source in various other aliases
################################################################################
# For private aliases that will only reside on this machine
if [[ -f "$HOME/.bashrc.priv" ]]; then
    source "$HOME/.bashrc.priv"
fi
