#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
# Reuse the same script nightly; idempotent by design
export GH_USER="${GH_USER:-glad2be4}"
export REPO="${REPO:-ai-saga-sphere-pipeline}"
bash "$HOME/repo/$REPO/$(basename "$0")" || true
