#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ======= derive env & paths =======
GH_USER="${GH_USER:-glad2be4}"
REPO="${REPO:-ai-saga-sphere-pipeline}"
BRANCH="${BRANCH:-main}"
ROOT="${ROOT:-$HOME/repo/$REPO}"

PUBLIC_DIR="${PUBLIC_DIR:-public}"
FEED_FILE="${FEED_FILE:-feed.xml}"
AUDIO_OUT="${AUDIO_OUT:-public/audio}"
OUTPUTS_DIR="${OUTPUTS_DIR:-outputs}"
QC_DIR="${QC_DIR:-public/qc}"
PLOTS_DIR="${PLOTS_DIR:-public/qc/plots}"
FP_DIR="${FP_DIR:-public/fp}"
RECOVERY_DIR="${RECOVERY_DIR:-recovery}"
DELIV="${DELIV:-deliverables}"

TARGET_LUFS="${TARGET_LUFS:- -16}"
LUFS_TOL="${LUFS_TOL:-1}"
TP_MAX="${TP_MAX:- -1}"
LRA_MIN="${LRA_MIN:-6}"
LRA_MAX="${LRA_MAX:-12}"

ONEDRIVE_REMOTE="${ONEDRIVE_REMOTE:-onedrive}"
IPFS_BIN="${IPFS_BIN:-}"
IPNS_KEY="${IPNS_KEY:-codex}"

PODCASTINDEX_KEY="${PODCASTINDEX_KEY:-}"
PODCASTINDEX_SECRET="${PODCASTINDEX_SECRET:-}"
WEBSUB_HUB="${WEBSUB_HUB:-}"

eok(){ printf "\033[1;32m%s\033[0m\n" "$*"; }
ewarn(){ printf "\033[1;33m%s\033[0m\n" "$*"; }
efail(){ printf "\033[1;31m%s\033[0m\n" "$*"; }

cd "$ROOT"
git fetch origin "$BRANCH" -q || true
git checkout "$BRANCH" -q || true
git pull --ff-only -q || true

mkdir -p "$PUBLIC_DIR" "$AUDIO_OUT" "$OUTPUTS_DIR" "$QC_DIR" "$PLOTS_DIR" "$FP_DIR" "$RECOVERY_DIR" "$DELIV"

# --- 1) Feed + Pages seed ---
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
if [ ! -s "$FEED_FILE" ]; then
  cat > "$FEED_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>AI Saga Sphere Pipeline</title>
  <updated>${NOW}</updated>
  <id>https://${GH_USER}.github.io/${REPO}/feed.xml</id>
</feed>
EOF
fi
[ -f .nojekyll ] || : > .nojekyll
[ -s index.html ] || printf '<!doctype html><meta http-equiv="refresh" content="0;url=./%s">' "$FEED_FILE" > index.html
git add -A; git diff --cached --quiet || { git commit -m "Codex: ensure Pages seed"; git push -q; }

# --- 2) Pages enable & wait 200 ---
FEED_URL="https://${GH_USER}.github.io/${REPO}/$FEED_FILE"
gh repo edit "$GH_USER/$REPO" --enable-pages --source "$BRANCH" --branch "$BRANCH" --cname "" >/dev/null 2>&1 || true
gh api -X POST "repos/$GH_USER/$REPO/pages/builds" >/dev/null 2>&1 || true
ok=0; for i in $(seq 1 30); do code="$(curl -s -o /dev/null -w '%{http_code}' "$FEED_URL" || true)"; echo "Pages try $i/30 → $code"; [ "$code" = "200" ] && { ok=1; break; }; sleep 10; done
[ $ok -eq 1 ] && eok "Feed OK (200)" || ewarn "Feed not 200 yet (continuing)."

# --- 3) Ingest outputs → public/audio (idempotent) ---
ingested=0
find "$OUTPUTS_DIR" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.ogg' -o -iname '*.opus' -o -iname '*.wav' \) -print0 2>/dev/null | \
while IFS= read -r -d '' f; do
  bn="$(basename "$f")"
  if [ ! -f "$AUDIO_OUT/$bn" ]; then
    cp -f "$f" "$AUDIO_OUT/$bn"; git add "$AUDIO_OUT/$bn"; ingested=1; echo "  + ingested $bn"
  fi
done
[ $ingested -eq 1 ] && { git commit -m "Codex: ingest public audio"; git push -q; }

