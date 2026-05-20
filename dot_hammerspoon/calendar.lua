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

-- Returns {url=string, kind=string} or nil.
-- Scans the event's url field first, then notes for recognized service patterns.
-- Notes scan only matches known services — no catch-all for notes.
local LINK_PATTERNS = {
    { pat = "teams%.microsoft%.com/l/meetup%-join", kind = "teams" },
    { pat = "zoom%.us/j/",                          kind = "zoom"  },
    { pat = "meet%.google%.com/",                   kind = "meet"  },
    { pat = "webex%.com/",                          kind = "webex" },
    { pat = "gotomeeting%.com/join/",               kind = "goto"  },
}

local function detectLink(urlField, notes)
    -- 1. Check url field against known patterns
    for _, p in ipairs(LINK_PATTERNS) do
        if urlField:find(p.pat) then
            return { url = urlField, kind = p.kind }
        end
    end
    -- 2. Any https:// in url field → generic link
    if urlField:find("https://") then
        return { url = urlField, kind = "link" }
    end
    -- 3. Scan notes for recognized service patterns only
    for _, p in ipairs(LINK_PATTERNS) do
        -- Extract URLs from notes text
        local pos = 1
        while pos <= #notes do
            local s, e = notes:find("https://[^%s\"'<>]+", pos)
            if not s then break end
            local candidate = notes:sub(s, e)
            -- Strip trailing punctuation that appears after URLs in invite bodies
            candidate = candidate:gsub("[%.%,%)[%]>]+$", "")
            if candidate:find(p.pat) then
                return { url = candidate, kind = p.kind }
            end
            pos = e + 1
        end
    end
    return nil
end

local function htmlEscape(s)
    if not s then return "" end
    return s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub('"',"&quot;"):gsub("'","&#39;")
end

-- Badge HTML snippets keyed by linkType / "now"
local BADGE_CSS = {
    teams = "background:#4f52b244;color:#a8aaff;border:1px solid #4f52b255",
    zoom  = "background:#2d8cff22;color:#60a5fa;border:1px solid #2d8cff33",
    meet  = "background:#a6e3a122;color:#a6e3a1;border:1px solid #a6e3a133",
    webex = "background:#89dceb22;color:#89dceb;border:1px solid #89dceb33",
    ["goto"]  = "background:#45475a;color:#a6adc8;border:1px solid #585b7055",
    link  = "background:#45475a;color:#a6adc8;border:1px solid #585b7055",
    now   = "background:#a6e3a122;color:#a6e3a1;border:1px solid #a6e3a133",
}
local BADGE_LBL = {
    teams="Teams", zoom="Zoom", meet="Meet", webex="Webex",
    ["goto"]="GoTo", link="Link", now="● now",
}
local BADGE_BASE = "display:inline-flex;align-items:center;padding:1px 5px;" ..
                   "border-radius:3px;font-size:9px;letter-spacing:.04em;font-weight:600;"

local function makeBadge(kind)
    local css = BADGE_CSS[kind] or ""
    local lbl = BADGE_LBL[kind] or kind
    return string.format('<span style="%s%s">%s</span>', BADGE_BASE, css, lbl)
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

        local endMins   = (eh or 0) * 60 + (em or 0)
        local startMins = (sh or 0) * 60 + (sm or 0)
        local notesStr  = (notes or ""):sub(1, 3000)
        local isAllDayEv = (isAllDay == true)

        -- Skip timed events that have already ended.
        -- All-day events report endMins=0 (midnight end), so exempt them from this check.
        if not isAllDayEv and endMins <= nowMins then goto continue end

        local link = detectLink(urlField or "", notesStr)
        -- Skip all-day events with no meeting link (per spec).
        if isAllDayEv and not link then goto continue end

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
            isAllDay     = isAllDayEv,
            joinUrl      = link and link.url  or nil,
            linkType     = link and link.kind or nil,
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
    -- Borderless while off-screen: macOS clamps titled windows so their
    -- title bar remains reachable, which lands them at (0,0) instead of
    -- (-10000,-10000). Borderless windows have no such constraint.
    -- The titled style is restored in reveal() just before becoming visible.
    webview:windowStyle(hs.webview.windowMasks.borderless)
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

