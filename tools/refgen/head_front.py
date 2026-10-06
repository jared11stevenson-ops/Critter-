"""Place the upscaled straight-on (CALM) face on the shared head landmark rows. Original pixels only (ESRGAN upscaled)."""
import json, numpy as np
from PIL import Image, ImageDraw
OUT='design/reference_gen/aruun/'
PXM=4000  # px per metre for head sheets
CREAM=(233,225,200)
M={'top':2.4,'crown':2.127,'eyes':2.0752,'chin':1.97,'neck':1.772}
W,H=1500,2800
def row(k): return int(round((2.45-M[k])*PXM))   # y of landmark, 2.45 m at y=0
src=Image.open(OUT+'_work/calm_x4.png').convert('RGB')
# measured rows in the 2080px upscaled tile (see _work/calm_x4 inspection)
SRC_EYES, SRC_CHIN, AXIS = 692, 1050, 1050
s=(row('chin')-row('eyes'))/(SRC_CHIN-SRC_EYES)
im=src.resize((int(src.width*s),int(src.height*s)),Image.LANCZOS)
ox=int(W/2-AXIS*s); oy=int(row('eyes')-SRC_EYES*s)
canvas=Image.new('RGB',(W,H),CREAM)
a=np.array(src).astype(int); fg=(np.abs(a-np.array(CREAM)).sum(2)>45)
mask=Image.fromarray((fg*255).astype('uint8')).resize(im.size,Image.LANCZOS).convert('L')
canvas.paste(im,(ox,oy),mask)
canvas.save(OUT+'head/aruun_head_front_straighton.png')
lm=canvas.copy(); d=ImageDraw.Draw(lm)
cols={'top':(150,40,30),'crown':(170,60,40),'eyes':(190,100,40),'chin':(180,130,30),'neck':(130,130,40)}
for k in M: d.line([(0,row(k)),(W,row(k))],fill=cols[k],width=2); d.text((8,row(k)-14),f'{k} {M[k]:.3f} m',fill=cols[k])
d.line([(W//2,0),(W//2,H)],fill=(120,120,120),width=1)
lm.save(OUT+'head/aruun_head_front_straighton_landmarks.png')
# derivation: green = original (upscaled) pixels, yellow = generated/filled (none here)
dv=Image.blend(canvas,Image.new('RGB',(W,H),(0,200,0)),0.0)
ov=Image.new('RGB',(W,H),(40,40,40)); gm=Image.new('RGB',(W,H),(0,200,0))
full=Image.new('L',(W,H),0); full.paste(mask,(ox,oy))
dv=Image.composite(Image.blend(canvas,gm,0.45),canvas,full)
dv.save(OUT+'derivation/aruun_head_front_straighton_derivation.png')
json.dump({'file':'head/aruun_head_front_straighton.png','sources':['design/reference_packs/aruun/head/aruun_expressions.jpg (CALM tile, itself x4 of tools/source_art/aruun_nerit_sheet.jpg)'],
 'method':'Real-ESRGAN x4plus_anime_6B upscale of CALM tile, scaled so eye row and chin row land on landmarks_m; no diffusion',
 'px_per_m':PXM,'rows_px':{k:row(k) for k in M},'scale_applied':s,'seed':None,'generated_fraction':0.0,
 'legend':'green = original sheet paint (upscaled), yellow = generated (none)'},open(OUT+'derivation/aruun_head_front_straighton.json','w'),indent=1)
print(s,ox,oy,{k:row(k) for k in M})
