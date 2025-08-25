#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/logs/distribution/pages_probe.jsonl"
DST_DIR="$ROOT/public/logs"
DST="$DST_DIR/pages_probe.jsonl"
mkdir -p "$DST_DIR"
if [ -s "$SRC" ]; then
  # keep the whole JSONL so the page can show a recent history
  cp -f "$SRC" "$DST"
else
  # create an empty JSONL file (valid but empty) — page will show "no data yet"
  : > "$DST"
fi
echo "[dashboard] staged $DST"
