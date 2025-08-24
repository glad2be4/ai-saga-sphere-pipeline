# (autonomic) pre-sync
./codex_git_sync.sh main || true
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
: "${GH_USER:?GH_USER required}"

echo "== Codex Verify (Spine + Mirror + Pipeline + Recovery) =="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${FEED_URL:-https://${GH_USER}.github.io/ai-saga-sphere-pipeline/feed.xml}" || true)
if [ "$HTTP_CODE" != "200" ]; then
  echo "✖ Feed not 200 OK"
else
  echo "✓ Feed OK"
fi

mkdir -p outputs
printf '{"run":"%s","ts":"%s","checklist":"%s"}\n' \
  "$(date -u +%Y%m%d_%H%M%S)" "$(date -u +%FT%TZ)" \
  "$( [ "$HTTP_CODE" = "200" ] && echo ok || echo missing )" \
  > "outputs/qc_report_$(date -u +%Y%m%d_%H%M%S).json"

# (autonomic) post-sync publish
git add -A || true
git commit -m "codex: autopublish $(date -u +%Y%m%d_%H%M%S)" || true
./codex_git_sync.sh main || true
