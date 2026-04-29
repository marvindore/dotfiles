-- scratchpad.lua
-- Floating textarea overlay for quick notes.
-- Toggle with the hotkey defined in init.lua.
-- Notes are auto-saved to NOTES_FILE every second of idle typing,
-- and on hide (Esc or hotkey). Content persists across toggles.
--
-- AeroSpace integration: we never call webview:hide()/show() after init
-- because each show() re-triggers AeroSpace detection and tiling. Instead
-- the window stays permanently shown and we toggle alpha 0/1. Before each
-- reveal we move the window to the focused workspace via socket and set
-- layout floating, so it always appears where the cursor is.

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
-- Runs async via hs.task so the UI is never blocked; calls done() on completion.
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
    uc:setCallback(function(msg)
        local body = msg.body
        if body.a == "save" then
            writeNotes(body.c)
        elseif body.a == "hide" then
            writeNotes(body.c)
            M.hide()
        end
    end)

    webview = hs.webview.new(hs.geometry.rect(-10000, -10000, 100, 100),
                             {developerExtrasEnabled = false}, uc)
    webview:windowStyle({"titled", "closable", "resizable"})
    webview:level(hs.drawing.windowLevels.floating)
    webview:shadow(true)
    webview:allowTextEntry(true)
    webview:windowTitle("scratchpad")
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
    -- Show once invisible so AeroSpace registers it; we never call hide()/show() again.
    webview:alpha(0)
    webview:show()
end

function M.show()
    -- Reinit if window was closed externally.
    if webview and not webview:hswindow() then
        webview = nil
        visible = false
    end
    if not webview then init() end

    local screen = hs.mouse.getCurrentScreen():frame()
    local w = math.floor(screen.w * 0.4)
    local h = math.floor(screen.h * 0.4)
    local frame = hs.geometry.rect(
        screen.x + (screen.w - w) / 2,
        screen.y + (screen.h - h) / 3,
        w, h)

    prevWindow = hs.window.focusedWindow()
    webview:html(buildHtml(readNotes()))
    webview:windowTitle("scratchpad")
    webview:frame(frame)
    visible = true

    -- Keep alpha=0 until AeroSpace has moved the window to the correct workspace,
    -- then reveal. This avoids the flicker on the old monitor.
    local function reveal()
        if not visible or not webview then return end
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

    -- Fallback: guarantee the window appears even if the async task stalls.
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

-- Create the window at load time so AeroSpace registers it well before
-- the user ever presses the hotkey.
init()

return M
