#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
GH_USER="${GH_USER:-$(gh api user -q .login)}"
REPO="${REPO:-ai-saga-sphere-pipeline}"
REPO_DIR="$HOME/repo/$REPO"
OUTDIR="${REPO_DIR}/recovery"
FEED_URL="https://${GH_USER}.github.io/${REPO}/feed.xml"

mkdir -p "$OUTDIR"
cd "$REPO_DIR"

STAMP="$(date -u +%Y%m%d_%H%M%S)"
TAR="recovery_${STAMP}.tar"
TGZ="${TAR}.gz"
MAN="${OUTDIR}/RECOVERY_MANIFEST_${STAMP}.json"

# include Pages spine + workflow indicators
tar -cf "$OUTDIR/$TAR" \
  .nojekyll index.html feed.xml \
  .github/workflows/pages.yml 2>/dev/null || true

gzip -f "$OUTDIR/$TAR"

# hashes
sha256sum "$OUTDIR/$TGZ" | awk '{print $1}' > "${OUTDIR}/${TGZ}.sha256"

# manifest
cat > "$MAN" <<JSON
{
  "gh_user": "${GH_USER}",
  "repo": "${REPO}",
  "feed_url": "${FEED_URL}",
  "artifact": "$(basename "$TGZ")",
  "sha256": "$(cat "${OUTDIR}/${TGZ}.sha256")",
  "generated_utc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "codex": {
    "spine": "feed.xml",
    "mirror": "GitHub Pages",
    "pipeline": "pages.yml",
    "recovery": "this manifest + tarball"
  }
}
JSON

echo "== Recovery Kit =="
ls -lh "$OUTDIR/$TGZ" "${OUTDIR}/${TGZ}.sha256" "$MAN"

echo "Tip: mirror this directory to OneDrive and Storacha/IPFS to satisfy multi-mirror redundancy."
