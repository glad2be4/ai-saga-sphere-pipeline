#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${REPO_NAME:=ai-saga-sphere-pipeline}"
FEED_URL="https://${GH_USER}.github.io/${REPO_NAME}/feed.xml"
code="$(curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" || true)"
if [ "$code" = "200" ]; then
  echo "✅ Feed OK 200 -> $FEED_URL"
else
  echo "❌ Feed not 200 (got $code) -> $FEED_URL"
fi
