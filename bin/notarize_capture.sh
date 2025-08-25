#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KIT="${KIT_DIR:-$ROOT/recovery_kits/latest}"
[ -d "$KIT" ] || { bin/codex_log.sh --cat notarization --stage capture --status skip --reason "no_latest_kit"; exit 0; }

CID="${CID:-}"; IPNS="${IPNS:-}"
[ -z "$CID" ]  && [ -s "$KIT/cid.txt" ]      && CID="$(tr -d '[:space:]' < "$KIT/cid.txt")"
[ -z "$IPNS" ] && [ -s "$KIT/ipns.txt" ]     && IPNS="$(tr -d '[:space:]' < "$KIT/ipns.txt")"
[ -z "$CID" ]  && [ -s "$KIT/storacha.json" ] && CID="$(jq -r '.cid // empty' "$KIT/storacha.json" 2>/dev/null || true)"
[ -z "$IPNS" ] && [ -s "$KIT/storacha.json" ] && IPNS="$(jq -r '.ipns // empty' "$KIT/storacha.json" 2>/dev/null || true)"

# Capture a representative hash if a tar exists
TAR="$(ls -1 "$KIT"/*.tar 2>/dev/null | head -n1 || true)"
HSH=""; [ -n "$TAR" ] && HSH="$(sha256sum "$TAR" | awk '{print $1}')"

if [ -n "$CID" ]; then
  bin/codex_log.sh --cat notarization --stage capture --status ok --cid "$CID" ${IPNS:+--ipns "$IPNS"} ${HSH:+--hash "$HSH"}
else
  bin/codex_log.sh --cat notarization --stage capture --status skip --reason "missing_cid" ${HSH:+--hash "$HSH"}
fi
