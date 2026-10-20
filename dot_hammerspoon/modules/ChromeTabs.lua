-- ChromeTabs: focus an open Google Chrome tab by exact URL, else open the URL.

local ChromeTabs = {}

local FOCUS_SCRIPT = [[
tell application "Google Chrome"
    repeat with w in windows
        set i to 1
        repeat with t in tabs of w
            if URL of t is "%s" then
                set active tab index of w to i
                set index of w to 1
                activate
                return true
            end if
            set i to i + 1
        end repeat
    end repeat
    return false
end tell
]]

local function appleScriptString(value)
    return (value:gsub("\\", "\\\\"):gsub('"', '\\"'))
end

-- Do not tell Chrome anything when it is not running: that would launch it.
local function focusTab(url)
    if not hs.application.get("Google Chrome") then return false end
    local ok, found = hs.osascript.applescript(string.format(FOCUS_SCRIPT, appleScriptString(url)))
    return ok and found == true
end

function ChromeTabs.focusOrOpen(url)
    if focusTab(url) then return end
    hs.urlevent.openURL(url)
end

return ChromeTabs
