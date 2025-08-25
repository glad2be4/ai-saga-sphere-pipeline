#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_HTML="$ROOT/public/index.html"
BADGE_REL="recovery/badge.svg"
INDEX_REL="recovery/index.html"

mkdir -p "$(dirname "$HOME_HTML")"
[ -s "$HOME_HTML" ] || cat > "$HOME_HTML" <<'HTML'
<!doctype html><meta charset="utf-8">
<title>AI Saga Sphere</title>
<h1>AI Saga Sphere</h1>
HTML

# Remove previous block if present
perl -0777 -pe 's/<!-- CODEX:BADGE START -->.*?<!-- CODEX:BADGE END -->//s' -i "$HOME_HTML"

# Append fresh block to the end of <h1> section (or document end if not found)
BLOCK="$(cat <<HTML
<!-- CODEX:BADGE START -->
<style>
.codex-badge { display:inline-flex; align-items:center; gap:.5rem; margin:.5rem 0 1rem }
.codex-badge a { text-decoration:none; font:14px system-ui; color:#0366d6 }
</style>
<div class="codex-badge">
  <img src="${BADGE_REL}" alt="audio QC badge" height="20">
  <a href="${INDEX_REL}">Recovery Kits</a>
</div>
<!-- CODEX:BADGE END -->
HTML
)"

# If <h1> exists, insert after first </h1>, else append at end
if grep -qi '</h1>' "$HOME_HTML"; then
  awk -v block="$BLOCK" '
    BEGIN{done=0}
    {print}
    !done && /<\/h1>/ {print block; done=1}
  ' "$HOME_HTML" > "$HOME_HTML.tmp" && mv "$HOME_HTML.tmp" "$HOME_HTML"
else
  printf '\n%s\n' "$BLOCK" >> "$HOME_HTML"
fi
echo "[inject_home_badge] updated $HOME_HTML"
