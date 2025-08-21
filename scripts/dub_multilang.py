import os
from pathlib import Path
langs=[l.strip() for l in os.getenv("LANG_CODES","").split(",") if l.strip()]
if not langs: 
    print("[i18n] LANG_CODES not set; skipping"); raise SystemExit(0)
from gtts import gTTS
indir=Path("work/i18n"); indir.mkdir(parents=True, exist_ok=True)
outdir=Path("public/audio"); outdir.mkdir(parents=True, exist_ok=True)
for lg in langs:
    p=indir/f"episode_{lg}.txt"
    if not p.exists(): 
        print("[i18n] missing translated text for", lg); continue
    text=p.read_text(encoding="utf-8")[:4500]  # keep safe length for single call
    out=outdir/f"book0_story_premise_{lg}.mp3"
    gTTS(text=text, lang=lg).save(str(out))
    print("[i18n] dub:", out)
