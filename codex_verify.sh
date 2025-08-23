#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"; : "${REPO_NAME:?REPO_NAME required}"
FEED_URL="https://${GH_USER}.github.io/${REPO_NAME}/feed.xml"
code="$(curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" || true)"
echo "== Codex Verify (Spine + Mirror + Pipeline + Recovery) =="
if [ "$code" = "200" ]; then
  echo "✓ Feed 200 OK -> $FEED_URL"
  exit 0
else
  echo "✗ Feed not 200 OK (got $code) -> $FEED_URL"
  exit 1
fi
