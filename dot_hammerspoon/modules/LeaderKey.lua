-- ~/.hammerspoon/modules/LeaderKey.lua
--
-- Generic leader-key module built on RecursiveBinder.
--
-- Features:
--   * Single-level and nested key sequences
--   * Optional modifiers on any sequence key
--   * Descriptions displayed by RecursiveBinder
--   * Named groups for nested sequences
--   * Generic Lua callback actions
--   * Error handling for actions
--   * start(), stop(), and restart() lifecycle methods
--
-- Example:
--
-- local LeaderKey = require("modules.LeaderKey")
--
-- local leader = LeaderKey.new({
--     modifiers = { "alt" },
--     key = "l",
-- })
--
-- leader:bind("b", function()
--     hs.application.launchOrFocus("Safari")
-- end, "Safari")
--
-- leader:bind({ "g", "p" }, function()
--     hs.urlevent.openURL("https://github.com/pulls")
-- end, "Pull requests")
--
-- leader:start()

local LeaderKey = {}
LeaderKey.__index = LeaderKey

-- ---------------------------------------------------------------------
-- Utility functions
-- ---------------------------------------------------------------------

local function copyTable(source)
    local result = {}

    if source then
        for key, value in pairs(source) do
            result[key] = value
        end
    end

    return result
end

local function copyArray(source)
    local result = {}

    if source then
        for index, value in ipairs(source) do
            result[index] = value
        end
    end

    return result
end

local function isArray(value)
    if type(value) ~= "table" then
        return false
    end

    return value[1] ~= nil
end

local function tablesEqual(left, right)
    if #left ~= #right then
        return false
    end

    for index, value in ipairs(left) do
        if value ~= right[index] then
            return false
        end
    end

    return true
end

local function modifiersToId(modifiers)
    local normalized = copyArray(modifiers)

    table.sort(normalized)

    return table.concat(normalized, "+")
end

local function bindingToId(binding)
    return modifiersToId(binding.modifiers)
        .. ":"
        .. string.lower(binding.key)
end

-- ---------------------------------------------------------------------
-- Constructor
-- ---------------------------------------------------------------------

function LeaderKey.new(options)
    options = options or {}

    local self = setmetatable({}, LeaderKey)

    self.modifiers = copyArray(
        options.modifiers or { "alt" }
    )

    self.key = options.key or "l"

    self.showHelper = options.showHelper ~= false
    self.helperEntryEachLine =
        options.helperEntryEachLine or 5
    self.helperEntryLengthInChar =
        options.helperEntryLengthInChar or 22

    self.alertOnError = options.alertOnError ~= false
    self.loggerName = options.loggerName or "LeaderKey"
    self.logLevel = options.logLevel or "warning"

    self.logger = hs.logger.new(
        self.loggerName,
        self.logLevel
    )

    -- Internal logical binding tree.
    self.root = {
        children = {},
        description = options.description or "Leader",
    }

    self.hotkey = nil
    self.startFunction = nil
    self.started = false

    self:_loadRecursiveBinder()

    return self
end

-- ---------------------------------------------------------------------
-- RecursiveBinder setup
-- ---------------------------------------------------------------------

function LeaderKey:_loadRecursiveBinder()
    local loaded, loadError = pcall(function()
        hs.loadSpoon("RecursiveBinder")
    end)

    if not loaded or not spoon.RecursiveBinder then
        error(
            "LeaderKey could not load RecursiveBinder.spoon.\n"
                .. "Install it at:\n"
                .. "~/.hammerspoon/Spoons/"
                .. "RecursiveBinder.spoon\n\n"
                .. "Original error: "
                .. tostring(loadError),
            2
        )
    end

    self.recursiveBinder = spoon.RecursiveBinder

    self.recursiveBinder.showBindHelper =
        self.showHelper

    self.recursiveBinder.helperEntryEachLine =
        self.helperEntryEachLine

    self.recursiveBinder.helperEntryLengthInChar =
        self.helperEntryLengthInChar
end

-- ---------------------------------------------------------------------
-- Binding normalization
-- ---------------------------------------------------------------------

