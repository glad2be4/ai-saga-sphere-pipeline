#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# === Codex Run (Spine + Mirror + Pipeline + Recovery + Mirrors) ===
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG=".codex_run_${STAMP}.log"
exec > >(tee -a "$LOG") 2>&1

FEED_TITLE="${FEED_TITLE:-AI Saga Sphere}"
SITE_URL="https://glad2be4.github.io/ai-saga-sphere-pipeline"
FEED_URL="${SITE_URL}/feed.xml"

# 1) Layout
mkdir -p public/audio recovery

# 2) Generate demo audio (normalized to Codex: I=-18 LUFS, TP=-2 dBTP)
OUT_MP3="public/audio/book0_premise_demo.mp3"
if [ ! -f "$OUT_MP3" ]; then
  ffmpeg -hide_banner -loglevel error \
    -f lavfi -i "sine=frequency=440:duration=8" -ar 48000 -ac 2 \
    -af loudnorm=I=-18:TP=-2:LRA=11 \
    -b:a 192k "$OUT_MP3"
fi

# 3) Build a minimal RSS feed with one item (demo episode)
cat > public/feed.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>${FEED_TITLE}</title>
    <link>${SITE_URL}</link>
    <description>${FEED_TITLE} — autonomic Codex pipeline</description>
    <item>
      <title>Book 0 — Story Premise (demo)</title>
      <description>Autonomic demo episode (normalized to Codex loudness).</description>
      <enclosure url="${SITE_URL}/audio/$(basename "$OUT_MP3")" type="audio/mpeg" />
      <guid>${SITE_URL}/audio/$(basename "$OUT_MP3")</guid>
      <pubDate>$(date -R)</pubDate>
    </item>
  </channel>
</rss>
EOF

# 4) Recovery kit (tar + sha256 + manifest)
RCV="recovery/recovery_${STAMP}.tar"
tar -cf "$RCV" public
sha256sum "$RCV" > "${RCV}.sha256"

MAN="recovery/RECOVERY_MANIFEST_${STAMP}.json"
cat > "$MAN" <<EOF
{
  "generated_at": "${STAMP}",
  "feed_url": "${FEED_URL}",
  "files": [
    {"path": "public/feed.xml"},
    {"path": "$(echo "$OUT_MP3")"}
  ],
  "checksums": [
    {"path": "$(basename "$RCV")", "sha256": "$(awk '{print $1}' ${RCV}.sha256)"}
  ]
}
EOF

# 5) Optional mirrors
# 5a) OneDrive (if rclone onedrive: is configured)
if rclone listremotes 2>/dev/null | grep -q '^onedrive:$'; then
  rclone mkdir onedrive:AI_Saga_Sphere/outputs >/dev/null 2>&1 || true
  rclone copy public onedrive:AI_Saga_Sphere/outputs -P || true
fi

# 5b) Storacha/IPFS placeholders (will be replaced by your real CLI once available)
echo "CID_PENDING"  > public/ipfs.txt     # replace with real CID when published
echo "IPNS_PENDING" > public/ipns.txt     # replace with real IPNS name

echo "== Codex run complete =="
echo "Feed: ${FEED_URL}"
