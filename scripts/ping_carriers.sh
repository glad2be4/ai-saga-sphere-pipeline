#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FEED_URL_DEFAULT="https://$(git -C "$ROOT" remote get-url origin | sed -n 's#.*github.com[:/]\([^/]*\)/\([^/.]*\).*#\1.github.io/\2/p;#')feed.xml"
FEED_URL="${FEED_URL:-$FEED_URL_DEFAULT}"

APPLE_URL="${APPLE_URL:-${VAR_APPLE_URL:-}}"
SPOTIFY_URL="${SPOTIFY_URL:-${VAR_SPOTIFY_URL:-}}"
AMAZON_URL="${AMAZON_URL:-${VAR_AMAZON_URL:-}}"

# --- Pages feed probe (required)
code=$(curl -s -o /dev/null -w '%{http_code}' "$FEED_URL" || echo 000)
"$ROOT/bin/dist_log.sh" ok "pages:probe" "pages" "$FEED_URL" "" "$code"

# --- Apple Podcasts (optional)
if [ -n "$APPLE_URL" ]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' -I "$APPLE_URL" || echo 000)
  "$ROOT/bin/dist_log.sh" ok "carrier:probe" "apple" "$APPLE_URL" "" "$code"
else
  "$ROOT/bin/dist_log.sh" skip "carrier:probe" "apple" "" "missing_url"
fi

# --- Spotify (optional)
if [ -n "$SPOTIFY_URL" ]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' -I "$SPOTIFY_URL" || echo 000)
  "$ROOT/bin/dist_log.sh" ok "carrier:probe" "spotify" "$SPOTIFY_URL" "" "$code"
else
  "$ROOT/bin/dist_log.sh" skip "carrier:probe" "spotify" "" "missing_url"
fi

# --- Amazon Music / Audible (optional)
if [ -n "$AMAZON_URL" ]; then
  code=$(curl -s -o /dev/null -w '%{http_code}' -I "$AMAZON_URL" || echo 000)
  "$ROOT/bin/dist_log.sh" ok "carrier:probe" "amazon" "$AMAZON_URL" "" "$code"
else
  "$ROOT/bin/dist_log.sh" skip "carrier:probe" "amazon" "" "missing_url"
fi
