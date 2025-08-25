#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$ROOT/logs/system/pipeline_status.log"
FEED_URL="https://$GH_USER.github.io/$REPO_NAME/feed.xml"

# Narration (requires manuscripts/input.txt)
RAW="$(scripts/narrate.sh)"
# Mastering + metrics
MP3="$(scripts/master.sh "$RAW")"
# Package + feed entry
PKG="$(scripts/package.sh "$MP3")"

# Recovery kit
KIT="$(bin/codex_recovery.sh)"
echo "[pipeline] packaged: $PKG ; kit: $KIT" >> "$LOG"

# Mirrors (optional)
if [ -n "${RCLONE_TARGETS:-}" ]; then
  for tgt in $RCLONE_TARGETS; do
    if rclone lsd "$tgt" >/dev/null 2>&1; then
      rclone copy "$ROOT/public" "$tgt/public" --transfers=4 --checkers=8 >/dev/null 2>&1 || true
      rclone copy "$ROOT/recovery_kits" "$tgt/recovery_kits" --transfers=4 --checkers=8 >/dev/null 2>&1 || true
    fi
  done
fi

# Probe Pages (non-fatal if first run)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" || echo 000)
echo "[pages] $HTTP $FEED_URL" >> "$LOG"
echo "✅ DONE: $PKG"
