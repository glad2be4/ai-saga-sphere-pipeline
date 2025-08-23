#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
. "$(dirname "$0")/codex_env.sh"

note "== 0) Tooling =="
pkg update -y >/dev/null 2>&1 || true
pkg install -y git jq curl ffmpeg sox rclone termux-api >/dev/null 2>&1 || true
# GitHub CLI is optional; if present we'll enable Pages via CLI
pkg install -y gh >/dev/null 2>&1 || true || true

note "== 1) Repo =="
mkdir -p "$(dirname "$REPO_DIR")"
if [ ! -d "$REPO_DIR/.git" ]; then
  note "Cloning repo: https://github.com/${GH_USER}/${REPO}.git"
  git clone "https://github.com/${GH_USER}/${REPO}.git" "$REPO_DIR"
else
  note "Repo exists; pulling latest"
  git -C "$REPO_DIR" pull --ff-only
fi

# Git essentials
git -C "$REPO_DIR" config user.name "AI Saga Sphere"
git -C "$REPO_DIR" config user.email "no-reply@users.noreply.github.com"

note "== 2) Minimal feed.xml (if missing) =="
if [ ! -f "$REPO_DIR/feed.xml" ]; then
  DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  cat >"$REPO_DIR/feed.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>AI Saga Sphere Pipeline</title>
  <updated>${DATE}</updated>
  <id>https://${GH_USER}.github.io/${REPO}/feed.xml</id>
  <entry>
    <title>Codex Bootstrap</title>
    <updated>${DATE}</updated>
    <id>tag:ai-saga-sphere,bootstrap</id>
  </entry>
</feed>
XML
  git -C "$REPO_DIR" add feed.xml
  git -C "$REPO_DIR" commit -m "Bootstrap: add minimal feed.xml" || true
  git -C "$REPO_DIR" push origin main || true
else
  note "feed.xml present"
fi

note "== 3) Enable GitHub Pages (optional) =="
if command -v gh >/dev/null 2>&1; then
  # Try enabling Pages from / (root) of repo, branch main
  gh repo edit "${GH_USER}/${REPO}" --enable-pages --source main --branch main || true
else
  note "gh CLI not present; ensure Pages is enabled in GitHub UI for ${GH_USER}/${REPO} (root / branch main)"
fi

note "Bootstrap complete."
