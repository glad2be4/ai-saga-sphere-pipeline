#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KITS_DIR="$ROOT/recovery_kits"
PUB_DIR="$ROOT/public/recovery"
JSON="$PUB_DIR/index.json"
HTML="$PUB_DIR/index.html"
BADGE="$PUB_DIR/badge.svg"

mkdir -p "$PUB_DIR"

# ---------- Thresholds (Codex Benchmark Sovereignty) ----------
PASS_LUFS_MIN=-18.0   # within broadcast/podcast sweet spot
PASS_LUFS_MAX=-14.0
PASS_TP_MAX=-1.0      # true peak ≤ -1.0 dBTP
PASS_LRA_MIN=5.0
PASS_LRA_MAX=14.0

AMBER_LUFS_MIN=-20.0  # acceptable drift (amber)
AMBER_LUFS_MAX=-12.0
AMBER_TP_MAX=-0.5
AMBER_LRA_MIN=3.0
AMBER_LRA_MAX=18.0

# ---------- Helpers ----------
normnum() { awk 'BEGIN{ORS="";} {if ($0 ~ /^-?[0-9]+(\.[0-9]+)?$/) print $0; else print "nan"}' <<<"${1:-}"; }
classify() {
  local lufs="$(normnum "$1")" tp="$(normnum "$2")" lra="$(normnum "$3")"

  # If any metric is missing => amber (incomplete)
  if [[ "$lufs" == "nan" || "$tp" == "nan" || "$lra" == "nan" ]]; then
    echo "amber"; return
  fi

  # PASS window
  awk -v L="$lufs" -v TP="$tp" -v LR="$lra" \
      -v LMIN="$PASS_LUFS_MIN" -v LMAX="$PASS_LUFS_MAX" \
      -v TPMAX="$PASS_TP_MAX" \
      -v LRMIN="$PASS_LRA_MIN" -v LRMAX="$PASS_LRA_MAX" \
      'BEGIN{ if (L>=LMIN && L<=LMAX && TP<=TPMAX && LR>=LRMIN && LR<=LRMAX) exit 0; else exit 1 }' \
      && { echo "green"; return; }

  # AMBER window
  awk -v L="$lufs" -v TP="$tp" -v LR="$lra" \
      -v LMIN="$AMBER_LUFS_MIN" -v LMAX="$AMBER_LUFS_MAX" \
      -v TPMAX="$AMBER_TP_MAX" \
      -v LRMIN="$AMBER_LRA_MIN" -v LRMAX="$AMBER_LRA_MAX" \
      'BEGIN{ if (L>=LMIN && L<=LMAX && TP<=TPMAX && LR>=LRMIN && LR<=LRMAX) exit 0; else exit 1 }' \
      && { echo "amber"; return; }

  echo "red"
}

badge_svg() {
  # $1 status; outputs an SVG badge
  local status="$1"
  local label="audio QC"
  local color
  case "$status" in
    green) color="#2ea043" ;;
    amber) color="#d4a72c" ;;
    red)   color="#cf222e" ;;
    *)     color="#6e7781" ;; # neutral
  esac
  cat <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="140" height="20" role="img" aria-label="${label}: ${status}">
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#fff" stop-opacity=".7"/>
    <stop offset=".1" stop-opacity=".1"/>
    <stop offset=".9" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".3"/>
  </linearGradient>
  <mask id="m"><rect width="140" height="20" rx="3" fill="#fff"/></mask>
  <g mask="url(#m)">
    <rect width="70" height="20" fill="#555"/>
    <rect x="70" width="70" height="20" fill="${color}"/>
    <rect width="140" height="20" fill="url(#s)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="35" y="14">audio QC</text>
    <text x="105" y="14">${status}</text>
  </g>
</svg>
SVG
}

# ---------- Collect kits ----------
mapfile -d '' kits < <(find "$KITS_DIR" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null | sort -z -r)

# ---------- JSON index ----------
printf '[\n' > "$JSON"
SEP=""
site_green=0; site_amber=0; site_red=0; total=0

