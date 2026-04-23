-- scratchpad.lua
-- Floating textarea overlay for quick notes.
-- Toggle with the hotkey defined in init.lua.
-- Notes are auto-saved to NOTES_FILE every second of idle typing,
-- and on hide (Esc or hotkey). Content persists across toggles.

local M = {}

local NOTES_FILE = os.getenv("HOME") .. "/.local/share/scratchpad.md"
local webview = nil
local visible = false
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

-- Escape text for safe embedding in an HTML attribute value
local function htmlEscape(s)
    return s
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
end

local function buildHtml(notes)
    return string.format([[<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
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

    webview = hs.webview.new(hs.geometry.rect(0, 0, 100, 100),
                             {developerExtrasEnabled = false}, uc)
    webview:windowStyle({"titled", "closable", "resizable"})
    webview:level(hs.drawing.windowLevels.floating)
    webview:shadow(true)
    webview:allowTextEntry(true)
    webview:windowTitle("scratchpad")
end

local function cancelFocusTimer()
    if focusTimer then focusTimer:stop(); focusTimer = nil end
end

function M.show()
    if not webview then init() end

    -- Capture cursor screen now, before any async work shifts focus.
    local screen = hs.mouse.getCurrentScreen():frame()
    local w = math.floor(screen.w * 0.4)
    local h = math.floor(screen.h * 0.4)
    local frame = hs.geometry.rect(
        screen.x + (screen.w - w) / 2,
        screen.y + (screen.h - h) / 3,
        w, h)

    prevWindow = hs.window.focusedWindow()
    webview:html(buildHtml(readNotes()))
    webview:show()

    -- Apply frame and focus after show() so the window is live on screen.
    cancelFocusTimer()
    focusTimer = hs.timer.doAfter(0.15, function()
        focusTimer = nil
        if not visible then return end
        webview:frame(frame)
        local hw = webview:hswindow()
        if hw then hw:focus() end
    end)

    visible = true
end

function M.hide()
    cancelFocusTimer()
    if webview then webview:hide() end
    visible = false
    if prevWindow and prevWindow:isVisible() then
        prevWindow:focus()
    end
end

function M.toggle()
    if visible then M.hide() else M.show() end
end

return M
