#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
echo "== Codex Verify (Spine + Mirror + Pipeline + Recovery) =="

# Feed Check
if curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" | grep -q 200; then
  echo "✔ Feed OK"
else
  echo "✗ Feed not 200 OK"
fi

# Recovery Kit
if ls recovery/recovery_*.tar.sha256 >/dev/null 2>&1; then
  echo "✔ Recovery artifacts OK"
else
  echo "✗ Recovery artifacts missing"
fi

# Mirrors
[ -f public/ipfs.txt ] && echo "✔ IPFS present"
[ -f public/ipns.txt ] && echo "✔ IPNS present"

# Transparency
LOGFILE="$(ls -1 .codex_run_*.log 2>/dev/null | tail -1 || true)"
[ -n "$LOGFILE" ] && tail -n 10 "$LOGFILE"
