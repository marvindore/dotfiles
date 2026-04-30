-- calendar.lua
-- Floating popup showing remaining meetings for today.
-- Toggle with Ctrl+Shift+M (wired in init.lua).
local M = {}

local AERO_SOCK  = "/tmp/bobko.aerospace-" .. os.getenv("USER") .. ".sock"
local webview    = nil
local visible    = false
local focusTimer = nil
local prevWindow = nil
local eventCache = {}

-- Catppuccin Mocha (matches scratchpad.lua)
local FONT    = "'JetBrains Mono', 'SF Mono', 'Menlo', monospace"
local BG      = "#1e1e2e"
local BG_DARK = "#181825"
local FG      = "#cdd6f4"
local MUTED   = "#6c7086"
local BORDER  = "#313244"
local ACCENT  = "#89b4fa"

-- Move the webview to the focused AeroSpace workspace and set it floating.
-- Uses the Unix socket protocol (same as scratchpad.lua). Runs via hs.task
-- so the hotkey handler returns immediately.
local function aeroMoveAndFloat(window_id, done)
    local wid = tostring(window_id)
    local script = string.format([[
import json, socket
def cmd(*args):
    s = socket.socket(socket.AF_UNIX)
    s.settimeout(1)
    s.connect("%s")
    s.send(json.dumps({"stdin": "", "args": list(args)}).encode())
    r = json.loads(s.recv(4096))
    s.close()
    return r.get("stdout", "").strip()
try:
    ws = cmd("list-workspaces", "--focused")
    cmd("move-node-to-workspace", ws, "--window-id", "%s")
    cmd("layout", "floating", "--window-id", "%s")
except:
    pass
]], AERO_SOCK, wid, wid)
    hs.task.new("/usr/bin/python3", function()
        if done then done() end
    end, {"-c", script}):start()
end

local function cancelFocusTimer()
    if focusTimer then focusTimer:stop(); focusTimer = nil end
end

-- AppleScript returns a list of lists:
-- { title, startH, startM, endH, endM, calName, urlField, notes, isAllDay, organizer }
-- isAllDay is true/false (AppleScript boolean); organizer may be "" if unavailable.
local AS_FETCH = [[
tell application "Calendar"
  set todayStart to current date
  set hours   of todayStart to 0
  set minutes of todayStart to 0
  set seconds of todayStart to 0
  set todayEnd to todayStart + (60 * 60 * 24)
  set evList to {}
  repeat with cal in calendars
    set calName to name of cal
    try
      set evs to every event of cal whose start date >= todayStart and start date < todayEnd
      repeat with ev in evs
        set evTitle to summary of ev
        set s to start date of ev
        set e to end date of ev
        set evDesc to ""
        try
          set evDesc to description of ev
        end try
        set evUrl to ""
        try
          set evUrl to url of ev
        end try
        set isAD to allday event of ev
        -- Organizer: Calendar.app exposes attendees; look for the organizer role.
        -- Wrapped in try so non-Outlook events (which lack attendees) degrade silently.
        set orgName to ""
        try
          repeat with att in attendees of ev
            if role of att is organizer then
              set orgName to name of att
              exit repeat
            end if
          end repeat
        end try
        set end of evList to {evTitle, hours of s, minutes of s, hours of e, minutes of e, calName, evUrl, evDesc, isAD, orgName}
      end repeat
    end try
  end repeat
  return evList
end tell
]]

local function fmtTime(h, m)
    local ampm = h < 12 and "AM" or "PM"
    local h12  = h % 12
    if h12 == 0 then h12 = 12 end
    return string.format("%d:%02d %s", h12, m, ampm)
end

