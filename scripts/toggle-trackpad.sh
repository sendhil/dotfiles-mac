#!/bin/bash -e

# Inspiration - https://itectec.com/askdifferent/macos-toggle-natural-scrolling-from-command-line-with-reload/

osascript -e 'tell application "System Preferences"
  reveal anchor "trackpadTab" of pane id "com.apple.preference.trackpad"
end tell

tell application "System Events" to tell process "System Preferences"
    click radio button 2 of tab group 1 of window 1
    click checkbox 1 of tab group 1 of window 1
end tell

quit application "System Preferences"'
