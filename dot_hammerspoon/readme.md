# Whispr — Voice Dictation to AI Agent

Press **F13** to start recording, press again to stop. Your speech is transcribed and sent to a Claude agent running in a tmux session named `Neo`.

## Architecture

```
F13 → Hammerspoon
       ├── START: launch rec (sox_ng) → records to /tmp/whispr.wav
       ├── STOP:  SIGINT → rec finalizes WAV cleanly
       └── PROCESS: whispr_process.py (system python, no venv)
                     ├── transcribe via groq / whisper-cpp / mlx-whisper
                     ├── normalize developer jargon (REPLACEMENTS dict)
                     └── dispatch to tmux Neo session
```

No Python virtual environment required. `whispr_process.py` uses only stdlib.

## Quick Start

### 1. Install system dependencies

```bash
brew install hammerspoon tmux sox_ng
```

### 2. Install transcription backend (pick one)

#### Option A: Groq API (recommended)

No model download. Works on corporate networks. Free tier: 2,000 req/day.

```bash
# 1. Get a free API key at https://console.groq.com
# 2. Add to your shell profile:
echo 'export GROQ_API_KEY="gsk_your_key_here"' >> ~/.zshrc
source ~/.zshrc
```

#### Option B: whisper-cpp (fully offline)

```bash
# 1. Install whisper-cpp
brew install whisper-cpp

# 2. Download the large-v3-turbo model (~1.5 GB)
curl -L -o /opt/homebrew/share/whisper-cpp/ggml-large-v3-turbo.bin \
     "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
```

#### Option C: mlx-whisper (Apple Neural Engine)

```bash
# 1. Install uv if you don't have it
brew install uv

# 2. Install mlx-whisper CLI
uv tool install mlx-whisper

# 3. Download model weights (~800 MB, requires non-corporate network)
mlx_whisper /dev/null --model mlx-community/whisper-large-v3-turbo --output-format txt
```

Weights are cached at `~/.cache/huggingface/hub/` and reused on every run.

### 3. Install the AI agent CLI

```bash
npm install -g @anthropic-ai/claude-code
```

### 4. Apply dotfiles and reload

```bash
chezmoi apply
```

Open Hammerspoon and click **Reload Config**, or run:
```bash
open -a Hammerspoon
hs -c "hs.reload()"
```

### 5. Grant microphone access

**System Settings → Privacy & Security → Microphone** → enable **Hammerspoon**.

### 6. Set the backend

Edit `~/.hammerspoon/whispr.lua` and set `BACKEND` to match your choice:

```lua
local BACKEND = "groq"          -- Option A
-- local BACKEND = "whisper-cpp"   -- Option B
-- local BACKEND = "mlx-whisper"   -- Option C
```

For whisper-cpp, also update the model path:
```lua
["whisper-cpp"] = {
    cmd   = "/opt/homebrew/bin/whisper-cli",
    model = "/opt/homebrew/share/whisper-cpp/ggml-large-v3-turbo.bin",
},
```

## Usage

| Action | Result |
|---|---|
| Press **F13** | Starts recording (on-screen alert + menu bar `REC` + Tink sound) |
| Press **F13** again | Stops recording, transcribes, sends to Claude (Pop sound) |
| Press **F13** while processing | Shows "processing, please wait" |

If the `Neo` tmux session doesn't exist, Whispr creates it and launches `claude` automatically.

## Configuration

Edit `~/.hammerspoon/whispr.lua`:

| Variable | Default | Description |
|---|---|---|
| `BACKEND` | `"mlx-whisper"` | `"groq"`, `"whisper-cpp"`, or `"mlx-whisper"` |
| `AGENT_CMD` | `"claude"` | Command launched in the tmux pane |
| `TMUX_TARGET` | `"Neo:0.0"` | tmux `session:window.pane` |
| `MIN_RECORD_SECS` | `0.5` | Discard recordings shorter than this |
| `PROCESS_TIMEOUT` | `120` | Kill hung transcription after this many seconds |

## Troubleshooting

| Problem | Fix |
|---|---|
| F13 doesn't trigger | Check System Settings → Keyboard → disable "Use F1, F2, etc. as standard function keys" is OFF, or use a key that isn't mapped to a system function |
| "failed to start recorder" | Run `brew install sox_ng` and verify `/opt/homebrew/bin/rec` exists |
| Groq 401 error | Check `GROQ_API_KEY` is set: `echo $GROQ_API_KEY` |
| whisper-cpp empty transcript | You may be using the tiny test stub. Download a real model (see step 2B) |
| mlx-whisper 403 error | Model download blocked by corporate network. Use Groq or download on home WiFi |
| No sound on start/stop | Verify `/System/Library/Sounds/Tink.aiff` exists |

## Files

| File | Purpose |
|---|---|
| `init.lua` | Binds F13 to `Whispr.toggle` |
| `whispr.lua` | Orchestrator: recording lifecycle, UI, launches processing |
| `whispr_process.py` | Transcription, text normalization, tmux dispatch (stdlib only) |
