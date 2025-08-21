#!/usr/bin/env bash
set -euo pipefail
mkdir -p public/audio work
ORDER="work/segments_order.txt"
if [ -f "$ORDER" ]; then
  rm -f work/concat.txt
  while IFS= read -r f; do echo "file '$PWD/$f'" >> work/concat.txt; done < "$ORDER"
  ffmpeg -y -f concat -safe 0 -i work/concat.txt -c copy work/narration.mp3 >/dev/null 2>&1
  ffmpeg -y -i work/narration.mp3 -ar 48000 -ac 2 work/narr.wav >/dev/null 2>&1
else
  cp public/audio/book0_story_premise_raw.mp3 work/narr.wav
fi
BG="assets/music/bg.mp3"
if [ -f "$BG" ]; then
  ffmpeg -y -i work/narr.wav -i "$BG" \
    -filter_complex "[1:a]volume=0.15[a2];[0:a][a2]sidechaincompress=threshold=0.05:ratio=12:attack=5:release=250[out]" \
    -map "[out]" work/narr_bg.wav >/dev/null 2>&1
else
  cp work/narr.wav work/narr_bg.wav
fi
SFXDIR="assets/sfx"
if [ -d "$SFXDIR" ] && ls -A "$SFXDIR" >/dev/null 2>&1; then
  SFX=$(find "$SFXDIR" -type f | head -n1)
  ffmpeg -y -i work/narr_bg.wav -stream_loop 20 -i "$SFX" \
    -filter_complex "[1:a]adelay=90000|90000,volume=0.3[s];[0:a][s]amix=inputs=2:duration=first:dropout_transition=3[out]" \
    -map "[out]" work/narr_fx.wav >/dev/null 2>&1
  SRC=work/narr_fx.wav
else
  SRC=work/narr_bg.wav
fi
ffmpeg -y -i "$SRC" -af "loudnorm=I=-18:TP=-2:LRA=11:print_format=summary" \
  -c:a libmp3lame -b:a 128k public/audio/book0_story_premise.mp3 >/dev/null 2>&1
echo "[master] public/audio/book0_story_premise.mp3"
