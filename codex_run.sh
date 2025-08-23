#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"; : "${REPO_NAME:?REPO_NAME required}"
REPO_DIR="$HOME/repo/$REPO_NAME"
LOGDIR="$REPO_DIR/logs"
OUTDIR="$REPO_DIR/outputs"
RECDIR="$REPO_DIR/recovery"
mkdir -p "$LOGDIR" "$OUTDIR" "$RECDIR"

echo "== Codex Run (Spine + Mirror + Pipeline + Recovery) =="
run_id="$(date +%Y%m%d_%H%M%S)"
log="$LOGDIR/codex_run_${run_id}.log"

# Refresh timestamps inside feed and copy to public/
now_iso="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
sed -i "0,/<updated>.*<\/updated>/s##<updated>${now_iso}<\/updated>#" "$REPO_DIR/feed.xml" || true
cp -f "$REPO_DIR/feed.xml" "$REPO_DIR/public/feed.xml"
touch "$REPO_DIR/public/.nojekyll"

# Example QC artifact (extend as your pipeline grows)
echo "{\"run\":\"$run_id\",\"gh_user\":\"$GH_USER\",\"repo\":\"$REPO_NAME\",\"updated\":\"$now_iso\"}" \
  > "$OUTDIR/qc_report_${run_id}.json"

# Recovery kit
tar_name="$RECDIR/recovery_${run_id}.tar"
tar -cf "$tar_name" feed.xml public/feed.xml outputs || true
sha256sum "$tar_name" | awk '{print $1}' > "$OUTDIR/latest.sha256"

# Optional mirrors via rclone (only if targets exist)
if [ -n "${RCLONE_TARGETS:-}" ]; then
  echo "== Mirrors =="
  for tgt in $RCLONE_TARGETS; do
    if rclone listremotes 2>/dev/null | sed 's/:$//' | grep -q "^${tgt%%:*}$"; then
      echo "→ rclone copy outputs/ to $tgt/outputs/"
      rclone copy outputs/ "$tgt/outputs/" --transfers=4 --checkers=8 --progress 2>/dev/null || true
      echo "→ rclone copy recovery/ to $tgt/recovery/"
      rclone copy recovery/ "$tgt/recovery/" --transfers=4 --checkers=8 --progress 2>/dev/null || true
    else
      echo "! Skip mirror: remote '$tgt' not found (use 'rclone config')."
    fi
  done
fi

echo "== Codex Run complete =="
echo "log:$log"
