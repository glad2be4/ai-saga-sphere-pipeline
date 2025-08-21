#!/usr/bin/env bash
set -euo pipefail
: "${FEED_URL:?FEED_URL required}"
[ -z "${PODCASTINDEX_KEY:-}" ] && exit 0
[ -z "${PODCASTINDEX_SECRET:-}" ] && exit 0
TS=$(date +%s)
curl -s -G "https://api.podcastindex.org/api/1.0/add/byfeedurl" \
  --data-urlencode "url=${FEED_URL}" \
  -H "X-Auth-Date: ${TS}" \
  -H "X-Auth-Key: ${PODCASTINDEX_KEY}" \
  -H "Authorization: ${PODCASTINDEX_SECRET}" \
  -H "User-Agent: AISagaSphere/1.0" || true
echo "[podcastindex] notified"
