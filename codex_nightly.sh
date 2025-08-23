#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"; : "${REPO_NAME:?REPO_NAME required}"
cd "$HOME/repo/$REPO_NAME"
./codex_run.sh   || true
./codex_verify.sh || true
