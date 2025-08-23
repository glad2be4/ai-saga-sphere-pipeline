#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
./codex_run.sh | tee "codex_run_$(date +%Y%m%d_%H%M%S).log"
./codex_verify.sh
# Optional mirrors if configured
if [ -n "${RCLONE_TARGETS:-}" ]; then
  for tgt in $RCLONE_TARGETS; do
    rclone copy --ignore-existing outputs "${tgt}:/${REPO}/outputs" || true
    rclone copy --ignore-existing recovery "${tgt}:/${REPO}/recovery" || true
  done
fi
