from pathlib import Path
def from_docx(p):
    import docx; d=docx.Document(str(p))
    return "\n".join([x.text.strip() for x in d.paragraphs if x.text.strip()])
def from_txt(p):
    return "\n".join([l for l in p.read_text(encoding="utf-8").splitlines() if not l.startswith("#")]).strip()
docx=Path("source/Book0_Codex.docx"); txt=Path("source/book0_story_premise.txt")
text=from_docx(docx) if docx.exists() else from_txt(txt)
Path("work").mkdir(exist_ok=True); Path("work/episode.txt").write_text(text,encoding="utf-8")
print("[extract] work/episode.txt")