-- Normalize one key in a path.
--
-- Supported formats:
--
-- "b"
--
-- {
--     key = "b",
--     modifiers = { "shift" },
--     description = "Bookmarks",
-- }
--
-- RecursiveBinder also recognizes uppercase letters, but this module
-- stores modifiers explicitly to keep its internal representation
-- predictable.
function LeaderKey:_normalizeBinding(binding)
    if type(binding) == "string" then
        if binding == "" then
            error(
                "LeaderKey binding cannot be an empty string",
                3
            )
        end

        return {
            key = binding,
            modifiers = {},
            description = nil,
        }
    end

    if type(binding) ~= "table" then
        error(
            "Each LeaderKey binding must be a string or table",
            3
        )
    end

    if type(binding.key) ~= "string"
        or binding.key == ""
    then
        error(
            "A LeaderKey binding table requires "
                .. "a non-empty 'key' property",
            3
        )
    end

    return {
        key = binding.key,
        modifiers = copyArray(
            binding.modifiers or {}
        ),
        description = binding.description,
    }
end

-- Normalize a complete path.
--
-- Supported:
--
-- "b"
--
-- { "g", "p" }
--
-- {
--     { key = "g", description = "GitHub" },
--     { key = "p", description = "Pull requests" },
-- }
function LeaderKey:_normalizePath(path)
    if type(path) == "string" then
        return {
            self:_normalizeBinding(path),
        }
    end

    if type(path) ~= "table" then
        error(
            "LeaderKey path must be a string or array",
            3
        )
    end

    -- Allow a single key descriptor:
    --
    -- {
    --     key = "b",
    --     modifiers = { "shift" },
    -- }
    if path.key then
        return {
            self:_normalizeBinding(path),
        }
    end

    if not isArray(path) then
        error(
            "LeaderKey path must contain at least one key",
            3
        )
    end

    local normalized = {}

    for _, binding in ipairs(path) do
        table.insert(
            normalized,
            self:_normalizeBinding(binding)
        )
    end

    if #normalized == 0 then
        error(
            "LeaderKey path must contain at least one key",
            3
        )
    end

    return normalized
end

-- ---------------------------------------------------------------------
-- Internal tree handling
-- ---------------------------------------------------------------------

function LeaderKey:_findChild(node, binding)
    local id = bindingToId(binding)

    return node.children[id]
end

function LeaderKey:_getOrCreateChild(node, binding)
    local id = bindingToId(binding)
    local existing = node.children[id]

    if existing then
        if binding.description then
            existing.description = binding.description
        end

        return existing
    end

    local child = {
        key = binding.key,
        modifiers = copyArray(binding.modifiers),
        description = binding.description,
        children = {},
        action = nil,
    }

    node.children[id] = child

    return child
end

function LeaderKey:_getNode(path, createMissing)
    local normalizedPath = self:_normalizePath(path)
    local node = self.root

    for _, binding in ipairs(normalizedPath) do
        local child

        if createMissing then
            child = self:_getOrCreateChild(
                node,
                binding
            )
        else
            child = self:_findChild(
                node,
                binding
            )
        end

        if not child then
            return nil
        end

        node = child
    end

    return node
end

function LeaderKey:_hasChildren(node)
    return next(node.children) ~= nil
end

-- ---------------------------------------------------------------------
-- Public registration API
-- ---------------------------------------------------------------------

-- Register an action.
--
-- path:
--   "b"
--   { "g", "p" }
--   {
--       { key = "g", description = "GitHub" },
--       { key = "p" },
--   }
--
-- action:
--   Any Lua function.
--
-- description:
--   Text shown in the RecursiveBinder helper.
--
-- Examples:
--
-- leader:bind("b", function()
--     print("Bookmarks")
-- end, "Bookmarks")
--
-- leader:bind({ "g", "p" }, function()
--     hs.urlevent.openURL("https://github.com/pulls")
-- end, "Pull requests")
function LeaderKey:bind(path, action, description)
    if self.started then
        error(
            "Cannot add LeaderKey bindings after start(). "
                .. "Add all bindings first, or call stop(), "
                .. "add bindings, and call start() again.",
            2
        )
    end

    if type(action) ~= "function" then
        error(
            "LeaderKey action must be a function",
            2
        )
    end

    local node = self:_getNode(path, true)

    if self:_hasChildren(node) then
        error(
            "Cannot assign an action to this path because "
                .. "it already contains nested bindings",
            2
        )
    end

    node.action = action

    if description then
        node.description = description
    end

    if not node.description then
        node.description = node.key
    end

    return self
