-- Bookmarks: search bookmarks from ~/.hammerspoon/data/bookmarks.json (private).
-- Format: [{ "name": "...", "url": "...", "keywords": "space separated" }]
-- See data/bookmarks.example.json. Enter focuses the Chrome tab with the URL,
-- else opens it.

local ChromeTabs = require("modules.ChromeTabs")
local Picker = require("modules.Picker")

local function isValid(bookmark)
    return type(bookmark.name) == "string" and type(bookmark.url) == "string"
end

local function toChoice(bookmark)
    return { text = bookmark.name, subText = bookmark.keywords or "" }
end

local function onChoose(bookmark)
    ChromeTabs.focusOrOpen(bookmark.url)
end

return Picker.new({
    file = "bookmarks.json",
    placeholder = "Search bookmarks…",
    isValid = isValid,
    toChoice = toChoice,
    onChoose = onChoose,
})
