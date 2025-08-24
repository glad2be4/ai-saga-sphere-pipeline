#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
export GH_USER="'"$GH_USER"'"
export REPO_NAME="'"$REPO_NAME"'"
export REPO_DIR="$HOME/repo/$REPO_NAME"
cd "$REPO_DIR"
./codex_nightly.sh || true
