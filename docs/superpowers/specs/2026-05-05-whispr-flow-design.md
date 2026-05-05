# Whispr Flow — Design Spec

**Date:** 2026-05-05
**Status:** Approved

## Overview

A Hammerspoon-based voice dictation pipeline inspired by Whispr Flow. Press F2 to start recording; press F2 again to stop. Audio is transcribed locally via `mlx-whisper` (Apple Silicon optimised), developer vocabulary is normalised via a find-replace dict, and the cleaned text is auto-submitted to a named tmux session running a configurable AI agent.

## Goals

- One-key toggle (F2) to start and stop recording
- Fully local transcription — no cloud audio upload
- Configurable AI agent target (`AGENT_CMD`)
- Best-effort verification that the tmux session and agent are running before sending
- Visual feedback via a transient menu bar indicator

## Design choices (intentional, not bugs)

- Text is auto-submitted with a newline — the user cannot review or edit before the agent receives it. This is by design for a fast dictation-to-agent workflow.
- Agent verification is best-effort: if a tmux pane exists but is running an interactive process other than the agent, the command is injected into that process's stdin. No further guard is applied.

## Non-Goals

- LLM post-processing of transcriptions (whisper-large-v3 handles dev vocabulary natively)
- Hold-to-record mode
- Multiple concurrent recordings or concurrent processing runs

---

## Architecture & Data Flow

```
F2 (toggle on)
  └─► rec (sox_ng) → /tmp/whispr.wav        [Hammerspoon: menu bar ⏺ REC]

F2 (toggle off)
  └─► set wasTerminated = true, SIGTERM to rec
       └─► rec exits → Hammerspoon exit callback fires
            ├─► if isSilentDiscard: reset flags, return (no processing)
            └─► spawn whispr_process.py (+ start PROCESS_TIMEOUT timer)
                [Hammerspoon: menu bar ⟳]
                ├─► delete stale /tmp/whispr.txt if present
                ├─► mlx_whisper → /tmp/whispr.txt
                ├─► strip timestamp artifacts
                ├─► guard: exit 0 if transcript is empty/whitespace
                ├─► find-replace dict → normalised text
                ├─► best-effort: verify tmux session + AGENT_CMD running
                │    └─► if not: create session/start agent, sleep AGENT_READY_WAIT
                └─► tmux load-buffer + paste-buffer → text + newline
            [Hammerspoon exit callback: cancel timer, clear menu bar]
```

> Menu bar state is always managed by Hammerspoon in `hs.task` callbacks — the Python script has no knowledge of it.

---

## File Structure

```
dot_hammerspoon/
  init.lua               ← register F2 hotkey, require whispr
  whispr.lua             ← recording lifecycle, processing guard, menu bar
  whispr_process.py      ← transcription, find-replace, tmux dispatch
```

---

## Configuration

All user-facing config lives at the top of `whispr.lua`. `whispr_process.py` receives all values as CLI arguments — it has no hardcoded config of its own.

| Constant | Default | Purpose |
|---|---|---|
| `AGENT_CMD` | `"claude"` | Command run in tmux (may include flags, e.g. `"claude --dangerously-skip-permissions"`); basename used for pane-command check |
| `TMUX_TARGET` | `"Neo:0.0"` | Fully-qualified tmux target (session:window.pane); session name is extracted from this where needed |
| `WHISPER_MODEL` | `"mlx-community/whisper-large-v3"` | Any mlx-community Whisper variant |
| `AGENT_READY_WAIT` | `2` | Seconds to sleep after starting a fresh agent (best-effort) |
| `PYTHON_CMD` | `"/opt/homebrew/bin/python3"` | Path to the Python that has `mlx-whisper` installed |
| `PROCESS_TIMEOUT` | `120` | Seconds before Hammerspoon kills a hung `whispr_process.py` |
| `MIN_RECORD_SECS` | `0.5` | Recordings shorter than this are silently discarded |

---

## Section 1: Hammerspoon Module (`whispr.lua`)

### State variables

