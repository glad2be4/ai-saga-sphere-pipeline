#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${REPO:=ai-saga-sphere-pipeline}"
: "${REPO_DIR:=$HOME/repo/$REPO}"
: "${RCLONE_TARGETS:=${RCLONE_TARGETS:-}}"
: "${REC_DIR_DISABLED:=1}"

cd "$REPO_DIR"
LOGFILE="outputs/codex_run_$(date -Is).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "== Codex Run (Spine + Mirror + Pipeline + Recovery) =="
# 1) (Place your real production steps here, narration/build/mix/package feed.xml)
#    For now we just ensure feed exists and is fresh.
if [ ! -f feed.xml ]; then
  cat > feed.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>AI Saga Sphere Pipeline</title>
  <updated>2000-01-01T00:00:00Z</updated>
  <id>tag:bootstrap</id>
  <entry>
    <title>Codex Bootstrap</title>
    <updated>2000-01-01T00:00:00Z</updated>
    <id>tag:codex-bootstrap</id>
  </entry>
</feed>
XML
fi
# touch updated date
perl -0777 -pe 's#<updated>.*?</updated>#"<updated>".gmtime()."Z</updated>"#e' -i feed.xml

# 2) Recovery Kit (zip + sha256)
mkdir -p outputs/recovery
TAR="outputs/recovery/recovery_$(date +%Y%m%d_%H%M%S).tar"
tar -cf "$TAR" feed.xml || true
sha256sum "$TAR" > "${TAR}.sha256" || true

# 3) Optional mirrors via rclone (if configured and remotes exist)
if [ -n "${RCLONE_TARGETS:-}" ]; then
  echo "== Mirrors =="
  for tgt in $RCLONE_TARGETS; do
    # Require remote to exist (appears as 'name:' in listremotes)
    if rclone listremotes 2>/dev/null | sed 's/:$//' | grep -q "^${tgt%%:*}$"; then
      echo "→ rclone copy outputs/ → $tgt/outputs/"
      rclone copy outputs/ "$tgt/outputs/" --create-empty-src-dirs --fast-list \
        --transfers=4 --checkers=8 --progress 2>/dev/null || true
    else
      echo "(!) Skipping $tgt (remote not found)"
    fi
  done
fi

echo "== Done =="
