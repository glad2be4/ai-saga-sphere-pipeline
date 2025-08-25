#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_HTML="$ROOT/public/index.html"
JSON_REL="logs/compliance_report.json"

# Ensure index exists (don’t fabricate content)
[ -s "$HOME_HTML" ] || { echo "[inject_home_compliance] no index.html; skipping"; exit 0; }

# Remove previous block (if present)
perl -0777 -pe 's/<!-- CODEX:COMPLIANCE START -->.*?<!-- CODEX:COMPLIANCE END -->//s' -i "$HOME_HTML"

read -r -d '' BLOCK <<'HTML'
<!-- CODEX:COMPLIANCE START -->
<style>
.codex-chip { display:inline-flex; gap:.5rem; align-items:center; padding:.2rem .55rem; border-radius:999px; border:1px solid #ccc; font:12px/1.4 system-ui; margin:.35rem 0 .75rem }
.codex-dot { width:8px; height:8px; border-radius:50% }
</style>
<div id="codex-chip" class="codex-chip"><span class="codex-dot" style="background:#6e7781"></span><span>status: unknown</span></div>
<script>
(async()=>{
  try{
    const r = await fetch("/<?=JSON_REL?>",{cache:"no-store"});
    if(!r.ok){ return; }
    const c = await r.json();
    const el = document.getElementById("codex-chip"); if(!el) return;
    let color="#6e7781", text="status: unknown";
    if(typeof c.pass==="boolean"){
      if(c.pass){ color="#2ea043"; text="release‑ready"; }
      else { color="#cf222e"; text="not release‑ready"; }
    } else if(c && Array.isArray(c.reasons) && c.reasons.includes("skip_ok")) {
      color="#d4a72c"; text="release‑pending";
    }
    el.querySelector(".codex-dot").style.background=color;
    el.querySelector("span:nth-child(2)").textContent=text;
    el.style.borderColor=color+"80";
  }catch(e){ /* silent */ }
})();
</script>
<!-- CODEX:COMPLIANCE END -->
HTML

# Insert after first <h1>…</h1>, else append to end
if grep -qi '</h1>' "$HOME_HTML"; then
  awk -v block="$BLOCK" '
    BEGIN{done=0}
    { print; if(!done && /<\/h1>/){ print block; done=1 } }
  ' "$HOME_HTML" > "$HOME_HTML.tmp" && mv "$HOME_HTML.tmp" "$HOME_HTML"
else
  printf '\n%s\n' "$BLOCK" >> "$HOME_HTML"
fi
echo "[inject_home_compliance] updated $HOME_HTML"
