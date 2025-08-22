#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
C_0=0
ok(){ printf "✓ %s\n" "$*"; }
bad(){ printf "✗ %s\n" "$*"; C_0=$((C_0+1)); }

OWNER="'"$OWNER"'"
REPO="'"$REPO"'"
FEED_URL="https://$OWNER.github.io/$REPO/feed.xml"

if curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" | grep -q 200; then
  ok "Feed OK: $FEED_URL"
else
  bad "Feed not 200: $FEED_URL"
fi

# Recovery + mirrors (best effort if first boot)
MANIFEST="$(ls -1 recovery/RECOVERY_MANIFEST_*.json 2>/dev/null | head -n1 || true)"
[ -n "$MANIFEST" ] && ok "Recovery manifest present: $(basename "$MANIFEST")" || echo "ℹ Recovery manifest will appear after full pipeline run"
[ -f public/ipfs.txt ] && ok "IPFS CID present: $(cat public/ipfs.txt)" || echo "ℹ IPFS CID missing"
[ -f public/ipns.txt ] && ok "IPNS name present: $(cat public/ipns.txt)" || echo "ℹ IPNS name missing"

echo "== Summary: errors=$C_0 =="
exit "$C_0"
