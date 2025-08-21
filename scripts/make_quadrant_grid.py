import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ART=Path("public/art"); ART.mkdir(parents=True, exist_ok=True)
labels=json.loads(Path("assets/labels/quadrants.json").read_text())
cover=ART/"cover.png"; poster=ART/"poster_landscape.png"
W,H=2000,2000
grid=Image.new("RGB",(W,H),(0,0,0))
draw=ImageDraw.Draw(grid)
try:
    fnt=ImageFont.truetype("DejaVuSans.ttf", 64)
except:
    fnt=ImageFont.load_default()

def cell(x,y): return (x*W//2, y*H//2, (x+1)*W//2, (y+1)*H//2)
def paste_fit(img, box):
    img = img.copy()
    tw,th = img.size; bw,bh = box[2]-box[0], box[3]-box[1]
    ratio=min(bw/tw,bh/th); img=img.resize((int(tw*ratio),int(th*ratio)))
    ox=box[0]+(bw-img.size[0])//2; oy=box[1]+(bh-img.size[1])//2
    grid.paste(img,(ox,oy))

def label(text, box):
    x=box[0]+20; y=box[1]+20
    draw.text((x,y), text, fill=(255,255,255), font=fnt, stroke_width=2, stroke_fill=(0,0,0))

# Load or synthesize placeholders
def load_or_synth(p, size):
    if p.exists(): return Image.open(p).convert("RGB")
    img=Image.new("RGB",size,(15,15,15)); d=ImageDraw.Draw(img); d.text((20,20), p.name, fill=(240,240,240))
    return img
cov=load_or_synth(cover,(1200,1600))
pos=load_or_synth(poster,(1920,1080))

# Place cover in Q1/Q3 cells; poster in Q2/Q4 cells for variety
c00=cell(0,0); paste_fit(cov,c00); label(f"Q1: {labels['Q1']}", c00)
c10=cell(1,0); paste_fit(pos,c10); label(f"Q2: {labels['Q2']}", c10)
c01=cell(0,1); paste_fit(pos,c01); label(f"Q3: {labels['Q3']}", c01)
c11=cell(1,1); paste_fit(cov,c11); label(f"Q4: {labels['Q4']}", c11)

out=ART/"quadrant_grid.png"; grid.save(out, "PNG")
print("[art] quadrant grid ->", out)
