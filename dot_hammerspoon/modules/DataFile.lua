-- DataFile: read machine-local JSON data from ~/.hammerspoon/data/.
-- The real files are not managed by chezmoi. Tracked *.example.json files
-- in the same folder show the format.

local DataFile = {}

local DATA_DIR = hs.configdir .. "/data/"

function DataFile.read(name)
    local path = DATA_DIR .. name
    local ok, data = pcall(hs.json.read, path)
    if ok and type(data) == "table" then return data end
    local example = (name:gsub("%.json$", ".example.json"))
    hs.alert.show("Missing or invalid " .. path .. "\nCopy " .. example .. " to start.")
    return nil
end

return DataFile
