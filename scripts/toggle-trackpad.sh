#!/bin/bash -e

# Toggle natural scrolling via AppleScript UI automation
# Inspiration - https://itectec.com/askdifferent/macos-toggle-natural-scrolling-from-command-line-with-reload/

osascript <<'EOF'
tell application "System Settings"
	activate
end tell

delay 1

tell application "System Events"
	tell application process "System Settings"
		-- Navigate to Trackpad settings
		click menu item "Trackpad" of menu "View" of menu bar item "View" of menu bar 1
		delay 1.5

		set w to window "Trackpad"
		set sg to splitter group 1 of group 1 of w

		-- Get the last group in the splitter group (the main content area)
		set allElems to UI elements of sg
		set allGroups to {}
		repeat with elem in allElems
			if class of elem is group then
				set end of allGroups to elem
			end if
		end repeat
		set contentGroup to last item of allGroups
		set innerGroup to group 1 of contentGroup

		-- Click the "Scroll & Zoom" tab (radio button 2)
		set tabElem to UI element 3 of innerGroup
		set scrollZoomButton to radio button 2 of tabElem
		click scrollZoomButton
		delay 1

		-- Get the scroll area and find the Natural scrolling checkbox
		set scrollArea to UI element 4 of innerGroup
		set scrollGroup to group 1 of scrollArea
		set naturalScrollingCheckbox to UI element 3 of scrollGroup

		-- Toggle the checkbox
		click naturalScrollingCheckbox
		delay 0.3

		-- Close System Settings
		click menu item "Quit System Settings" of menu "System Settings" of menu bar item "System Settings" of menu bar 1

	end tell
end tell
EOF
