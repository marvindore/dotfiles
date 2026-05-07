#!/usr/bin/env python3
"""
whispr_rec.py — record from default mic to WAV using a sentinel-file stop.

Hammerspoon cannot reliably signal child processes, so we use a file-based
stop mechanism instead: the script polls for /tmp/whispr.stop and exits
cleanly when it appears, writing a well-formed WAV file on the way out.

Usage: python3 whispr_rec.py <wav_path>
Exit:  0 on success (including empty recording), 1 on error
"""
import os
import sys
import wave

STOP_FILE   = "/tmp/whispr.stop"
SAMPLE_RATE = 16000
CHUNK_FRAMES = 1600  # 100 ms at 16 kHz

wav_path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/whispr.wav"

try:
    import numpy as np
except ImportError:
    sys.stderr.write("numpy not installed — run: pip3 install numpy\n")
    sys.exit(1)

try:
    import sounddevice as sd
except ImportError:
    sys.stderr.write("sounddevice not installed — run: pip3 install sounddevice\n")
    sys.exit(1)

# Clear any stale stop file from a previous session.
if os.path.exists(STOP_FILE):
    os.remove(STOP_FILE)

frames = []
try:
    with sd.InputStream(samplerate=SAMPLE_RATE, channels=1, dtype="int16") as stream:
        while not os.path.exists(STOP_FILE):
            data, _ = stream.read(CHUNK_FRAMES)
            frames.append(data.copy())
except Exception as exc:
    sys.stderr.write(f"audio capture failed: {exc}\n")
    sys.exit(1)

if not frames:
    sys.exit(0)

try:
    audio = np.concatenate(frames)
    with wave.open(wav_path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)   # 16-bit PCM
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(audio.tobytes())
except Exception as exc:
    sys.stderr.write(f"failed to write WAV: {exc}\n")
    sys.exit(1)
