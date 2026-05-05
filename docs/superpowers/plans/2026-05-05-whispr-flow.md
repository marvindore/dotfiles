# Whispr Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an F2 toggle that records audio, transcribes it locally with whisper-cpp (configurable), normalises developer vocabulary, and auto-submits the result to a tmux session running a configurable AI agent.

**Architecture:** `whispr.lua` owns the hotkey, `rec` process lifecycle, and transient menu bar indicator. `whispr_process.py` is a standalone Python script that transcribes via a pluggable `transcribe()` function (whisper-cpp by default, mlx-whisper as drop-in alternative), normalises text (find-replace regex dict), verifies the tmux session, and sends text via `tmux load-buffer` + `paste-buffer`. All config lives in `whispr.lua` and is passed to the Python script as CLI arguments.

**Tech Stack:** Hammerspoon (Lua), sox_ng (`rec` binary), whisper-cpp (Metal-accelerated, via Homebrew), tmux

**Spec:** `docs/superpowers/specs/2026-05-05-whispr-flow-design.md`

**Note on backend:** `whisper-cpp` is the active backend (installs via Homebrew, no PyPI). `mlx-whisper` remains supported as an alternative — switching requires changing 3 constants in `whispr.lua`.

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `dot_hammerspoon/whispr.lua` | **Create** | Hotkey, rec process, exit callback, menu bar, timeout |
| `dot_hammerspoon/whispr_process.py` | **Create** | Transcribe (pluggable), normalise, verify tmux, send text |
| `dot_hammerspoon/tests/test_whispr_process.py` | **Create** | Unit tests for pure text-processing functions + backend guard |
| `dot_hammerspoon/init.lua` | **Modify** | Add `require("whispr")` + F2 hotkey binding |

---

## Task 1: Install dependencies

**Note:** `sox_ng` is already installed (`rec` available at `/opt/homebrew/bin/rec`). Only whisper-cpp and model download remain.

**Files:** none (shell setup)

- [x] **Step 1: sox_ng** — already installed, `rec` verified at `/opt/homebrew/bin/rec`

- [ ] **Step 2: Install whisper-cpp**

```bash
brew install whisper-cpp
```

Verify:
```bash
whisper-cpp --help 2>&1 | head -5
```
Expected: help output from whisper-cpp.

- [ ] **Step 3: Download the ggml-large-v3-q5_0 model**

whisper-cpp uses local `.bin` model files. The quantized `q5_0` variant (~1.1 GB) gives near-identical accuracy to full precision at much higher speed on Metal.

```bash
mkdir -p ~/.cache/whisper
# Check if brew installed a download helper
ls $(brew --prefix)/share/whisper-cpp/models/ 2>/dev/null || echo "no helper"
```

If the helper script exists:
```bash
cd ~/.cache/whisper && $(brew --prefix)/share/whisper-cpp/models/download-ggml-model.sh large-v3-q5_0
```

If not, download directly:
```bash
curl -L \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-q5_0.bin" \
  -o ~/.cache/whisper/ggml-large-v3-q5_0.bin
```

Verify:
```bash
ls -lh ~/.cache/whisper/ggml-large-v3-q5_0.bin
```
Expected: ~1.1 GB file present.

- [ ] **Step 4: Smoke-test whisper-cpp with the model**

```bash
whisper-cpp -m ~/.cache/whisper/ggml-large-v3-q5_0.bin --help 2>&1 | head -3
```

Expected: no "model not found" errors.

- [ ] **Step 5: Confirm tmux sessions**

```bash
tmux list-sessions 2>/dev/null || echo "no tmux sessions"
```

Note whether a session named `Neo` exists — the script creates it automatically if absent.

- [ ] **Step 6: Commit nothing** (deps are system-level, not in repo)

---

## Task 2: `whispr_process.py` — text processing functions (TDD)

The pure functions (find-replace, timestamp stripping, backend guard) can be unit-tested in isolation. Build and test them first, then assemble the full pipeline.

**Files:**
- Create: `dot_hammerspoon/tests/test_whispr_process.py`
- Create: `dot_hammerspoon/whispr_process.py`

