#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${REPO:=ai-saga-sphere-pipeline}"
FEED_URL="https://${GH_USER}.github.io/${REPO}/feed.xml"
echo "== Codex Verify (Spine + Mirror + Pipeline + Recovery) =="
code="$(curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" || echo 000)"
if [ "$code" = "200" ]; then echo "✅ Feed OK: $FEED_URL"; else echo "❌ Feed not 200 (got $code) -> $FEED_URL"; fi
# Transparency tail if present
LOGFILE="$(ls -1t outputs/codex_run_*.log 2>/dev/null | head -n1 || true)"
[ -n "${LOGFILE}" ] && { echo "Recent log tail:"; tail -n 40 "$LOGFILE"; }
# Recovery artifact presence
if ls outputs/recovery/recovery_*.tar >/dev/null 2>&1; then
  echo "✅ Recovery kit present"; ls -lh outputs/recovery/recovery_*.tar | tail -n1
else
  echo "⚠️ Recovery kit missing (first run may create on next pass)"
fi
