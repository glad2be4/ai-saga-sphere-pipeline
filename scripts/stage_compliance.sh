#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/outputs/compliance_report.json"
DST_DIR="$ROOT/public/logs"
DST="$DST_DIR/compliance_report.json"
mkdir -p "$DST_DIR"
if [ -s "$SRC" ]; then
  cp -f "$SRC" "$DST"
else
  # neutral, non-fabricated: banner will show 'unknown'
  cat > "$DST" <<JSON
{"kit":null,"pass":null,"reasons":["no_report"],"qc":null,"feed":null,"notarization":null,"ts":"$(date -u +%FT%TZ)"}
JSON
fi
echo "[stage_compliance] staged -> $DST"
