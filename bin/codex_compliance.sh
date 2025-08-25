#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${OUT:-$ROOT/outputs}"; mkdir -p "$OUT"
REPORT="$OUT/compliance_report.json"

# ---- Tunables (Codex defaults; override via env) ----
LUFS_MIN="${LUFS_MIN:--18.0}"   # pass window
LUFS_MAX="${LUFS_MAX:--14.0}"
TP_MAX="${TP_MAX:--1.0}"
LRA_MIN="${LRA_MIN:-5.0}"
LRA_MAX="${LRA_MAX:-14.0}"
PROBE_MAX_AGE_H="${PROBE_MAX_AGE_H:-24}"      # feed probe freshness
REQUIRE_NOTARIZATION="${REQUIRE_NOTARIZATION:-false}"  # true/false

# ---- Locate latest kit manifest (must exist) ----
KIT_DIR="${KIT_DIR:-$(ls -1dt "$ROOT/recovery_kits"/*/ 2>/dev/null | head -n1 || true)}"
[ -n "$KIT_DIR" ] || { jq -n '{pass:false, reason:["no_recovery_kit"]}' > "$REPORT"; echo "[gate] fail: no kit"; exit 1; }

MAN="$KIT_DIR/codex_manifest.json"
[ -s "$MAN" ] || { jq -n --arg kit "$(basename "$KIT_DIR")" '{pass:false, reason:["missing_manifest"], kit:$kit}' > "$REPORT"; echo "[gate] fail: missing manifest"; exit 1; }

# ---- Extract QC metrics (must be numeric to check) ----
LUFS="$(jq -r '.audio_qc.ebu_r128.integrated_lufs // empty' "$MAN" 2>/dev/null || true)"
TP="$(jq -r '.audio_qc.ebu_r128.true_peak_dbTP // empty' "$MAN" 2>/dev/null || true)"
LRA="$(jq -r '.audio_qc.ebu_r128.loudness_range_lu // empty' "$MAN" 2>/dev/null || true)"
isnum(){ awk 'BEGIN{exit !(ARGV[1] ~ /^-?[0-9]+(\.[0-9]+)?$/)}' "$1"; }

reasons=()
ok_qc=false
if isnum "${LUFS:-x}" && isnum "${TP:-x}" && isnum "${LRA:-x}"; then
  awk -v L="$LUFS" -v T="$TP" -v R="$LRA" \
      -v LMIN="$LUFS_MIN" -v LMAX="$LUFS_MAX" -v TMAX="$TP_MAX" -v RMIN="$LRA_MIN" -v RMAX="$LRA_MAX" \
      'BEGIN{exit ! (L>=LMIN && L<=LMAX && T<=TMAX && R>=RMIN && R<=RMAX)}' \
   && ok_qc=true || reasons+=("qc_out_of_bounds")
else
  reasons+=("qc_metrics_missing")
fi

# ---- Feed probe: require 200 within PROBE_MAX_AGE_H ----
PROBE="$ROOT/logs/distribution/pages_probe.jsonl"
ok_feed=false
if [ -s "$PROBE" ]; then
  last="$(tail -n 1 "$PROBE")"
  code="$(printf '%s' "$last" | jq -r '.http // empty' 2>/dev/null || true)"
  ts="$(printf '%s' "$last" | jq -r '.ts // empty' 2>/dev/null || true)"
  if [ -n "$code" ] && [ -n "$ts" ]; then
    # age check
    age_h="$(
      printf '%s\n' "$ts" | awk -v now="$(date -u +%s)" '
        { gsub("Z","",$1); gsub("T"," ",$1);
          cmd="date -u -d \""$1"\" +%s"; cmd | getline t; close(cmd);
          if (t>0) printf "%.1f", (now-t)/3600; else print 1e9 }'
    )"
    if [ "$code" = "200" ] && awk -v a="$age_h" -v m="$PROBE_MAX_AGE_H" 'BEGIN{exit !(a<=m)}'; then ok_feed=true; else reasons+=("feed_probe_bad_or_stale"); fi
  else
    reasons+=("feed_probe_incomplete")
  fi
else
  reasons+=("feed_probe_missing")
fi

# ---- Notarization (optional) ----
ok_note=true
if [ "$REQUIRE_NOTARIZATION" = "true" ]; then
  CID="${CID:-}"
  [ -z "$CID" ] && [ -s "$KIT_DIR/cid.txt" ] && CID="$(tr -d '[:space:]' < "$KIT_DIR/cid.txt")"
  [ -z "$CID" ] && [ -s "$KIT_DIR/storacha.json" ] && CID="$(jq -r '.cid // empty' "$KIT_DIR/storacha.json" 2>/dev/null || true)"
  if [ -z "$CID" ]; then ok_note=false; reasons+=("notarization_missing"); fi
fi

# ---- Verdict ----
pass=false
if $ok_qc && $ok_feed && $ok_note; then pass=true; fi

jq -n \
  --arg kit "$(basename "$KIT_DIR")" \
  --argjson pass "$pass" \
  --arg lufs "${LUFS:-}" --arg tp "${TP:-}" --arg lra "${LRA:-}" \
  --argjson limits "$(jq -nc --arg lmin "$LUFS_MIN" --arg lmax "$LUFS_MAX" --arg tmax "$TP_MAX" --arg rmin "$LRA_MIN" --arg rmax "$LRA_MAX" \
    '{lufs_min:($lmin|tonumber), lufs_max:($lmax|tonumber), tp_max:($tmax|tonumber), lra_min:($rmin|tonumber), lra_max:($rmax|tonumber)}')" \
  --argjson require_notarization "$REQUIRE_NOTARIZATION" \
  --arg feed_age_h "${age_h:-}" --arg feed_code "${code:-}" --arg feed_ts "${ts:-}" \
  --argjson reasons "$(printf '%s\n' "${reasons[@]:-}" | jq -R . | jq -s .)" \
'{
  kit:$kit, pass:$pass,
  qc:{metrics:{lufs:($lufs|tonumber?), tp:($tp|tonumber?), lra:($lra|tonumber?)}, limits:$limits},
  feed:{http:($feed_code|tonumber?), ts:$feed_ts, age_h:($feed_age_h|tonumber?)},
  notarization:{required:$require_notarization},
  reasons:$reasons,
  ts:"'"$(date -u +%FT%TZ)"'"
}' > "$REPORT"

echo "[gate] $(jq -r '.pass' "$REPORT") → $REPORT"
$pass && exit 0 || exit 1
