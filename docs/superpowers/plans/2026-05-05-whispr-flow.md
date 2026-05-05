# Whispr Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an F2 toggle that records audio, transcribes it locally with mlx-whisper, normalises developer vocabulary, and auto-submits the result to a tmux session running a configurable AI agent.

**Architecture:** `whispr.lua` owns the hotkey, `rec` process lifecycle, and transient menu bar indicator. `whispr_process.py` is a standalone Python script that transcribes (mlx_whisper), normalises (find-replace regex dict), verifies the tmux session, and sends text via `tmux load-buffer` + `paste-buffer`. All config lives in `whispr.lua` and is passed to the Python script as CLI arguments.

**Tech Stack:** Hammerspoon (Lua), sox_ng (`rec` binary), mlx-whisper (Apple Silicon), tmux

**Spec:** `docs/superpowers/specs/2026-05-05-whispr-flow-design.md`

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `dot_hammerspoon/whispr.lua` | **Create** | Hotkey, rec process, exit callback, menu bar, timeout |
| `dot_hammerspoon/whispr_process.py` | **Create** | Transcribe, normalise, verify tmux, send text |
| `dot_hammerspoon/tests/test_whispr_process.py` | **Create** | Unit tests for pure text-processing functions |
| `dot_hammerspoon/init.lua` | **Modify** | Add `require("whispr")` + F2 hotkey binding |

---

## Task 1: Install dependencies

**Files:** none (shell setup)

- [ ] **Step 1: Install sox_ng**

```bash
brew install sox_ng
```

Expected: `sox_ng` installs successfully. Verify:
```bash
rec --version
```
Expected output contains `SoX NG`.

- [ ] **Step 2: Install mlx-whisper**

```bash
/opt/homebrew/bin/pip3 install mlx-whisper
```

Verify:
```bash
/opt/homebrew/bin/python3 -c "import mlx_whisper; print('ok')"
```
Expected: `ok`

- [ ] **Step 3: Verify mlx_whisper binary**

```bash
/opt/homebrew/bin/mlx_whisper --help 2>&1 | head -3
```

Expected: help output referencing `mlx_whisper`. If the binary is at a different path, note it — you'll need to update `PYTHON_CMD` in `whispr.lua` or pass the full path to `mlx_whisper` in the script.

- [ ] **Step 4: Confirm tmux session target**

```bash
tmux list-sessions 2>/dev/null || echo "no tmux sessions"
```

Note whether a session named `Neo` already exists. The script creates it automatically if absent — this is just for awareness.

- [ ] **Step 5: Commit nothing yet** (deps are system-level, not in the repo)

---

## Task 2: `whispr_process.py` — text processing functions (TDD)

The pure functions (find-replace, timestamp stripping) can be unit-tested in isolation. Build and test them first before wiring the full pipeline.

**Files:**
- Create: `dot_hammerspoon/tests/test_whispr_process.py`
- Create: `dot_hammerspoon/whispr_process.py` (skeleton + pure functions only)

- [ ] **Step 1: Create tests directory and test file**

```bash
mkdir -p /Users/marvin.dore/.local/share/chezmoi/dot_hammerspoon/tests
```

Create `dot_hammerspoon/tests/test_whispr_process.py`:

```python
"""Unit tests for whispr_process.py pure text-processing functions."""
import importlib.util, sys, re
from pathlib import Path

# Load whispr_process.py as a module without running main()
spec = importlib.util.spec_from_file_location(
    "whispr_process",
    Path(__file__).parent.parent / "whispr_process.py"
)
mod = importlib.util.module_from_spec(spec)
# Stub sys.argv so the module-level arg parsing doesn't fail on import
sys.argv = ["whispr_process.py", "/tmp/x.wav", "Neo:0.0", "claude", "mlx-community/whisper-large-v3", "2"]
spec.loader.exec_module(mod)


class TestStripTimestamps:
    def test_strips_single_timestamp(self):
        raw = "[00:00:00.000 --> 00:00:05.000] hello world"
        assert mod.strip_timestamps(raw) == "hello world"

    def test_strips_multiple_timestamps(self):
        raw = "[00:00:00.000 --> 00:00:03.000] hello\n[00:00:03.000 --> 00:00:06.000] world"
        assert mod.strip_timestamps(raw) == "hello\nworld"

    def test_no_timestamps_unchanged(self):
        raw = "kubectl apply -f deployment.yaml"
        assert mod.strip_timestamps(raw) == "kubectl apply -f deployment.yaml"

    def test_empty_string(self):
        assert mod.strip_timestamps("") == ""

    def test_all_timestamps_produces_empty(self):
        # Pure timestamp file → empty string → triggers empty-transcript guard at runtime
        raw = "[00:00:00.000 --> 00:00:03.000]  \n[00:00:03.000 --> 00:00:06.000]  "
        assert mod.strip_timestamps(raw) == ""


class TestApplyReplacements:
    def test_github_space(self):
        assert mod.apply_replacements("push to git hub") == "push to GitHub"

    def test_kubectl_cuddle(self):
        assert mod.apply_replacements("run kube cuddle get pods") == "run kubectl get pods"

    def test_postgresql(self):
        assert mod.apply_replacements("connect to post gress") == "connect to PostgreSQL"

    def test_grpc(self):
        assert mod.apply_replacements("using grpc service") == "using gRPC service"

    def test_case_insensitive(self):
        assert mod.apply_replacements("using GRPC service") == "using gRPC service"

    def test_oauth_not_corrupted_in_oauth2(self):
        # oauth2 should NOT be touched (word boundary protects it)
        result = mod.apply_replacements("using oauth2 tokens")
        assert result == "using oauth2 tokens"

    def test_api_spelled_out(self):
        assert mod.apply_replacements("call the a p i endpoint") == "call the API endpoint"

    def test_neovim_split(self):
        assert mod.apply_replacements("open neo vim") == "open Neovim"

    def test_no_match_unchanged(self):
        assert mod.apply_replacements("docker run hello-world") == "docker run hello-world"
```