```lua
local recProcess      = nil    -- live hs.task for `rec`; non-nil only while recording
local processTask     = nil    -- live hs.task for whispr_process.py
local processTimer    = nil    -- hs.timer for PROCESS_TIMEOUT
local isProcessing    = false  -- true while whispr_process.py is running
local wasTerminated   = false  -- set before calling terminate() to distinguish SIGTERM from crash
local isSilentDiscard = false  -- set for sub-MIN_RECORD_SECS recordings
local menuItem        = nil    -- transient hs.menubar item
local recStartTime    = nil    -- epoch seconds at recording start
```

### Recording lifecycle

**F2 pressed, `recProcess == nil` and `isProcessing == false`:**
1. Create `menuItem` showing `⏺ REC`.
2. Record `recStartTime = hs.timer.secondsSinceEpoch()`.
3. Spawn `rec -q -r 16000 -c 1 -t wav /tmp/whispr.wav` via `hs.task` with an exit callback.
4. Set `recProcess` to the task handle.

**F2 pressed, `recProcess ~= nil`:**
1. If `hs.timer.secondsSinceEpoch() - recStartTime < MIN_RECORD_SECS`:
   - Set `isSilentDiscard = true`, `wasTerminated = true`.
   - Call `recProcess:terminate()`.
   - Immediately delete `menuItem`, reset `recProcess = nil`. (The exit callback will see `isSilentDiscard` and return early.)
   - Done.
2. Otherwise: set `wasTerminated = true`, call `recProcess:terminate()`. Exit callback fires next.

**F2 pressed, `isProcessing == true`:** ignore.

### `rec` exit callback `(exitCode, stdout, stderr)`

Note: the silent-discard toggle handler nils `recProcess` immediately before `terminate()`. The exit callback does **not** nil `recProcess` in its early-return path — it was already nil'd by the toggle handler.

```
if isSilentDiscard:
    isSilentDiscard = false
    wasTerminated   = false
    -- recProcess already nil'd by toggle handler; do not touch it here
    return

if not wasTerminated and exitCode ~= 0:
    -- rec crashed on its own (mic denied, device error, etc.)
    hs.alert("Whispr: " .. stderr)
    menuItem:delete(); menuItem = nil
    recProcess = nil
    wasTerminated = false
    return

-- Normal stop (wasTerminated == true, rec exited due to our SIGTERM).
-- rec exits non-zero on signal (128+15 = 143); this is expected and not an error.
wasTerminated  = false
recProcess     = nil
isProcessing   = true
menuItem:setTitle("⟳")

local scriptPath = hs.configdir .. "/whispr_process.py"
processTask = hs.task.new(PYTHON_CMD, function(code, out, err)
    -- cancel timeout timer
    if processTimer then processTimer:stop(); processTimer = nil end
    processTask   = nil
    isProcessing  = false
    menuItem:delete(); menuItem = nil
    if code ~= 0 then
        hs.alert("Whispr: " .. err)
    end
end, {scriptPath, "/tmp/whispr.wav", TMUX_TARGET, AGENT_CMD, WHISPER_MODEL, tostring(AGENT_READY_WAIT)})
processTask:start()

-- Timeout: kill hung process after PROCESS_TIMEOUT seconds.
-- The timer callback ONLY terminates the task and shows an alert.
-- It does NOT touch isProcessing or menuItem — the task's exit callback
-- fires after terminate() and handles that cleanup. If the exit callback
-- somehow never fires, isProcessing stays true (blocking further recordings),
-- which is the safe failure mode.
processTimer = hs.timer.doAfter(PROCESS_TIMEOUT, function()
    processTimer = nil
    if processTask then
        processTask:terminate()
        hs.alert("Whispr: timed out after " .. PROCESS_TIMEOUT .. "s")
    end
end)
```

### Menu bar

A transient `hs.menubar` item created on recording start. Deleted in the `whispr_process.py` exit callback (or immediately in the silent-discard path). Not present at any other time.

### sox_ng and SIGTERM

`sox_ng`'s `rec` handles `SIGTERM` by finalising the WAV header before exiting, producing a valid file. It exits with a non-zero code (signal-killed exit, typically 143) — this is expected and handled by the `wasTerminated` flag.

---

## Section 2: Processing Script (`whispr_process.py`)

Path: `hs.configdir .. "/whispr_process.py"` (same directory as `whispr.lua`).

