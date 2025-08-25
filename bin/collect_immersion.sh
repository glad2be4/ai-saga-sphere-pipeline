#!/data/data/com.termux/files/usr/bin/bash
# collect_immersion.sh <audio_file>
set -euo pipefail
audio="${1:?audio required}"
[ -s "$audio" ] || { echo "✘ missing audio: $audio"; exit 2; }

# ebur128 Summary block
readarray -t EBU < <(ffmpeg -hide_banner -nostats -i "$audio" -filter_complex ebur128 -f null - 2>&1 | awk '/Summary:/{flag=1;next}/^$/{flag=0}flag')
I="$(printf '%s\n' "${EBU[@]}" | awk '/I:/{print $2}')"
LRA="$(printf '%s\n' "${EBU[@]}" | awk '/LRA:/{print $2}')"
TP="$(printf '%s\n' "${EBU[@]}" | awk '/True peak:/{print $3}')"

# SoX stats
readarray -t S < <(sox "$audio" -n stat 2>&1 || true)
RMS="$(printf '%s\n' "${S[@]}" | awk -F':' '/RMS.*amplitude/{gsub(/^[ \t]+/,"",$2); print $2}' | tail -1)"
PEAK="$(printf '%s\n' "${S[@]}" | awk -F':' '/Maximum.*amplitude/{gsub(/^[ \t]+/,"",$2); print $2}')"
CREST="$(printf '%s\n' "${S[@]}" | awk -F':' '/Crest factor/{gsub(/^[ \t]+/,"",$2); print $2}')"

# Optional immersion context via env (real values only if you set them)
metrics="$(jq -nc \
  --arg lufs "${I:-}" --arg tp "${TP:-}" --arg lra "${LRA:-}" \
  --arg rms "${RMS:-}" --arg pk "${PEAK:-}" --arg crest "${CREST:-}" \
  --arg v "${VOICES:-}" --arg e "${EMOTIONS:-}" \
  --argjson pace "${PACE_WPM:-null}" --argjson duck "${DUCK_DB:-null}" --argjson sfx "${SFX_DB:-null}" '
  {
    lufs:($lufs|tonumber?),
    tp:($tp|tonumber?),
    lra:($lra|tonumber?),
    rms_amp:($rms|tonumber?),
    peak_amp:($pk|tonumber?),
    crest:($crest|tonumber?)
  }
  + ( $v|length>0 ? {voices:($v|split(",")|map(.|gsub("^ +| +$";"")))} : {} )
  + ( $e|length>0 ? {emotions:($e|split(",")|map(.|gsub("^ +| +$";"")))} : {} )
  + ( $pace|type=="number" ? {pace_wpm:$pace} : {} )
  + ( $duck|type=="number" ? {duck_db:$duck} : {} )
  + ( $sfx|type=="number"  ? {sfx_db:$sfx}   : {} )
')"
bin/codex_log.sh --cat immersion --stage metrics --status ok --file "$audio" --metrics "$metrics"
bin/codex_log.sh --cat qc        --stage ebu-r128 --status ok --file "$audio" --metrics "$(jq -nc --arg l "${I:-}" --arg t "${TP:-}" --arg r "${LRA:-}" '{lufs:($l|tonumber?),tp:($t|tonumber?),lra:($r|tonumber?)}')"
