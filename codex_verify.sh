#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
GH_USER="${GH_USER:-$(gh api user -q .login)}"
REPO="${REPO:-ai-saga-sphere-pipeline}"
FEED_URL="https://${GH_USER}.github.io/${REPO}/feed.xml"

echo "== Codex Verify (Spine + Mirror + Pipeline + Recovery) =="
for i in $(seq 1 40); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FEED_URL")
  echo "$(date) — HTTP $CODE — $FEED_URL"
  if [ "$CODE" = "200" ]; then
    echo "✅ Codex Feed Verified!"
    exit 0
  fi
  sleep 15
done
echo "❌ Feed not 200 after polling. Inspect GitHub Pages settings and the Actions logs."
exit 1
