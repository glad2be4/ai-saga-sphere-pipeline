#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"

LOGDIR="${PWD}/logs"; mkdir -p "$LOGDIR"
echo "== Codex Run (Spine + Mirror + Pipeline + Recovery) =="

# Place real production steps here (narrate, master, package...)
# For now: write a marker and build a recovery kit
echo "BUILD: $(date -Is)" > outputs/build.txt

tar -cf "outputs/recovery/recovery_$(date +%Y%m%d_%H%M%S).tar" \
  feed.xml public/index.html outputs/build.txt 2>/dev/null || true

sha256sum outputs/recovery/recovery_* 2>/dev/null | tail -n1 | awk '{print $1}' > outputs/latest.sha256 || true
