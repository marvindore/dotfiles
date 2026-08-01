-- ~/.hammerspoon/modules/Actions.lua
--
-- Generic action factories for LeaderKey and ordinary Hammerspoon
-- hotkeys.
--
-- Each function returns a callback that can be passed directly to:
--
--     leader:bind(path, action, description)
--
-- Examples:
--
--     Actions.application("Safari")
--     Actions.url("https://github.com")
--     Actions.hotkey({ "cmd", "shift" }, "b")
--     Actions.hotkeyString("Command+Shift+B")
--     Actions.shell("$HOME/bin/update-projects")
--     Actions.script("$HOME/.local/bin/bookmarks")
--     Actions.appleShortcut("Create Note")

local Actions = {}

-- ---------------------------------------------------------------------
-- Internal utilities
-- ---------------------------------------------------------------------

local function expandHome(path)
    if type(path) ~= "string" then
        return path
    end

    local home = os.getenv("HOME")

    if not home then
        return path
    end

    if path == "~" then
        return home
    end

    if path:sub(1, 2) == "~/" then
        return home .. path:sub(2)
    end

    return path
end

local function copyArray(source)
    local result = {}

    if source then
        for _, value in ipairs(source) do
            table.insert(result, value)
        end
    end

    return result
end

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function defaultErrorHandler(context)
    return function(exitCode, stdout, stderr)
        local message =
            context.failureMessage
            or (
                "Action failed with exit code "
                .. tostring(exitCode)
            )

        if context.alertOnFailure ~= false then
            hs.alert.show(message)
        end

        print(
            "[Actions] Action failed"
                .. "\nExit code: "
                .. tostring(exitCode)
                .. "\nStandard output:\n"
                .. tostring(stdout or "")
                .. "\nStandard error:\n"
                .. tostring(stderr or "")
        )
    end
end

-- Execute an action after an optional delay.
local function executeWithDelay(delay, callback)
    if delay and delay > 0 then
        hs.timer.doAfter(delay, callback)
        return
    end

    callback()
end

-- ---------------------------------------------------------------------
-- Hotkey parsing
-- ---------------------------------------------------------------------

local modifierAliases = {
    -- Command
    command = "cmd",
    cmd = "cmd",
    ["⌘"] = "cmd",

    -- Control
    control = "ctrl",
    ctrl = "ctrl",
    ctl = "ctrl",
    ["⌃"] = "ctrl",

    -- Option
    option = "alt",
    opt = "alt",
    alt = "alt",
    ["⌥"] = "alt",

    -- Shift
    shift = "shift",
    ["⇧"] = "shift",

    -- Function
    fn = "fn",
    functionkey = "fn",
}

local keyAliases = {
    ["return"] = "return",
    ["enter"] = "return",

    ["escape"] = "escape",
    ["esc"] = "escape",

    ["space"] = "space",
    ["spacebar"] = "space",

    ["tab"] = "tab",
    ["backtab"] = "tab",

    ["delete"] = "delete",
    ["backspace"] = "delete",

    ["forwarddelete"] = "forwarddelete",

    ["left"] = "left",
    ["leftarrow"] = "left",

    ["right"] = "right",
    ["rightarrow"] = "right",

    ["up"] = "up",
    ["uparrow"] = "up",

    ["down"] = "down",
    ["downarrow"] = "down",

    ["home"] = "home",
    ["end"] = "end",

    ["pageup"] = "pageup",
    ["pagedown"] = "pagedown",

    ["minus"] = "-",
    ["hyphen"] = "-",

    ["equal"] = "=",
    ["equals"] = "=",

    ["comma"] = ",",
    ["period"] = ".",
    ["slash"] = "/",
    ["backslash"] = "\\",
    ["semicolon"] = ";",
    ["quote"] = "'",
    ["leftbracket"] = "[",
    ["rightbracket"] = "]",
    ["grave"] = "`",
}

local function normalizeModifier(value)
    local normalized =
        trim(tostring(value)):lower()

    local modifier = modifierAliases[normalized]

    if not modifier then
        error(
            "Unsupported hotkey modifier: "
                .. tostring(value),
            3
        )
    end

    return modifier
end

local function normalizeKey(value)
    local original = trim(tostring(value))
    local lowered = original:lower()
    local alias = keyAliases[lowered]

    if alias then
        return alias
    end

    -- Function keys such as F1 through F20.
    if lowered:match("^f%d+$") then
        return lowered
    end

    -- Single printable characters.
    if #original == 1 then
        return original:lower()
    end

    return lowered