end

-- Assign or update the description for a nested group.
--
-- Example:
--
-- leader:group("g", "GitHub")
-- leader:group({ "w", "m" }, "Move window")
function LeaderKey:group(path, description)
    if self.started then
        error(
            "Cannot add LeaderKey groups after start(). "
                .. "Call stop() before modifying the tree.",
            2
        )
    end

    if type(description) ~= "string"
        or description == ""
    then
        error(
            "LeaderKey group description must "
                .. "be a non-empty string",
            2
        )
    end

    local node = self:_getNode(path, true)

    if node.action then
        error(
            "Cannot turn an action binding into a group",
            2
        )
    end

    node.description = description

    return self
end

-- Remove an action or group.
--
-- remove("b")
-- remove({ "g", "p" })
function LeaderKey:remove(path)
    if self.started then
        error(
            "Cannot remove LeaderKey bindings after start(). "
                .. "Call stop() first.",
            2
        )
    end

    local normalizedPath = self:_normalizePath(path)
    local parent = self.root

    for index = 1, #normalizedPath - 1 do
        parent = self:_findChild(
            parent,
            normalizedPath[index]
        )

        if not parent then
            return self
        end
    end

    local finalBinding =
        normalizedPath[#normalizedPath]

    parent.children[bindingToId(finalBinding)] = nil

    return self
end

-- ---------------------------------------------------------------------
-- Action error handling
-- ---------------------------------------------------------------------

function LeaderKey:_runAction(node)
    local succeeded, actionError = xpcall(
        node.action,
        debug.traceback
    )

    if succeeded then
        return
    end

    local message =
        "Leader action failed: "
        .. tostring(node.description or node.key)

    self.logger.e(
        message .. "\n" .. tostring(actionError)
    )

    if self.alertOnError then
        hs.alert.show(message)
    end
end

-- ---------------------------------------------------------------------
-- RecursiveBinder keymap conversion
-- ---------------------------------------------------------------------

function LeaderKey:_toRecursiveBinderKey(node)
    return {
        copyArray(node.modifiers),
        node.key,
        node.description or node.key,
    }
end

function LeaderKey:_buildRecursiveMap(parentNode)
    local keymap = {}

    for _, node in pairs(parentNode.children) do
        local recursiveKey =
            self:_toRecursiveBinderKey(node)

        if node.action then
            keymap[recursiveKey] = function()
                self:_runAction(node)
            end
        elseif self:_hasChildren(node) then
            keymap[recursiveKey] =
                self:_buildRecursiveMap(node)
        else
            self.logger.w(
                "Ignoring empty LeaderKey group: "
                    .. tostring(node.description or node.key)
            )
        end
    end

    return keymap
end

-- ---------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------

function LeaderKey:start()
    if self.started then
        return self
    end

    if not self:_hasChildren(self.root) then
        error(
            "LeaderKey has no bindings. "
                .. "Register at least one binding before start().",
            2
        )
    end

    local keymap =
        self:_buildRecursiveMap(self.root)

    self.startFunction =
        self.recursiveBinder.recursiveBind(keymap)

    self.hotkey = hs.hotkey.bind(
        self.modifiers,
        self.key,
        function()
            self.startFunction()
        end
    )

    self.started = true

    self.logger.i(
        "Started leader key: "
            .. table.concat(self.modifiers, "+")
            .. "+"
            .. self.key
    )

    return self
end

function LeaderKey:stop()
    if self.hotkey then
        self.hotkey:delete()
        self.hotkey = nil
    end

    self.startFunction = nil
    self.started = false

    return self
end

function LeaderKey:restart()
    return self:stop():start()
end

function LeaderKey:isStarted()
    return self.started
end

return LeaderKey
