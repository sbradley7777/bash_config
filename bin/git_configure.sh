#!/bin/sh

#################################################################################
# Main
#################################################################################
# git config --global core.attributesfile ~/.gitattributes;
git config --global core.excludesfile ~/.gitignore;
git config --global core.editor emacs;
git config --global push.default "matching";

#################################################################################
# Set the colors
#################################################################################
git config --global color.ui true
git config --global color.status.changed "green"
git config --global color.status.added "yellow"
git config --global color.status.untracked "cyan"
git config --global color.branch.current "yellow reverse"
git config --global color.branch.local "yellow"
git config --global color.branch.remote "green"

#################################################################################
# Aliases
#################################################################################
git config --global alias.addall 'add .';
git config --global alias.commitm 'commit -m';
git config --global alias.configls 'config --list';
git config --global alias.pusho 'push origin';
git config --global alias.rebasem 'rebase master';
git config --global alias.resetm 'reset --hard origin/master';

# View the current working tree status using the short format.
git config --global alias.st status;
git config --global alias.ci 'commit -v';
# Clone a repository including all submodules
git config --global alias.c 'clone --recursive';

# View abbreviated SHA, description, and history graph of the latest 20 commits.
git config --global alias.l 'log --pretty=oneline -n 20 --graph --abbrev-commit';

# Show verbose output about tags, branches or remotes
git config --global alias.tags 'tag -l';
git config --global alias.branches 'branches -a';
git config --global alias.remotes 'remote -v';

# Pull in remote changes for the current repository and all its submodules
#p = !"git pull; git submodule foreach git pull origin master"
# Show the diff between the latest commit and the current state
#d = !"git diff-index --quiet HEAD -- || clear; git --no-pager diff --patch-with-stat"
# `git di $number` shows the diff between the state `$number` revisions ago and the current state
#di = !"d() { git diff --patch-with-stat HEAD~$1; }; git diff-index --quiet HEAD -- || clear; d"

