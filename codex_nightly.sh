#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"
: "${REPO_NAME:=ai-saga-sphere-pipeline}"
cd "$HOME/repo/$REPO_NAME"
# create a minimal feed if missing so Pages always has something to serve
if [ ! -s feed.xml ]; then
  dt="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  cat > feed.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>AI Saga Sphere Pipeline</title>
  <updated>${dt}</updated>
  <id>tag:${GH_USER},${dt}:feed</id>
  <entry><title>Bootstrap</title><id>tag:${GH_USER},${dt}:bootstrap</id><updated>${dt}</updated></entry>
</feed>
EOF
fi
git add -A
git commit -m "Codex: nightly $(date -u +'%Y%m%d_%H%M%S')" 2>/dev/null || true
git push origin main
./codex_verify.sh || true

# Optional mirrors
if [ -n "${RCLONE_TARGETS:-}" ]; then
  for tgt in $RCLONE_TARGETS; do
    if rclone lsd "${tgt%%:*}:" >/dev/null 2>&1; then
      echo "== Mirror -> $tgt/outputs"
      rclone copy --ignore-existing outputs/ "$tgt/outputs/" >/dev/null 2>&1 || true
    fi
  done
fi
