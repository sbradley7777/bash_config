#!/bin/sh
# Preferences Configurations of OSX.
# Main osx-for-hackers.sh: https://gist.github.com/brandonb927/3195465
# Another example for osx-for-hackers.sh: https://github.com/diimdeep/dotfiles/blob/master/osx/configure/yosemite/osx_set_defaults.sh
# Another example for osx-for-hackers.sh: https://github.com/diimdeep/dotfiles/blob/master/osx/configure/yosemite/osx_set_defaults.sh
# Another example for osx-for-hackers.sh: https://gist.github.com/MatthewMueller/e22d9840f9ea2fee4716
# Useful examples and what osx-for-hackers.sh based on: https://github.com/mathiasbynens/dotfiles/blob/master/.osx
# Yosemite hiddle utilies link: https://github.com/diimdeep/dotfiles/blob/master/osx/configure/yosemite/link_hidden_utilities
# OSX Lion Tweaks: http://knoopx.net/2011/10/28/os-x-lion-tweaks

# TODO:
# * Add the osx-prefs.sh items to here.
# * Test this code first
# * Get rid of questions or set an auto yes in there option.
# * Add these chrome setting to disable swipe back/forward:
#   defaults write com.google.Chrome.plist AppleEnableSwipeNavigateWithScrolls -bool FALSE
#   defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool FALSE
# Add recent applications in dock
# * defaults write com.apple.dock persistent-others -array-add '{"tile-data" = {"list-type" = 1;}; "tile-type" = "recents-tile";}'; killall Dock

# Source in the color functions and colors
source ~/.functions.sh;

# Set continue to false by default
CONTINUE=false

echo ""
cecho "###############################################" $red
cecho "#        DO NOT RUN THIS SCRIPT BLINDLY       #" $red
cecho "#         YOU'LL PROBABLY REGRET IT...        #" $red
cecho "#                                             #" $red
cecho "#              READ IT THOROUGHLY             #" $red
cecho "#         AND EDIT TO SUIT YOUR NEEDS         #" $red
cecho "###############################################" $red
echo ""

echo ""
cecho "Have you read through the script you're about to run and " $red
cecho "understood that it will make changes to your computer? (y/n)" $red
read -r response
case $response in
  [yY]) CONTINUE=true
      break;;
  *) break;;
esac

if ! $CONTINUE; then
  # Check if we're continuing and output a message if not
  cecho "Please go read the script, it only takes a few minutes" $red
