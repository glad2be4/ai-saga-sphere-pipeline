import os, re, sys
from pathlib import Path

SRC_DOCX = Path("source/Book0_Codex.docx")
SRC_TXT  = Path("source/book0_story_premise.txt")
SSML_DIR = Path("work/ssml"); SSML_DIR.mkdir(parents=True, exist_ok=True)
SEG_DIR  = Path("work/segments"); SEG_DIR.mkdir(parents=True, exist_ok=True)

def ssmlize(txt:str)->str:
    t = (txt.strip()
            .replace("—", '<break time="220ms"/> ')
            .replace(","," ,<break time=\"120ms\"/> "))
    t = re.sub(r"\.\s*", ".<break time=\"260ms\"/> ", t)
    return f"<speak><p><break time=\"200ms\"/>{t}</p></speak>"

def from_txt(p:Path):
    raw = p.read_text(encoding="utf-8")
    body = "\n".join([ln for ln in raw.splitlines() if not ln.startswith("#")]).strip()
    (SEG_DIR/"Book0_Premise.txt").write_text(body, encoding="utf-8")
    (SSML_DIR/"Book0_Premise.ssml").write_text(ssmlize(body), encoding="utf-8")

def from_docx(p:Path):
    import docx
    d = docx.Document(str(p))
    chapter, buf, idx = "Prologue", [], 1
    def flush():
        nonlocal buf, idx, chapter
        if not buf: return
        text = "\n".join(buf).strip()
        (SEG_DIR/f"Book0_{idx:02d}_{chapter}.txt").write_text(text, encoding="utf-8")
        (SSML_DIR/f"Book0_{idx:02d}_{chapter}.ssml").write_text(ssmlize(text), encoding="utf-8")
        buf.clear(); idx += 1
    for para in d.paragraphs:
        t = para.text.strip()
        if not t: continue
        m = re.match(r"^(Chapter|Book|Prologue|Epilogue)\b.*", t, re.I)
        if m: flush(); chapter = re.sub(r"\W+","_",t)[:40]; continue
        buf.append(t)
    flush()

if SRC_DOCX.exists():
    try: from_docx(SRC_DOCX)
    except Exception as e:
        print("[parse] docx failed, fallback to TXT", e); from_txt(SRC_TXT)
else:
    from_txt(SRC_TXT)
print("[parse] segments ->", SEG_DIR, "ssml ->", SSML_DIR)
