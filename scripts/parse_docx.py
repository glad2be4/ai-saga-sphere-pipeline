import os, re
from pathlib import Path
SRC_DOCX=Path("source/Book0_Codex.docx")
SRC_TXT =Path("source/book0_story_premise.txt")
SSML=Path("work/ssml"); SEG=Path("work/segments"); SSML.mkdir(parents=True,exist_ok=True); SEG.mkdir(parents=True,exist_ok=True)
def ssmlize(t): 
    t=t.strip().replace("—",'<break time="220ms"/> ').replace(",",' ,<break time="120ms"/> ')
    t=re.sub(r"\.\s*",'.<break time="260ms"/> ',t); return f'<speak><p><break time="200ms"/>{t}</p></speak>'
def from_txt(p):
    text="\n".join([l for l in p.read_text(encoding="utf-8").splitlines() if not l.startswith("#")]).strip()
    (SEG/"Book0_Premise.txt").write_text(text,encoding="utf-8")
    (SSML/"Book0_Premise.ssml").write_text(ssmlize(text),encoding="utf-8")
def from_docx(p):
    import docx
    d=docx.Document(str(p)); buf=[]; idx=1; chapter="Prologue"
    def flush():
        nonlocal buf,idx,chapter
        if not buf: return
        t="\n".join(buf).strip()
        (SEG/f"Book0_{idx:02d}_{chapter}.txt").write_text(t,encoding="utf-8")
        (SSML/f"Book0_{idx:02d}_{chapter}.ssml").write_text(ssmlize(t),encoding="utf-8")
        buf.clear(); idx+=1
    for para in d.paragraphs:
        t=para.text.strip()
        if not t: continue
        if re.match(r"^(Prologue|Epilogue|Chapter|Book)\b",t,re.I): flush(); chapter=re.sub(r"\W+","_",t)[:40]; continue
        buf.append(t)
    flush()
try:
    if SRC_DOCX.exists(): from_docx(SRC_DOCX)
    else: from_txt(SRC_TXT)
    print("[parse] OK -> work/ssml")
except Exception as e:
    print("[parse] fallback TXT:",e); from_txt(SRC_TXT)
