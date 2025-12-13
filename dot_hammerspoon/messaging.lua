-- ~/.hammerspoon/messaging.lua
local M = {}

-- Track the currently "focused" screen by subscribing to window focus events
local currentScreen = hs.screen.mainScreen() -- fallback
local wf = hs.window.filter.default

-- Whenever a window becomes focused, remember its screen
wf:subscribe(hs.window.filter.windowFocused, function(win, appName)
  local ok, screen = pcall(function() return win:screen() end)
  if ok and screen then currentScreen = screen end
end)

-- Helper: move mouse to center of a screen (so chooser opens on that monitor)
local function moveMouseToScreenCenter(scr)
  local f = scr:frame()
  local center = { x = f.x + f.w/2, y = f.y + f.h/2 }
  hs.mouse.setAbsolutePosition(center)
end

-- Slack/Teams list
local apps = {
  { text = "Slack",            subText = "Messaging", appName = "Slack" },
  { text = "Microsoft Teams",  subText = "Messaging", appName = "Microsoft Teams" },
}

local function ensureRunning(name)
  local app = hs.application.get(name)
  if not app then
    hs.application.launchOrFocus(name) -- launch if missing; focus otherwise
  end
end

function M.pick()
  -- 1) Make sure both apps are running
  for _, a in ipairs(apps) do ensureRunning(a.appName) end

  -- 2) Move the mouse to the center of the current focused screen
  if currentScreen then moveMouseToScreenCenter(currentScreen) end

  -- 3) Show a chooser on that monitor
  local chooser = hs.chooser.new(function(choice)
    if choice and choice.appName then
      hs.application.launchOrFocus(choice.appName)
    end
  end)

  chooser:placeholderText("Pick a messaging app")
         :searchSubText(true)
         :choices(apps)
         :width(28)     -- tweak to taste
         :rows(6)       -- tweak to taste
         :show()
end

return M
