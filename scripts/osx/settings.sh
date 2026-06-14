#!/opt/homebrew/bin/bash
#
# Description:
#   Apply a curated set of macOS system and Finder preferences via the `defaults` command.
#   Configures Finder behaviors (path bar, extensions, hidden files, Quick Look) and
#   other system-level view settings. Each setting takes effect immediately via killall Finder.
#
# Usage:
#   settings.sh
#
# Examples:
#   $ ./settings.sh
#

# #############################################################################################################################
# FINDER BEHAVIORS & SYSTEM VIEW
# #############################################################################################################################
# Display the absolute POSIX file paths within Finder window title banners
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true; killall Finder
# Deploy the click-to-navigate interactive Path Bar along the bottom of Finder
defaults write com.apple.finder ShowPathbar -bool true; killall Finder
# Pin structural folder hierarchies directly to the top when sorting alphabetically
defaults write com.apple.finder _FXSortFoldersFirst -bool true; killall Finder
# Force all hidden files and system dotfiles to stay permanently visible
defaults write com.apple.finder AppleShowAllFiles -bool true; killall Finder
# Enforce a global rule showing every file format extension natively
defaults write NSGlobalDomain AppleShowAllExtensions -bool true; killall Finder
# Disable the warning prompt box when manually renaming file format extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false; killall Finder
# Unlock text highlighting and copying permissions inside Quick Look windows
defaults write com.apple.finder QLEnableTextSelection -bool true; killall Finder
