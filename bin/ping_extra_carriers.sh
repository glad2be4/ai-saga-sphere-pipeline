#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
deezer="${DEEZER_URL:-${VAR_DEEZER_URL:-}}"
iheart="${IHEART_URL:-${VAR_IHEART_URL:-}}"
tunein="${TUNEIN_URL:-${VAR_TUNEIN_URL:-}}"

ping_one(){
  local name="$1" url="$2"
  if [ -n "$url" ]; then
    code="$(curl -s -o /dev/null -w '%{http_code}' -I "$url" || echo 000)"
    case "$code" in
      2*|3*) bin/codex_log.sh --cat distribution --stage carrier:probe --status ok    --endpoint "$name" --feed_url "$url" --http "$code" ;;
      *)     bin/codex_log.sh --cat distribution --stage carrier:probe --status error --endpoint "$name" --feed_url "$url" --http "$code" --reason "http_$code" ;;
    esac
  else
    bin/codex_log.sh --cat distribution --stage carrier:probe --status skip --endpoint "$name" --reason "missing_url"
  fi
}

ping_one "deezer"  "$deezer"
ping_one "iheart"  "$iheart"
ping_one "tunein"  "$tunein"
