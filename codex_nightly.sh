#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${REPO:=ai-saga-sphere-pipeline}"
: "${REPO_DIR:=$HOME/repo/$REPO}"
: "${RCLONE_TARGETS:=${RCLONE_TARGETS:-}}"

cd "$REPO_DIR"
./codex_run.sh  || true
./codex_verify.sh || true

# Optional mirrors re-run (idempotent)
if [ -n "${RCLONE_TARGETS:-}" ]; then
  for tgt in $RCLONE_TARGETS; do
    if rclone listremotes 2>/dev/null | sed 's/:$//' | grep -q "^${tgt%%:*}$"; then
      rclone copy outputs/ "$tgt/outputs/" --create-empty-src-dirs --fast-list \
        --transfers=4 --checkers=8 --progress 2>/dev/null || true
    fi
  done
fi
