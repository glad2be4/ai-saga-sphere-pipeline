#!/usr/bin/env bash
set -euo pipefail
status="${1:?}"; stage="${2:?}"; endpoint="${3:?}"; url="${4:-}"
reason="${5:-}"; http="${6:-}"; meta="${7:-{}}"
run_id="${RUN_ID:-dist_$(date -u +%Y%m%d_%H%M%S)}"; ts="$(date -u +%FT%TZ)"
jq -nc --arg run_id "$run_id" --arg ts "$ts" --arg stage "$stage" --arg status "$status" \
      --arg endpoint "$endpoint" --arg feed_url "$url" --arg reason "$reason" --arg http "$http" \
      --argjson meta "$meta" '
  {run_id:$run_id,ts:$ts,stage:$stage,status:$status,endpoint:$endpoint}
  + ( $feed_url|length>0 ? {url:$feed_url} : {} )
  + ( ($http|length>0 and ($http|tonumber?!=null))?{http:($http|tonumber)}:(($http|length>0)?{http:$http}:{}) )
  + ( $reason|length>0 ? {reason:$reason} : {} )
  + ( ($meta|type=="object") ? {meta:$meta} : {} )
' >> logs/distribution/distribution.jsonl