local function fetchEvents()
    local ok, result = hs.osascript.applescript(AS_FETCH)
    if not ok or type(result) ~= "table" then return {} end

    local now     = os.date("*t")
    local nowMins = now.hour * 60 + now.min
    local events  = {}

    for _, row in ipairs(result) do
        local title, sh, sm, eh, em, calName, urlField, notes, isAllDay, organizer =
            row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9], row[10]

        -- Skip events that have already ended
        local endMins = (eh or 0) * 60 + (em or 0)
        if endMins <= nowMins then goto continue end

        -- Skip all-day events (they have no join link worth showing)
        -- Per spec: include all-day only if they have a join link
        -- (detectLink is added in Task 3; for now include all)

        local startMins = (sh or 0) * 60 + (sm or 0)

        -- Cap notes length to avoid memory bloat on large Outlook bodies
        local notesStr = (notes or ""):sub(1, 3000)

        events[#events + 1] = {
            title        = title or "(no title)",
            startTime    = fmtTime(sh or 0, sm or 0),
            endTime      = fmtTime(eh or 0, em or 0),
            startMins    = startMins,
            endMins      = endMins,
            calendarName = calName or "",
            organizer    = organizer or "",
            urlField     = urlField or "",
            notes        = notesStr,
            isAllDay     = isAllDay == true,
            joinUrl      = nil,
            linkType     = nil,
        }
        ::continue::
    end

    table.sort(events, function(a, b) return a.startMins < b.startMins end)
    return events
end

local refreshTimer = nil

local function refreshCache()
    eventCache = fetchEvents()
end

local function startRefreshTimer()
    if refreshTimer then return end
    refreshTimer = hs.timer.doEvery(300, refreshCache)
end

local function initWindow()
    local uc = hs.webview.usercontent.new("cal")
    uc:setCallback(function(msg)
        local body = msg.body
        if body.a == "hide" then
            M.hide()
        elseif body.a == "join" then
            hs.urlevent.openURL(body.url)
            M.hide()
        end
    end)

    webview = hs.webview.new(hs.geometry.rect(-10000, -10000, 100, 100),
                             {developerExtrasEnabled = false}, uc)
    webview:windowStyle({"titled", "closable", "resizable"})
    webview:level(hs.drawing.windowLevels.floating)
    webview:shadow(true)
    webview:allowTextEntry(false)
    webview:windowTitle("meetings")
    webview:windowCallback(function(action, _wv, _)
        if action == "closing" then
            cancelFocusTimer()
            visible = false
            webview = nil
            if prevWindow and prevWindow:isVisible() then
                prevWindow:focus()
            end
        end
    end)
    webview:alpha(0)
    webview:show()
end

-- Placeholder until buildHtml is implemented in Task 4
local function buildHtml(_events)
    return string.format([[<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>meetings</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:%s;color:%s;font-family:%s;font-size:13px;display:flex;align-items:center;justify-content:center;height:100%%}</style>
</head><body><p style="color:%s">Loading meetings…</p></body></html>
]], BG, FG, FONT, MUTED)
end

function M.show()
    if webview and not webview:hswindow() then
        webview = nil
        visible = false
    end
    if not webview then initWindow() end

    local screen = hs.mouse.getCurrentScreen():frame()
    local w = math.floor(screen.w * 0.4)
    local h = math.floor(screen.h * 0.4)
    local frame = hs.geometry.rect(
        screen.x + (screen.w - w) / 2,
        screen.y + (screen.h - h) / 3,
        w, h)

    prevWindow = hs.window.focusedWindow()
    webview:html(buildHtml(eventCache))
    webview:windowTitle("meetings")
    webview:frame(frame)
    visible = true

    local function reveal()
        if not visible or not webview then return end
        webview:frame(frame)
        webview:alpha(1)
        local hw = webview:hswindow()
        if hw then hw:focus() end
    end

    local hw = webview:hswindow()
    if hw then
        aeroMoveAndFloat(hw:id(), reveal)
    else
        reveal()
    end

    cancelFocusTimer()
    focusTimer = hs.timer.doAfter(0.3, function()
        focusTimer = nil
        reveal()
    end)
end

function M.hide()
    cancelFocusTimer()
    if webview then webview:alpha(0) end
    visible = false
    if prevWindow and prevWindow:isVisible() then
        prevWindow:focus()
    end
end

function M.toggle()
    if visible then M.hide() else M.show() end
end

-- Eager init: fetch events and create window at Hammerspoon startup.
refreshCache()
startRefreshTimer()
initWindow()

return M
