#!/usr/bin/env bash
set -euo pipefail
mkdir -p public/audio
ffmpeg -y -i public/audio/book0_story_premise_raw.mp3 \
  -af "loudnorm=I=-18:TP=-2:LRA=11:print_format=summary" \
  -c:a libmp3lame -b:a 128k public/audio/book0_story_premise.mp3 >/dev/null 2>&1
echo "[master] public/audio/book0_story_premise.mp3"
