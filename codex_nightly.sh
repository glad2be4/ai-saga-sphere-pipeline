#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
GH_USER="${GH_USER:?GH_USER required}"
REPO_NAME="${REPO_NAME:-ai-saga-sphere-pipeline}"
RCLONE_TARGETS="${RCLONE_TARGETS:-}"
cd "$HOME/repo/$REPO_NAME"
./codex_run.sh || true
./codex_verify.sh || true
