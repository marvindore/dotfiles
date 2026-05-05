-- whispr.lua
-- Voice-to-agent pipeline: F2 toggle → rec (sox_ng) → whisper-cpp → tmux
--
-- CONFIGURATION — edit these to customise behaviour:
local AGENT_CMD        = "claude"                 -- command run in tmux pane (swap to "gemini" etc.)
local TMUX_TARGET      = "Neo:0.0"               -- session:window.pane
local AGENT_READY_WAIT = 2                        -- seconds to wait after starting agent

-- Transcription backend — swap all three to switch to mlx-whisper:
--   BACKEND     = "mlx-whisper"
--   BACKEND_CMD = "/opt/homebrew/bin/mlx_whisper"
--   MODEL       = "mlx-community/whisper-large-v3"
local BACKEND      = "whisper-cpp"
local BACKEND_CMD  = "/opt/homebrew/bin/whisper-cli"
local MODEL        = os.getenv("HOME") .. "/.cache/whisper/ggml-large-v3-q5_0.bin"

local PYTHON_CMD      = "/opt/homebrew/bin/python3"  -- python3 (no mlx-whisper needed for whisper-cpp backend)
local REC_CMD         = "/opt/homebrew/bin/rec"       -- sox_ng; hard-coded path avoids Hammerspoon PATH issues
local PROCESS_TIMEOUT = 120                           -- seconds before killing hung whispr_process.py
local MIN_RECORD_SECS = 0.5                           -- discard recordings shorter than this

local M = {}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local recProcess      = nil    -- hs.task handle for rec; non-nil only while recording
local processTask     = nil    -- hs.task handle for whispr_process.py
local processTimer    = nil    -- hs.timer for PROCESS_TIMEOUT
local isProcessing    = false  -- true while whispr_process.py is running
local wasTerminated   = false  -- set before terminate() to distinguish SIGTERM from crash
local isSilentDiscard = false  -- set when recording is too short to process
local menuItem        = nil    -- transient hs.menubar item (nil when inactive)
local recStartTime    = nil    -- epoch seconds when recording started

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clearMenu()
    if menuItem then
        menuItem:delete()
        menuItem = nil
    end
end

-- ---------------------------------------------------------------------------
-- rec exit callback
-- ---------------------------------------------------------------------------
local function onRecExit(exitCode, _, stderr)
    if isSilentDiscard then
        -- Toggle handler already nilled recProcess and deleted menuItem.
        -- Just reset flags — do not start processing.
        isSilentDiscard = false
        wasTerminated   = false
        return
    end

    if not wasTerminated and exitCode ~= 0 then
        -- rec crashed on its own (mic denied, device error, etc.)
        hs.alert("Whispr: " .. (stderr ~= "" and stderr or "rec failed (exit " .. exitCode .. ")"))
        clearMenu()
        recProcess    = nil
        wasTerminated = false
        return
    end

    -- Normal stop: wasTerminated == true; rec exits non-zero on SIGTERM (typically 143).
    wasTerminated = false
    recProcess    = nil
    isProcessing  = true
    if menuItem then menuItem:setTitle("⟳") end

    local scriptPath = hs.configdir .. "/whispr_process.py"
    processTask = hs.task.new(
        PYTHON_CMD,
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
          "/tmp/whispr.wav",
          TMUX_TARGET,
          AGENT_CMD,
          BACKEND,
          BACKEND_CMD,
          MODEL,
          tostring(AGENT_READY_WAIT) }
    )
    processTask:start()

    -- Timeout: kill hung script after PROCESS_TIMEOUT seconds.
    -- Does NOT touch isProcessing/menuItem — the task exit callback handles cleanup.
    processTimer = hs.timer.doAfter(PROCESS_TIMEOUT, function()
        processTimer = nil
        if processTask then
            processTask:terminate()
            hs.alert("Whispr: timed out after " .. PROCESS_TIMEOUT .. "s")
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Toggle handler — bound to F2 in init.lua
-- ---------------------------------------------------------------------------
function M.toggle()
    if isProcessing then return end  -- ignore F2 while pipeline is running

    if recProcess == nil then
        -- START recording
        menuItem = hs.menubar.new()
        if menuItem then menuItem:setTitle("⏺ REC") end
        recStartTime = hs.timer.secondsSinceEpoch()

        recProcess = hs.task.new(
            REC_CMD,
            onRecExit,
            { "-q", "-r", "16000", "-c", "1", "-t", "wav", "/tmp/whispr.wav" }
        )
        recProcess:start()
    else
        -- STOP recording
        local elapsed = hs.timer.secondsSinceEpoch() - recStartTime
        if elapsed < MIN_RECORD_SECS then
            -- Too short — discard silently
            isSilentDiscard = true
            wasTerminated   = true
            recProcess:terminate()
            recProcess = nil  -- toggle handler nils this; exit callback checks isSilentDiscard
            clearMenu()
        else
            wasTerminated = true
            recProcess:terminate()
            -- recProcess is nil'd in onRecExit's normal-stop path
        end
    end
end

return M
