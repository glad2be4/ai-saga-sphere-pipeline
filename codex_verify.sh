#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${REPO:=ai-saga-sphere-pipeline}"
FEED_URL="https://${GH_USER}.github.io/${REPO}/feed.xml"

echo "== Codex Verify (Spine + Mirror + Pipeline + Recovery) =="
code=$(curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" || true)
if [ "$code" = "200" ]; then
  echo "✓ Feed 200 OK → $FEED_URL"
else
  echo "✖ Feed not 200 (got $code) → $FEED_URL"
fi
# Show latest run log tail if any
LOGFILE="$(ls -1t outputs/codex_run_*.log 2>/dev/null | head -n1 || true)"
[ -n "${LOGFILE:-}" ] && { echo "== Recent log tail =="; tail -n 40 "$LOGFILE"; }
