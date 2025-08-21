import os, re, sys
from pathlib import Path
langs=[l.strip() for l in os.getenv("LANG_CODES","").split(",") if l.strip()]
if not langs: 
    print("[i18n] LANG_CODES not set; skipping"); sys.exit(0)
from argostranslate import translate
src=Path("public/captions/book0_story_premise.srt")
if not src.exists(): 
    print("[i18n] no English SRT; skipping"); sys.exit(0)
en=src.read_text(encoding="utf-8")
def trans_block(b,lg):
    parts=b.splitlines()
    if len(parts)>=3:
        text="\n".join(parts[2:])
        tt=translate.translate(text,"en",lg)
        return "\n".join(parts[:2]+[tt,""])
    return b
blocks=[b for b in en.split("\n\n") if b.strip()]
for lg in langs:
    out=Path("public/captions")/f"book0_story_premise.{lg}.srt"
    out.write_text("\n\n".join(trans_block(b,lg) for b in blocks), encoding="utf-8")
    print("[i18n] captions:", out)
