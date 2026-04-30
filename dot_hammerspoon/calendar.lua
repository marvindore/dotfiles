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

-- Eager init: window created at load so AeroSpace registers it before first toggle.
initWindow()

return M
