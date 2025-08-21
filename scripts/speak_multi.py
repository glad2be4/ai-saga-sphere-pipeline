import os, re, json, hashlib, requests
from pathlib import Path
API=os.getenv("ELEVEN_API_KEY")
ROOT=Path("."); OUT=ROOT/"work/tts_segments"; OUT.mkdir(parents=True,exist_ok=True)
TEXT=(ROOT/"work/episode.txt").read_text(encoding="utf-8")
VOICES={"NARRATOR":os.getenv("ELEVEN_VOICE_NARRATOR") or "EXAVITQu4vr4xnSDxMaL"}
def chunks(t):
    L=[]; 
    for raw in t.splitlines():
        s=raw.strip()
        if not s: continue
        m=re.match(r"^([A-Za-z0-9_ ]+)\s*:\s*(.+)$", s)
        L.append((m.group(1).strip(),m.group(2).strip()) if m else ("NARRATOR", s))
    return L
def tts_el(txt, voice, out):
    url=f"https://api.elevenlabs.io/v1/text-to-speech/{voice}"
    hdr={"xi-api-key":API,"accept":"audio/mpeg","content-type":"application/json"}
    data={"text":txt,"model_id":"eleven_multilingual_v2","voice_settings":{"stability":0.30,"similarity_boost":0.80,"use_speaker_boost":True}}
    try:
        r=requests.post(url,headers=hdr,json=data,timeout=180)
        if r.status_code==200: out.write_bytes(r.content); return True
    except Exception: pass
    return False
def tts_gtts(txt,out):
    from gtts import gTTS; gTTS(txt).save(str(out)); return True
order=[]
for i,(sp,line) in enumerate(chunks(TEXT),1):
    key=hashlib.sha1(f"{sp}|{line}".encode()).hexdigest()[:8]
    f=OUT/f"{i:04d}_{sp}_{key}.mp3"
    if not f.exists():
        ok=False
        if API: ok=tts_el(line, VOICES.get(sp, VOICES["NARRATOR"]), f)
        if not ok: tts_gtts(line, f)
    order.append(str(f))
(Path("work/segments_order.txt")).write_text("\n".join(order))
print("[tts] segments:", len(order))
