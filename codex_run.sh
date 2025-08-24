#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Vars & dirs
REPO_NAME="${REPO_NAME:-ai-saga-sphere-pipeline}"
REPO_DIR="${REPO_DIR:-$HOME/repo/$REPO_NAME}"
OUT_DIR="$REPO_DIR/outputs"
REC_DIR="$REPO_DIR/recovery"
LOG_DIR="$REPO_DIR/logs"
CHK_NAME="AI_SagaSphere_Consolidated_QC_Checklist.docx"
RCLONE_TARGETS="${RCLONE_TARGETS:-}"
mkdir -p "$OUT_DIR" "$REC_DIR" "$LOG_DIR" "$REPO_DIR/public"

RUN_ID="$(date -u +%Y%m%d_%H%M%S)"
LOG="$LOG_DIR/codex_run_${RUN_ID}.log"
exec > >(tee -a "$LOG") 2>&1

echo "== Codex Run (embed QC checklist + Recovery Kit) =="

# 1) Refresh <updated> timestamp in feed.xml (no XML libs needed)
if [ -f "$REPO_DIR/feed.xml" ]; then
  TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  sed -i "0,/<updated>.*<\/updated>/s##<updated>${TS}<\/updated>#" "$REPO_DIR/feed.xml" || true
else
  # Minimal feed if missing (keeps Pages/feeds alive)
  TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat > "$REPO_DIR/feed.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>AI Saga Sphere Pipeline</title>
  <updated>${TS}</updated>
  <id>tag:ai-saga-sphere,pipeline</id>
  <entry><title>Codex Bootstrap</title><updated>${TS}</updated><id>tag:bootstrap</id></entry>
</feed>
XML
fi

# 2) Ensure checklist is present in repo and recovery (skip gracefully if missing)
if [ -f "$REPO_DIR/$CHK_NAME" ]; then
  cp -f "$REPO_DIR/$CHK_NAME" "$REC_DIR/$CHK_NAME"
  echo "✓ Embedded checklist -> recovery/$CHK_NAME"
else
  echo "⚠ Checklist not found at $REPO_DIR/$CHK_NAME (skipping embed this run)"
fi

# 3) Emit a small QC JSON for transparency
echo "{\"run\":\"$RUN_ID\",\"ts\":\"$(date -u +"%FT%TZ")\",\"checklist\":\"$( [ -f "$REC_DIR/$CHK_NAME" ] && echo present || echo missing )\"}" \
  > "$OUT_DIR/qc_report_${RUN_ID}.json"

# 4) Build Recovery Kit (always includes feed + index + .nojekyll + optional DOCX + outputs)
KIT="$REC_DIR/recovery_${RUN_ID}.tar"
tar -cf "$KIT" -C "$REPO_DIR" feed.xml index.html .nojekyll 2>/dev/null || true
# include outputs (QC etc)
tar -rf "$KIT" -C "$REPO_DIR" outputs 2>/dev/null || true
# include checklist if present
[ -f "$REC_DIR/$CHK_NAME" ] && tar -rf "$KIT" -C "$REC_DIR" "$CHK_NAME" || true
sha256sum "$KIT" | awk '{print $1}' > "${KIT}.sha256"
ln -sf "$(basename "$KIT")" "$REC_DIR/latest.tar" || true
ln -sf "$(basename "${KIT}.sha256")" "$REC_DIR/latest.sha256" || true
echo "✓ Recovery kit -> $(basename "$KIT")"

# 5) Optional mirrors via rclone (runs only when remotes exist)
if [ -n "$RCLONE_TARGETS" ]; then
  echo "== Mirrors =="
  for tgt in $RCLONE_TARGETS; do
    # Only attempt if remote name exists (prevents noisy failures)
    if rclone listremotes 2>/dev/null | sed 's/:$//' | grep -q "^${tgt%%:*}$"; then
      echo "→ rclone copy outputs/ → $tgt/outputs/"
      rclone copy "$OUT_DIR" "$tgt/outputs/" --create-empty-src-dirs --fast-list --transfers=4 --checkers=8 >/dev/null 2>&1 || true
      echo "→ rclone copy recovery/ → $tgt/recovery/"
      rclone copy "$REC_DIR" "$tgt/recovery/" --fast-list --transfers=4 --checkers=8 >/dev/null 2>&1 || true
    else
      echo "… skip mirror: remote '${tgt%%:*}' not configured."
    fi
  done
fi

echo "== Run complete: $RUN_ID =="
