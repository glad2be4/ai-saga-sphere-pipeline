#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
IN_WAV="${1:?input wav required}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TS="$(date -u +%Y%m%d_%H%M%S)"
OUT_MP3="$ROOT/work/master_$TS.mp3"
QC_DIR="$ROOT/public/qc"
mkdir -p "$QC_DIR"

# two-pass loudnorm (stats then apply)
AN="$(ffmpeg -hide_banner -nostats -i "$IN_WAV" -filter_complex loudnorm=I=-16:TP=-1.0:LRA=11:print_format=json -f null - 2>&1 || true)"
I=$(echo "$AN" | jq -r '.input_i' 2>/dev/null || echo "")
TP=$(echo "$AN" | jq -r '.input_tp' 2>/dev/null || echo "")
LRA=$(echo "$AN" | jq -r '.input_lra' 2>/dev/null || echo "")
TH=$(echo "$AN" | jq -r '.input_thresh' 2>/dev/null || echo "")

if [ -n "$I" ] && [ -n "$TP" ] && [ -n "$LRA" ] && [ -n "$TH" ]; then
  ffmpeg -hide_banner -nostats -y -i "$IN_WAV" \
    -af "loudnorm=I=-16:TP=-1.0:LRA=11:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$TH:print_format=summary" \
    -ar 44100 -ac 2 -b:a 160k "$OUT_MP3"
else
  ffmpeg -hide_banner -nostats -y -i "$IN_WAV" \
    -af "loudnorm=I=-16:TP=-1.0:LRA=11" -ar 44100 -ac 2 -b:a 160k "$OUT_MP3"
fi

# Metrics (EBU R128, SoX) + visuals
EBU_LOG="$QC_DIR/ebu_${TS}.txt"
ffmpeg -hide_banner -nostats -i "$OUT_MP3" -filter_complex ebur128=peak=true -f null - 2> "$EBU_LOG" || true
INT_LUFS="$(awk '/Integrated loudness/{print $(NF-1)}' "$EBU_LOG" | head -1)"
TRUE_PEAK="$(awk '/True peak:/{print $(NF-1)}' "$EBU_LOG" | head -1)"
LRA_LU="$(awk '/Loudness range/{print $(NF-1)}' "$EBU_LOG" | head -1)"

SOX_LOG="$QC_DIR/sox_${TS}.txt"
sox "$OUT_MP3" -n stat 2> "$SOX_LOG" || true
RMS_DB="$(awk '/RMS.*amplitude/{amp=$NF; printf("%.2f",20*log(amp)/log(10))}' "$SOX_LOG")"
CREST="$(awk '/Crest factor/{print $3}' "$SOX_LOG")"

ffmpeg -hide_banner -y -i "$OUT_MP3" -filter_complex "aformat=channel_layouts=mono,showwavespic=s=1200x240" -frames:v 1 "$QC_DIR/wave_${TS}.png" >/dev/null 2>&1 || true
sox "$OUT_MP3" -n spectrogram -o "$QC_DIR/spec_${TS}.png" >/dev/null 2>&1 || true

jq -nc \
  --arg ts "$TS" --arg mp3 "$OUT_MP3" \
  --arg lufs "${INT_LUFS:-}" --arg tp "${TRUE_PEAK:-}" --arg lra "${LRA_LU:-}" \
  --arg rms "${RMS_DB:-}" --arg crest "${CREST:-}" \
  '{ts:$ts, file:$mp3, ebu_r128:{integrated_lufs:$lufs, true_peak_dbTP:$tp, loudness_range_lu:$lra}, sox:{rms_db:$rms, crest_db:$crest}}' \
  > "$QC_DIR/metrics_${TS}.json"

echo "$OUT_MP3"
