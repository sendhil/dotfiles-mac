require("hs.ipc")

stackline = require "stackline"
stackline:init()

hs.ipc.cliInstall("/opt/homebrew")

function displayMessageOnAllScreens(msg, duration)
  screens = hs.screen.allScreens()
  for key,val in pairs(screens) do
    hs.alert.show(msg, val, duration)
  end
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
