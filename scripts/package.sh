#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
MP3="${1:?mp3 required}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUB="$ROOT/public"
AUDIO="$PUB/audio"
mkdir -p "$AUDIO" "$PUB/captions"

BASE="$(basename "$MP3")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cp -f "$MP3" "$AUDIO/$BASE"

FEED="$PUB/feed.xml"
if [ ! -s "$FEED" ]; then
cat > "$FEED" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>AI Saga Sphere</title>
  <id>https://$GH_USER.github.io/$REPO_NAME/</id>
  <updated>$TS</updated>
  <author><name>$GH_USER</name></author>
</feed>
XML
fi

# append entry
ENTRY="<entry><id>tag:ai-saga-sphere:${BASE}</id><title>${BASE}</title><updated>${TS}</updated><link rel=\"enclosure\" href=\"audio/${BASE}\" type=\"audio/mpeg\"/></entry>"
tmp=$(mktemp); awk -v e="$ENTRY" '1;/<\/feed>/{print e;exit}' "$FEED" > "$tmp" && mv "$tmp" "$FEED"

# bump updated
tmp=$(mktemp)
awk -v U="$TS" '{if (!done && $0 ~ /<updated>.*<\/updated>/){gsub(/<updated>.*<\/updated>/,"<updated>"U"</updated>"); done=1} print }' "$FEED" > "$tmp" && mv "$tmp" "$FEED"

echo "$AUDIO/$BASE"
