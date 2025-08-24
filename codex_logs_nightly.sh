#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
ts="$(date -u +%Y%m%d_%H%M%S)"
# rotate single JSON index for quick diff + compact recovery kit
jq -n --arg ts "$ts" --arg run "codex_$ts" \
  '{run:$run, ts:$ts, checkpoints: ["pages","cadence","logs"]}' > "logs/system/codex_run_$ts.json"
tar -cf "recovery/recovery_$ts.tar" public 2>/dev/null || true
sha256sum "recovery/recovery_$ts.tar" > "recovery/recovery_$ts.tar.sha256"
git add -A
git commit -m "Codex: logs + recovery ${ts} (idempotent)" || true
git push origin main || true
