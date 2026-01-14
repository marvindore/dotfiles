-- ~/.hammerspoon/init.lua
local messaging = require("messaging")

-- URL trigger so Aerospace (or Terminal) can call it
hs.urlevent.bind("messaging", function()
  messaging.pick()
end)

-- Optional: Hammerspoon-only hotkey for quick testing
-- hs.hotkey.bind({"alt"}, "m", messaging.pick)

-- Handy reload hotkey while you iterate
--hs.hotkey.bind({"cmd"}, "r", hs.reload)
