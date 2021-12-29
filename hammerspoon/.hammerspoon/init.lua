require("hs.ipc")

stackline = require "stackline"
stackline:init()

hs.ipc.cliInstall("/opt/homebrew")

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
