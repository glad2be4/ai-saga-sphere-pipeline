#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${RCLONE_TARGETS:=}"

./codex_run.sh  || true
./codex_verify.sh || true

# Optional mirrors
if [ -n "$RCLONE_TARGETS" ]; then
  for tgt in $RCLONE_TARGETS; do
    if rclone lsd "$tgt" 2>/dev/null >/dev/null; then
      echo "→ rclone copy outputs/ -> $tgt/outputs/"
      rclone copy outputs/ "$tgt/outputs/" --transfers=4 --checkers=8 --fast-list --quiet || true
      [ -d recovery ] && rclone copy recovery/ "$tgt/recovery/" --transfers=4 --checkers=8 --fast-list --quiet || true
    else
      echo "skip mirror (not configured): $tgt"
    fi
  done
fi
