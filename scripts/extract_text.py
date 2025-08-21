import re
from pathlib import Path
docx_path = Path("source/Book0_Codex.docx")
txt_path  = Path("source/book0_story_premise.txt")
def from_docx(p):
    import docx
    d = docx.Document(str(p))
    return "\n".join([x.text.strip() for x in d.paragraphs if x.text.strip()])
def from_txt(p):
    return "\n".join([l for l in p.read_text(encoding="utf-8").splitlines() if not l.startswith("#")]).strip()
text = from_docx(docx_path) if docx_path.exists() else from_txt(txt_path)
Path("work").mkdir(exist_ok=True)
Path("work/episode.txt").write_text(text, encoding="utf-8")
print("[extract] work/episode.txt")
