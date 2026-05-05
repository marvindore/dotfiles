#!/usr/bin/env python3
"""
whispr_process.py — transcribe, normalise, and dispatch to tmux.

Usage:
    python3 whispr_process.py <wav> <tmux_target> <agent_cmd> \
                              <backend> <backend_cmd> <model> <ready_wait>

Backends:
    whisper-cpp  — local .bin model file, Metal-accelerated (default)
                   backend_cmd: /opt/homebrew/bin/whisper-cli
                   model: path to ggml .bin file
    mlx-whisper  — HuggingFace model ID, Apple Neural Engine
                   backend_cmd: /opt/homebrew/bin/mlx_whisper
                   model: HuggingFace model ID string

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
      "whisper-cpp"  — backend_cmd is the whisper-cli binary path;
                       model is a local .bin file path.
                       Output file: <txt_path> (derived from -of flag + .txt suffix).
      "mlx-whisper"  — backend_cmd is the mlx_whisper binary path;
                       model is a HuggingFace model ID.
                       Output file: /tmp/whispr.txt (derived from wav stem).

    To add a new backend: add an elif branch here and update whispr.lua constants.
    """
    output_base = txt_path[:-4]  # strip .txt for whisper-cpp -of flag

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
