#!/bin/bash -e


touch ~/.hammerspoon/init.lua
cd ~/.hammerspoon
git clone https://github.com/AdamWagner/stackline.git ~/.hammerspoon/stackline
echo 'stackline = require "stackline.stackline.stackline"' >> init.lua
echo 'stackline:init()' >> init.lua

# Just attempt to replicate what https://github.com/Hammerspoon/hammerspoon/blob/da2f41aa2c008c84a746ffc0d5a0d3291d6e5264/extensions/ipc/init.lua#L266 does.

if [ ! \( -e "$HOME/.local/bin/hs" \) ]
then
  ln -s /Applications/Hammerspoon.app/Contents/Resources/extensions/hs/ipc/bin/hs "$HOME/.local/bin/hs"
fi

if [ ! \( -e "/opt/homebrew/share/man/man1/hs.1" \) ]
then
  ln -s /Applications/Hammerspoon.app/Contents/Resources/extensions/hs/ipc/share/man/man1/hs.1 /opt/homebrew/share/man/man1/hs.1
fi

sed 's/\/usr\/local\/bin\/jq/\/opt\/homebrew\/bin\/jq/' "$HOME/.hammerspoon/stackline/conf.lua" \
  | sed 's/\/usr\/local\/bin\/yabai/\/opt\/homebrew\/bin\/yabai/' | \
sed 's/showIcons.*/showIcons                = false/' > "$HOME/.hammerspoon/stackline/temp-config.lua"

mv "$HOME/.hammerspoon/stackline/temp-config.lua" "$HOME/.hammerspoon/stackline/conf.lua"
