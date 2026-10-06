"""Place an (upscaled original) view on shared head landmark rows; emit clean, landmarks, derivation overlay, json."""
import json, numpy as np, cv2
from PIL import Image, ImageDraw
OUT='design/reference_gen/aruun/'
PXM=4000; CREAM=(233,225,200)
M={'top':2.4,'crown':2.127,'eyes':2.0752,'chin':1.97,'neck':1.772}
W,H=1500,2800
def row(k): return int(round((2.45-M[k])*PXM))
COL={'top':(150,40,30),'crown':(170,60,40),'eyes':(190,100,40),'chin':(180,130,30),'neck':(130,130,40)}
def fgmask(a):
    light=((a>190).all(2)&((a.max(2)-a.min(2))<62)).astype('uint8')
    n,lab=cv2.connectedComponents(light,connectivity=4)
    border=set(lab[0,:])|set(lab[-1,:])|set(lab[:,0])|set(lab[:,-1])
    bg=np.isin(lab,[b for b in border if b!=0])&(light>0)
    return ~bg
def place(name,src,axis_x,eyes_y,scale,desc,sources,notes='',eyes_row='eyes',gen_mask=None,flip=False):
    im=Image.open(src).convert('RGB')
    b=12; im=im.crop((b,b,im.width-b,im.height-b)); axis_x-=b; eyes_y-=b  # drop tile border line
    if flip: im=im.transpose(Image.FLIP_LEFT_RIGHT); axis_x=im.width-axis_x
    fg=fgmask(np.array(im))
    mk=Image.fromarray((fg*255).astype('uint8'))
    sz=(int(im.width*scale),int(im.height*scale))
    im2=im.resize(sz,Image.LANCZOS); mk2=mk.resize(sz,Image.LANCZOS)
    ox=int(W/2-axis_x*scale); oy=int(row(eyes_row)-eyes_y*scale)
    cv=Image.new('RGB',(W,H),CREAM); cv.paste(im2,(ox,oy),mk2)
    cv.save(OUT+f'head/{name}.png')
    lm=cv.copy(); d=ImageDraw.Draw(lm)
    for k in M: d.line([(0,row(k)),(W,row(k))],fill=COL[k],width=2); d.text((8,row(k)-14),f'{k} {M[k]:.3f} m',fill=COL[k])
    lm.save(OUT+f'head/{name}_landmarks.png')
    full=Image.new('L',(W,H),0); full.paste(mk2,(ox,oy))
    ov=Image.composite(Image.blend(cv,Image.new('RGB',(W,H),(0,200,0)),0.4),cv,full)
    if gen_mask is not None:
        ov=Image.composite(Image.blend(cv,Image.new('RGB',(W,H),(255,220,0)),0.5),ov,gen_mask)
    ov.save(OUT+f'derivation/{name}_derivation.png')
    json.dump({'file':f'head/{name}.png','view':desc,'sources':sources,'method':'Real-ESRGAN anime-6B x4 of original sheet pixels, placed by landmark row; no diffusion','px_per_m':PXM,
      'rows_px':{k:row(k) for k in M},'scale':scale,'eyes_row_src_y':eyes_y,'axis_x_src':axis_x,'seed':None,'notes':notes,
      'legend':'derivation: green = original paint, yellow = generated'},open(OUT+f'derivation/{name}.json','w'),indent=1)
    return cv
