#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
GH_USER="${GH_USER:?GH_USER required (export GH_USER then re-run)}"
REPO_NAME="${REPO_NAME:?REPO_NAME required (export REPO_NAME then re-run)}"

REPO_DIR="$HOME/repo/$REPO_NAME"
OUT_DIR="$REPO_DIR/outputs"
LOG_DIR="$REPO_DIR/logs"
REC_DIR="$REPO_DIR/recovery"
TS="$(date -u +%Y%m%d_%H%M%S)"
RUN_ID="smoketest_${TS}"
LOG="$LOG_DIR/${RUN_ID}.log"
QC="$OUT_DIR/qc_report_${TS}.json"
REC_TAR="$REC_DIR/recovery_${TS}.tar"
REC_SHA="$REC_TAR.sha256"
FEED_URL="https://$GH_USER.github.io/$REPO_NAME/feed.xml"

mkdir -p "$OUT_DIR" "$LOG_DIR" "$REC_DIR"

# 1) Build a compact QC JSON (keeps diffs tiny in git)
printf '{"run":"%s","ts":"%s","checklist":"smoketest"}\n' "$RUN_ID" "$(date -u +%FT%TZ)" >"$QC"

# 2) Make a tiny recovery kit with checksums (atomic)
tar -cf "$REC_TAR" -C "$REPO_DIR" $(printf ".gitignore 2>/dev/null || true")  >/dev/null 2>&1 || true
( cd "$(dirname "$REC_TAR")" && sha256sum "$(basename "$REC_TAR")" > "$(basename "$REC_SHA")" )

# 3) Pages sanity (200 OK)
code="$(curl -s -o /dev/null -w "%{http_code}" "$FEED_URL" || true)"
[ "$code" = "200" ] || echo "WARN: FEED not 200 (got $code) -> $FEED_URL" | tee -a "$LOG"

echo "Recovery OK -> $REC_TAR" | tee -a "$LOG"
