#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
termux-job-scheduler --cancel --job-id 9002 >/dev/null 2>&1 || true
termux-job-scheduler \
  --job-id 9002 \
  --persisted true \
  --script "${PWD}/codex_nightly.sh"
