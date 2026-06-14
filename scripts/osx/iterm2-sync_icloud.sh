#!/opt/homebrew/bin/bash
#
# Description:
#   Configure iTerm2 to save and load its preferences (including all profiles) from
#   iCloud Drive. On first run, copies existing local settings to iCloud so nothing
#   is lost. On a new machine, running this script and restarting iTerm2 is all that
#   is needed to restore the full configuration. Ends with a verification section
#   confirming the sync is correctly configured.
#
# CLI Verification:
#   Confirm preference keys are set:
#     $ defaults read com.googlecode.iterm2 PrefsCustomFolder
#     $ defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder
#   Confirm plist exists in iCloud and check its modification time:
#     $ ls -lh ~/Library/Mobile\ Documents/com~apple~CloudDocs/iTerm2/
#   After quitting iTerm2, the plist timestamp should update — confirming writes are landing:
#     $ stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" ~/Library/Mobile\ Documents/com~apple~CloudDocs/iTerm2/com.googlecode.iterm2.plist
#
# Fresh Install / Restore:
#   1. Sign in to iCloud via System Settings → Apple ID and enable iCloud Drive.
#   2. Wait for iCloud Drive to finish syncing before continuing.
#   3. Install iTerm2:
#      $ brew install --cask iterm2
#   4. Run this script:
#      $ ./iterm2-sync_icloud.sh
#   5. Quit and reopen iTerm2 — all profiles and settings will be loaded from iCloud.
#
# GUI Verification:
#   1. Finder → iCloud Drive (sidebar) → iTerm2 folder → com.googlecode.iterm2.plist
#      should be present. A cloud/download icon means not yet synced; no icon means current.
#   2. iTerm2 → Cmd+, → General → Preferences tab → custom folder field should show
#      the iCloud path with the "Load preferences" checkbox ticked.
#
# Usage:
#   iterm2-sync_icloud.sh
#
# Examples:
#   $ ./iterm2-sync_icloud.sh
#

ICLOUD_ITERM2_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/iTerm2"
LOCAL_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
CLOUD_PLIST="$ICLOUD_ITERM2_DIR/com.googlecode.iterm2.plist"

# Warn if iTerm2 is running — defaults writes land after the process exits otherwise
if pgrep -x "iTerm2" > /dev/null; then
    echo "Warning: iTerm2 is currently running. Quit it after this script finishes, then reopen."
fi

# Create the iCloud target directory
mkdir -p "$ICLOUD_ITERM2_DIR"

# Initial export: copy local plist to iCloud if the cloud copy does not yet exist
if [[ -f "$LOCAL_PLIST" && ! -f "$CLOUD_PLIST" ]]; then
    cp "$LOCAL_PLIST" "$CLOUD_PLIST"
    echo "Exported existing iTerm2 settings to iCloud."
elif [[ -f "$CLOUD_PLIST" ]]; then
    echo "Cloud plist already exists — skipping initial export (restore mode)."
else
    echo "No local plist found — iTerm2 will create one in iCloud on first quit."
fi

# Point iTerm2's preference engine at the iCloud folder (use $HOME, not ~, to avoid tilde expansion issues)
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ICLOUD_ITERM2_DIR"

# Enable loading preferences from the custom folder on launch
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# Suppress the save-changes dialog on quit
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true

# Auto-save policy: 0 = automatically write changes to the custom folder on quit
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 0

echo "Done. Quit and reopen iTerm2 to activate iCloud sync."

# #############################################################################################################################
# VERIFY
# #############################################################################################################################
echo ""
echo "--- Verification ---"

# Confirm the preference keys were written correctly
echo "PrefsCustomFolder:      $(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null || echo 'NOT SET')"
echo "LoadPrefsFromCustomFolder: $(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null || echo 'NOT SET')"

# Confirm the plist file exists in iCloud and show last modified time
if [[ -f "$CLOUD_PLIST" ]]; then
    echo "Plist file:             found ($(du -h "$CLOUD_PLIST" | cut -f1), modified $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$CLOUD_PLIST"))"
else
    echo "Plist file:             NOT FOUND — quit iTerm2 once to trigger the first write"
fi
