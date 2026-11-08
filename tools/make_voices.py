#!/usr/bin/env python3
"""Pre-records the PNN news anchors with Kokoro-82M (Apache-2.0 neural TTS).

    godot --headless --path . res://tests/export_voice_lines.tscn -- lines.json
    python tools/make_voices.py lines.json assets/audio/voice

Needs: pip install kokoro soundfile  (Python 3.10-3.12) and espeak-ng.
Each line becomes assets/audio/voice/<key>.ogg, where key = first 16 hex
chars of md5("<who>|<line>"), the same key news_break.gd looks for.
Existing clips are skipped, so re-running only records new or changed lines.
"""
import json
import os
import re
import sys

import numpy as np
import soundfile as sf
from kokoro import KPipeline

RATE = 24000
# Cast: (Kokoro language code, voice, speed)
CAST = {
    "chip": ("a", "am_michael", 0.95),     # warm American anchorman
    "brenda": ("b", "bf_emma", 1.0),       # crisp British co-anchor
    "gary": ("b", "bm_george", 1.08),      # excitable British field reporter
}
# How a few words should be said (spelling hints, not shown on screen).
SAY = {
    "PNN": "P N N",
    "FOB": "fob",
    "SAM": "Sam",
    "SAMs": "Sams",
    "Wi-Fi": "Wi-Fi",
}


def say(text: str) -> str:
    for k, v in SAY.items():
        text = re.sub(r"\b%s\b" % re.escape(k), v, text)
    return text


def main() -> None:
    lines = json.load(open(sys.argv[1]))
    out_dir = sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    pipes = {}

    def speak(who: str, text: str) -> np.ndarray:
        lang, voice, speed = CAST[who]
        if lang not in pipes:
            pipes[lang] = KPipeline(lang_code=lang, repo_id="hexgrad/Kokoro-82M")
        parts = [a.numpy() if hasattr(a, "numpy") else a for _, _, a in pipes[lang](say(text), voice=voice, speed=speed)]
        return np.concatenate(parts) if parts else np.zeros(1, dtype=np.float32)

    done = 0
    for item in lines:
        path = os.path.join(out_dir, item["key"] + ".ogg")
        if os.path.exists(path):
            continue
        who, line = item["who"], item["line"]
        if who == "both":
            # Duets: Brenda takes her own introduction, Chip the rest.
            sentences = re.split(r"(?<=[.!?])\s+", line)
            gap = np.zeros(int(RATE * 0.22), dtype=np.float32)
            chunks = []
            for s in sentences:
                chunks += [speak("brenda" if "I'm Brenda" in s else "chip", s), gap]
            audio = np.concatenate(chunks)
        else:
            audio = speak(who, line)
        audio = audio / max(1e-6, float(np.abs(audio).max())) * 0.89   # even loudness
        sf.write(path, audio.astype(np.float32), RATE, format="OGG", subtype="VORBIS")
        done += 1
        print(f"[{done}] {who}: {line[:60]}", flush=True)
    print(f"recorded {done} new clips")


if __name__ == "__main__":
    main()
