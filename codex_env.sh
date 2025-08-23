#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# --- Environment (user may export before calling; we also try to auto-derive) ---
: "${GH_USER:=glad2be4}"
: "${REPO:=ai-saga-sphere-pipeline}"
: "${REPO_DIR:=$HOME/repo/$REPO}"
: "${RCLONE_TARGETS:=}"           # space-separated, e.g. 'onedrive:AI_Saga_Sphere'
: "${NIGHTLY_HOUR:=3}"
: "${TEASER_SEC:=75}"
: "${TEASER_VOICEOVER:=false}"

# Derive GH_USER from origin if not set and repo exists
if [ -z "${GH_USER:-}" ] && [ -d "$REPO_DIR/.git" ]; then
  url="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)"
  if [ -n "$url" ]; then
    GH_USER="$(printf "%s" "$url" | sed -E 's#.*github.com[:/]{1}([^/]+)/.*#\1#')"
    export GH_USER
  fi
fi

# Feed URL
: "${FEED_URL:=https://${GH_USER}.github.io/${REPO}/feed.xml}"
export GH_USER REPO REPO_DIR RCLONE_TARGETS NIGHTLY_HOUR TEASER_SEC TEASER_VOICEOVER FEED_URL

# Common dirs
OUT_DIR="$REPO_DIR/outputs"
PUB_DIR="$REPO_DIR/public"
REC_DIR="$REPO_DIR/recovery"
LOG_DIR="$REPO_DIR/logs"
mkdir -p "$OUT_DIR" "$PUB_DIR" "$REC_DIR" "$LOG_DIR"

# Logging helper
ts() { date +"%Y-%m-%dT%H:%M:%S%z"; }
note() { echo "[$(ts)] $*"; }