- [ ] **Step 2: Run tests — expect ImportError or AttributeError (file doesn't exist yet)**

```bash
cd /Users/marvin.dore/.local/share/chezmoi/dot_hammerspoon
/opt/homebrew/bin/python3 -m pytest tests/test_whispr_process.py -v 2>&1 | head -20
```

Expected: `FileNotFoundError` (whispr_process.py doesn't exist yet) — confirms tests aren't passing vacuously.

- [ ] **Step 3: Create `whispr_process.py` skeleton with pure functions**

Create `dot_hammerspoon/whispr_process.py`:

```python
#!/usr/bin/env python3
"""
whispr_process.py — transcribe, normalise, and dispatch to tmux.

Usage: python3 whispr_process.py <wav> <tmux_target> <agent_cmd> <model> <ready_wait>

Exit codes:
  0 — success (including empty-transcript early exit)
  1 — transcription failed
  2 — tmux error
"""
import os
import re
import subprocess
import sys
import time

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
_, wav_path, tmux_target, agent_cmd, model, ready_wait_str = sys.argv
agent_ready_wait = float(ready_wait_str)

# ---------------------------------------------------------------------------
# Find-replace dictionary
# All entries applied as whole-word, case-insensitive regex (\b boundaries).
# ---------------------------------------------------------------------------
REPLACEMENTS = {
    # Git / hosting
    r"get hub":        "GitHub",
    r"git hub":        "GitHub",
    r"git lab":        "GitLab",
    # Kubernetes
    r"kube cuddle":    "kubectl",
    r"kube city":      "kubectl",
    r"kube ctl":       "kubectl",
    r"cube ctl":       "kubectl",
    # Databases
    r"post gress":     "PostgreSQL",
    r"postgress":      "PostgreSQL",
    r"my sequel":      "MySQL",
    r"no sequel":      "NoSQL",
    # Protocols / formats
    r"g ?r ?p ?c":     "gRPC",
    r"graph ?q ?l":    "GraphQL",
    r"web hook":       "webhook",
    r"web socket":     "WebSocket",
    r"jay son":        "JSON",
    r"j ?w ?t":        "JWT",
    r"o ?auth":        "OAuth",
    # Acronyms Whisper spells out
    r"a ?p ?i":        "API",
    r"c ?l ?i":        "CLI",
    r"u ?r ?l":        "URL",
    r"s ?s ?h":        "SSH",
    r"v ?p ?n":        "VPN",
    r"d ?n ?s":        "DNS",
    r"c ?r ?u ?d":     "CRUD",
    r"u ?u ?i ?d":     "UUID",
    r"y ?a ?m ?l":     "YAML",
    r"t ?o ?m ?l":     "TOML",
    # Tools
    r"neo ?vim":       "Neovim",
    r"aero ?space":    "AeroSpace",
    r"hammer ?spoon":  "Hammerspoon",
    r"home ?brew":     "Homebrew",
    r"pie ?pie":       "PyPI",
    r"vs code":        "VS Code",
}

# ---------------------------------------------------------------------------
# Pure functions (unit-testable)
# ---------------------------------------------------------------------------

def strip_timestamps(text: str) -> str:
    """Remove [HH:MM:SS.mmm --> HH:MM:SS.mmm] timestamp prefixes."""
    return re.sub(
        r'\[\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}\]\s*',
        '',
        text,
    ).strip()


def apply_replacements(text: str) -> str:
    """Apply REPLACEMENTS dict using whole-word case-insensitive regex."""
    for pattern, replacement in REPLACEMENTS.items():
        text = re.sub(r'\b' + pattern + r'\b', replacement, text, flags=re.IGNORECASE)
    return text


# ---------------------------------------------------------------------------
# Main pipeline (runs when executed directly, not on import)
# ---------------------------------------------------------------------------

def main():
    txt_path = "/tmp/whispr.txt"

    # Step 1: Remove stale transcript (mlx_whisper does not overwrite)
    if os.path.exists(txt_path):
        os.remove(txt_path)

    # Step 2: Transcribe
    result = subprocess.run(
        ["mlx_whisper", wav_path, "--model", model,
         "--output-format", "txt", "--output-dir", "/tmp"],
        capture_output=True, text=True,
    )
    if result.returncode != 0 or not os.path.exists(txt_path):
        sys.stderr.write(result.stderr or "mlx_whisper produced no output\n")
        sys.exit(1)

    # Step 3: Strip timestamp artifacts
    raw = open(txt_path).read()
    text = strip_timestamps(raw)

    # Step 4: Guard empty transcript
    if not text:
        sys.exit(0)

    # Step 5: Normalise developer vocabulary
    text = apply_replacements(text)

    # Step 6: Verify tmux session + agent
    session   = tmux_target.split(":")[0]
    agent_bin = os.path.basename(agent_cmd.split()[0])

    def session_exists() -> bool:
        return subprocess.run(
            ["tmux", "has-session", "-t", session],
            capture_output=True,
        ).returncode == 0

    def pane_command() -> str:
        r = subprocess.run(
            ["tmux", "display-message", "-p", "-t", tmux_target, "#{pane_current_command}"],
            capture_output=True, text=True,
        )
        return r.stdout.strip()

    if not session_exists():
        subprocess.run(["tmux", "new-session", "-d", "-s", session])
        subprocess.run(["tmux", "send-keys", "-t", tmux_target, agent_cmd, "Enter"])
        time.sleep(agent_ready_wait)
    elif pane_command() != agent_bin:
        subprocess.run(["tmux", "send-keys", "-t", tmux_target, agent_cmd, "Enter"])
        time.sleep(agent_ready_wait)

    # Step 7: Send text safely (named buffer avoids racing with user's buffer0)
    proc = subprocess.run(
        ["tmux", "load-buffer", "-b", "whispr", "-"],
        input=(text + "\n").encode(),
        capture_output=True,
    )
    if proc.returncode != 0:
        sys.stderr.write("tmux load-buffer failed\n")
        sys.exit(2)

    proc = subprocess.run(
        ["tmux", "paste-buffer", "-b", "whispr", "-t", tmux_target],
        capture_output=True,
    )
    if proc.returncode != 0:
        sys.stderr.write("tmux paste-buffer failed\n")
        sys.exit(2)


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd /Users/marvin.dore/.local/share/chezmoi/dot_hammerspoon
/opt/homebrew/bin/python3 -m pytest tests/test_whispr_process.py -v
```

Expected: all tests pass. Fix any failures before continuing.

- [ ] **Step 5: Commit**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
git add dot_hammerspoon/whispr_process.py dot_hammerspoon/tests/test_whispr_process.py
git commit -m "feat: add whispr_process.py with text normalisation and tmux dispatch"
```

---

## Task 3: Smoke-test `whispr_process.py` against a live tmux session

Integration smoke test: record a real WAV with `rec`, run the script, verify text lands in tmux.

**Files:** none (manual testing)

- [ ] **Step 1: Create a test tmux session**

```bash
tmux new-session -d -s whispr_test
```

- [ ] **Step 2: Record 3 seconds of yourself saying "kubectl get pods"**

```bash
rec -q -r 16000 -c 1 -t wav /tmp/whispr.wav trim 0 3
```

(Press Ctrl-C after ~3 seconds if it doesn't auto-stop — `trim 0 3` limits to 3s.)

- [ ] **Step 3: Run the script against the test session**

```bash
/opt/homebrew/bin/python3 \
  /Users/marvin.dore/.local/share/chezmoi/dot_hammerspoon/whispr_process.py \
  /tmp/whispr.wav \
  whispr_test:0.0 \
  cat \
  mlx-community/whisper-large-v3 \
  2
```

Note: first run downloads the model (~3 GB) — this will take several minutes. Subsequent runs are instant.

Expected: the transcript text appears in the `whispr_test` pane (check with `tmux attach -t whispr_test`).

- [ ] **Step 4: Verify find-replace applied**

Say "using g r p c" in a new recording and confirm `gRPC` appears in tmux output.

- [ ] **Step 5: Clean up test session**

```bash
tmux kill-session -t whispr_test
```

---

## Task 4: Write `whispr.lua`

**Files:**
- Create: `dot_hammerspoon/whispr.lua`

- [ ] **Step 1: Create `whispr.lua`**

Create `dot_hammerspoon/whispr.lua`:

```lua
-- whispr.lua
-- Voice-to-agent pipeline: F2 toggle → rec (sox_ng) → mlx-whisper → tmux
--
-- CONFIGURATION — edit these to customise behaviour:
local AGENT_CMD        = "claude"                           -- command run in tmux pane
local TMUX_TARGET      = "Neo:0.0"                         -- session:window.pane
local WHISPER_MODEL    = "mlx-community/whisper-large-v3"  -- any mlx-community variant
local AGENT_READY_WAIT = 2                                  -- seconds to wait after starting agent
local PYTHON_CMD       = "/opt/homebrew/bin/python3"       -- python3 with mlx-whisper installed
local REC_CMD          = "/opt/homebrew/bin/rec"           -- sox_ng rec binary; hard-coded path avoids Hammerspoon PATH issues
local PROCESS_TIMEOUT  = 120                               -- seconds before killing hung script
local MIN_RECORD_SECS  = 0.5                               -- discard recordings shorter than this

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
-- rec exit callback (called by hs.task when rec exits for any reason)
-- ---------------------------------------------------------------------------
local function onRecExit(exitCode, _, stderr)
    -- Silent-discard path: toggle handler already nilled recProcess and menuItem.
    -- Just reset flags and return — do not start processing.
    if isSilentDiscard then
        isSilentDiscard = false
        wasTerminated   = false
        return
    end

    -- Crash path: rec exited on its own with an error (mic denied, device gone, etc.)
    if not wasTerminated and exitCode ~= 0 then
        hs.alert("Whispr: " .. (stderr ~= "" and stderr or "rec failed (exit " .. exitCode .. ")"))
        clearMenu()
        recProcess    = nil
        wasTerminated = false
        return
    end

    -- Normal stop: we sent SIGTERM (wasTerminated == true).
    -- rec exits non-zero when killed by signal (typically 143); this is expected.
    wasTerminated = false
    recProcess    = nil
    isProcessing  = true
    if menuItem then menuItem:setTitle("⟳") end

    local scriptPath = hs.configdir .. "/whispr_process.py"
    processTask = hs.task.new(
        PYTHON_CMD,
        function(code, _, err)
            -- Cancel timeout timer
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
          WHISPER_MODEL,
          tostring(AGENT_READY_WAIT) }
    )
    processTask:start()

    -- Timeout guard: terminate the script if it hangs.
    -- Does NOT touch isProcessing/menuItem — the task exit callback handles that.
    -- If the exit callback somehow never fires, isProcessing stays true,
    -- which is the safe failure mode (blocks further recordings).
    processTimer = hs.timer.doAfter(PROCESS_TIMEOUT, function()
        processTimer = nil
        if processTask then
            processTask:terminate()
            hs.alert("Whispr: timed out after " .. PROCESS_TIMEOUT .. "s")
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Toggle handler — called on every F2 press
-- ---------------------------------------------------------------------------
function M.toggle()
    -- Ignore if transcription pipeline is running
    if isProcessing then return end

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
            recProcess = nil  -- nil here; exit callback checks isSilentDiscard and returns
            clearMenu()
        else
            wasTerminated = true
            recProcess:terminate()
            -- recProcess is nil'd in the exit callback's normal-stop path
        end
    end
end

return M
```

- [ ] **Step 2: Reload Hammerspoon and check for Lua errors**

In Hammerspoon Console (menubar → Hammerspoon → Console):
```lua
hs.reload()
```

Expected: no red error lines. If there are errors, fix them and reload again.

- [ ] **Step 3: Commit**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
git add dot_hammerspoon/whispr.lua
git commit -m "feat: add whispr.lua recording lifecycle and menu bar"
```

---

## Task 5: Wire `init.lua`

**Files:**
- Modify: `dot_hammerspoon/init.lua`

- [ ] **Step 1: Add whispr require and F2 hotkey**

Open `dot_hammerspoon/init.lua`. After the existing requires, add:

```lua
-- Whispr: voice dictation → tmux agent (F2 toggle)
local Whispr = require("whispr")
hs.hotkey.bind({}, "f2", Whispr.toggle)
```

The full file should look like:

```lua
-- ~/.hammerspoon/init.lua

-- Ctrl + Esc → Ctrl + Shift + Tab
hs.hotkey.bind({ "ctrl" }, "escape", function()
    hs.eventtap.keyStroke({ "ctrl", "shift" }, "tab")
end)

-- Scratchpad overlay (ctrl + alt + n)
local Scratchpad = require("scratchpad")
hs.hotkey.bind({ "ctrl", "shift" }, "n", Scratchpad.toggle)

-- Meeting popup (ctrl + shift + m)
local Calendar = require("calendar")
hs.hotkey.bind({ "ctrl", "shift" }, "m", Calendar.toggle)

-- Menu bar
require("menu-bar")

-- Whispr: voice dictation → tmux agent (F2 toggle)
local Whispr = require("whispr")
hs.hotkey.bind({}, "f2", Whispr.toggle)
```

- [ ] **Step 2: Reload Hammerspoon**

```lua
hs.reload()
```

Expected: no errors. F2 key is now bound.

- [ ] **Step 3: Commit**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
git add dot_hammerspoon/init.lua
git commit -m "feat: bind F2 to whispr toggle in init.lua"
```

---

## Task 6: End-to-end manual verification

Work through the spec's testing checklist manually.

**Files:** none

- [ ] **Step 1: Basic record → transcribe → send**

Ensure a tmux session `Neo` exists with `claude` running (or let the script create it):
```bash
tmux new-session -d -s Neo
```

Press F2. Speak: *"Use kubectl to get all pods in the kube system namespace."*
Press F2 again.

Expected:
- Menu bar shows `⏺ REC` while speaking
- Menu bar shows `⟳` while processing
- Menu bar disappears when done
- Text appears in tmux `Neo:0.0` with `kubectl` correctly rendered

- [ ] **Step 2: Sub-0.5s discard**

Press F2 and immediately press F2 again (within 0.5s).

Expected: menu bar clears immediately, no tmux output, no alert.

- [ ] **Step 3: F2 during processing is ignored**

Press F2, speak for 2s, press F2 to stop. While `⟳` is shown, press F2 again.

Expected: nothing happens — second press is ignored.

- [ ] **Step 4: Empty/silent recording**

Press F2, stay silent for 2s, press F2.

Expected: processing runs (⟳ shows briefly), no text sent to tmux, no alert.

- [ ] **Step 5: Auto-create session**

Kill the Neo session first:
```bash
tmux kill-session -t Neo 2>/dev/null; true
```

Press F2, say *"Hello agent"*, press F2.

Expected: script creates session `Neo`, starts `claude`, sends text.

- [ ] **Step 6: Special characters**

Press F2, say something that would naturally include dollar signs if typed (e.g., *"Echo the PATH variable"*). Press F2.

Expected: transcript sent without shell expansion — `PATH` appears literally, not expanded.

- [ ] **Step 7: Swap agent to `cat` for testing**

Temporarily change `AGENT_CMD = "cat"` in `whispr.lua`, reload Hammerspoon, record a phrase, verify the transcript appears in the `cat` pane (`cat` reads stdin and echoes it — safe). Restore `AGENT_CMD = "claude"` and reload.

- [ ] **Step 8: Stale `/tmp/whispr.txt` is not dispatched**

```bash
echo "stale text from previous run" > /tmp/whispr.txt
```

Press F2, stay completely silent for 1s, press F2. Expected: the stale text does NOT appear in tmux (empty transcript guard fires after mlx_whisper produces blank output; if mlx_whisper fails, exit 1 triggers an alert — either way, "stale text" is not sent).

- [ ] **Step 9: Process timeout**

Temporarily set `PROCESS_TIMEOUT = 3` in `whispr.lua` and set `WHISPER_MODEL = "mlx-community/whisper-large-v3-nonexistent"` (a bad model path that will cause mlx_whisper to hang or error). Reload Hammerspoon, press F2, speak, press F2.

Expected: after ~3s the `⟳` menu bar clears and an alert shows "Whispr: timed out after 3s". Restore both constants to their defaults and reload.

- [ ] **Step 10: Wrong `PYTHON_CMD` shows alert**

Temporarily set `PYTHON_CMD = "/usr/bin/python3-nonexistent"` in `whispr.lua`. Reload. Press F2, speak, press F2.

Expected: `⟳` clears quickly and an alert appears ("Whispr: …"). Restore `PYTHON_CMD` and reload.

- [ ] **Step 11: Mic permission denied (manual observation)**

If macOS mic permission for Hammerspoon has not been granted: revoke it in System Settings → Privacy & Security → Microphone, then press F2.

Expected: an alert shows (rec exits non-zero without `wasTerminated` being set). Re-grant permission afterward.

Note: if Hammerspoon already has mic permission and you don't want to revoke it, skip this step — the code path is covered by the `not wasTerminated and exitCode ~= 0` branch in `onRecExit`.

- [ ] **Step 12: Chezmoi apply**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
chezmoi apply
```

Expected: changes propagate to `~/.hammerspoon/` cleanly.

- [ ] **Step 13: Final commit**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
git add -p  # review any remaining unstaged changes
git commit -m "feat: whispr flow complete — voice dictation to tmux agent via F2"
```