end

-- Parses a shortcut string such as:
--
--     Command+Shift+B
--     Control+Alt+Left
--     Control+Alt+Return
--     Control+Alt+=
--     Control+Alt+-
--
-- Returns:
--
--     modifiers, key
--
-- Example:
--
--     local modifiers, key =
--         Actions.parseHotkey("Command+Shift+B")
function Actions.parseHotkey(shortcut)
    if type(shortcut) ~= "string"
        or trim(shortcut) == ""
    then
        error(
            "Hotkey must be a non-empty string",
            2
        )
    end

    local components = {}

    for component in shortcut:gmatch("[^+]+") do
        table.insert(
            components,
            trim(component)
        )
    end

    if #components == 0 then
        error(
            "Could not parse hotkey: " .. shortcut,
            2
        )
    end

    local keyComponent =
        table.remove(components)

    local modifiers = {}

    for _, component in ipairs(components) do
        table.insert(
            modifiers,
            normalizeModifier(component)
        )
    end

    local key = normalizeKey(keyComponent)

    if key == "" then
        error(
            "Hotkey is missing its key: " .. shortcut,
            2
        )
    end

    return modifiers, key
end

-- ---------------------------------------------------------------------
-- Keyboard actions
-- ---------------------------------------------------------------------

-- Creates an action that emits a keyboard shortcut.
--
-- Example:
--
--     Actions.hotkey(
--         { "cmd", "shift" },
--         "b"
--     )
--
-- Options:
--
-- {
--     delay = 0,
--     keyDelay = 0,
-- }
function Actions.hotkey(modifiers, key, options)
    if type(modifiers) ~= "table" then
        error(
            "Actions.hotkey modifiers must be a table",
            2
        )
    end

    if type(key) ~= "string"
        or key == ""
    then
        error(
            "Actions.hotkey key must be a non-empty string",
            2
        )
    end

    options = options or {}

    local normalizedModifiers = {}

    for _, modifier in ipairs(modifiers) do
        table.insert(
            normalizedModifiers,
            normalizeModifier(modifier)
        )
    end

    local normalizedKey = normalizeKey(key)

    return function()
        executeWithDelay(
            options.delay or 0,
            function()
                hs.eventtap.keyStroke(
                    normalizedModifiers,
                    normalizedKey,
                    options.keyDelay or 0
                )
            end
        )
    end
end

-- Creates an action from a readable shortcut string.
--
-- Examples:
--
--     Actions.hotkeyString("Command+Shift+B")
--     Actions.hotkeyString("Control+Alt+Left")
--     Actions.hotkeyString("Control+Alt+Return")
--
-- Options:
--
-- {
--     delay = 0,
--     keyDelay = 0,
-- }
function Actions.hotkeyString(shortcut, options)
    local modifiers, key =
        Actions.parseHotkey(shortcut)

    return Actions.hotkey(
        modifiers,
        key,
        options
    )
end

-- Alias emphasizing its use for SuperCmd command hotkeys.
--
-- SuperCmd is still responsible for registering the global command
-- shortcut. Hammerspoon simply emits that shortcut.
--
-- Example:
--
--     Actions.superCmdHotkey(
--         "Command+Shift+B"
--     )
function Actions.superCmdHotkey(shortcut, options)
    return Actions.hotkeyString(
        shortcut,
        options
    )
end

-- Types ordinary text.
--
-- Example:
--
--     Actions.text("Hello from Hammerspoon")
function Actions.text(value, options)
    if type(value) ~= "string" then
        error(
            "Actions.text value must be a string",
            2
        )
    end

    options = options or {}

    return function()
        executeWithDelay(
            options.delay or 0,
            function()
                hs.eventtap.keyStrokes(value)
            end
        )
    end
end

-- ---------------------------------------------------------------------
-- Application actions
-- ---------------------------------------------------------------------

-- Launches an application or focuses it if it is already running.
--
-- Example:
--
--     Actions.application("Visual Studio Code")
function Actions.application(applicationName, options)
    if type(applicationName) ~= "string"
        or applicationName == ""
    then
        error(
            "Application name must be a non-empty string",
            2
        )
    end

    options = options or {}

    return function()
        executeWithDelay(
            options.delay or 0,
            function()
                local launched =
                    hs.application.launchOrFocus(
                        applicationName
                    )

                if not launched
                    and options.alertOnFailure ~= false
                then
                    hs.alert.show(
                        options.failureMessage
                            or (
                                "Could not launch "
                                .. applicationName
                            )
                    )
                end
            end
        )
    end
