#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
GH_USER="${GH_USER:?GH_USER required}"
REPO_NAME="${REPO_NAME:-ai-saga-sphere-pipeline}"
FEED_URL="https://$GH_USER.github.io/$REPO_NAME/feed.xml"

echo "== Codex Verify =="
code=$(curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" || echo 000)
if [ "$code" = "200" ]; then
  echo "✓ Feed OK ($FEED_URL)"
  exit 0
else
  echo "✗ Feed not $code OK ($FEED_URL)"; exit 1
fi
