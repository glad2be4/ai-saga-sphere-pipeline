#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${REPO:=ai-saga-sphere-pipeline}"
: "${RCLONE_TARGETS:=}"
cd "$HOME/repo/$REPO"
./codex_run.sh
GH_USER="$GH_USER" REPO="$REPO" ./codex_verify.sh || true
# Optional mirrors if configured
if [ -n "$RCLONE_TARGETS" ]; then
  echo "== Mirrors =="
  for tgt in $RCLONE_TARGETS; do
    if rclone listremotes 2>/dev/null | sed 's/:$//' | grep -q "^${tgt%%:*}$"; then
      echo "→ rclone copy outputs/ to $tgt/outputs/ (skip-existing)"
      rclone copy outputs/ "$tgt/outputs/" --create-empty-src-dirs \
        --skip-links --ignore-existing --transfers=8 --checkers=8 \
        --progress 2>/dev/null || true
      # recovery folder too
      [ -d outputs/recovery ] && rclone copy outputs/recovery "$tgt/recovery" \
        --ignore-existing --transfers=4 --checkers=4 2>/dev/null || true
    else
      echo "… skipping $tgt (not defined in 'rclone config')"
    fi
  done
fi
