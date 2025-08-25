#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
file="${1:-logs/distribution/distribution.jsonl}"
echo "== Last 20 distribution events =="
tail -n 20 "$file" | jq -r '[.ts,.stage,.endpoint,.status, (.http//""), (.reason//"")]|@tsv'
echo; echo "== Summary by endpoint/status =="
jq -r 'group_by(.endpoint)[] | {e:.[0].endpoint, s:(group_by(.status)|map({k:.[0].status, n:length})|from_entries)} | [.e,(.s.ok//0),(.s.skip//0),(.s.error//0)]|@tsv' "$file"
