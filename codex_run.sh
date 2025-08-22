#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
GH_USER="${GH_USER:-$(gh api user -q .login 2>/dev/null || echo unknown)}"
REPO="${REPO:-ai-saga-sphere-pipeline}"
FEED_URL="https://${GH_USER}.github.io/${REPO}/feed.xml"
echo "== Codex Run (Spine + Mirrors + Recovery) =="

mkdir -p outputs public recovery logs

# Demo artifact if none exists (keeps pipeline observable)
if ! ls outputs/*.mp3 >/dev/null 2>&1; then
  printf "AI Saga Sphere demo\n" | ffmpeg -f lavfi -i anullsrc=r=44100:cl=mono -f s16le -i - -t 2 \
    -filter_complex "amix=inputs=1,volume=1.0" -ar 44100 -ac 2 -b:a 128k "outputs/demo_$(date +%Y%m%d_%H%M%S).mp3" -y >/dev/null 2>&1 || true
fi

# Public production stub feed (separate folder) for mirroring
cat > public/feed.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>AI Saga Sphere – Production</title>
  <updated>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</updated>
  <id>tag:${REPO},prod</id>
</feed>
EOF

# Recovery Kit (Spine+Mirror+Feed+Hashes) per Autonomic DNA
MAN="recovery/RECOVERY_MANIFEST_$(date -u +%Y%m%d_%H%M%S).json"
tar czf "recovery/recovery_$(date -u +%Y%m%d_%H%M%S).tar.gz" outputs public feed.xml 2>/dev/null || true
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum recovery/*.tar.gz > recovery/recovery_hashes.sha256
else
  openssl dgst -sha256 recovery/*.tar.gz > recovery/recovery_hashes.sha256
fi

# Manifest: timestamp + feed + file list
python - <<PY || true
import json, os, datetime
files = sorted(os.listdir('outputs')) if os.path.isdir('outputs') else []
json.dump({
  "timestamp": datetime.datetime.utcnow().isoformat()+"Z",
  "feed_url": "${FEED_URL}",
  "outputs": files
}, open("${MAN}", "w"))
PY

echo "== Recovery kit ready: $(ls -1 recovery/* | wc -l) files =="

# Optional mirror to OneDrive via rclone (if configured)
if rclone listremotes 2>/dev/null | grep -q '^onedrive:'; then
  echo "== Mirror → OneDrive (optional) =="
  rclone copy outputs onedrive:AI_Saga_Sphere/outputs -P || true
  rclone copy public  onedrive:AI_Saga_Sphere/public  -P || true
  rclone copy recovery onedrive:AI_Saga_Sphere/recovery -P || true
fi
