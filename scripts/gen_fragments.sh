#!/usr/bin/env bash
set -euo pipefail
mkdir -p public/fragments public/art
head -n 4 source/book0_story_premise.txt > public/fragments/fragment1.txt || true
tail -n 4 source/book0_story_premise.txt > public/fragments/fragment2.txt || true
ffmpeg -f lavfi -i color=c=black:s=1200x1200 -frames:v 1 -y \
  -vf "drawtext=text='AI SAGA SPHERE\\: BOOK 0':x=(w-text_w)/2:y=(h-text_h)/2:fontsize=64:fontcolor=white" \
  public/art/cover.png >/dev/null 2>&1
echo "[fragments+art] ready"
