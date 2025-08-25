#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEEZER_URL="${DEEZER_URL:-${VAR_DEEZER_URL:-}}"
IHEART_URL="${IHEART_URL:-${VAR_IHEART_URL:-}}"
TUNEIN_URL="${TUNEIN_URL:-${VAR_TUNEIN_URL:-}}"
log(){ "$ROOT/bin/codex_log.sh" --cat distribution --stage carrier:probe --status "$1" --endpoint "$2" --http "$3" --feed_url "$4" --reason "$5"; }

probe(){
  local name="$1" url="$2"
  if [ -n "$url" ]; then
    code=$(curl -s -o /dev/null -w '%{http_code}' -I "$url" || echo 000)
    case "$code" in 2*|3*) log ok "$name" "$code" "$url" "" ;; *) log error "$name" "$code" "$url" "http_$code" ;; esac
  else
    log skip "$name" "" "" "missing_url"
  fi
}
probe "deezer"  "$DEEZER_URL"
probe "iheart"  "$IHEART_URL"
probe "tunein"  "$TUNEIN_URL"
