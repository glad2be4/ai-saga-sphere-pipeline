#!/usr/bin/env bash
# Usage patterns:
#  codex_log.sh --cat narration --stage synth --status ok --file public/audio/ch1.mp3 --metrics '{"lufs":-16.1}'
#  codex_log.sh --raw '{"ts":"...","run_id":"...","category":"feed","stage":"probe","status":"ok","feed_url":"..."}'
set -euo pipefail
LOG="${LOG:-logs/codex/codex.jsonl}"
mkdir -p "$(dirname "$LOG")"
run_id="${RUN_ID:-codex_$(date -u +%Y%m%d_%H%M%S)}"
ts="$(date -u +%FT%TZ)"

raw=""
catg=""; stage=""; status=""
endpoint=""; file=""; hash=""; feed_url=""; cid=""; ipns=""
metrics=""; http=""; reason=""; notes=""; meta=""

while [ $# -gt 0 ]; do
  case "$1" in
    --raw) raw="$2"; shift 2;;
    --cat|--category) catg="$2"; shift 2;;
    --stage) stage="$2"; shift 2;;
    --status) status="$2"; shift 2;;
    --endpoint) endpoint="$2"; shift 2;;
    --file) file="$2"; shift 2;;
    --hash) hash="$2"; shift 2;;
    --feed_url) feed_url="$2"; shift 2;;
    --cid) cid="$2"; shift 2;;
    --ipns) ipns="$2"; shift 2;;
    --metrics) metrics="$2"; shift 2;;
    --http) http="$2"; shift 2;;
    --reason) reason="$2"; shift 2;;
    --notes) notes="$2"; shift 2;;
    --meta) meta="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

if [ -n "$raw" ]; then
  echo "$raw" | jq -c . >> "$LOG"
  exit 0
fi

jq -nc \
  --arg ts "$ts" --arg run_id "$run_id" \
  --arg category "$catg" --arg stage "$stage" --arg status "$status" \
  --arg endpoint "$endpoint" --arg file "$file" --arg hash "$hash" \
  --arg feed_url "$feed_url" --arg cid "$cid" --arg ipns "$ipns" \
  --arg reason "$reason" --arg notes "$notes" --arg http "$http" \
  --argjson metrics "${metrics:-{}}" --argjson meta "${meta:-{}}" '
  {
    ts:$ts, run_id:$run_id, category:$category, stage:$stage, status:$status
  }
  + ( $endpoint|length>0 ? {endpoint:$endpoint} : {} )
  + ( $file|length>0 ? {file:$file} : {} )
  + ( $hash|length>0 ? {hash:$hash} : {} )
  + ( $feed_url|length>0 ? {feed_url:$feed_url} : {} )
  + ( $cid|length>0 ? {cid:$cid} : {} )
  + ( $ipns|length>0 ? {ipns:$ipns} : {} )
  + ( $reason|length>0 ? {reason:$reason} : {} )
  + ( $notes|length>0 ? {notes:$notes} : {} )
  + ( ($http|length>0 and ($http|tonumber?!=null)) ? {http:($http|tonumber)} : ( $http|length>0 ? {http:$http} : {} ) )
  + ( ($metrics|type=="object" and ($metrics|length>0)) ? {metrics:$metrics} : {} )
  + ( ($meta|type=="object" and ($meta|length>0)) ? {meta:$meta} : {} )
' >> "$LOG"
