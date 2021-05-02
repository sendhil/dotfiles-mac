#!/bin/bash -e

# Just attempt to replicate what https://github.com/Hammerspoon/hammerspoon/blob/da2f41aa2c008c84a746ffc0d5a0d3291d6e5264/extensions/ipc/init.lua#L266 does.
ln -s /Applications/Hammerspoon.app/Contents/Resources/extensions/hs/ipc/bin/hs "$HOME/.local/bin/hs"
ln -s /Applications/Hammerspoon.app/Contents/Resources/extensions/hs/ipc/share/man/man1/hs.1 /opt/homebrew/share/man/man1/hs.1


sed 's/\/usr\/local\/bin\/jq/\/opt\/homebrew\/bin\/jq/' "$HOME/.hammerspoon/stackline/conf.lua" | sed 's/\/usr\/local\/bin\/yabai/\/opt\/homebrew\/bin\/yabai/'> "$HOME/.hammerspoon/stackline/conf.lua"
