require("hs.ipc")
stackline = require "stackline.stackline.stackline"
stackline:init()

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
