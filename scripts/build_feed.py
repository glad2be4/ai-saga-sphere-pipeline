import os, subprocess, datetime, json
from pathlib import Path
AUDIO_OUT=Path("public/audio"); AUDIO_OUT.mkdir(parents=True, exist_ok=True)
FEED=Path("public/feed.xml"); masters=sorted(Path("work/masters").glob("*.wav"))
def transcode(src:Path)->Path:
    dst=AUDIO_OUT/f"{src.stem}.mp3"
    if not dst.exists():
        subprocess.check_call(["ffmpeg","-y","-i",str(src),"-c:a","libmp3lame","-b:a","128k",str(dst)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return dst
items=[]
for wav in masters:
    mp3=transcode(wav)
    size=mp3.stat().st_size
    dur=subprocess.check_output(["ffprobe","-v","error","-show_entries","format=duration","-of","default=nw=1:nk=1", str(mp3)]).decode().strip().split('.')[0]
    items.append((mp3.name,size,dur))
feed=f'''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
 <channel>
  <title>AI SAGA SPHERE</title>
  <link>FEED_URL</link>
  <description>Codex‑sealed, AI‑only narrated audiobook continuum.</description>
'''
for name,size,dur in items:
    feed+=f'''
  <item>
    <title>{name}</title>
    <enclosure url="FEED_BASE/audio/{name}" type="audio/mpeg" length="{size}"/>
    <itunes:duration>{dur}</itunes:duration>
    <pubDate>{datetime.datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S +0000')}</pubDate>
  </item>'''
feed+='\n </channel>\n</rss>\n'
FEED.write_text(feed, encoding="utf-8")
print("[feed] ->", FEED)