end

-- Launches or focuses an application using its bundle identifier.
--
-- Example:
--
--     Actions.applicationBundle(
--         "com.microsoft.VSCode"
--     )
function Actions.applicationBundle(bundleId, options)
    if type(bundleId) ~= "string"
        or bundleId == ""
    then
        error(
            "Bundle identifier must be a non-empty string",
            2
        )
    end

    options = options or {}

    return function()
        executeWithDelay(
            options.delay or 0,
            function()
                local launched =
                    hs.application.launchOrFocusByBundleID(
                        bundleId
                    )

                if not launched
                    and options.alertOnFailure ~= false
                then
                    hs.alert.show(
                        options.failureMessage
                            or (
                                "Could not launch "
                                .. bundleId
                            )
                    )
                end
            end
        )
    end
end

-- ---------------------------------------------------------------------
-- URL actions
-- ---------------------------------------------------------------------

-- Opens a URL using the default macOS handler.
--
-- Example:
--
--     Actions.url("https://github.com")
function Actions.url(url, options)
    if type(url) ~= "string"
        or url == ""
    then
        error(
            "URL must be a non-empty string",
            2
        )
    end

    options = options or {}

    return function()
        executeWithDelay(
            options.delay or 0,
            function()
                local opened =
                    hs.urlevent.openURL(url)

                if opened == false
                    and options.alertOnFailure ~= false
                then
                    hs.alert.show(
                        options.failureMessage
                            or "Could not open URL"
                    )
                end
            end
        )
    end
end

-- ---------------------------------------------------------------------
-- Shell actions
-- ---------------------------------------------------------------------

-- Runs a command through a login shell.
--
-- This is useful for commands that depend on shell initialization,
-- Homebrew PATH configuration, mise, pyenv, nvm, aliases, or shell
-- environment variables.
--
-- Example:
--
--     Actions.shell(
--         "$HOME/bin/update-projects",
--         {
--             successMessage = "Projects updated",
--             failureMessage = "Update failed",
--             printOutput = true,
--         }
--     )
function Actions.shell(command, options)
    if type(command) ~= "string"
        or command == ""
    then
        error(
            "Shell command must be a non-empty string",
            2
        )
    end

    options = options or {}

    local shell =
        options.shell
        or os.getenv("SHELL")
        or "/bin/zsh"

    return function()
        executeWithDelay(
            options.delay or 0,
            function()
                local task

                task = hs.task.new(
                    shell,
                    function(exitCode, stdout, stderr)
                        if exitCode ~= 0 then
                            local onError =
                                defaultErrorHandler(options)

                            onError(
                                exitCode,
                                stdout,
                                stderr
                            )

                            if options.onFailure then
                                options.onFailure(
                                    exitCode,
                                    stdout,
                                    stderr
                                )
                            end

                            return
                        end

                        if options.printOutput
                            and stdout
                            and stdout ~= ""
                        then
                            print(
                                "[Actions.shell] Output:\n"
                                    .. stdout
                            )
                        end

                        if options.successMessage then
                            hs.alert.show(
                                options.successMessage
                            )
                        end

                        if options.onSuccess then
                            options.onSuccess(
                                stdout,
                                stderr
                            )
                        end
                    end,
                    {
                        "-lc",
                        command,
                    }
                )

                if not task then
                    hs.alert.show(
                        options.failureMessage
                            or "Could not create shell task"
                    )

                    return
                end

                local started = task:start()

                if not started
                    and options.alertOnFailure ~= false
                then
                    hs.alert.show(
                        options.failureMessage
                            or "Could not start shell command"
                    )
                end
            end
        )
    end
end

-- ---------------------------------------------------------------------
-- Script actions
-- ---------------------------------------------------------------------