local function buildHtml(events)
    -- Compute isNow fresh at render time (cache may be minutes old)
    local now     = os.date("*t")
    local nowMins = now.hour * 60 + now.min

    -- Build meeting rows
    local rows = {}
    for i, ev in ipairs(events) do
        local isNow = (ev.startMins <= nowMins) and (nowMins < ev.endMins)

        -- Badges
        local badges = ""
        if ev.linkType then badges = badges .. makeBadge(ev.linkType) end
        if isNow       then badges = badges .. " " .. makeBadge("now")  end

        -- Detail panel content
        local detailRows = ""
        if ev.organizer and ev.organizer ~= "" then
            detailRows = detailRows .. string.format(
                '<div class="dr"><span class="dk">Organizer</span><span class="dv">%s</span></div>',
                htmlEscape(ev.organizer))
        end
        if ev.calendarName ~= "" then
            detailRows = detailRows .. string.format(
                '<div class="dr"><span class="dk">Calendar</span><span class="dv">%s</span></div>',
                htmlEscape(ev.calendarName))
        end
        local detailExtra = '<div class="dr" style="color:#6c7086;font-size:10px">No meeting link</div>'
        if ev.joinUrl then
            local shortUrl = #ev.joinUrl > 45 and ev.joinUrl:sub(1, 45) .. "…" or ev.joinUrl
            detailRows = detailRows .. string.format(
                '<div class="dr"><span class="dk">Link</span><span class="dv dl">%s</span></div>',
                htmlEscape(shortUrl))
            detailExtra = string.format(
                '<button class="jb" onclick="join(this)" data-url="%s">Join Meeting ↗</button>',
                htmlEscape(ev.joinUrl))
        end

        rows[#rows + 1] = string.format([[
<div class="meeting" id="r%d" onclick="tog(%d)">
  <div class="mhdr">
    <div class="tc"><div class="ts">%s</div><div class="te">%s</div></div>
    <div class="inf">
      <div class="ttl">%s</div>
      <div class="met">%s<span class="cal">%s</span></div>
    </div>
    <div class="chv">›</div>
  </div>
  <div class="det">%s%s</div>
</div>]], i, i,
            htmlEscape(ev.startTime), htmlEscape(ev.endTime),
            htmlEscape(ev.title),
            badges, htmlEscape(ev.calendarName),
            detailRows, detailExtra)
    end

    local body
    local remaining = #events
    if remaining == 0 then
        body = string.format([[
<div style="padding:36px 14px;text-align:center;color:%s;font-size:11px;line-height:1.8">
  <div style="font-size:22px;margin-bottom:8px">✓</div>
  <div style="color:%s;font-size:13px;margin-bottom:4px">You're done for today</div>
  <div>No more meetings remaining</div>
</div>]], MUTED, FG)
    else
        body = table.concat(rows, "\n")
    end

    local countLabel = remaining == 1 and "1 remaining" or (remaining .. " remaining")

    return string.format([[<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>meetings</title><style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{height:100%%;background:%s;color:%s;font-family:%s;font-size:13px;display:flex;flex-direction:column;overflow:hidden}
.bar{padding:6px 14px;background:%s;color:%s;font-size:10px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid %s;user-select:none;letter-spacing:.04em;flex-shrink:0}
.dot{color:%s}.cnt{color:%s}
.list{flex:1;overflow-y:auto}
.list::-webkit-scrollbar{width:4px}
.list::-webkit-scrollbar-thumb{background:#45475a;border-radius:2px}
.meeting{border-bottom:1px solid %s;cursor:pointer}
.meeting:last-child{border-bottom:none}
.mhdr{padding:9px 14px;display:flex;align-items:flex-start;gap:10px}
.mhdr:hover{background:rgba(137,180,250,.05)}
.meeting.open>.mhdr{background:rgba(137,180,250,.08)}
.meeting.open .ttl{color:%s}
.tc{text-align:right;min-width:56px;padding-top:1px;flex-shrink:0}
.ts{color:%s;font-size:11px}.te{color:%s;font-size:10px}
.inf{flex:1;min-width:0}
.ttl{font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-bottom:3px}
.met{display:flex;align-items:center;gap:5px;flex-wrap:wrap}
.cal{color:%s;font-size:10px}
.chv{color:%s;font-size:12px;padding-top:2px;transition:transform .15s;flex-shrink:0}
.meeting.open .chv{transform:rotate(90deg);color:%s}
.det{display:none;background:%s;border-top:1px solid %s;padding:8px 14px 12px 80px;font-size:11px;line-height:1.8}
.meeting.open .det{display:block}
.dr{display:flex;margin-bottom:1px}
.dk{color:%s;min-width:72px;font-size:10px;flex-shrink:0}
.dv{color:%s}.dl{color:%s}
.jb{margin-top:10px;padding:5px 12px;background:%s;color:%s;border:none;border-radius:5px;font-family:inherit;font-size:10px;font-weight:700;letter-spacing:.03em;cursor:pointer}
</style></head><body>
<div class="bar"><span><span class="dot">◆</span> meetings · today</span><span class="cnt">%s</span></div>
<div class="list">%s</div>
<script>
var open=-1;
function tog(i){
  var r=document.getElementById('r'+i);
  if(open===i){r.classList.remove('open');open=-1;}
  else{if(open!==-1)document.getElementById('r'+open).classList.remove('open');r.classList.add('open');open=i;}
}
function join(btn){
  window.webkit.messageHandlers.cal.postMessage({a:'join',url:btn.dataset.url});
}
document.addEventListener('keydown',function(e){
  if(e.key==='Escape') window.webkit.messageHandlers.cal.postMessage({a:'hide'});
});
</script>
</body></html>]],
        BG, FG, FONT,
        BG_DARK, MUTED, BORDER, ACCENT, FG,
        BORDER,
        ACCENT,
        ACCENT, MUTED,
        MUTED, MUTED, ACCENT,
        BG_DARK, BORDER,
        MUTED, FG, ACCENT,
        ACCENT, BG_DARK,
        countLabel, body)
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
        webview:level(hs.drawing.windowLevels.floating)
        webview:windowStyle({"titled", "closable", "resizable"})
        webview:frame(frame)
        webview:alpha(1)
        local hw2 = webview:hswindow()
        if hw2 then hw2:focus() end
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
    -- Move off-screen so the invisible window doesn't intercept clicks
    -- from apps (e.g. Teams, Chrome) that sit below the floating level.
    if webview then
        webview:windowStyle(hs.webview.windowMasks.borderless)
        webview:alpha(0)
        webview:level(hs.drawing.windowLevels._MinimumWindowLevelKey)
        webview:frame(hs.geometry.rect(-10000, -10000, 100, 100))
    end
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
