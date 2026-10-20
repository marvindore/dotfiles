-- RepoPicker: fuzzy-search your starred GitHub repos from a Hammerspoon chooser.
-- Source: `gh api user/starred` (star the repos you use; the list is dynamic).
-- Choices are held in memory and shown at once, then refreshed in the background.
--   Enter        open repo in browser
--   Shift+Enter  open `gh dash` for the repo in Ghostty

local RepoPicker = {}

local HOME = os.getenv("HOME")
local CACHE_DIR = HOME .. "/.cache"
local CACHE_PATH = CACHE_DIR .. "/repo-picker.json"
local REFRESH_SECONDS = 3600
local JQ_FILTER = ".[] | {full_name, description, html_url}"

local function findGh()
    for _, path in ipairs({ "/opt/homebrew/bin/gh", "/usr/local/bin/gh" }) do
        if hs.fs.attributes(path) then return path end
    end
end

-- Resolve once at load, not per keypress.
local GH_BIN = findGh()

-- Module-level references. A local hs.task or hs.chooser can be garbage
-- collected while it runs, which kills the task and fails the refresh.
local state = { chooser = nil, task = nil, choices = nil }

local function readCache()
    local file = io.open(CACHE_PATH, "r")
    if not file then return {} end
    local data = file:read("*a")
    file:close()
    local ok, repos = pcall(hs.json.decode, data)
    return (ok and type(repos) == "table") and repos or {}
end

local function writeCache(repos)
    hs.fs.mkdir(CACHE_DIR)
    local file = io.open(CACHE_PATH, "w")
    if not file then return end
    file:write(hs.json.encode(repos))
    file:close()
end

local function cacheIsStale()
    local attrs = hs.fs.attributes(CACHE_PATH)
    return not attrs or (os.time() - attrs.modification) > REFRESH_SECONDS
end

-- gh prints one JSON object per line with --jq '.[] | {...}'.
local function parseRepoLines(output)
    local repos = {}
    for line in output:gmatch("[^\n]+") do
        local ok, repo = pcall(hs.json.decode, line)
        if ok and repo then repos[#repos + 1] = repo end
    end
    return repos
end

local function toChoices(repos)
    local choices = {}
    for _, repo in ipairs(repos) do
        choices[#choices + 1] = {
            text = repo.full_name,
            subText = repo.description or "",
            url = repo.html_url,
            repo = repo.full_name,
        }
    end
    return choices
end

local function setChoices(repos)
    state.choices = toChoices(repos)
    if state.chooser then state.chooser:choices(state.choices) end
end

local function firstLine(text)
    return (text or ""):match("[^\n]+") or "no output"
end

local function onRefreshDone(exitCode, stdOut, stdErr)
    state.task = nil
    if exitCode ~= 0 then
        hs.alert.show("RepoPicker: gh failed (" .. exitCode .. "): " .. firstLine(stdErr))
        return
    end
    local repos = parseRepoLines(stdOut)
    writeCache(repos)
    setChoices(repos)
end

function RepoPicker.refresh()
    if state.task then return end -- refresh already in flight
    if not GH_BIN then
        hs.alert.show("RepoPicker: gh not found")
        return
    end
    state.task = hs.task.new(GH_BIN, onRefreshDone,
        { "api", "user/starred?per_page=100", "--paginate", "--jq", JQ_FILTER })
    if not state.task:start() then
        state.task = nil
        hs.alert.show("RepoPicker: could not start gh")
    end
end

local function openDash(repo)
    local cmd = string.format("GH_REPO=%q gh dash", repo)
    hs.task.new("/usr/bin/open", nil, { "-na", "Ghostty", "--args", "-e", "zsh", "-lic", cmd }):start()
end

local function onChoose(choice)
    if not choice then return end
    if hs.eventtap.checkKeyboardModifiers().shift then
        openDash(choice.repo)
        return
    end
    hs.urlevent.openURL(choice.url)
end

local function getChooser()
    if state.chooser then return state.chooser end
    state.chooser = hs.chooser.new(onChoose)
    state.chooser:placeholderText("Search starred repos…  (⇧⏎ = gh dash)")
    return state.chooser
end

function RepoPicker.show()
    if not state.choices then setChoices(readCache()) end
    local chooser = getChooser()
    chooser:choices(state.choices)
    chooser:query(nil)
    chooser:show()
    if cacheIsStale() then RepoPicker.refresh() end
end

function RepoPicker.bind(modifiers, key)
    hs.hotkey.bind(modifiers, key, RepoPicker.show)
end

return RepoPicker
