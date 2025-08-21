import os, email.utils
from pathlib import Path
root=Path("public"); audio=root/"audio"; audio.mkdir(parents=True,exist_ok=True)
feed=root/"feed.xml"; base=os.getenv("FEED_URL","").rsplit("/",1)[0] if os.getenv("FEED_URL") else ""
items=[]
for p in sorted(audio.glob("*.mp3")):
    items.append((p.name,p.stat().st_size,email.utils.formatdate(usegmt=True)))
xml=['<?xml version="1.0" encoding="UTF-8"?>',
     '<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">',' <channel>',
     '  <title>AI SAGA SPHERE</title>', f'  <link>{os.getenv("FEED_URL","")}</link>',
     '  <language>en</language>','  <itunes:author>AI Saga Sphere</itunes:author>',
     '  <itunes:category text="Fiction"/>',
     '  <description>Codex‑sealed, AI‑only narrated audiobook continuum.</description>']
for name,size,pub in items:
    xml+=['  <item>',f'    <title>{name.replace("_"," ")}</title>',
          f'    <enclosure url="{base}/audio/{name}" length="{size}" type="audio/mpeg"/>',
          f'    <pubDate>{pub}</pubDate>','    <itunes:explicit>no</itunes:explicit>','  </item>']
xml+=[' </channel>','</rss>']; feed.write_text("\n".join(xml),encoding="utf-8"); print("[feed] public/feed.xml")
