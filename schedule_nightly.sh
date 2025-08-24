#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
# Cancel if exists, then register
termux-job-scheduler --cancel --job-id 9001 >/dev/null 2>&1 || true
termux-job-scheduler \
  --job-id 9001 \
  --persisted true \
  --period-ms 86400000 \
  --require-charging true \
  --network any \
  --script "${PWD}/codex_nightly.sh"
