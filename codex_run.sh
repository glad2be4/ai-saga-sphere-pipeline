#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
GH_USER="${GH_USER:?GH_USER required}"
REPO_NAME="${REPO_NAME:-ai-saga-sphere-pipeline}"
REPO_DIR="${REPO_DIR:-$HOME/repo/$REPO_NAME}"
FEED_URL="https://$GH_USER.github.io/$REPO_NAME/feed.xml"

mkdir -p logs outputs recovery
run_id=$(date -u +"%Y%m%d_%H%M%S")
LOG="logs/codex_run_${run_id}.log"
exec > >(tee -a "$LOG") 2>&1

echo "== Codex Run (Spine + Mirror + Pipeline + Recovery) =="

# Refresh <updated> in feed.xml (keep perl in deps to avoid sed-XML pitfalls)
if [ -f feed.xml ]; then
  perl -0777 -pe 's|<updated>.*?</updated>|"<updated>".`date -u +\"%Y-%m-%dT%H:%M:%SZ\"`."</updated>"|e' -i feed.xml
fi

# Recovery bundle (tiny but proves recoverability)
tar -cf "outputs/recovery_${run_id}.tar" feed.xml index.html .nojekyll 2>/dev/null || true
sha256sum "outputs/recovery_${run_id}.tar" | awk '{print $1}' > outputs/latest.sha256

# Optional mirrors via rclone (only if remote names exist)
if [ -n "${RCLONE_TARGETS:-}" ]; then
  for tgt in $RCLONE_TARGETS; do
    base="${tgt%%:*}"
    if rclone lsd "${base}:" >/dev/null 2>&1; then
      echo "→ rclone copy outputs/ → $tgt/outputs/"
      rclone copy outputs "$tgt/outputs" --progress --transfers=4 --checkers=8 || true
    else
      echo "⚠︎ rclone remote '$base' not configured; skipping."
    fi
  done
fi