**CLI signature** (all args from `whispr.lua`):
```
python3 whispr_process.py <wav> <tmux_target> <agent_cmd> <backend> <backend_cmd> <model> <ready_wait>
```

- [ ] **Step 1: Create tests directory and test file**

```bash
mkdir -p /Users/marvin.dore/.local/share/chezmoi/dot_hammerspoon/tests
```

Create `dot_hammerspoon/tests/test_whispr_process.py`:

```python
"""Unit tests for whispr_process.py pure text-processing functions."""
import importlib.util, sys
from pathlib import Path

# Stub sys.argv before loading module (module-level arg parsing runs on import)
sys.argv = ["whispr_process.py", "/tmp/x.wav", "Neo:0.0", "claude",
            "whisper-cpp", "/opt/homebrew/bin/whisper-cpp",
            str(Path.home() / ".cache/whisper/ggml-large-v3-q5_0.bin"), "2"]

spec = importlib.util.spec_from_file_location(
    "whispr_process",
    Path(__file__).parent.parent / "whispr_process.py"
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class TestStripTimestamps:
    def test_strips_single_timestamp(self):
        assert mod.strip_timestamps("[00:00:00.000 --> 00:00:05.000] hello world") == "hello world"

    def test_strips_multiple_timestamps(self):
        raw = "[00:00:00.000 --> 00:00:03.000] hello\n[00:00:03.000 --> 00:00:06.000] world"
        assert mod.strip_timestamps(raw) == "hello\nworld"

    def test_no_timestamps_unchanged(self):
        assert mod.strip_timestamps("kubectl apply -f deployment.yaml") == "kubectl apply -f deployment.yaml"

    def test_empty_string(self):
        assert mod.strip_timestamps("") == ""

    def test_all_timestamps_produces_empty(self):
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
        result = mod.apply_replacements("using oauth2 tokens")
        assert result == "using oauth2 tokens"

    def test_api_spelled_out(self):
        assert mod.apply_replacements("call the a p i endpoint") == "call the API endpoint"

    def test_neovim_split(self):
        assert mod.apply_replacements("open neo vim") == "open Neovim"

    def test_no_match_unchanged(self):
        assert mod.apply_replacements("docker run hello-world") == "docker run hello-world"


class TestTranscribe:
    def test_unknown_backend_returns_false(self, tmp_path):
        txt = str(tmp_path / "out.txt")
        ok, err = mod.transcribe("/tmp/x.wav", "unknown-backend", "/usr/bin/false", "/tmp/model.bin", txt)
        assert not ok
        assert "unknown-backend" in err.lower() or "unknown" in err.lower()
```

- [ ] **Step 2: Run tests — expect FileNotFoundError (whispr_process.py not created yet)**

```bash
cd /Users/marvin.dore/.local/share/chezmoi/dot_hammerspoon
/opt/homebrew/bin/python3 -m pytest tests/test_whispr_process.py -v 2>&1 | head -20
```

Expected: `FileNotFoundError` — confirms tests aren't passing vacuously.

- [ ] **Step 3: Create `whispr_process.py`**

Create `dot_hammerspoon/whispr_process.py`:

