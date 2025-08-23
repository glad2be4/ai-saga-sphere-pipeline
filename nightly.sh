#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
cd "$HOME/repo/ai-saga-sphere-pipeline"
git pull --ff-only -q || true
./codex_run.sh
git add -A
git commit -m "Nightly: Codex auto-run" || true
git push origin main || true
./codex_verify.sh || true
./codex_mirrors.sh || true
