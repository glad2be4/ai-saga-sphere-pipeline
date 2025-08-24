#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
dist="$repo_root/public/distribution"
mkdir -p "$dist"

# Platform URLs via repo Variables or fallbacks (edit in GitHub → Settings → Variables)
spotify="${SPOTIFY_URL:-#}"
apple="${APPLE_URL:-#}"
amazon="${AMAZON_URL:-#}"
deezer="${DEEZER_URL:-#}"
iheart="${IHEART_URL:-#}"
tunein="${TUNEIN_URL:-#}"
feed="${FEED_URL:-https://example.github.io/ai-saga-sphere-pipeline/feed.xml}"

cat > "$dist/index.html" <<HTML
<!doctype html><meta charset=utf-8>
<title>Subscribe — AI Saga Sphere</title>
<h1>Subscribe</h1>
<p>Primary RSS feed: <a href="$feed">$feed</a></p>
<ul>
  <li><a rel="external" href="$spotify">Spotify</a></li>
  <li><a rel="external" href="$apple">Apple Podcasts</a></li>
  <li><a rel="external" href="$amazon">Amazon / Audible</a></li>
  <li><a rel="external" href="$deezer">Deezer</a></li>
  <li><a rel="external" href="$iheart">iHeart</a></li>
  <li><a rel="external" href="$tunein">TuneIn</a></li>
</ul>
HTML

jq -n \
  --arg ts "$(date -u +%FT%TZ)" \
  --arg feed "$feed" \
  --arg spotify "$spotify" --arg apple "$apple" --arg amazon "$amazon" \
  --arg deezer "$deezer" --arg iheart "$iheart" --arg tunein "$tunein" \
  '{ts:$ts, feed:$feed, links:{spotify:$spotify, apple:$apple, amazon:$amazon, deezer:$deezer, iheart:$iheart, tunein:$tunein}}' \
> "$dist/links.json"

echo "[distribution] hub updated"