# --- 4) QC + Benchmark + fingerprints + plots + feed annotations ---
qc_added=0
for f in "$AUDIO_OUT"/*; do
  [ -f "$f" ] || continue
  bn="$(basename "$f")"; qcfile="$QC_DIR/${bn}.json"
  dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" | awk '{printf "%.2f",$1+0}')" || dur=0
  br="$(ffprobe -v error -show_entries format=bit_rate -of csv=p=0 "$f" || echo 0)"
  stats="$(ffmpeg -hide_banner -nostats -v error -i "$f" -af loudnorm=I=${TARGET_LUFS}:TP=${TP_MAX}:LRA=$(( (LRA_MIN+LRA_MAX)/2 )):print_format=json -f null - 2>&1 || true)"
  I="$(echo "$stats" | jq -r '.input_i // empty')" ; TP="$(echo "$stats"| jq -r '.input_tp // empty')" ; LRA="$(echo "$stats"| jq -r '.input_lra // empty')"
  pass=1; notes=()
  awk -v v="$I" -v t="$TARGET_LUFS" -v tol="$LUFS_TOL" 'BEGIN{exit !((v>=t-tol)&&(v<=t+tol))}' || { pass=0; notes+=("LUFS"); }
  awk -v m="$TP" -v lim="$TP_MAX" 'BEGIN{exit !(m<=lim)}' || { pass=0; notes+=("TP"); }
  awk -v l="$LRA" -v lo="$LRA_MIN" -v hi="$LRA_MAX" 'BEGIN{exit !((l>=lo)&&(l<=hi))}' || { pass=0; notes+=("LRA"); }
  jq -n --arg file "$bn" --argjson dur "$dur" --argjson br "$br" \
        --arg I "${I:-null}" --arg TP "${TP:-null}" --arg LRA "${LRA:-null}" \
        --argjson pass "$pass" --arg notes "$(IFS=,; echo "${notes[*]-}")" \
        '{
          file:$file,
          duration_s:$dur|tonumber,
          bitrate_bps:$br|tonumber,
          loudness:{I_LUFS:($I|tonumber?), TP_dBTP:($TP|tonumber?), LRA:($LRA|tonumber?)},
          pass:$pass, notes:$notes
        }' > "$qcfile"
  qc_added=1
  # fingerprint (optional)
  if command -v fpcalc >/dev/null 2>&1; then fpcalc "$f" > "$FP_DIR/${bn}.fp.txt" 2>/dev/null || true; fi
  # plots (waveform + spectrogram)
  ffmpeg -hide_banner -nostats -y -i "$f" -filter_complex "showwavespic=s=1200x300:split_channels=0" "$PLOTS_DIR/${bn}.wave.png"  >/dev/null 2>&1 || true
  ffmpeg -hide_banner -nostats -y -i "$f" -lavfi "showspectrumpic=s=1200x300:legend=disabled:mode=combined" "$PLOTS_DIR/${bn}.spec.png" >/dev/null 2>&1 || true
  # feed entry (only once)
  if ! grep -Fq "$bn" "$FEED_FILE"; then
    UPDATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    URL="https://${GH_USER}.github.io/${REPO}/${AUDIO_OUT#${PUBLIC_DIR}/}/$bn"
    WAVE_URL="https://${GH_USER}.github.io/${REPO}/${PLOTS_DIR#${PUBLIC_DIR}/}/${bn}.wave.png"
    SPEC_URL="https://${GH_USER}.github.io/${REPO}/${PLOTS_DIR#${PUBLIC_DIR}/}/${bn}.spec.png"
    GUID="tag:${REPO},${bn}"
    awk -v entry="$(cat <<EOT
  <entry>
    <title>${bn}</title>
    <updated>${UPDATED}</updated>
    <id>${GUID}</id>
    <link href="${URL}"/>
    <content type="text">QC: I=${I:-?} LUFS, TP=${TP:-?} dBTP, LRA=${LRA:-?} (pass=${pass})
Waveform: ${WAVE_URL}
Spectrogram: ${SPEC_URL}
    </content>
  </entry>
EOT
)" '
/<\/feed>/ && !printed { print entry; printed=1 }{ print }
' "$FEED_FILE" > "$FEED_FILE.new" && mv "$FEED_FILE.new" "$FEED_FILE"
  fi
done
[ $qc_added -eq 1 ] && { jq -s '.' "$QC_DIR"/*.json > "$QC_DIR/index.json"; git add "$QC_DIR" "$FP_DIR" "$PLOTS_DIR" "$FEED_FILE"; git commit -m "Codex: QC+plots + feed annotations"; git push -q; }

# --- 7) PodcastIndex + WebSub (optional) ---
FEED_URL="https://${GH_USER}.github.io/${REPO}/$FEED_FILE"
if [ -n "${PODCASTINDEX_KEY}" ] && [ -n "${PODCASTINDEX_SECRET}" ]; then
  TS=$(date +%s)
  curl -s -G "https://api.podcastindex.org/api/1.0/add/byfeedurl" \
    --data-urlencode "url=$FEED_URL" -H "X-Auth-Date: $TS" \
    -H "X-Auth-Key: $PODCASTINDEX_KEY" -H "Authorization: $PODCASTINDEX_SECRET" \
    -H "User-Agent: AISagaSphere/1.0" >/dev/null 2>&1 || true
  eok "PodcastIndex notified."
fi
if [ -n "${WEBSUB_HUB}" ]; then
  curl -s -d "hub.mode=publish" -d "hub.url=$FEED_URL" "$WEBSUB_HUB" >/dev/null 2>&1 || true
  eok "WebSub hub pinged."
fi

# --- 8) Recovery Kit (with lineage) ---
STAMP="$(date -u +%Y%m%d_%H%M%S)"
KIT="$RECOVERY_DIR/recovery_$STAMP.tar"
prev="$(ls -1t "$RECOVERY_DIR"/RECOVERY_MANIFEST_*.json 2>/dev/null | head -1 || true)"
prev_sha=""; [ -n "$prev" ] && prev_sha="$(jq -r '.sha256 // empty' "$prev" 2>/dev/null || true)"
tar -cf "$KIT" "$FEED_FILE" "$PUBLIC_DIR" "$OUTPUTS_DIR" "$QC_DIR" "$FP_DIR" .nojekyll index.html 2>/dev/null || true
sha256sum "$KIT" | awk '{print $1}' > "${KIT}.sha256"
jq -n --arg kit "$(basename "$KIT")" --arg sha "$(cat "${KIT}.sha256")" --arg ts "$STAMP" --arg url "$FEED_URL" --arg prev "$prev_sha" \
  '{kit:$kit, sha256:$sha, ts_utc:$ts, feed_url:$url, prev_sha:$prev}' > "$RECOVERY_DIR/RECOVERY_MANIFEST_$STAMP.json"
git add "$RECOVERY_DIR"/*.json "$RECOVERY_DIR"/*.sha256 || true
git commit -m "Codex: Recovery Kit $STAMP (lineage)" || true
git push -q || true
eok "Recovery Kit created."

# --- 9) Mirrors (rclone OneDrive; IPFS+IPNS if present) ---
if rclone listremotes 2>/dev/null | grep -q "^${ONEDRIVE_REMOTE}:"; then
  DEST="${ONEDRIVE_REMOTE}:AI_Saga_Sphere/${STAMP}"
  rclone copy "$RECOVERY_DIR" "$DEST/recovery" --fast-list --create-empty-src-dirs || true
  rclone copy "$PUBLIC_DIR"   "$DEST/public"   --fast-list --create-empty-src-dirs || true
  eok "OneDrive mirror OK → $DEST"
else
  ewarn "rclone '${ONEDRIVE_REMOTE}:' not configured (skip)."
fi
if [ -n "$IPFS_BIN" ] && command -v "$IPFS_BIN" >/dev/null 2>&1; then
  CID="$($IPFS_BIN add -Qr "$PUBLIC_DIR" 2>/dev/null || true)"
  if [ -n "$CID" ]; then
    echo "$CID" > "$PUBLIC_DIR/ipfs.txt"; git add "$PUBLIC_DIR/ipfs.txt"
    $IPFS_BIN key list -l | grep -q " $IPNS_KEY$" || $IPFS_BIN key gen --type=ed25519 "$IPNS_KEY" >/dev/null 2>&1 || true
    $IPFS_BIN name publish --key="$IPNS_KEY" "/ipfs/$CID" >/dev/null 2>&1 || true
    $IPFS_BIN key list -l | awk -v k="$IPNS_KEY" '$2==k{print $1}' > "$PUBLIC_DIR/ipns.txt"; git add "$PUBLIC_DIR/ipns.txt"
    git commit -m "Codex: record IPFS/IPNS pointers ($STAMP)" || true
    git push -q || true
    eok "IPFS CID=$CID (IPNS recorded)"
  else
    ewarn "ipfs add failed (skip IPNS)."
  fi
fi

# --- 10) Retailer packages (ACX / Findaway / Google Play) ---
mkdir -p "$DELIV"/{acx,findaway,google}
rsync -a --delete "$AUDIO_OUT"/ "$DELIV/acx/"      >/dev/null 2>&1 || true
rsync -a --delete "$AUDIO_OUT"/ "$DELIV/findaway/" >/dev/null 2>&1 || true
rsync -a --delete "$AUDIO_OUT"/ "$DELIV/google/"   >/dev/null 2>&1 || true
[ -f $PUBLIC_DIR/cover.jpg ] && cp -f $PUBLIC_DIR/cover.jpg "$DELIV/acx/cover.jpg" || true
[ -f $PUBLIC_DIR/cover.jpg ] && cp -f $PUBLIC_DIR/cover.jpg "$DELIV/findaway/cover.jpg" || true
[ -f $PUBLIC_DIR/cover.jpg ] && cp -f $PUBLIC_DIR/cover.jpg "$DELIV/google/cover.jpg" || true
echo "field,value" > "$DELIV/acx/ACX_manifest.csv"; echo "Feed,$FEED_URL" >> "$DELIV/acx/ACX_manifest.csv"
printf '<ONIXMessage/>\n' > "$DELIV/findaway/ONIX.xml"
echo "title,feed_url" > "$DELIV/google/google_metadata.csv"; echo "\"AI Saga Sphere\",\"$FEED_URL\"" >> "$DELIV/google/google_metadata.csv"
zip -qr "$DELIV/acx_package.zip" "$DELIV/acx" || true
zip -qr "$DELIV/findaway_package.zip" "$DELIV/findaway" || true
zip -qr "$DELIV/google_package.zip" "$DELIV/google" || true
eok "Retailer packages updated."
