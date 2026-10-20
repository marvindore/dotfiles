-- Picker: generic "search a local list, then act on the pick" chooser.
--
-- A picker is a spec table. Picker.new(spec) returns { show = function }.
--
--   spec.file         data file name in ~/.hammerspoon/data/ (private, not in git)
--   spec.placeholder  search box text
--   spec.toChoice     function(item) -> { text = "...", subText = "..." }
--   spec.onChoose     function(item) called with the picked data item
--   spec.isValid      optional function(item) -> boolean; invalid items are skipped
--   spec.loader       optional function(file) -> table|nil (default: DataFile.read)
--
-- To add a picker: write a spec, call Picker.new, bind its show().
-- Picker never knows what the data is. The spec never touches hs.chooser.

local DataFile = require("modules.DataFile")

local Picker = {}

local function keepValid(items, isValid)
    if not isValid then return items end
    local kept = {}
    for _, item in ipairs(items) do
        if isValid(item) then kept[#kept + 1] = item end
    end
    return kept
end

local function buildChoices(items, toChoice)
    local choices = {}
    for i, item in ipairs(items) do
        local choice = toChoice(item)
        choice.itemIndex = i
        choices[i] = choice
    end
    return choices
end

local function requireFunction(spec, field)
    if type(spec[field]) ~= "function" then
        error("Picker spec needs a function: " .. field, 3)
    end
end

function Picker.new(spec)
    assert(type(spec.file) == "string", "Picker spec needs a file name")
    requireFunction(spec, "toChoice")
    requireFunction(spec, "onChoose")

    local loader = spec.loader or DataFile.read
    -- Held in this closure so the chooser is not garbage collected.
    local chooser = nil
    local items = {}

    local function onChoose(choice)
        if choice then spec.onChoose(items[choice.itemIndex]) end
    end

    local function getChooser()
        if chooser then return chooser end
        chooser = hs.chooser.new(onChoose)
        chooser:placeholderText(spec.placeholder or "Search…")
        chooser:searchSubText(true)
        return chooser
    end

    local picker = {}

    -- Data is read on every show, so edits to the file apply without a reload.
    function picker.show()
        local loaded = loader(spec.file)
        if not loaded then return end
        items = keepValid(loaded, spec.isValid)
        local view = getChooser()
        view:choices(buildChoices(items, spec.toChoice))
        view:query(nil)
        view:show()
    end

    return picker
end

return Picker
