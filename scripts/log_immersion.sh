#!/data/data/com.termux/files/usr/bin/bash
# Usage:
#  log_immersion.sh <mp3> <voices_csv> <emotions_csv> <pace_wpm> <duck_db> <sfx_db>
# Emits: category=immersion stage=scene|mix status=ok
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; MP3="${1:?mp3}"; voices="${2:-}"; emotions="${3:-}"
pace="${4:-}"; duck="${5:-}"; sfx="${6:-}"
[ -s "$MP3" ] || { echo "✘ missing audio: $MP3"; exit 2; }
metrics="$(jq -nc --arg v "$voices" --arg e "$emotions" --argjson pace "${pace:-null}" --argjson duck "${duck:-null}" --argjson sfx "${sfx:-null}" '
{
  voices: ( ($v|length>0) ? ($v|split(",")|map(.|trim)) : [] ),
  emotions: ( ($e|length>0) ? ($e|split(",")|map(.|trim)) : [] )
} + ( $pace|type=="number" ? {pace_wpm:$pace} : {} )
  + ( $duck|type=="number" ? {duck_db:$duck} : {} )
  + ( $sfx|type=="number" ? {sfx_db:$sfx} : {} ) ')"
"$ROOT/bin/codex_log.sh" --cat immersion --stage mix --status ok --file "$MP3" --metrics "$metrics"