Called by Hammerspoon as:
```
PYTHON_CMD <configdir>/whispr_process.py <wav> <tmux_target> <agent_cmd> <model> <ready_wait>
```

All five arguments come from `whispr.lua`; the script has no hardcoded config.

Argument parsing at the top of the script:
```python
_, wav_path, tmux_target, agent_cmd, model, ready_wait_str = sys.argv
agent_ready_wait = float(ready_wait_str)   # passed as string, must be cast
```

### Step 1 — Clean up stale output file

```python
txt_path = "/tmp/whispr.txt"
if os.path.exists(txt_path):
    os.remove(txt_path)
```

Prevents a failed `mlx_whisper` run from silently dispatching a previous transcript. `/tmp/whispr.wav` is intentionally overwritten silently by `rec` on each run — no cleanup needed for it. The `.txt` file must be deleted explicitly because `mlx_whisper` does not overwrite an existing output file.

### Step 2 — Transcribe

The `pip install mlx-whisper` package installs the binary as `mlx_whisper` (underscore). The CLI argument is `argv[4]` for model.

```python
result = subprocess.run(
    ["mlx_whisper", wav_path, "--model", model,
     "--output-format", "txt", "--output-dir", "/tmp"],
    capture_output=True, text=True
)
if result.returncode != 0 or not os.path.exists(txt_path):
    sys.stderr.write(result.stderr or "mlx_whisper produced no output")
    sys.exit(1)
```

`mlx_whisper` derives the output filename from the input stem: `/tmp/whispr.wav` → `/tmp/whispr.txt`. This is `mlx-whisper`'s documented `--output-format txt` + `--output-dir` behaviour.

### Step 3 — Strip timestamp artifacts

`mlx-whisper` in txt mode occasionally emits `[HH:MM:SS.mmm --> HH:MM:SS.mmm]` prefixes:

```python
text = open(txt_path).read().strip()
text = re.sub(r'\[\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}\]\s*', '', text).strip()
```

### Step 4 — Guard empty transcript

```python
if not text:
    sys.exit(0)  # silence or unintelligible audio; not an error
```

### Step 5 — Find-replace normalisation

Applied as whole-word, case-insensitive regex. `\b` is placed at the start and end of each full pattern string. Because `2` is a word character, patterns like `r"o ?auth"` will not match inside `oauth2` (`\b` after `h` requires a non-word character, which `2` is not) — compound tokens are safe.

```python
REPLACEMENTS = {
    # Git / hosting
    r"get hub":       "GitHub",
    r"git hub":       "GitHub",
    r"git lab":       "GitLab",
    # Kubernetes
    r"kube cuddle":   "kubectl",
    r"kube city":     "kubectl",
    r"kube ctl":      "kubectl",
    r"cube ctl":      "kubectl",
    # Databases
    r"post gress":    "PostgreSQL",
    r"postgress":     "PostgreSQL",
    r"my sequel":     "MySQL",
    r"no sequel":     "NoSQL",
    # Protocols / formats
    r"g ?r ?p ?c":    "gRPC",
    r"graph ?q ?l":   "GraphQL",
    r"web hook":      "webhook",
    r"web socket":    "WebSocket",
    r"jay son":       "JSON",
    r"j ?w ?t":       "JWT",
    r"o ?auth":       "OAuth",
    # Acronyms Whisper spells out
    r"a ?p ?i":       "API",
    r"c ?l ?i":       "CLI",
    r"u ?r ?l":       "URL",
    r"s ?s ?h":       "SSH",
    r"v ?p ?n":       "VPN",
    r"d ?n ?s":       "DNS",
    r"c ?r ?u ?d":    "CRUD",
    r"u ?u ?i ?d":    "UUID",
    r"y ?a ?m ?l":    "YAML",
    r"t ?o ?m ?l":    "TOML",
    # Tools
    r"neo ?vim":      "Neovim",
    r"aero ?space":   "AeroSpace",
    r"hammer ?spoon": "Hammerspoon",
    r"home ?brew":    "Homebrew",
    r"pie ?pie":      "PyPI",
    r"vs code":       "VS Code",
}

for pattern, replacement in REPLACEMENTS.items():
    text = re.sub(r'\b' + pattern + r'\b', replacement, text, flags=re.IGNORECASE)
```

