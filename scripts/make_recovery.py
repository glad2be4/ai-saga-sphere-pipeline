import os, json, hashlib, time, tarfile, subprocess
from pathlib import Path
ROOT=Path("."); OUT=ROOT/"recovery"; OUT.mkdir(parents=True, exist_ok=True)
sha=lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
GIT_SHA=subprocess.check_output(["git","rev-parse","--short","HEAD"]).decode().strip()
TS=time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
FEED=os.getenv("FEED_URL","")
manifest={"ts":TS,"commit":GIT_SHA,"feed":FEED,"files":[]}
def add(p):
    P=ROOT/p
    if P.is_file(): manifest["files"].append({"path":str(p),"sha256":sha(P),"bytes":P.stat().st_size})
INCLUDE=["source/Book0_Codex.docx","public/feed.xml","public/audio","public/captions","public/art/cover.png",".github/workflows/codex_publish.yml"]
for item in INCLUDE:
    P=ROOT/item
    if P.is_dir():
        for f in P.rglob("*"):
            if f.is_file(): add(f)
    else: add(item)
man=OUT/f"RECOVERY_MANIFEST_{TS}_{GIT_SHA}.json"; man.write_text(json.dumps(manifest,indent=2))
tar=OUT/f"recovery_{TS}_{GIT_SHA}.tar"
with tarfile.open(tar,"w") as t:
    for f in manifest["files"]: t.add(f["path"], arcname=f["path"])
    t.add(man, arcname=man.name)
(Path(str(tar)+".sha256")).write_text(f"{sha(tar)}  {tar.name}\n")
print("[recovery] built", tar)
