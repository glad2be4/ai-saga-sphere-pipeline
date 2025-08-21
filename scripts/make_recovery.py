import os, json, hashlib, time, subprocess, tarfile
from pathlib import Path

ROOT = Path(".")
OUTD = ROOT/"recovery"; OUTD.mkdir(parents=True, exist_ok=True)
GIT_SHA = subprocess.check_output(["git","rev-parse","--short","HEAD"]).decode().strip()
TS = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
FEED_URL = os.getenv("FEED_URL","")
MAN = {
  "codex_version": "1.0",
  "ts_utc": TS,
  "git_commit": GIT_SHA,
  "feed_url": FEED_URL,
  "ipfs_cid": (ROOT/"public/ipfs.txt").read_text().strip() if (ROOT/"public/ipfs.txt").exists() else "",
  "ipns_name": (ROOT/"public/ipns.txt").read_text().strip() if (ROOT/"public/ipns.txt").exists() else "",
  "files": []
}

def add_file(relpath):
    p = ROOT/relpath
    if not p.exists(): return
    h = hashlib.sha256(p.read_bytes()).hexdigest()
    MAN["files"].append({"path": relpath.replace("\\","/"), "sha256": h, "bytes": p.stat().st_size})

# include canonical artifacts (extend freely)
INCLUDE = [
  "source/Book0_Codex.docx",
  "AISagaSphere_64Book_Contextualization.docx",
  "Autonomic_Protocol_Bundle.docx",
  "AI_SagaSphere_Final_Codex.docx",
  "public/feed.xml",
  "public/audio",
  "public/captions",
  "public/art/cover.png",
  "public/benchmarks/audio_bench.json",
  "voices.json",
  ".github/workflows/codex_publish.yml"
]

for item in INCLUDE:
    p = ROOT/item
    if p.is_dir():
        for f in p.rglob("*"):
            if f.is_file(): add_file(str(f.relative_to(ROOT)))
    else:
        add_file(item)

# write manifest
manifest_path = OUTD/f"RECOVERY_MANIFEST_{TS}_{GIT_SHA}.json"
manifest_path.write_text(json.dumps(MAN, indent=2))
# tarball (uncompressed tar first for reproducible hashing)
tar_name = OUTD/f"recovery_{TS}_{GIT_SHA}.tar"
with tarfile.open(tar_name, "w") as tar:
    for f in MAN["files"]:
        tar.add(f["path"], arcname=f["path"])
    tar.add(manifest_path, arcname=manifest_path.name)

# produce sha256 of tar
sha = hashlib.sha256(tar_name.read_bytes()).hexdigest()
(Path(str(tar_name)+".sha256")).write_text(f"{sha}  {tar_name.name}\n")
print("[recovery] built:", tar_name)
