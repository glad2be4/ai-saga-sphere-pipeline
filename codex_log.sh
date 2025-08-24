#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
LOG_ROOT="${LOG_ROOT:-logs}"
ts_utc() { date -u +%FT%TZ; }
stamp()  { date -u +%Y%m%dT%H%M%SZ; }

# log_json <domain> <json>
log_json() {
  local domain="$1"; shift
  local now="$(stamp)"
  local dir="$LOG_ROOT/$domain/jsonl"
  mkdir -p "$dir"
  local f="$dir/codex_${domain}_${now}.jsonl"
  printf '%s\n' "$*" >> "$f"
  echo "$f"
}

# append_manifest <domain> <granularity:daily|week|quarter> <json>
append_manifest() {
  local domain="$1" gran="$2" json="$3" d i
  case "$gran" in
    daily)   d="$(date -u +%Y%m%d)"; i="$LOG_ROOT/$domain/manifests/index_${d}.json";;
    week)    d="$(date -u +%G-W%V)"; i="$LOG_ROOT/$domain/manifests/index_week_${d}.json";;
    quarter) d="$(date -u +%Y)-Q$(( ( ($(date -u +%-m)+2)/3 ) ))"; i="$LOG_ROOT/$domain/manifests/index_quarter_${d}.json";;
    *) echo "bad granularity"; return 1;;
  esac
  mkdir -p "$(dirname "$i")"
  { test -s "$i" || printf '[]'; } | jq --argjson e "$json" '. + [$e]' > "${i}.tmp" && mv "${i}.tmp" "$i"
}

# rotate domain keepN (gz older than N days, keep manifests)
rotate_logs() {
  local domain="$1" keep="${2:-14}"
  find "$LOG_ROOT/$domain/jsonl" -type f -mtime +"$keep" -name '*.jsonl' -print0 | xargs -0r gzip -f
}
