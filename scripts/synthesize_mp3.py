import os, requests
from pathlib import Path
API=os.getenv("ELEVEN_API_KEY")
VOICE=os.getenv("ELEVEN_VOICE_ID") or "EXAVITQu4vr4xnSDxMaL"
outdir=Path("public/audio"); outdir.mkdir(parents=True, exist_ok=True)
text=Path("work/episode.txt").read_text(encoding="utf-8")
def eleven(t):
    url=f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE}"
    hdr={"xi-api-key":API,"accept":"audio/mpeg","content-type":"application/json"}
    data={"text":t,"model_id":"eleven_multilingual_v2",
          "voice_settings":{"stability":0.30,"similarity_boost":0.80,"use_speaker_boost":True}}
    r=requests.post(url,headers=hdr,json=data,timeout=180)
    if r.status_code==200:
        (outdir/"book0_story_premise_raw.mp3").write_bytes(r.content); return True
    return False
ok=False
if API:
    try: ok=eleven(text)
    except Exception: ok=False
if not ok:
    from gtts import gTTS
    gTTS(text).save(str(outdir/"book0_story_premise_raw.mp3"))
print("[tts] public/audio/book0_story_premise_raw.mp3")
