import sys,json,numpy as np,cv2
sys.path.insert(0,'tools/recon')
from PIL import Image,ImageDraw,ImageFont,ImageEnhance
from head_data import REG
OUT='design/model_sheets/aruun/recon/analyst/'
SRC='design/reference_packs/aruun/ortho/aruun_front_4096.png'
X0,Y0,X1,Y1=600,80,1500,880; S=2
im=Image.open(SRC);rgba=im.convert('RGBA');alpha=np.array(rgba)[Y0:Y1,X0:X1,3]
idx=np.array(im);pal=np.array(im.getpalette()).reshape(-1,3);rgb=pal[idx[Y0:Y1,X0:X1]]
fg=alpha>=128
# rebuild labels identical to head_regions.py
q=(rgb//24).astype(int);key=q[...,0]*10000+q[...,1]*100+q[...,2]
lab=np.zeros(fg.shape,int);n=0
for k in np.unique(key[fg]):
    mm=((key==k)&fg).astype(np.uint8);nc,cc,st,ce=cv2.connectedComponentsWithStats(mm,connectivity=4)
    for i in range(1,nc):
        if st[i,4]<250: continue
        n+=1;lab[cc==i]=n
cls={}
for c,d in REG.items():
    for k in d: cls[int(k)]=c
col={'A':(255,40,40),'B':(40,90,255),'C':(0,190,60),'D':(255,0,255)}
bgc=Image.new('RGBA',im.size,(230,222,200,255));bgc.alpha_composite(rgba)
base=bgc.crop((X0,Y0,X1,Y1)).convert('RGB');base=ImageEnhance.Brightness(base).enhance(0.55).resize((fg.shape[1]*S,fg.shape[0]*S),Image.LANCZOS)
ov=np.array(base)
for rid in range(1,n+1):
    c=cls.get(rid); 
    m=(lab==rid).astype(np.uint8)
    if m.sum()<250: continue
    cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
    colr=col[c] if c else (150,150,150)
    for cc in cs: cv2.polylines(ov,[(cc*S).astype(np.int32)],True,colr[::-1][::-1],1 if not c else 2)
# silhouette: thick white+orange
cs,_=cv2.findContours(fg.astype(np.uint8),cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE)
for cc in cs: cv2.polylines(ov,[(cc*S).astype(np.int32)],True,(255,200,0),3)
img=Image.fromarray(ov);d=ImageDraw.Draw(img);f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',14)
regs={r['id']:r for r in json.load(open(OUT+'regions.json'))}
for rid,c in cls.items():
    if rid in regs and regs[rid]['area_px']>=500:
        cx,cy=regs[rid]['centroid_src']; d.text(((cx-X0)*S-8,(cy-Y0)*S-8),str(rid),font=f,fill=(255,255,255),stroke_width=2,stroke_fill=(0,0,0))
MAN=[((885,533),'A knob joint'),((880,208),'A elbow cap'),((1138,100),'A top knob'),((1290,150),'A segment->claw'),((1000,265),'A spur'),((893,390),'D highlight stripe'),((905,300),'C shading'),((1130,130),'C shading/D hi'),((650,470),'A elbow knob'),((720,380),'D highlight'),((700,420),'C'),((1025,500),'A spike C'),((1200,480),'A blade D'),((1285,480),'A stub E'),((935,330),'C horn tone'),((1240,490),'D lt blade stripe')]
for (x,y),t in MAN:
    cl={'A':col['A'],'B':col['B'],'C':col['C'],'D':col['D']}[t[0]]
    X,Y=(x-X0)*S,(y-Y0)*S; d.ellipse([X-5,Y-5,X+5,Y+5],fill=cl,outline=(255,255,255)); d.text((X+8,Y-8),t,font=f,fill=(255,255,255),stroke_width=2,stroke_fill=(0,0,0))
leg=[('A form change (real raised/recessed geometry)',col['A']),('B overlapping geometry (plate/strand in front of another)',col['B']),('C colour boundary (pigment/shadow, NO geometry)',col['C']),('D stylised linework / highlight (NO geometry)',col['D']),('silhouette (A/B: outer edge, must match)',(255,200,0)),('unclassified small regions (grey)',(150,150,150))]
for i,(t,c) in enumerate(leg):
    d.rectangle([10,10+i*22,26,26+i*22],fill=c);d.text((32,10+i*22),t,font=f,fill=(255,255,255),stroke_width=2,stroke_fill=(0,0,0))
img.save(OUT+'head_line_classification.png')
json.dump(dict(legend={'A':'form change','B':'overlapping geometry','C':'colour boundary','D':'stylised linework / highlight'},region_class={str(k):dict(cls=v,role=REG[v][str(k)]) for k,v in cls.items()}),open(OUT+'head_line_classification.json','w'),indent=1)
