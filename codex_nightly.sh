#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
REPO_NAME="${REPO_NAME:-ai-saga-sphere-pipeline}"
REPO_DIR="${REPO_DIR:-$HOME/repo/$REPO_NAME}"
RCLONE_TARGETS="${RCLONE_TARGETS:-}"
LOGDIR="$REPO_DIR/logs"; mkdir -p "$LOGDIR"; cd "$REPO_DIR"

chmod +x codex_run.sh codex_verify.sh 2>/dev/null || true

# Run (do not stop if verify fails — we still mirror logs/recovery)
./codex_run.sh    | tee -a "$LOGDIR/codex_run_$(date +%Y%m%d_%H%M%S).log" || true
./codex_verify.sh || true

# Optional mirrors
if [ -n "$RCLONE_TARGETS" ]; then
  for tgt in $RCLONE_TARGETS; do
    # push outputs and recovery (create targets if needed)
    rclone copy --create-empty-src-dirs --fast-list --transfers 8 \
      "$REPO_DIR/outputs" "$tgt/outputs" 2>/dev/null || true
    rclone copy --fast-list --transfers 4 \
      "$REPO_DIR/recovery" "$tgt/recovery" 2>/dev/null || true
  done
fi
