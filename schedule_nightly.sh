#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
. "$(dirname "$0")/codex_env.sh"

if ! command -v termux-job-scheduler >/dev/null 2>&1; then
  echo "termux-job-scheduler not available (install termux-api and allow permission)."
  exit 1
fi

# Persisted periodic job ~24h (Android may jitter exact time)
termux-job-scheduler \
  --job-id 9001 \
  --period-ms 86400000 \
  --persisted true \
  --require-charging false \
  --require-device-idle false \
  --script "$REPO_DIR/codex_nightly.sh"

echo "Nightly job scheduled (ID=9001)."
