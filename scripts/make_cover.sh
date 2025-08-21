#!/usr/bin/env bash
set -euo pipefail
mkdir -p public/art
ffmpeg -f lavfi -i color=c=black:s=1200x1200 -frames:v 1 -y \
  -vf "drawtext=text='AI SAGA SPHERE\\: BOOK 0':x=(w-text_w)/2:y=(h-text_h)/2:fontsize=64:fontcolor=white" \
  public/art/cover.png >/dev/null 2>&1
echo "[art] public/art/cover.png"
