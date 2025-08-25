#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FEED_URL_DEFAULT="https://$(git -C "$ROOT" remote get-url origin | sed -n 's#.*github.com[:/]\([^/]*\)/\([^/.]*\).*#\1.github.io/\2/p;#')feed.xml"
FEED_URL="${FEED_URL:-$FEED_URL_DEFAULT}"

# Optional platform URLs via repo vars or env
APPLE_URL="${APPLE_URL:-${VAR_APPLE_URL:-}}"
SPOTIFY_URL="${SPOTIFY_URL:-${VAR_SPOTIFY_URL:-}}"
AMAZON_URL="${AMAZON_URL:-${VAR_AMAZON_URL:-}}"

# Optional PodcastIndex creds (for VISIBILITY ping only; read-only)
PI_KEY="${PODCASTINDEX_KEY:-}"
PI_SECRET="${PODCASTINDEX_SECRET:-}"

# --- Pages feed probe
code=$(curl -s -o /dev/null -w '%{http_code}' "$FEED_URL" || echo 000)
"$ROOT/bin/dist_log.sh" ok "pages:probe" "pages" "$FEED_URL" "" "$code"

# --- PodcastIndex visibility (byfeedurl) — read-only GET; log skip if no creds/feed
if [ -z "$FEED_URL" ]; then
  "$ROOT/bin/dist_log.sh" skip "pi:visibility" "podcastindex" "" "no_feed_url"
else
  if [ -n "$PI_KEY" ] && [ -n "$PI_SECRET" ]; then
    DATE="$(date -u +%s)"
    SIG="$(printf "%s%s%s" "$PI_KEY" "$PI_SECRET" "$DATE" | sha1sum | awk '{print $1}')"
    API="https://api.podcastindex.org/api/1.0/podcasts/byfeedurl?url=$(printf '%s' "$FEED_URL" | jq -sRr @uri)"
    resp="$(curl -s -w '\n%{http_code}' -H "X-Auth-Date: $DATE" -H "X-Auth-Key: $PI_KEY" -H "Authorization: $SIG" \
            -H "User-Agent: Codex-Autonomic/1.0" "$API" || printf '\n000')"
    body="$(printf '%s' "$resp" | sed '$d')"; http="$(printf '%s' "$resp" | tail -n1)"
    # Visible if http 200 and count>0
    visible="$(printf '%s' "$body" | jq -r 'try (.count // .items|length) // 0' 2>/dev/null || echo 0)"
    status="ok"; reason=""
    if [ "$http" != "200" ]; then status="error"; reason="http_$http"; fi
    meta="$(jq -nc --argjson visible "${visible:-0}" '{visible:$visible}')"
    "$ROOT/bin/dist_log.sh" "$status" "pi:visibility" "podcastindex" "$FEED_URL" "$reason" "$http" "$meta"
  else
    "$ROOT/bin/dist_log.sh" skip "pi:visibility" "podcastindex" "$FEED_URL" "missing_credentials"
  fi
fi

# --- Platform landing checks (HEAD → 2xx/3xx OK; otherwise error). Log skip if not configured.
ping_url() {
  local name="$1" url="$2"
  if [ -n "$url" ]; then
    code=$(curl -s -o /dev/null -w '%{http_code}' -I "$url" || echo 000)
    case "$code" in
      2*|3*) "$ROOT/bin/dist_log.sh" ok "carrier:probe" "$name" "$url" "" "$code" ;;
      *)     "$ROOT/bin/dist_log.sh" error "carrier:probe" "$name" "$url" "http_$code" "$code" ;;
    esac
  else
    "$ROOT/bin/dist_log.sh" skip "carrier:probe" "$name" "" "missing_url"
  fi
}

ping_url "apple"   "$APPLE_URL"
ping_url "spotify" "$SPOTIFY_URL"
ping_url "amazon"  "$AMAZON_URL"
