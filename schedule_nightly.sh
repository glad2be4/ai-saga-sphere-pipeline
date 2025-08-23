#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"; : "${REPO_NAME:?REPO_NAME required}"
REPO_DIR="$HOME/repo/$REPO_NAME"
JOB_ID=9001
# Cancel if exists (no-op if missing)
termux-job-scheduler --cancel --job-id $JOB_ID >/dev/null 2>&1 || true
# Period in ms (24h); Termux API may not support exact hour, but period keeps it daily.
termux-job-scheduler \
  --job-id $JOB_ID \
  --script "$REPO_DIR/codex_nightly.sh" \
  --period-ms 86400000 \
  --persisted true \
  --require-charging true \
  --network any
echo "Nightly job scheduled (id $JOB_ID)."
