-- whispr.lua
-- Voice-to-agent pipeline: F13 toggle → rec (sox_ng) → whisper/groq → tmux
--
-- CONFIGURATION — edit these to customise behaviour:
local AGENT_CMD        = "claude"                 -- command run in tmux pane (swap to "gemini" etc.)
local TMUX_TARGET      = "Neo:0.0"               -- session:window.pane
local AGENT_READY_WAIT = 2                        -- seconds to wait after starting agent

-- Transcription backend — change BACKEND to switch; cmd/model are selected automatically.
local BACKEND = "mlx-whisper"  -- "whisper-cpp" | "mlx-whisper" | "groq"

local BACKENDS = {
    ["whisper-cpp"] = {
        cmd   = "/opt/homebrew/bin/whisper-cli",
        model = "/opt/homebrew/share/whisper-cpp/ggml-large-v3-q5_0.bin",
    },
    ["mlx-whisper"] = {
        cmd   = os.getenv("HOME") .. "/.local/bin/mlx_whisper",
        model = "mlx-community/whisper-large-v3-turbo",
    },
    ["groq"] = {
        cmd   = "groq",   -- not a binary; whispr_process.py uses urllib
        model = "whisper-large-v3-turbo",
    },
}

local BACKEND_CMD = BACKENDS[BACKEND].cmd
local MODEL       = BACKENDS[BACKEND].model

local REC_CMD         = "/opt/homebrew/bin/rec"       -- sox_ng rec binary
local WAV_PATH        = "/tmp/whispr.wav"
local PROCESS_TIMEOUT = 120                            -- seconds before killing hung whispr_process.py
local MIN_RECORD_SECS = 0.5                            -- discard recordings shorter than this

local M = {}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local recProcess   = nil    -- hs.task handle for rec; non-nil only while recording
local processTask  = nil    -- hs.task handle for whispr_process.py
local processTimer = nil    -- hs.timer for PROCESS_TIMEOUT
local isProcessing = false  -- true while whispr_process.py is running
local menuItem     = nil    -- transient hs.menubar item (nil when inactive)
local recStartTime = nil    -- epoch seconds when recording started
local recAlert     = nil    -- on-screen recording indicator UUID

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clearMenu()
    if menuItem then
        menuItem:delete()
        menuItem = nil
    end
end

local function clearAlert()
    if recAlert then
        hs.alert.closeSpecific(recAlert)
        recAlert = nil
    end
end

local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true end
    return false
end

local function fileSize(path)
    local f = io.open(path, "r")
    if not f then return 0 end
    local size = f:seek("end")
    f:close()
    return size or 0
end

-- ---------------------------------------------------------------------------
-- rec exit callback
-- ---------------------------------------------------------------------------
local function onRecExit(exitCode, _, stderr)
    recProcess = nil
    clearAlert()

    -- Check elapsed time — discard very short recordings silently
    local elapsed = 0
    if recStartTime then
        elapsed = hs.timer.secondsSinceEpoch() - recStartTime
        recStartTime = nil
    end

    if elapsed < MIN_RECORD_SECS then
        clearMenu()
        return
    end

    -- rec exits 0 on SIGINT (clean stop) and non-zero on actual errors
    if exitCode ~= 0 then
        hs.alert("Whispr: recorder failed — " .. (stderr ~= "" and stderr or "exit " .. exitCode))
        clearMenu()
        return
    end

    -- Verify WAV was written and has content
    if not fileExists(WAV_PATH) or fileSize(WAV_PATH) < 100 then
        clearMenu()
        return
    end

    -- Launch transcription + dispatch
    isProcessing = true
    if menuItem then menuItem:setTitle("⟳") end

    local scriptPath = hs.configdir .. "/whispr_process.py"
    processTask = hs.task.new(
        "/usr/bin/python3",
        function(code, _, err)
            if processTimer then processTimer:stop(); processTimer = nil end
            processTask  = nil
            isProcessing = false
            clearMenu()
            if code ~= 0 then
                hs.alert("Whispr: " .. (err ~= "" and err or "script failed (exit " .. code .. ")"))
            end
        end,
        { scriptPath,
          WAV_PATH,
          TMUX_TARGET,
          AGENT_CMD,
          BACKEND,
          BACKEND_CMD,
          MODEL,
          tostring(AGENT_READY_WAIT) }
    )
    if not processTask:start() then
        processTask  = nil
        isProcessing = false
        clearMenu()
        hs.alert("Whispr: failed to launch processing script")
        return
    end

    processTimer = hs.timer.doAfter(PROCESS_TIMEOUT, function()
        processTimer = nil
        if processTask then
            processTask:terminate()
            hs.alert("Whispr: timed out after " .. PROCESS_TIMEOUT .. "s")
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Toggle handler — bound to F13 in init.lua
-- ---------------------------------------------------------------------------
function M.toggle()
    if isProcessing then
        hs.alert("⟳ Whispr: processing, please wait…")
        return
    end

    if recProcess == nil then
        -- START recording
        menuItem = hs.menubar.new()
        if menuItem then menuItem:setTitle("⏺ REC") end
        recAlert     = hs.alert.show("🎙 Recording…", {}, hs.screen.mainScreen(), 99999)
        recStartTime = hs.timer.secondsSinceEpoch()

        recProcess = hs.task.new(
            REC_CMD,
            onRecExit,
            { "-r", "16000", "-c", "1", "-b", "16", WAV_PATH }
        )
        if not recProcess:start() then
            recProcess = nil
            clearMenu()
            clearAlert()
            hs.alert("Whispr: failed to start recorder — is sox_ng installed?")
            return
        end
        hs.execute("afplay /System/Library/Sounds/Tink.aiff &")
    else
        -- STOP recording: SIGINT → rec finalizes WAV header and exits cleanly
        hs.execute("afplay /System/Library/Sounds/Pop.aiff &")
        recProcess:interrupt()
    end
end

return M
