-- ~/.hammerspoon/init.lua

-- Ctrl + Esc → Ctrl + Shift + Tab
hs.hotkey.bind({ "ctrl" }, "escape", function()
    hs.eventtap.keyStroke({ "ctrl", "shift" }, "tab")
end)

-- Scratchpad overlay (ctrl + alt + n)
local Scratchpad = require("scratchpad")
hs.hotkey.bind({ "ctrl", "shift" }, "n", Scratchpad.toggle)
