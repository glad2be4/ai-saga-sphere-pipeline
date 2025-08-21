#!/usr/bin/env bash
set -euo pipefail
pip install --quiet opentimestamps-client >/dev/null 2>&1 || true
for f in $(ls -1t recovery/recovery_*.tar{,.enc} 2>/dev/null | head -n2); do ots stamp "$f" || true; done
echo "[ots] stamped (if present)"
