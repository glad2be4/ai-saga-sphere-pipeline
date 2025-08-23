#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
# Re-run the same ALL-IN script nightly (idempotent)
export GH_USER="${GH_USER:-glad2be4}"
export REPO="${REPO:-ai-saga-sphere-pipeline}"
bash "$HOME/repo/$REPO/$(basename "$0")" || true
