#!/data/data/com.termux/files/usr/bin/bash
# Called at the end of your production run; expects:
#   OUT_DIR (where master audio lives)
#   RUN_ID  (unique run stamp)
set -euo pipefail
audio="$(find "${OUT_DIR:-public}" -type f \( -iname '*.wav' -o -iname '*.mp3' -o -iname '*.flac' \) | head -n1 || true)"
if [ -n "${audio:-}" ]; then
  ./bin/collect_immersion.sh "$audio" "$RUN_ID" || true
else
  echo "[immersion] skipped: no audio found under \$OUT_DIR=${OUT_DIR:-public}"
fi

./bin/ping_extra_carriers.sh "$RUN_ID" || true

# Include every recovery kit tar created during the run
mkdir -p recovery
./bin/notarize_capture.sh "recovery/*.tar*" "$RUN_ID" || true
