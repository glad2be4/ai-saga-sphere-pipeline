#!/data/data/com.termux/files/usr/bin/bash
# Usage: log_captions.sh <lang1>:<file1> [<lang2>:<file2> ...]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
subs="[]"
for pair in "$@"; do
  lang="${pair%%:*}"; file="${pair#*:}"
  [ -s "$file" ] || { echo "✘ missing caption: $file"; exit 2; }
  sha=$(sha256sum "$file" | awk '{print $1}')
  subs="$(jq -nc --argjson a "$subs" --arg lang "$lang" --arg file "$file" --arg sha "$sha" \
    '$a + [ {lang:$lang,file:$file,sha256:$sha} ]' )"
done
metrics="$(jq -nc --argjson subs "$subs" '{subs:$subs}')"
"$ROOT/bin/codex_log.sh" --cat accessibility --stage captions --status ok --metrics "$metrics"
