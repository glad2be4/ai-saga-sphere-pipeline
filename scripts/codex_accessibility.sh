#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
capdir="$repo_root/public/captions"
index="$repo_root/public/index.html"

# 2.1 Make sure at least one caption track exists (placeholder if none provided yet)
lang_list="${VOICE_LANGS:-en-US}"   # allow multiple like: "en-US es-ES fr-FR"
mkdir -p "$capdir"
for L in $lang_list; do
  v="$capdir/master_${L}.vtt"
  if [ ! -s "$v" ]; then
    cat > "$v" <<VTT
WEBVTT

00:00.000 --> 00:01.000
[${L}] Captions placeholder — Codex will overwrite when transcripts are available.
VTT
  fi
done

# 2.2 Produce captions manifest (index.json)
jq -n --arg ts "$(date -u +%FT%TZ)" --arg langs "$lang_list" \
  '{ts:$ts, languages:($langs|split(" "))}' > "$capdir/index.json"

# 2.3 Inject <track> tags into public/index.html (idempotent)
if [ -s "$index" ]; then
  # remove old injected block (if any)
  sed -i '/<!-- CODEX:TRACKS START -->/,/<!-- CODEX:TRACKS END -->/d' "$index"
else
  mkdir -p "$(dirname "$index")"
  echo "<!doctype html><meta charset=utf-8><title>AI Saga Sphere</title><h1>AI Saga Sphere</h1>" > "$index"
fi

{
  echo "<!-- CODEX:TRACKS START -->"
  for L in $lang_list; do
    short="$(echo "$L" | cut -d- -f1)"
    echo "<track kind=\"captions\" srclang=\"$short\" label=\"$L\" src=\"captions/master_${L}.vtt\" default>"
  done
  echo "<!-- CODEX:TRACKS END -->"
} >> "$index"

# 2.4 Basic a11y enhancements (alt and aria) if a cover exists
if grep -q '<img ' "$index"; then
  sed -i 's/<img /<img alt="AI Saga Sphere cover" /' "$index" || true
else
  echo '<p aria-label="Project description">Codex Sovereign Audiobook Continuum</p>' >> "$index"
fi
echo "[accessibility] overlays updated"
