import os, pathlib, json, hashlib, time
root = pathlib.Path(__file__).resolve().parents[1]
src  = root/"source"
out  = root/"output"
out.mkdir(exist_ok=True)
# Fake TTS+mix for demo: just wrap text as "audio"
for p in src.glob("*.txt"):
    audio = (out / (p.stem + ".mp3"))
    audio.write_bytes(("FAKEAUDIO::" + p.read_text()).encode())
# Minimal feed
site = root/"site"; site.mkdir(exist_ok=True)
feed = site/"feed.xml"
items=[]
for a in sorted(out.glob("*.mp3")):
    size = a.stat().st_size
    items.append(f"""  <item>
    <title>{a.stem.replace('_',' ').title()}</title>
    <description>Codex excerpt</description>
    <enclosure url="{os.environ.get('FEED_URL','')[:-9]}/audio/{a.name}" type="audio/mpeg" length="{size}"/>
    <pubDate>{time.strftime("%a, %d %b %Y %H:%M:%S GMT", time.gmtime())}</pubDate>
  </item>""")
(feed).write_text("""<rss version="2.0">
<channel>
  <title>AI SAGA SPHERE</title>
  <link>""" + os.environ.get("SITE_URL","") + """</link>
  <description>Codex-sealed, AI-only narrated audiobook continuum</description>
""" + "\n".join(items) + """
</channel>
</rss>""")
# copy audio to site/audio
audio_dir = site/"audio"; audio_dir.mkdir(exist_ok=True)
for a in out.glob("*.mp3"): (audio_dir/a.name).write_bytes(a.read_bytes())
print("Built feed and audio.")