for d in "${kits[@]}"; do
  rid="$(basename "$d")"
  man="$d/codex_manifest.json"
  lufs=""; tp=""; lra=""; ts=""

  if [ -s "$man" ]; then
    ts="$(jq -r '.ts // empty' "$man" 2>/dev/null || true)"
    lufs="$(jq -r '.audio_qc.ebu_r128.integrated_lufs // empty' "$man" 2>/dev/null || true)"
    tp="$(jq -r '.audio_qc.ebu_r128.true_peak_dbTP // empty' "$man" 2>/dev/null || true)"
    lra="$(jq -r '.audio_qc.ebu_r128.loudness_range_lu // empty' "$man" 2>/dev/null || true)"
  fi

  status="$(classify "$lufs" "$tp" "$lra")"
  case "$status" in
    green) ((site_green++));;
    amber) ((site_amber++));;
    red)   ((site_red++));;
  esac
  ((total++))

  printf '%s  {"run_id": %q, "ts": %q, "status": %q, "qc": {"integrated_lufs": %s, "true_peak_dbTP": %s, "lra_lu": %s}, "manifest": %q, "hashes": %q}\n' \
    "$SEP" "$rid" "$ts" "$status" \
    "$( [ -n "$lufs" ] && echo "$lufs" || echo "null")" \
    "$( [ -n "$tp" ]   && echo "$tp"   || echo "null")" \
    "$( [ -n "$lra" ]  && echo "$lra"  || echo "null")" \
    "$( [ -s "$man" ] && echo "recovery_kits/$rid/codex_manifest.json" || echo "" )" \
    "$( [ -s "$d/codex_hashes.sha256" ] && echo "recovery_kits/$rid/codex_hashes.sha256" || echo "" )" \
    >> "$JSON"
  SEP=","
done
printf ']\n' >> "$JSON"

# ---------- Site status (majority rule; tie → amber) ----------
site_status="neutral"
if [ "$total" -gt 0 ]; then
  if   [ "$site_green" -gt "$site_amber" ] && [ "$site_green" -gt "$site_red" ]; then site_status="green"
  elif [ "$site_red"   -gt "$site_green" ] && [ "$site_red"   -gt "$site_amber" ]; then site_status="red"
  else site_status="amber"
  fi
fi

# ---------- Badge SVG ----------
badge_svg "$site_status" > "$BADGE"

# ---------- HTML ----------
cat > "$HTML" <<HTML
<!doctype html><meta charset="utf-8">
<title>AI Saga Sphere – Recovery Kits</title>
<style>
 body{font:16px system-ui,Segoe UI,Roboto,Helvetica,Arial;margin:2rem;max-width:80ch}
 h1{display:flex;gap:.75rem;align-items:center}
 table{border-collapse:collapse;width:100%;margin-top:1rem}
 th,td{border-bottom:1px solid #e5e5e5;padding:.5rem;text-align:left;vertical-align:top}
 code{background:#111;color:#0f0;padding:.15rem .35rem;border-radius:.2rem}
 .muted{color:#666}
 .pill{font:12px/1.6 system-ui;background:#111;color:#fff;padding:.15rem .5rem;border-radius:999px}
 .pill.green{background:#2ea043}.pill.amber{background:#d4a72c}.pill.red{background:#cf222e}
</style>
<h1>Recovery Kits <img src="badge.svg" alt="audio QC badge" height="20"></h1>
<p class="muted">Newest first. JSON API: <a href="/recovery/index.json">/recovery/index.json</a></p>
<table>
  <thead><tr><th>Run ID</th><th>Timestamp</th><th>Status</th><th>QC (LUFS / TP / LRA)</th><th>Proof</th></tr></thead>
  <tbody>
HTML

for d in "${kits[@]}"; do
  rid="$(basename "$d")"
  man="$d/codex_manifest.json"
  ts="$(jq -r '.ts // empty' "$man" 2>/dev/null || true)"
  lufs="$(jq -r '.audio_qc.ebu_r128.integrated_lufs // empty' "$man" 2>/dev/null || true)"
  tp="$(jq -r '.audio_qc.ebu_r128.true_peak_dbTP // empty' "$man" 2>/dev/null || true)"
  lra="$(jq -r '.audio_qc.ebu_r128.loudness_range_lu // empty' "$man" 2>/dev/null || true)"
  status="$(classify "$lufs" "$tp" "$lra")"
  pill="<span class=\"pill $status\">$status</span>"

  man_rel="recovery_kits/$rid/codex_manifest.json"
  sha_rel="recovery_kits/$rid/codex_hashes.sha256"
  [ -s "$man" ] || man_rel=""
  [ -s "$d/codex_hashes.sha256" ] || sha_rel=""

  printf '  <tr><td><code>%s</code></td><td>%s</td><td>%s</td><td>%s / %s / %s</td><td>%s | %s</td></tr>\n' \
    "$rid" "${ts:-""}" "$pill" \
    "${lufs:-"-"}" "${tp:-"-"}" "${lra:-"-"}" \
    "$( [ -n "$man_rel" ] && echo "<a href=\"/$man_rel\">manifest</a>" || echo "<span class=\"muted\">(none)</span>" )" \
    "$( [ -n "$sha_rel" ] && echo "<a href=\"/$sha_rel\">sha256</a>"   || echo "<span class=\"muted\">(none)</span>" )" \
    >> "$HTML"
done

printf '</tbody></table>\n' >> "$HTML"
echo "<p class=\"muted\">Status rules: green = LUFS in [-18..-14], True Peak ≤ -1.0 dBTP, LRA in [5..14]; amber = near; red = out.</p>" >> "$HTML"

echo "kit-index: OK -> $PUB_DIR (status: $site_status)"
