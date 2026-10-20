-- UrlBuilder: pick a URL template, fill its parameters, then open the URL.
-- Templates: ~/.hammerspoon/data/url-templates.json (private).
-- Format: [{ "name": "...", "description": "...", "url": "https://x/{0}?q={1}",
--            "params": [{ "label": "...", "placeholder": "..." }] }]
-- See data/url-templates.example.json.
-- {N} is replaced with parameter N (0-based), URL-encoded.

local ChromeTabs = require("modules.ChromeTabs")
local Picker = require("modules.Picker")

-- Same result as JavaScript encodeURIComponent for the common cases.
local function encodeComponent(value)
    return (value:gsub("[^%w%-%._~]", function(char)
        return string.format("%%%02X", char:byte())
    end))
end

local function buildUrl(template, values)
    return (template.url:gsub("{(%d+)}", function(index)
        return encodeComponent(values[tonumber(index)] or "")
    end))
end

-- Ask for one parameter. Returns nil if the user cancels or leaves it empty.
local function promptParam(template, param)
    hs.focus()
    local info = param.label .. "\n" .. (param.placeholder or "")
    local button, text = hs.dialog.textPrompt(template.name, info, "", "Open", "Cancel")
    if button ~= "Open" then return nil end
    if text == "" then
        hs.alert.show(param.label .. " is required")
        return nil
    end
    return text
end

-- Returns a table of values keyed from 0, or nil if the user cancelled.
local function promptParams(template)
    local values = {}
    for i, param in ipairs(template.params or {}) do
        local value = promptParam(template, param)
        if not value then return nil end
        values[i - 1] = value
    end
    return values
end

local function isValid(template)
    return type(template.name) == "string" and type(template.url) == "string"
end

local function toChoice(template)
    return { text = template.name, subText = template.description or template.url }
end

local function onChoose(template)
    local values = promptParams(template)
    if not values then return end
    ChromeTabs.focusOrOpen(buildUrl(template, values))
end

return Picker.new({
    file = "url-templates.json",
    placeholder = "Search URL templates…",
    isValid = isValid,
    toChoice = toChoice,
    onChoose = onChoose,
})
