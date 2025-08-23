#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${REPO_NAME:=ai-saga-sphere-pipeline}"
: "${RCLONE_TARGETS:=}"

LOGDIR="outputs"; mkdir -p "$LOGDIR" "recovery"
RUN_ID=$(date +"%Y%m%d_%H%M%S")
LOG="$LOGDIR/codex_run_${RUN_ID}.log"

# 0) Minimal self-heal feed (so Pages has something to serve)
if [ ! -f feed.xml ]; then
  cat > feed.xml <<XML
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>AI Saga Sphere Pipeline</title>
  <updated>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</updated>
  <id>https://${GH_USER}.github.io/${REPO_NAME}/feed.xml</id>
  <entry><title>Codex Bootstrap</title><updated>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</updated><id>tag:ai-saga-sphere,bootstrap</id></entry>
</feed>
XML
fi

# 1) Example “build” section (placeholder; extend with your real processing)
echo "== Codex Run (Spine + Mirror + Pipeline + Recovery) ==" | tee "$LOG"
echo "No master MP3 found — skipping teaser." | tee -a "$LOG"

# 2) Recovery kit (tar + sha256)
TAR="outputs/recovery/recovery_$(date +%Y%m%d_%H%M%S).tar"
mkdir -p outputs/recovery
tar -cf "$TAR" feed.xml || true
sha256sum "$TAR" | awk '{print $1}' > outputs/recovery/latest.sha256

# 3) Optional mirrors (only if remote exists)
if [ -n "$RCLONE_TARGETS" ]; then
  echo "== Mirrors ==" | tee -a "$LOG"
  for tgt in $RCLONE_TARGETS; do
    if rclone lsd "$tgt" >/dev/null 2>&1; then
      echo "→ rclone copy outputs/ to $tgt/${REPO_NAME}/outputs/" | tee -a "$LOG"
      rclone copy outputs/ "$tgt/${REPO_NAME}/outputs/" --fast-list --transfers=4 --checkers=8 >/dev/null 2>&1 || true
    else
      echo "… skipping mirror (remote missing): $tgt" | tee -a "$LOG"
    fi
  done
fi
