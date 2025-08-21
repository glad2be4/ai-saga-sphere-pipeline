"""
synthesize.py — Codex-grade narrator
------------------------------------
• Accepts: optional --docx path (default: source/Book0_Codex.docx), --txt fallback
• Parses headings (Prologue/Chapter/Epilogue/Book), or falls back to story premise TXT
• Segments text (~1.6k chars) with punctuation-aware splitting
• TTS: ElevenLabs primary (requires ELEVEN_API_KEY), auto-fallback to gTTS
• Outputs:
  - work/ssml/*.ssml
  - work/tts/*.mp3
  - logs/segments.jsonl (trace for recovery/transparency)
"""
import os, re, json, hashlib, requests, argparse, math
from pathlib import Path

P = Path
ROOT = P(".")
SRC_DOCX = ROOT / "source" / "Book0_Codex.docx"
SRC_TXT  = ROOT / "source" / "book0_story_premise.txt"
OUT_SSML = ROOT / "work" / "ssml"; OUT_SSML.mkdir(parents=True, exist_ok=True)
OUT_TTS  = ROOT / "work" / "tts";  OUT_TTS.mkdir(parents=True, exist_ok=True)
LOGS     = ROOT / "logs"; LOGS.mkdir(exist_ok=True)

API = os.getenv("ELEVEN_API_KEY")
VOICE_ID = os.getenv("ELEVEN_VOICE_ID")  # optional explicit

def read_docx(path:P)->str:
    import docx
    d = docx.Document(str(path))
    paras = []
    for p in d.paragraphs:
        t = p.text.strip()
        if t:
            paras.append(t)
    return "\n".join(paras)

def read_txt(path:P)->str:
    lines = [ln for ln in path.read_text(encoding="utf-8").splitlines() if not ln.startswith("#")]
    return "\n".join(lines).strip()

def extract_text(args)->str:
    if args.docx and P(args.docx).exists():
        return read_docx(P(args.docx))
    if SRC_DOCX.exists():
        try:
            return read_docx(SRC_DOCX)
        except Exception as e:
            print("[parse] docx parse failed, fallback:", e)
    return read_txt(SRC_TXT if not args.txt else P(args.txt))

def split_sentences(text:str)->list[str]:
    # Keep punctuation; prefer splitting on '.?!' followed by space
    raw = re.split(r'(?<=[\.?!])\s+', text)
    # Clean & strip
    return [s.strip() for s in raw if s.strip()]

def chunk(sentences:list[str], limit:int=1600)->list[str]:
    chunks, buf = [], ""
    for s in sentences:
        if len(buf)+len(s)+1 > limit and buf:
            chunks.append(buf.strip()); buf = s
        else:
            buf += (" " if buf else "") + s
    if buf: chunks.append(buf.strip())
    return chunks

def ssmlize(txt:str)->str:
    t = (txt.replace("—", '<break time="220ms"/> ')
           .replace(",", ',<break time="120ms"/> '))
    t = re.sub(r"\.\s*", '.<break time="260ms"/> ', t)
    return f"<speak><p><break time='200ms'/>{t}</p></speak>"

def ensure_voice_id()->str:
    if VOICE_ID: return VOICE_ID
    try:
        r = requests.get("https://api.elevenlabs.io/v1/voices", headers={"xi-api-key": API}, timeout=30)
        if r.ok and r.json().get("voices"):
            return r.json()["voices"][0]["voice_id"]
    except Exception:
        pass
    # Public sample ID from docs (will work for tests; replace if you have a specific voice)
    return "EXAVITQu4vr4xnSDxMaL"

def tts_eleven(text:str, out:P)->bool:
    voice = ensure_voice_id()
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice}"
    hdr = {"xi-api-key": API, "accept": "audio/mpeg", "content-type": "application/json"}
    data = {"text": text, "model_id": "eleven_multilingual_v2",
            "voice_settings": {"stability":0.30,"similarity_boost":0.80,"use_speaker_boost":True}}
    for _ in range(5):
        try:
            r = requests.post(url, headers=hdr, json=data, timeout=60)
            if r.status_code == 200:
                out.write_bytes(r.content); return True
        except Exception:
            pass
    return False

def tts_gtts(text:str, out:P)->bool:
    try:
        from gtts import gTTS
        gTTS(text).save(str(out)); return True
    except Exception as e:
        print("[gtts] fail:", e); return False

def narrate_segment(i:int, txt:str)->P:
    key = hashlib.sha1(txt.encode()).hexdigest()[:12]
    mp3 = OUT_TTS / f"seg_{i:03d}_{key}.mp3"
    if mp3.exists(): return mp3
    ok = False
    if API: ok = tts_eleven(txt, mp3)
    if not ok: ok = tts_gtts(txt, mp3)
    if not ok: raise RuntimeError(f"TTS failed for seg {i}")
    return mp3

def main():
    import argparse, time
    ap = argparse.ArgumentParser()
    ap.add_argument("--docx", help="Path to DOCX (optional)")
    ap.add_argument("--txt",  help="Path to TXT (fallback, optional)")
    args = ap.parse_args()

    text = extract_text(args)
    sentences = split_sentences(text)
    segments  = chunk(sentences, limit=1600)

    # logs for transparency
    with (LOGS/"segments.jsonl").open("w", encoding="utf-8") as lw:
        for i, seg in enumerate(segments, 1):
            ssml = ssmlize(seg)
            (OUT_SSML/f"seg_{i:03d}.ssml").write_text(ssml, encoding="utf-8")
            mp3 = narrate_segment(i, seg)
            lw.write(json.dumps({"idx": i, "mp3": str(mp3), "chars": len(seg)})+"\n")
            print(f"[ok] seg {i:03d} -> {mp3.name}")

if __name__ == "__main__":
    main()
