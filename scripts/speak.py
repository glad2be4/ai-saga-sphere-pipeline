import os, re, hashlib, requests
from pathlib import Path
SSML=Path("work/ssml"); TTS=Path("work/tts"); TTS.mkdir(parents=True,exist_ok=True)
API=os.getenv("ELEVEN_API_KEY"); VOICE_ID=os.getenv("ELEVEN_VOICE_ID")
def plain(s): return re.sub(r'<[^>]+>','',re.sub(r'<break time="(\d+)ms"/>',lambda m:' ' if int(m.group(1))<300 else '\n',s))
def pick_voice():
    if VOICE_ID: return VOICE_ID
    try:
        r=requests.get("https://api.elevenlabs.io/v1/voices",headers={"xi-api-key":API},timeout=30)
        if r.ok and r.json().get("voices"): return r.json()["voices"][0]["voice_id"]
    except Exception: pass
    return "EXAVITQu4vr4xnSDxMaL"  # public sample
def el(text,out):
    url=f"https://api.elevenlabs.io/v1/text-to-speech/{pick_voice()}"
    hdr={"xi-api-key":API,"accept":"audio/mpeg","content-type":"application/json"}
    data={"text":text,"model_id":"eleven_multilingual_v2","voice_settings":{"stability":0.30,"similarity_boost":0.80,"use_speaker_boost":True}}
    for _ in range(5):
        try:
            r=requests.post(url,headers=hdr,json=data,timeout=60)
            if r.status_code==200: out.write_bytes(r.content); return True
        except Exception: pass
    return False
def gtts(text,out):
    from gtts import gTTS; gTTS(text).save(str(out)); return True
for f in sorted(SSML.glob("*.ssml")):
    txt=plain(f.read_text(encoding="utf-8"))
    key=hashlib.sha1(txt.encode()).hexdigest()[:12]
    out=TTS/f"{f.stem}_{key}.mp3"
    if out.exists(): print("[skip]", out.name); continue
    ok=False
    if API: ok=el(txt,out)
    if not ok:
        try: ok=gtts(txt,out)
        except Exception as e: print("[gtts] fail",e)
    print("[ok]" if ok else "[fail]", out.name)
print("[speak] ->", TTS)
