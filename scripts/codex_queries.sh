#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
R="${1:-$PWD}"

echo "== LAST 5 KIT VERDICTS =="
[ -f "$R/logs/metrics/kit_verdict.jsonl" ] && tail -n 5 "$R/logs/metrics/kit_verdict.jsonl" | jq -r '[.ts,.run_id,.status,.lufs,.tp,.lra]|@tsv' || echo "(none)"

echo; echo "== FEED PROBES (last 10) =="
[ -f "$R/logs/distribution/pages_probe.jsonl" ] && tail -n 10 "$R/logs/distribution/pages_probe.jsonl" | jq -r '[.ts,.http,.feed_url]|@tsv' || echo "(none)"

echo; echo "== SKIP REASONS (last 10) =="
[ -f "$R/logs/distribution/kit_skip.jsonl" ] && tail -n 10 "$R/logs/distribution/kit_skip.jsonl" | jq -r '[.ts,.reason]|@tsv' || echo "(none)"

echo; echo "== BAD JSONL (quarantined) =="
ls -1 "$R/outputs"/jsonl_bad.txt "$R/outputs"/missing_required.jsonl 2>/dev/null || echo "(none)"