### Step 6 — Verify tmux session & agent

Session name is extracted from `TMUX_TARGET` by splitting on `:`. `pane_current_command` returns the binary name; comparison uses `os.path.basename` of the first token of `AGENT_CMD` (ignoring flags).

```python
session  = tmux_target.split(":")[0]
agent_bin = os.path.basename(agent_cmd.split()[0])

def session_exists():
    return subprocess.run(["tmux", "has-session", "-t", session],
                          capture_output=True).returncode == 0

def pane_command():
    r = subprocess.run(
        ["tmux", "display-message", "-p", "-t", tmux_target, "#{pane_current_command}"],
        capture_output=True, text=True
    )
    return r.stdout.strip()

if not session_exists():
    subprocess.run(["tmux", "new-session", "-d", "-s", session])
    subprocess.run(["tmux", "send-keys", "-t", tmux_target, agent_cmd, "Enter"])
    time.sleep(agent_ready_wait)
elif pane_command() != agent_bin:
    subprocess.run(["tmux", "send-keys", "-t", tmux_target, agent_cmd, "Enter"])
    time.sleep(agent_ready_wait)
```

### Step 7 — Send text safely

`tmux load-buffer` + `paste-buffer` avoids shell expansion of `$`, backticks, quotes, and backslashes in the transcript. The trailing newline auto-submits to the agent (intentional).

```python
# Use a named buffer (-b whispr) to avoid racing with the user's default buffer0
proc = subprocess.run(
    ["tmux", "load-buffer", "-b", "whispr", "-"],
    input=(text + "\n").encode(),
    capture_output=True
)
if proc.returncode != 0:
    sys.stderr.write("tmux load-buffer failed\n")
    sys.exit(2)

proc = subprocess.run(
    ["tmux", "paste-buffer", "-b", "whispr", "-t", tmux_target],
    capture_output=True
)
if proc.returncode != 0:
    sys.stderr.write("tmux paste-buffer failed\n")
    sys.exit(2)
```

### Exit codes

| Code | Meaning |
|---|---|
| `0` | Success (including empty-transcript early exit) |
| `1` | Transcription failed |
| `2` | tmux error |

---

## Dependencies & Setup

| Dependency | Install |
|---|---|
| `sox_ng` | `brew install sox_ng` |
| `mlx-whisper` | `pip install mlx-whisper` (use Homebrew/mise Python, not `/usr/bin/python3`) |
| `mlx-community/whisper-large-v3` | Auto-downloaded on first use (~3 GB) |

Set `PYTHON_CMD` in `whispr.lua` to the `python3` that has `mlx-whisper` installed (e.g. `/opt/homebrew/bin/python3`). The system `/usr/bin/python3` (Apple's Xcode CLT shim) does not have `mlx-whisper`.

No API keys required. `mlx-whisper` uses the Apple Neural Engine — minimal CPU/GPU impact on M3.

---

## Testing Checklist

- [ ] F2 starts recording; menu bar shows `⏺ REC`
- [ ] F2 stops recording; menu bar transitions to `⟳` then clears
- [ ] Sub-0.5s recording is silently discarded; menu bar clears immediately
- [ ] F2 during processing is ignored
- [ ] Empty/silent recording produces no tmux output (exit 0, no alert)
- [ ] Transcript arrives correctly in tmux target `Neo:0.0`
- [ ] `AGENT_CMD` is auto-started when session is missing
- [ ] `AGENT_CMD` is auto-started when session exists but agent is not running
- [ ] Session exists with a different process running (e.g. `vim`) — agent command is injected (known best-effort behaviour)
- [ ] Mic permission denied (rec crashes without terminate()) shows alert and resets state
- [ ] Process timeout (>120s) triggers alert and resets state
- [ ] Find-replace dict normalises known terms correctly
- [ ] Transcript with `$`, quotes, backslashes sends safely without shell expansion
- [ ] Swapping `AGENT_CMD = "gemini"` routes to Gemini instead
- [ ] Stale `/tmp/whispr.txt` from a previous run is not dispatched
- [ ] `whispr_process.py` not found or `PYTHON_CMD` wrong → non-zero exit → alert shown
