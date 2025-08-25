#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IN_TXT="${1:-$ROOT/manuscripts/input.txt}"
OUT_WAV="$ROOT/work/narr_raw.wav"

[ -s "$IN_TXT" ] || { echo "✘ manuscripts/input.txt missing or empty. Provide real text."; exit 2; }

API="$ELEVEN_API_KEY"
VOICE="${ELEVEN_VOICE_ID:-Rachel}"
if [ -n "${API:-}" ]; then
  # ElevenLabs v1 text-to-speech
  curl -fsS -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE" \
    -H "xi-api-key: $API" -H 'Content-Type: application/json' \
    -d @<(jq -nc --arg t "$(cat "$IN_TXT")" '{"text":$t,"model_id":"eleven_monolingual_v1","voice_settings":{"stability":0.35,"similarity_boost":0.7}}') \
    --output "$OUT_WAV"
else
  # espeak-ng fallback (no placeholders; actual TTS from user manuscript)
  espeak-ng -f "$IN_TXT" -s 160 -w "$OUT_WAV"
fi

[ -s "$OUT_WAV" ] || { echo "✘ narration failed"; exit 3; }
echo "$OUT_WAV"
