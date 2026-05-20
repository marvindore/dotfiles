-- ~/.hammerspoon/init.lua

-- Ctrl + Esc → Ctrl + Shift + Tab
hs.hotkey.bind({ "ctrl" }, "escape", function()
    hs.eventtap.keyStroke({ "ctrl", "shift" }, "tab")
end)

-- Scratchpad overlay (ctrl + alt + n)
local Scratchpad = require("scratchpad")
hs.hotkey.bind({ "ctrl", "shift" }, "n", Scratchpad.toggle)

-- Meeting popup (ctrl + shift + m)
local Calendar = require("calendar")
hs.hotkey.bind({ "ctrl", "shift" }, "m", Calendar.toggle)

-- Menu bar
require("menu-bar")

-- Whispr: voice dictation → tmux agent (F2 toggle)
local Whispr = require("whispr")
hs.hotkey.bind({}, "f13", Whispr.toggle)

-- Clear all notifications (ctrl+shift+x)
hs.hotkey.bind({"ctrl", "shift"}, "x", function()
    hs.execute("killall NotificationCenter")
end)