```python
#!/usr/bin/env python3
"""
whispr_process.py — transcribe, normalise, and dispatch to tmux.

Usage:
    python3 whispr_process.py <wav> <tmux_target> <agent_cmd> \
                              <backend> <backend_cmd> <model> <ready_wait>

Backends:
    whisper-cpp  — local .bin model file, Metal-accelerated (default)
    mlx-whisper  — HuggingFace model ID, Apple Neural Engine

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
_, wav_path, tmux_target, agent_cmd, backend, backend_cmd, model, ready_wait_str = sys.argv
agent_ready_wait = float(ready_wait_str)

# ---------------------------------------------------------------------------
# Find-replace dictionary
# Applied as whole-word, case-insensitive regex (\b boundaries).
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


def transcribe(wav_path: str, backend: str, backend_cmd: str, model: str, txt_path: str) -> tuple:
    """
    Run the transcription backend. Returns (success: bool, error_msg: str).

    Supported backends:
      "whisper-cpp"  — backend_cmd is the whisper-cpp binary path;
                       model is a local .bin file path.
      "mlx-whisper"  — backend_cmd is the mlx_whisper binary path;
                       model is a HuggingFace model ID.

    To add a new backend: add an elif branch here and update whispr.lua constants.
    """
    output_base = txt_path[:-4]  # strip .txt for -of flag

    if backend == "whisper-cpp":
        result = subprocess.run(
            [backend_cmd,
             "-m", model,
             "-f", wav_path,
             "-otxt",
             "-of", output_base,
             "-l", "en"],
            capture_output=True, text=True,
        )
    elif backend == "mlx-whisper":
        result = subprocess.run(
            [backend_cmd,
             wav_path,
             "--model", model,
             "--output-format", "txt",
             "--output-dir", os.path.dirname(txt_path)],
            capture_output=True, text=True,
        )
    else:
        return False, f"Unknown transcription backend: {backend!r}. Expected 'whisper-cpp' or 'mlx-whisper'."

    if result.returncode != 0:
        return False, result.stderr or f"{backend} exited with code {result.returncode}"
    if not os.path.exists(txt_path):
        return False, f"{backend} produced no output at {txt_path}"
    return True, ""


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def main():
    txt_path = "/tmp/whispr.txt"

    # Step 1: Remove stale transcript (whisper-cpp and mlx-whisper do not overwrite)
    if os.path.exists(txt_path):
        os.remove(txt_path)

    # Step 2: Transcribe
    ok, err = transcribe(wav_path, backend, backend_cmd, model, txt_path)
    if not ok:
        sys.stderr.write(err + "\n")
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

Expected: all 14 tests pass. Fix any failures before continuing.

- [ ] **Step 5: Commit**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
git add dot_hammerspoon/whispr_process.py dot_hammerspoon/tests/test_whispr_process.py
git commit -m "feat: add whispr_process.py with pluggable transcription backend"
```

---

## Task 3: Smoke-test `whispr_process.py` against a live tmux session

Integration smoke test: record a real WAV with `rec`, run the script, verify text lands in tmux. **Requires physically speaking into a microphone** — this task cannot be run by an automated agent.

**Files:** none (manual testing)

- [ ] **Step 1: Create a test tmux session**

```bash
tmux new-session -d -s whispr_test
```

- [ ] **Step 2: Record 3 seconds saying "kubectl get pods"**

```bash
rec -q -r 16000 -c 1 -t wav /tmp/whispr.wav trim 0 3
```

(`trim 0 3` auto-stops after 3 seconds.)

- [ ] **Step 3: Run the script**

```bash
/opt/homebrew/bin/python3 \
  /Users/marvin.dore/.local/share/chezmoi/dot_hammerspoon/whispr_process.py \
  /tmp/whispr.wav \
  whispr_test:0.0 \
  cat \
  whisper-cpp \
  /opt/homebrew/bin/whisper-cpp \
  "$HOME/.cache/whisper/ggml-large-v3-q5_0.bin" \
  2
```

Expected: transcript appears in `whispr_test` pane (`cat` echoes stdin).
Check: `tmux attach -t whispr_test` (detach with `Ctrl-b d`).

- [ ] **Step 4: Verify find-replace**

Record "using g r p c" and confirm `gRPC` appears in tmux output.

- [ ] **Step 5: Clean up**

```bash
tmux kill-session -t whispr_test
```

---

## Task 4: Write `whispr.lua`

**Files:**
- Create: `dot_hammerspoon/whispr.lua`

**To switch to mlx-whisper later:** change `BACKEND`, `BACKEND_CMD`, and `MODEL` — nothing else.

- [ ] **Step 1: Create `whispr.lua`**

Create `dot_hammerspoon/whispr.lua`:

```lua
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
local BACKEND_CMD  = "/opt/homebrew/bin/whisper-cpp"
local MODEL        = os.getenv("HOME") .. "/.cache/whisper/ggml-large-v3-q5_0.bin"

local PYTHON_CMD      = "/opt/homebrew/bin/python3"  -- python3 (no mlx-whisper needed for whisper-cpp)
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
```

