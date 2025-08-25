#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUN_ID="codex_$(date -u +%Y%m%d_%H%M%S)"
KIT="$ROOT/recovery_kits/$RUN_ID"
mkdir -p "$KIT/pipeline_logs" "$KIT/audio_samples" "$KIT/proof"

# copy logs + QC
cp -r "$ROOT/logs" "$KIT/pipeline_logs" 2>/dev/null || true
# pick latest mp3 in public/audio (if present)
MP3="$(ls -1t "$ROOT/public/audio/"*.mp3 2>/dev/null | head -n1 || true)"

# derive metrics if we have the latest QC json
QC="$(ls -1t "$ROOT/public/qc/metrics_"*.json 2>/dev/null | head -n1 || true)"
LUFS=""; TP=""; LRA=""
if [ -n "$QC" ]; then
  LUFS="$(jq -r '.ebu_r128.integrated_lufs // empty' "$QC" 2>/dev/null || true)"
  TP="$(jq -r '.ebu_r128.true_peak_dbTP // empty' "$QC" 2>/dev/null || true)"
  LRA="$(jq -r '.ebu_r128.loudness_range_lu // empty' "$QC" 2>/dev/null || true)"
fi

# manifest
cat > "$KIT/codex_manifest.json" <<JSON
{
  "run_id": "$RUN_ID",
  "ts": "$(date -u +%FT%TZ)",
  "artifacts": {
    "master_mp3": "$(basename "${MP3:-}")",
    "feed_xml": "public/feed.xml"
  },
  "audio_qc": {
    "ebu_r128": {
      "integrated_lufs": ${LUFS:-null},
      "true_peak_dbTP": ${TP:-null},
      "loudness_range_lu": ${LRA:-null}
    }
  }
}
JSON

# kit hashes (everything inside kit)
find "$KIT" -type f -exec sha256sum {} \; | sort -k2 > "$KIT/codex_hashes.sha256"
echo "$KIT"
