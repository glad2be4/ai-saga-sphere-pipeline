import os, re, json, hashlib, requests, subprocess
from pathlib import Path

SSML_DIR=Path("work/ssml"); OUT_DIR=Path("work/tts_cache"); OUT_DIR.mkdir(parents=True, exist_ok=True)
API=os.environ.get("ELEVEN_API_KEY")
VOICE="G2B-Narrative-Warm"; MODEL="eleven_multilingual_v2"

def plain(ssml:str)->str:
    s=re.sub(r'<break time="(\d+)ms"/>', lambda m: ' ' if int(m.group(1))<300 else '\n', ssml)
    return re.sub(r'<[^>]+>','',s)

def el_synth(text:str,out:Path)->bool:
    url=f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE}"
    hdr={"xi-api-key":API,"accept":"audio/mpeg","content-type":"application/json"}
    data={"text":text,"model_id":MODEL,"voice_settings":{"stability":0.30,"similarity_boost":0.80,"use_speaker_boost":True}}
    for i in range(6):
        r=requests.post(url,headers=hdr,json=data,timeout=60)
        if r.status_code==200:
            out.write_bytes(r.content); return True
    return False

def gtts_synth(text:str,out:Path)->bool:
    try:
        from gtts import gTTS
        gTTS(text).save(str(out)); return True
    except Exception as e:
        print("[gtts] fail:",e); return False

for f in sorted(SSML_DIR.glob("*.ssml")):
    txt=plain(f.read_text(encoding="utf-8"))
    key=hashlib.sha1((txt+VOICE+MODEL).encode()).hexdigest()[:16]
    out=OUT_DIR/f"{f.stem}_{key}.mp3"
    if out.exists(): 
        print("[skip]", out.name); continue
    ok=False
    if API: ok=el_synth(txt,out)
    if not ok: ok=gtts_synth(txt,out)
    print("[ok]" if ok else "[fail]", out.name)
