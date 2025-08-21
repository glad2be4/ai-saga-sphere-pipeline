import os, re, hashlib, requests, sys
from pathlib import Path

SRC_DOCX=Path("source/Book0_Codex.docx")
SRC_TXT =Path("source/book0_story_premise.txt")
OUT_DIR =Path("work/tts"); OUT_DIR.mkdir(parents=True, exist_ok=True)
TMP_DIR =Path("work/tmp"); TMP_DIR.mkdir(parents=True, exist_ok=True)

API=os.getenv("ELEVEN_API_KEY"); VOICE_ID=os.getenv("ELEVEN_VOICE_ID")  # optional override

def load_text():
    if SRC_DOCX.exists():
        try:
            import docx
            d=docx.Document(str(SRC_DOCX))
            text="\n".join([p.text for p in d.paragraphs])
            if text.strip(): return text
        except Exception as e:
            print("[speak] DOCX parse failed, fallback TXT:",e)
    return "\n".join([ln for ln in SRC_TXT.read_text(encoding="utf-8").splitlines() if not ln.startswith("#")]).strip()

def chunk_sentences(t, limit=1800):
    parts, buf = [], ""
    for s in re.split(r'(?<=[\.\?!])\s+', t):
        if len(buf)+len(s)+1>limit and buf: parts.append(buf.strip()); buf=s
        else: buf+=(" " if buf else "")+s
    if buf: parts.append(buf.strip())
    return parts

def eleven_voice():
    if VOICE_ID: return VOICE_ID
    try:
        r=requests.get("https://api.elevenlabs.io/v1/voices", headers={"xi-api-key":API}, timeout=30)
        if r.ok and r.json().get("voices"): return r.json()["voices"][0]["voice_id"]
    except Exception: pass
    # fallback to a well-known public voice id used in docs (may vary)
    return "EXAVITQu4vr4xnSDxMaL"

def tts_eleven(text, out):
    vid=eleven_voice()
    url=f"https://api.elevenlabs.io/v1/text-to-speech/{vid}"
    hdr={"xi-api-key":API,"accept":"audio/mpeg","content-type":"application/json"}
    data={"text":text,"model_id":"eleven_multilingual_v2","voice_settings":{"stability":0.30,"similarity_boost":0.80,"use_speaker_boost":True}}
    for i in range(6):
        try:
            r=requests.post(url, headers=hdr, json=data, timeout=60)
            if r.status_code==200: out.write_bytes(r.content); return True
        except Exception: pass
    return False

def tts_gtts(text, out):
    from gtts import gTTS
    gTTS(text).save(str(out)); return True

text=load_text()
for i, seg in enumerate(chunk_sentences(text), 1):
    key=hashlib.sha1(seg.encode()).hexdigest()[:12]
    out=OUT_DIR/f"book0_{i:02d}_{key}.mp3"
    if out.exists(): print("[skip]", out.name); continue
    ok=False
    if API: 
        print("[eleven] synth", out.name); ok=tts_eleven(seg, out)
    if not ok:
        print("[gtts] synth", out.name); ok=tts_gtts(seg, out)
    print("[ok]" if ok else "[fail]", out.name)
print("[speak] done:", OUT_DIR)
