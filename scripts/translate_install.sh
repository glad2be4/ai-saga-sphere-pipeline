#!/usr/bin/env bash
set -euo pipefail
pip install --quiet "argostranslate==1.9.0" >/dev/null 2>&1 || true
python - <<'PY'
import os, sys, argostranslate.package, argostranslate.translate
langs=os.getenv("LANG_CODES","").split(",")
langs=[l.strip() for l in langs if l.strip()]
if not langs: sys.exit(0)
# ensure English source in all pairs (en -> xx)
installed=argostranslate.package.get_installed_packages()
installed_codes={f"{p.from_code}:{p.to_code}" for p in installed}
available=argostranslate.package.get_available_packages()
for tgt in langs:
    pair=f"en:{tgt}"
    if pair in installed_codes: continue
    pkg = next((p for p in available if p.from_code=="en" and p.to_code==tgt), None)
    if pkg:
        dl_path=pkg.download()
        argostranslate.package.install_from_path(dl_path)
        print("[argos] installed", pair)
PY
