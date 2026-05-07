-- scratchpad.lua
-- Floating textarea overlay for quick notes.
-- Toggle with the hotkey defined in init.lua.
-- Notes are auto-saved to NOTES_FILE every second of idle typing,
-- and on hide (Esc or hotkey). Content persists across toggles.
--
-- ## AeroSpace compatibility
--
-- AeroSpace is a tiling window manager that detects new windows via macOS
-- Accessibility notifications and tiles them into the focused workspace.
-- A naive webview:hide()/show() cycle causes AeroSpace to re-detect the
-- window every time, re-tiling it and pulling the cursor to whichever
-- monitor owns that workspace. Three techniques work together to prevent this:
--
-- 1. ALPHA INSTEAD OF HIDE/SHOW — The window is created once at module load
--    and never hidden or re-shown. Visibility is toggled with alpha(0/1).
--    Because AeroSpace uses AX notifications (AXWindowCreated) to detect
--    windows, and alpha changes don't trigger those, AeroSpace only ever
--    sees the window once — during init() — and never re-tiles it.
--
-- 2. ASYNC WORKSPACE MOVE — The window lives in whatever workspace was
--    focused when init() ran (usually at Hammerspoon startup). When the
--    user toggles the scratchpad from a different workspace, we must move
--    the window there first, or AeroSpace's on-focus-changed callback
--    ('move-mouse window-lazy-center') would yank the cursor to the old
--    workspace's monitor. We send three commands to AeroSpace's Unix socket:
--      a) list-workspaces --focused   → get the user's current workspace
--      b) move-node-to-workspace <ws> → move the scratchpad there
--      c) layout floating             → ensure it stays floating, not tiled
--    This runs via hs.task (async) so the UI thread is never blocked.
--    Using hs.execute (sync) caused a ~5s stall because Hammerspoon's
--    default env resolves to /usr/bin/python3 (Apple's Xcode CLT shim)
--    which is slow on first invocation from a non-shell context.
--
-- 3. DEFERRED REVEAL — alpha stays at 0 until the async socket callback
--    confirms the window has been moved to the correct workspace. Only
--    then do we set alpha(1). This eliminates the flicker that would
--    otherwise occur if the window became visible on the old monitor
--    before the move completed. A 300ms fallback timer guarantees the
--    window appears even if the async task stalls or AeroSpace is down.
--
-- The AeroSpace config (aerospace.toml) also has an on-window-detected
-- rule that sets 'layout floating' for windows matching app=Hammerspoon
-- and title=scratchpad. That rule handles the initial detection at init().
-- The <title>scratchpad</title> in the HTML ensures the document title
-- matches even after webview:html() reloads content asynchronously.

local M = {}

local NOTES_FILE = os.getenv("HOME") .. "/.local/share/scratchpad.md"
local AERO_SOCK  = "/tmp/bobko.aerospace-" .. os.getenv("USER") .. ".sock"
local webview    = nil
local visible    = false
local focusTimer = nil
local prevWindow = nil

local FONT = "'JetBrains Mono', 'SF Mono', 'Menlo', monospace"

-- Catppuccin Mocha palette
local BG       = "#1e1e2e"
local BG_DARK  = "#181825"
local FG       = "#cdd6f4"
local MUTED    = "#6c7086"
local BORDER   = "#313244"
local SEL      = "#313244"
local THUMB    = "#45475a"
local CARET    = "#89b4fa"

local function readNotes()
    local f = io.open(NOTES_FILE, "r")
    if not f then return "" end
    local c = f:read("*all")
    f:close()
    return c
end

local function writeNotes(content)
    local f = io.open(NOTES_FILE, "w")
    if f then f:write(content); f:close() end
end

local function htmlEscape(s)
    return s
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
end

local function buildHtml(notes)
    return string.format([[<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>scratchpad</title><style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{height:100%%;background:%s;color:%s;font-family:%s;font-size:14px;display:flex;flex-direction:column}
#bar{padding:4px 12px;background:%s;color:%s;font-size:11px;display:flex;justify-content:space-between;border-bottom:1px solid %s;user-select:none;letter-spacing:.03em}
textarea{flex:1;background:%s;color:%s;border:none;outline:none;padding:12px;font-family:inherit;font-size:14px;resize:none;line-height:1.65;caret-color:%s}
textarea::selection{background:%s}
textarea::-webkit-scrollbar{width:5px}
textarea::-webkit-scrollbar-track{background:transparent}
textarea::-webkit-scrollbar-thumb{background:%s;border-radius:3px}
</style></head><body>
<div id="bar"><span>scratchpad</span><span id="st">—</span></div>
<textarea id="ta" spellcheck="false" autocorrect="off">%s</textarea>
<script>
const ta=document.getElementById('ta'),st=document.getElementById('st');
let timer;
function persist(content){
  window.webkit.messageHandlers.hs.postMessage({a:'save',c:content});
  st.textContent='saved';}
ta.addEventListener('input',()=>{
  st.textContent='·';
  clearTimeout(timer);
  timer=setTimeout(()=>persist(ta.value),1000);
});
document.addEventListener('keydown',e=>{
  if(e.key==='Escape'){
    clearTimeout(timer);
    window.webkit.messageHandlers.hs.postMessage({a:'hide',c:ta.value});
  }
});
ta.focus();
ta.setSelectionRange(ta.value.length,ta.value.length);
st.textContent='ready';
</script></body></html>]],
        BG, FG, FONT,
        BG_DARK, MUTED, BORDER,
        BG, FG, CARET,
        SEL,
        THUMB,
        htmlEscape(notes))
end

local function cancelFocusTimer()
    if focusTimer then focusTimer:stop(); focusTimer = nil end
end

-- Move a window to the currently focused workspace and set it floating.
-- Uses AeroSpace's Unix socket protocol (JSON over AF_UNIX) rather than
-- the `aerospace` CLI, which isn't symlinked on this system.
-- Runs via hs.task (async) so the hotkey handler returns immediately.
-- /usr/bin/python3 is used explicitly to avoid PATH resolution issues —
-- Hammerspoon's default env doesn't include mise/nix/homebrew paths.
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

local function init()
    local uc = hs.webview.usercontent.new("hs")
    -- The JS in buildHtml() posts messages here: 'save' for auto-save,
    -- 'hide' when the user presses Escape (includes final content).
    uc:setCallback(function(msg)
        local body = msg.body
        if body.a == "save" then
            writeNotes(body.c)
        elseif body.a == "hide" then
            writeNotes(body.c)
            M.hide()
        end
    end)

    -- Create the window off-screen and invisible (alpha=0). webview:show()
    -- is called once here so macOS and AeroSpace register the window.
    -- AeroSpace's on-window-detected rule matches title "scratchpad" and
    -- sets layout floating. From this point on we NEVER call hide()/show()
    -- again — only alpha(0/1) — so AeroSpace never re-detects or re-tiles.
    webview = hs.webview.new(hs.geometry.rect(-10000, -10000, 100, 100),
                             {developerExtrasEnabled = false}, uc)
    -- Borderless while off-screen: macOS clamps titled windows so their
    -- title bar remains reachable, which lands them at (0,0) instead of
    -- (-10000,-10000). Borderless windows have no such constraint.
    -- The titled style is restored in reveal() just before becoming visible.
    webview:windowStyle(hs.webview.windowMasks.borderless)
    webview:level(hs.drawing.windowLevels.floating)
    webview:shadow(true)
    webview:allowTextEntry(true)
    webview:windowTitle("scratchpad")
    -- If the user closes the window via the title-bar X button, reset state
    -- so the next toggle recreates it via init().
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

function M.show()
    -- If the window was destroyed externally (e.g. user clicked the X button)
    -- the Lua reference is stale. hswindow() returns nil for a dead window
    -- but non-nil when the window is merely invisible (alpha=0), so this
    -- check correctly distinguishes "closed" from "hidden".
    if webview and not webview:hswindow() then
        webview = nil
        visible = false
    end
    if not webview then init() end

    -- Center on the monitor where the cursor currently sits.
    local screen = hs.mouse.getCurrentScreen():frame()
    local w = math.floor(screen.w * 0.4)
    local h = math.floor(screen.h * 0.4)
    local frame = hs.geometry.rect(
        screen.x + (screen.w - w) / 2,
        screen.y + (screen.h - h) / 3,
        w, h)

    prevWindow = hs.window.focusedWindow()
    webview:html(buildHtml(readNotes()))
    -- Re-assert title after html() because WKWebView may sync the document's
    -- <title> to the NSWindow title asynchronously, and we need the title to
    -- match AeroSpace's on-window-detected regex at all times.
    webview:windowTitle("scratchpad")
    -- Pre-position the frame while still invisible so the window is in the
    -- right place the instant alpha goes to 1.
    webview:frame(frame)
    visible = true

    -- reveal() makes the window visible, re-asserts the frame, and focuses.
    -- It's called from whichever fires first: the async AeroSpace callback
    -- (~60ms) or the fallback timer (300ms). It's idempotent — safe to call
    -- from both without double-showing or double-focusing.
    local function reveal()
        if not visible or not webview then return end
        -- Restore titled style before becoming visible (was borderless while off-screen).
        webview:windowStyle({"titled", "closable", "resizable"})
        webview:frame(frame)
        webview:alpha(1)
        local hw2 = webview:hswindow()
        if hw2 then hw2:focus() end
    end

    -- Move the window to the user's current workspace before revealing.
    -- Without this, the window stays in whatever workspace it was assigned
    -- at init() time, and AeroSpace's on-focus-changed callback would yank
    -- the cursor to that workspace's monitor.
    local hw = webview:hswindow()
    if hw then
        aeroMoveAndFloat(hw:id(), reveal)
    else
        reveal()
    end

    -- Fallback: if AeroSpace is down or the hs.task stalls, show anyway.
    cancelFocusTimer()
    focusTimer = hs.timer.doAfter(0.3, function()
        focusTimer = nil
        reveal()
    end)
end

function M.hide()
    cancelFocusTimer()
    -- Alpha=0 makes the window invisible without triggering AeroSpace
    -- re-detection. The window stays in AeroSpace's floating set, so
    -- the next show() only needs to move it to the right workspace.
    -- Move off-screen so the invisible window doesn't intercept clicks
    -- from apps (e.g. Teams) that sit below the floating level.
    if webview then
        -- Switch to borderless before moving off-screen so macOS doesn't
        -- clamp the position to keep a title bar on-screen.
        webview:windowStyle(hs.webview.windowMasks.borderless)
        webview:alpha(0)
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

-- Eager init: create the window at module load time (Hammerspoon startup).
-- This gives AeroSpace time to detect the window and apply the floating
-- rule well before the user ever presses the hotkey. If init were lazy
-- (deferred to first toggle), there would be a race between AeroSpace's
-- detection and our first reveal().
init()

return M
