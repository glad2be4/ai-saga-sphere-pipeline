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
[ -x scripts/notarize_capture.sh ] && scripts/notarize_capture.sh || true
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

# === Codex: autonomic after-build (idempotent) ===
set -euo pipefail
export RUN_ID="${RUN_ID:-codex_$(date -u +%Y%m%d_%H%M%S)}"

# 1) Immersion fidelity capture (real audio only)
latest_mp3="$(ls -1t public/audio/*.mp3 2>/dev/null | head -n1 || true)"
if [ -n "${latest_mp3:-}" ]; then
  bin/collect_immersion.sh "$latest_mp3" || true
else
  bin/codex_log.sh --cat immersion --stage metrics --status skip --reason "no_audio"
fi

# 2) Distribution expansion pings (read-only, skip if URLs not set)
bin/ping_extra_carriers.sh || true

# 3) Notarization capture (CID/IPNS if available; else skip with reason)
bin/notarize_capture.sh || true
