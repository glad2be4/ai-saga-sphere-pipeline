#!/usr/bin/env bash
set -euo pipefail
mkdir -p public/fragments
head -n 4 source/book0_story_premise.txt > public/fragments/fragment1.txt || true
tail -n 4 source/book0_story_premise.txt > public/fragments/fragment2.txt || true
echo "[fragments] public/fragments/"
