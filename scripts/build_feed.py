import os, subprocess, datetime
from pathlib import Path
AUDIO=Path("public/audio"); AUDIO.mkdir(parents=True,exist_ok=True)
FEED=Path("public/feed.xml"); masters=sorted(Path("work/masters").glob("*.wav"))
def mp3(src:Path)->Path:
    dst=AUDIO/f"{src.stem}.mp3"
    if not dst.exists():
        subprocess.check_call(["ffmpeg","-y","-i",str(src),"-c:a","libmp3lame","-b:a","128k",str(dst)],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return dst
items=[]
for w in masters:
    m=mp3(w); size=m.stat().st_size
    dur=subprocess.check_output(["ffprobe","-v","error","-show_entries","format=duration","-of","default=nw=1:nk=1",str(m)]).decode().strip().split('.')[0]
    items.append((m.name,size,dur))
base=os.getenv("FEED_URL","").rsplit("/",1)[0] if os.getenv("FEED_URL") else ""
feed=['<?xml version="1.0" encoding="UTF-8"?>','<rss version="2.0">',' <channel>',
      '  <title>AI SAGA SPHERE</title>', f'  <link>{os.getenv("FEED_URL","")}</link>',
      '  <description>Codex‑sealed, AI‑only narrated audiobook continuum.</description>']
for name,size,dur in items:
    feed+=['  <item>',f'    <title>{name}</title>',
           f'    <enclosure url="{base}/audio/{name}" type="audio/mpeg" length="{size}"/>',
           f'    <itunes:duration>{dur}</itunes:duration>',
           f'    <pubDate>{datetime.datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S +0000")}</pubDate>',
           '  </item>']
feed+=[' </channel>','</rss>']
FEED.write_text("\n".join(feed),encoding="utf-8")
print("[feed] ->", FEED)
