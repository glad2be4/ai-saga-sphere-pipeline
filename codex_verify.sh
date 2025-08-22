#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
GH_USER="${GH_USER:-$(gh api user -q .login 2>/dev/null || echo unknown)}"
REPO="${REPO:-ai-saga-sphere-pipeline}"
FEED_URL="https://${GH_USER}.github.io/${REPO}/feed.xml"
TRIES="${TRIES:-30}"   # ~5 min with SLEEP=10
SLEEP="${SLEEP:-10}"

echo "== Codex Verify: $FEED_URL =="
for i in $(seq 1 "$TRIES"); do
  code="$(curl -sIL -o /dev/null -w "%{http_code}" "$FEED_URL" || true)"
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  if [ "$code" = "200" ]; then
    echo "[$ts] ✅ Feed OK (200)."
    exit 0
  fi
  echo "[$ts] ⏳ Feed not ready (HTTP $code), retry $i/$TRIES..."
  sleep "$SLEEP"
done
echo "❌ Feed never returned 200 after $TRIES tries."
exit 2