else
  # Here we go.. ask for the administrator password upfront and run a
  # keep-alive to update existing `sudo` time stamp until script has finished
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  ###############################################################################
  # General UI/UX
  ###############################################################################
  echo ""
  echo "Hide the Spotlight icon? (y/n)"
  read -r response
  case $response in
    [yY])
        sudo chmod 600 /System/Library/CoreServices/Search.bundle/Contents/MacOS/Search
        break;;
    *) break;;
  esac

  echo ""
  echo "Reveal IP address, hostname, OS version, etc. when clicking the clock in the login window? (y/n)"
  read -r response
  case $response in
    [yY])
	  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName;
        break;;
    *) break;;
  esac

  echo ""
  echo "Check for software updates daily, not just once per week? (y/n)"
  read -r response
  case $response in
    [yY])
	  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1;
        break;;
    *) break;;
  esac

  echo ""
  echo "Removing duplicates in the 'Open With' menu? (y/n)"
  read -r response
  case $response in
    [yY])
	  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user;
        break;;
    *) break;;
  esac

  echo ""
  echo "Disable crash reporter dialog box? (y/n)"
  read -r response
  case $response in
      defaults write com.apple.CrashReporter DialogType -string "none"
      break;;
      *) break;;
  esac

  echo ""
  echo "Disable dashboard from starting on boot? (y/n)"
  read -r response
  case $response in
      defaults write com.apple.dashboard mcx-disabled -boolean YES
      break;;
      *) break;;
  esac

  ###############################################################################
  # Screen
  ###############################################################################
  echo ""
  echo "Requiring password immediately after sleep or screen saver begins"
  read -r response
  case $response in
    [yY])
	  defaults write com.apple.screensaver askForPassword -int 1;
	  defaults write com.apple.screensaver askForPasswordDelay -int 0;
        break;;
    *) break;;
  esac

  echo "";
  echo "Where do you want screenshots to be stored? (hit ENTER if you want ~/Desktop as default)";
  read screenshot_location
  if [ -z "$1" ]
  then
    echo ""
    echo "Setting location to ~/Desktop"
    defaults write com.apple.screencapture location -string "$HOME/Desktop";
  else
    echo ""
    echo "Setting location to ~/$screenshot_location"
    defaults write com.apple.screencapture location -string "$HOME/$screenshot_location"
  fi

  echo ""
  echo "What format should screenshots be saved as? (hit ENTER for PNG, options: BMP, GIF, JPG, PDF, TIFF) "
  read screenshot_format
  if [ -z "$1" ]
  then
    echo ""
    echo "Setting screenshot format to PNG"
    defaults write com.apple.screencapture type -string "png"
  else
    echo ""
    echo "Setting screenshot format to $screenshot_format"
    defaults write com.apple.screencapture type -string "$screenshot_format"
  fi

  ###############################################################################
  # Finder
  ###############################################################################
  echo ""
  echo "Do not hid the ~/Library directory? (y/n)"
  case $response in
    [yY])
	  chflags nohidden ~/Library;
      break;;
    *) break;;
  esac

  echo ""
  echo "Do not open Finder window on mounted disk images? (y/n)"
  case $response in
    [yY])
	  defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool false
	  defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool false
      break;;
    *) break;;
  esac

  echo ""
  echo "Show icons for hard drives, servers, and removable media on the desktop? (y/n)"
  case $response in
    [yY])
      defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
      break;;
    *) break;;
  esac

  echo ""
  echo "Show hidden files in Finder by default? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.Finder AppleShowAllFiles -bool true
      break;;
    *) break;;
  esac

  echo ""
  echo "Show dotfiles in Finder by default? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.finder AppleShowAllFiles TRUE
      break;;
    *) break;;
  esac

  echo ""
  echo "Show all filename extensions in Finder by default? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write NSGlobalDomain AppleShowAllExtensions -bool true
      break;;
    *) break;;
  esac

  echo ""
  echo "Show status bar in Finder by default? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.finder ShowStatusBar -bool true
      break;;
    *) break;;
  esac

  echo ""
  echo "Display full POSIX path as Finder window title? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
      break;;
    *) break;;
  esac

  echo ""
  echo "Disable the warning when changing a file extension? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
      break;;
    *) break;;
  esac

  echo ""
  echo "Use column view in all Finder windows by default? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.finder FXPreferredViewStyle Clmv
      break;;
    *) break;;
  esac

  echo ""
  echo "Avoid creation of .DS_Store files on network volumes? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
      break;;
    *) break;;
  esac

  echo ""
  echo "Disable disk image verification? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.frameworks.diskimages skip-verify -bool true
      defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
      defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
      break;;
    *) break;;
  esac

  echo ""
  echo "Enable airdrop on all network interfaces? (y/n)"
  read -r response
  case $response in
      defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
      break;;
      *) break;;
  esac

  # echo ""
  # echo "Allowing text selection in Quick Look/Preview in Finder by default"
  # defaults write com.apple.finder QLEnableTextSelection -bool true

  # echo ""
  # echo "Enabling snap-to-grid for icons on the desktop and in other icon views"
  # /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
  # /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
  # /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

  ###############################################################################
  # Dock & Mission Control
  ###############################################################################
  # echo ""
  # echo "Setting the icon size of Dock items to 36 pixels for optimal size/screen-realestate"
  # defaults write com.apple.dock tilesize -int 36

  # echo ""
  # echo "Speeding up Mission Control animations and grouping windows by application"
  # defaults write com.apple.dock expose-animation-duration -float 0.1
  # defaults write com.apple.dock "expose-group-by-app" -bool true

  echo ""
  echo "Set Dock to auto-hide and remove the auto-hiding delay? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.dock autohide -bool true
      defaults write com.apple.dock autohide-delay -float 0
      defaults write com.apple.dock autohide-time-modifier -float 0
      break;;
    *) break;;
  esac

  ###############################################################################
  # Mail
  ###############################################################################
  echo ""
  echo "Set email addresses to copy as 'foo@example.com' instead of 'Foo Bar <foo@example.com>' in Mail.app? (y/n)"
  read -r response
  case $response in
    [yY])
	  defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
    break;;
    *) break;;
  esac
  ###############################################################################
  # Messages                                                                    #
  ###############################################################################
  echo ""
  echo "Disable automatic emoji substitution in Messages.app? (i.e. use plain text smileys) (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false
      break;;
    *) break;;
  esac

  echo ""
  echo "Disable smart quotes in Messages.app? (it's annoying for messages that contain code) (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false
      break;;
    *) break;;
  esac

  echo ""
  echo "Disable continuous spell checking in Messages.app? (y/n)"
  read -r response
  case $response in
    [yY])
      defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false
      break;;
    *) break;;
  esac

  #################################################################################
  # Power Saving Setting
  #################################################################################
  echo ""
  echo "Disable restore on logout, poweroff, reboot by unchecking the checkbox? (y/n)"
  read -r response
  case $response in
      # Disable restore on logout, poweroff, reboot by unchecking the checkbox
      defaults write com.apple.loginwindow TALLogoutSavesState -bool false
      defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
      # Disable sleep from hitting powerbutton cause I do all the time cause it ablve
      # delete: http://hints.macworld.com/article.php?story=20140305140635280
      defaults write com.apple.loginwindow PowerButtonSleepsSystem -bool no
      break;;
    *) break;;
  esac

  #################################################################################
  # Disables resume all apps
  #################################################################################
  echo ""
  echo "Disable resume of Preview, Quicktime, TextEdit, Safari apps and system-wide? (y/n)"
  read -r response
  case $response in
      #Disable resume system-wide.
      defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
      # Disable restore on apps.
      defaults write com.apple.Preview NSQuitAlwaysKeepsWindows -bool false
      defaults write com.apple.QuickTimePlayerX NSQuitAlwaysKeepsWindows -bool false
      defaults write com.apple.TextEdit NSQuitAlwaysKeepsWindows -bool false
      defaults write com.apple.Safari NSQuitAlwaysKeepsWindows -bool false
      break;;
    *) break;;
  esac

  ###############################################################################
  # Kill affected applications
  ###############################################################################
  echo ""
  cecho "Done!" $cyan
  echo ""
  echo ""
  cecho "################################################################################" $white
  echo ""
  echo ""
  cecho "Note that some of these changes require a logout/restart to take effect." $red
  cecho "Killing some open applications in order to take effect." $red
  echo ""

  find ~/Library/Application\ Support/Dock -name "*.db" -maxdepth 1 -delete
  for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "cfprefsd" \
    "Dock" "Finder" "Mail" "Messages" "Safari" "SystemUIServer" \
    "Terminal"; do
    killall "${app}" > /dev/null 2>&1
  done

  # End
fi
exit;