-- Executes a script directly without invoking a shell.
--
-- The script must have an executable shebang and executable permission,
-- unless an interpreter is supplied.
--
-- Examples:
--
--     Actions.script(
--         "~/.local/bin/bookmarks"
--     )
--
--     Actions.script(
--         "~/.local/bin/report.py",
--         { "--today" },
--         {
--             interpreter = "/usr/bin/python3",
--         }
--     )
function Actions.script(scriptPath, arguments, options)
    if type(scriptPath) ~= "string"
        or scriptPath == ""
    then
        error(
            "Script path must be a non-empty string",
            2
        )
    end

    arguments = arguments or {}
    options = options or {}

    local expandedPath =
        expandHome(scriptPath)

    return function()
        executeWithDelay(
            options.delay or 0,
            function()
                local executable = expandedPath
                local taskArguments = {}

                if options.interpreter then
                    executable =
                        expandHome(options.interpreter)

                    table.insert(
                        taskArguments,
                        expandedPath
                    )
                end

                for _, argument in ipairs(arguments) do
                    table.insert(
                        taskArguments,
                        tostring(argument)
                    )
                end

                local task = hs.task.new(
                    executable,
                    function(exitCode, stdout, stderr)
                        if exitCode ~= 0 then
                            local onError =
                                defaultErrorHandler(options)

                            onError(
                                exitCode,
                                stdout,
                                stderr
                            )

                            if options.onFailure then
                                options.onFailure(
                                    exitCode,
                                    stdout,
                                    stderr
                                )
                            end

                            return
                        end

                        if options.printOutput
                            and stdout
                            and stdout ~= ""
                        then
                            print(
                                "[Actions.script] Output:\n"
                                    .. stdout
                            )
                        end

                        if options.successMessage then
                            hs.alert.show(
                                options.successMessage
                            )
                        end

                        if options.onSuccess then
                            options.onSuccess(
                                stdout,
                                stderr
                            )
                        end
                    end,
                    taskArguments
                )

                if not task then
                    hs.alert.show(
                        options.failureMessage
                            or (
                                "Could not create task: "
                                .. scriptPath
                            )
                    )

                    return
                end

                if options.environment then
                    local environment = {}

                    for key, value in pairs(
                        hs.processInfo.environment
                    ) do
                        environment[key] = value
                    end

                    for key, value in pairs(
                        options.environment
                    ) do
                        environment[key] = value
                    end

                    task:setEnvironment(environment)
                end

                local started = task:start()

                if not started
                    and options.alertOnFailure ~= false
                then
                    hs.alert.show(
                        options.failureMessage
                            or (
                                "Could not start script: "
                                .. scriptPath
                            )
                    )
                end
            end
        )
    end
end

-- ---------------------------------------------------------------------
-- Apple Shortcuts actions
-- ---------------------------------------------------------------------

-- Runs an Apple Shortcut using the macOS shortcuts CLI.
--
-- Example:
--
--     Actions.appleShortcut("Create Note")
function Actions.appleShortcut(shortcutName, options)
    if type(shortcutName) ~= "string"
        or shortcutName == ""
    then
        error(
            "Shortcut name must be a non-empty string",
            2
        )
    end

    options = options or {}

    return Actions.script(
        "/usr/bin/shortcuts",
        {
            "run",
            shortcutName,
        },
        options
    )
end

-- ---------------------------------------------------------------------
-- Generic callback wrappers
-- ---------------------------------------------------------------------

-- Wraps a function with an optional delay.
--
-- Example:
--
--     Actions.callback(function()
--         hs.reload()
--     end)
function Actions.callback(callback, options)
    if type(callback) ~= "function" then
        error(
            "Actions.callback requires a function",
            2
        )
    end

    options = options or {}

    return function()
        executeWithDelay(
            options.delay or 0,
            callback
        )
    end
end

-- Runs several actions sequentially with a configurable interval.
--
-- Example:
--
--     Actions.sequence({
--         Actions.application("Safari"),
--         Actions.hotkeyString("Command+L"),
--         Actions.text("https://github.com"),
--         Actions.hotkeyString("Return"),
--     }, {
--         interval = 0.15,
--     })
function Actions.sequence(actions, options)
    if type(actions) ~= "table" then
        error(
            "Actions.sequence requires an array of actions",
            2
        )
    end

    options = options or {}

    local interval = options.interval or 0.10

    return function()
        for index, action in ipairs(actions) do
            if type(action) ~= "function" then
                error(
                    "Actions.sequence item "
                        .. tostring(index)
                        .. " is not a function"
                )
            end

            hs.timer.doAfter(
                (index - 1) * interval,
                action
            )
        end
    end
end

return Actions
