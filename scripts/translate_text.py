import os, sys
from pathlib import Path
langs=[l.strip() for l in os.getenv("LANG_CODES","").split(",") if l.strip()]
if not langs: 
    print("[i18n] LANG_CODES not set; skipping"); sys.exit(0)
from argostranslate import translate
src=Path("work/episode.txt").read_text(encoding="utf-8")
outdir=Path("work/i18n"); outdir.mkdir(parents=True, exist_ok=True)
for lg in langs:
    try:
        text=translate.translate(src,"en",lg)
        (outdir/f"episode_{lg}.txt").write_text(text,encoding="utf-8")
        print("[i18n] translated:", lg)
    except Exception as e:
        print("[i18n] failed", lg, e)
