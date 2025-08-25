#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -x bin/codex_autofix.sh ] && bin/codex_autofix.sh || true
