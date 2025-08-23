#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
LOGDIR="outputs"; mkdir -p "$LOGDIR"
echo "== Codex Run (Spine + Mirror + Pipeline + Recovery) ==" | tee "$LOGDIR/codex_run_$(date +%Y%m%d_%H%M%S).log"
# Example production anchor points (extend as your repo implements)
#  - audio render, LUFS normalize, package, etc.
#  - generate recovery kit (tar+sha256)
mkdir -p outputs/recovery
tar -cf "outputs/recovery/recovery_$(date +%Y%m%d_%H%M%S).tar" \
  feed.xml || true
( cd outputs/recovery && sha256sum recovery_*.tar > latest.sha256 ) || true