- [ ] **Step 2: Reload Hammerspoon — check for errors**

In Hammerspoon Console:
```lua
hs.reload()
```

Expected: no red error lines.

- [ ] **Step 3: Commit**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
git add dot_hammerspoon/whispr.lua
git commit -m "feat: add whispr.lua with configurable whisper-cpp backend"
```

---

## Task 5: Wire `init.lua`

**Files:**
- Modify: `dot_hammerspoon/init.lua`

- [ ] **Step 1: Add whispr require and F2 hotkey**

Append to `dot_hammerspoon/init.lua`:

```lua
-- Whispr: voice dictation → tmux agent (F2 toggle)
local Whispr = require("whispr")
hs.hotkey.bind({}, "f2", Whispr.toggle)
```

Full file after edit:

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

Expected: no errors. F2 is now bound.

- [ ] **Step 3: Commit**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
git add dot_hammerspoon/init.lua
git commit -m "feat: bind F2 to whispr toggle in init.lua"
```

---

## Task 6: End-to-end manual verification

**Requires physical microphone interaction** — cannot be automated.

- [ ] **Step 1: Basic record → transcribe → send**

```bash
tmux new-session -d -s Neo 2>/dev/null; true
```

Press F2. Say *"Use kubectl to get all pods in the kube system namespace."* Press F2 again.

Expected: `⏺ REC` → `⟳` → cleared. Text with `kubectl` appears in `Neo:0.0`.

- [ ] **Step 2: Sub-0.5s discard**

Press F2 and immediately press F2 (within 0.5s). Expected: menu clears instantly, no tmux output.

- [ ] **Step 3: F2 during processing ignored**

Press F2, speak 2s, press F2. While `⟳` shows, press F2 again. Expected: nothing happens.

- [ ] **Step 4: Silent recording**

Press F2, stay silent 2s, press F2. Expected: `⟳` shows briefly, no tmux output, no alert.

- [ ] **Step 5: Auto-create session**

```bash
tmux kill-session -t Neo 2>/dev/null; true
```

Press F2, say *"Hello agent"*, press F2. Expected: session `Neo` created, `claude` started, text sent.

- [ ] **Step 6: Special characters safe**

Press F2, say *"Echo the PATH variable"*, press F2. Expected: `PATH` appears literally, not shell-expanded.

- [ ] **Step 7: Swap agent to `cat`**

In `whispr.lua` set `AGENT_CMD = "cat"`, reload, record a phrase, verify text echoes in pane. Restore `AGENT_CMD = "claude"`, reload.

- [ ] **Step 8: Stale `/tmp/whispr.txt` not dispatched**

```bash
echo "stale text" > /tmp/whispr.txt
```

Press F2, stay silent 1s, press F2. Expected: "stale text" does NOT appear in tmux.

- [ ] **Step 9: Process timeout**

Set `PROCESS_TIMEOUT = 3` and `MODEL = "/nonexistent.bin"` in `whispr.lua`, reload, press F2, speak, press F2. Expected: alert "Whispr: timed out after 3s". Restore and reload.

- [ ] **Step 10: Wrong `PYTHON_CMD`**

Set `PYTHON_CMD = "/usr/bin/python3-nonexistent"`, reload, record, press F2. Expected: alert shown. Restore and reload.

- [ ] **Step 11: Backend switch smoke test**

Temporarily set the three `mlx-whisper` constants (skip if PyPI still blocked). Verify transcript still arrives in tmux. Restore whisper-cpp constants.

- [ ] **Step 12: Chezmoi apply**

```bash
cd /Users/marvin.dore/.local/share/chezmoi && chezmoi apply
```

Expected: changes propagate to `~/.hammerspoon/` cleanly.

- [ ] **Step 13: Final commit**

```bash
cd /Users/marvin.dore/.local/share/chezmoi
git add -p
git commit -m "feat: whispr flow complete — voice dictation to tmux agent via F2 (whisper-cpp backend)"
```
