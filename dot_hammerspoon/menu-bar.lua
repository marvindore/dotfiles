-- cmd+m: move mouse to top of screen (reveals native auto-hidden menu bar)
-- cmd+m again: move mouse to center (lets menu bar re-hide)
-- Requires "Automatically hide and show the menu bar" to be enabled in System Settings.

local _menuBarShown = false

hs.hotkey.bind({ "cmd" }, "m", function()
  local sf = hs.screen.mainScreen():fullFrame()

  if _menuBarShown then
    local pos = { x = sf.x + sf.w / 2, y = sf.y + sf.h / 2 }
    hs.mouse.absolutePosition(pos)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, pos):post()
    _menuBarShown = false
  else
    local pos = { x = sf.x + sf.w / 2, y = sf.y }
    hs.mouse.absolutePosition(pos)
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.mouseMoved, pos):post()
    _menuBarShown = true
  end
end)
