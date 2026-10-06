"""R-HERO deliverables: python3 tools/recon/build_hero.py"""
import json,numpy as np,cv2
from PIL import Image,ImageDraw,ImageFont
SRC='design/reference_packs/aruun/ortho/aruun_front_4096.png'
OUT='design/model_sheets/aruun/recon/analyst/'
H=3904.0;OX=945.5;OY=4000
norm=lambda p:(round((p[0]-OX)/H,4),round((OY-p[1])/H,4))
F=lambda s:ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',s)
im=Image.open(SRC);rgba=im.convert('RGBA');alpha=np.array(rgba)[:,:,3];m=(alpha>=128).astype(np.uint8)
LM=[
(1,'extreme top (horn A knob)',(1138,96),'V'),(2,'horn B top knob',(766,259),'V'),(3,'horn A claw tip',(1394,191),'V'),(4,'horn B elbow (left extreme of head)',(626,493),'V'),
(5,'snout / hook tip',(811,780),'V'),(6,'eye centre',(1022,638),'V'),(7,'crown top',(1079,544),'V'),(8,'throat gape apex',(1009,746),'V'),
(9,'fringe long streak tip',(1444,626),'V'),(10,'neck front edge y=1000',(1039,1000),'V'),(11,'neck back edge y=1000',(1266,1000),'V'),
(12,'neck front edge meets cape/shoulder',(1010,1150),'J'),(13,'left cape/shoulder slope y=1300',(832,1300),'V'),(14,'left cape extreme (leftmost shoulder)',(504,1500),'V'),
(15,'left cape lower hem corner',(560,1600),'V'),(16,'right pauldron top',(1590,1005),'V'),(17,'right pauldron right extreme',(1712,1470),'V'),(18,'right pauldron bottom',(1650,1625),'V'),
(19,'neck back / right shoulder junction (hidden under pauldron)',(1300,1130),'H'),(20,'left arm upper-outer edge',(365,1900),'V'),(21,'left forearm armour lower end',(130,2260),'J'),
(22,'left hand extreme-left tip',(8,2500),'V'),(23,'left hand claws underside',(200,2480),'V'),(24,'right elbow plate top',(1520,1830),'V'),(25,'right elbow plate right extreme',(1769,1900),'V'),
(26,'right fist bottom',(1640,2510),'V'),(27,'belt left end',(700,1880),'J'),(28,'belt right end',(1215,1880),'J'),(29,'hanging pendant (right of waist) bottom',(1330,2170),'V'),
(30,'chest bandolier left shoulder knot',(880,1480),'J'),(31,'skirt left edge top',(363,2800),'V'),(32,'skirt left hem strand tip',(540,3470),'V'),(33,'skirt right edge max',(1890,3430),'V'),
(34,'skirt hem between legs left',(900,3314),'V'),(35,'skirt hem between legs right',(1290,3350),'V'),(36,'left knee wrap centre',(700,2910),'J'),(37,'right knee plate centre',(1260,2730),'J'),
(38,'left ankle',(720,3560),'J'),(39,'left foot toe (flat vertical cut at x=365)',(365,3800),'V'),(40,'left foot heel / right extent',(880,3830),'V'),(41,'left foot bottom',(620,3873),'V'),
(42,'right ankle',(1600,3500),'J'),(43,'right foot right extreme',(1888,3830),'V'),(44,'right foot toe-left',(1487,3850),'V'),(45,'right foot bottom (ground row)',(1700,4000),'V'),
]
lm=[dict(id=i,name=n,src=list(p),norm=list(norm(p)),kind=k) for i,n,p,k in LM]
# concavity analysis
cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE);c=max(cs,key=len)
hull=cv2.convexHull(c);hm=np.zeros_like(m);cv2.fillPoly(hm,[hull],1)
pock=(hm>0)&(m==0)
nc,cc,st,ce=cv2.connectedComponentsWithStats(pock.astype(np.uint8),connectivity=8)
P=[]
for i in range(1,nc):
    if st[i,4]<20000: continue
    P.append(dict(id=i,area_px=int(st[i,4]),area_H2=round(st[i,4]/H/H,5),bbox_src=[int(st[i,0]),int(st[i,1]),int(st[i,0]+st[i,2]),int(st[i,1]+st[i,3])],centroid_src=[round(ce[i][0]),round(ce[i][1])],centroid_norm=list(norm(ce[i]))))
P.sort(key=lambda d:-d['area_px'])
# internal holes
holes=[];nc2,cc2,st2,ce2=cv2.connectedComponentsWithStats((1-m).astype(np.uint8),connectivity=4)
for i in range(1,nc2):
    x,y,w,h,a=st2[i]
    if x>0 and y>0 and x+w<m.shape[1] and y+h<m.shape[0] and a>500: holes.append(dict(bbox_src=[int(x),int(y),int(x+w),int(y+h)],area_px=int(a)))
# row extents
rows={}
for y in range(100,4001,100):
    r=np.nonzero(m[min(y,m.shape[0]-1)])[0]
    if len(r)==0: continue
    br=np.nonzero(np.diff(r)>1)[0];runs=[];s=r[0]
    for b in br: runs.append([int(s),int(r[b])]);s=r[b+1]
    runs.append([int(s),int(r[-1])]);rows[y]=runs
ys,xs=np.nonzero(m)
ap=cv2.approxPolyDP(c,3.0,True)[:,0,:]
json.dump(dict(image=SRC,coord_system=dict(origin_src=[OX,OY],origin_name='ground row (y=4000) at image centre x=945.5',unit_H_px=H,unit_name='body height H = 3904 px (y96 horn top to y4000 ground row)',axes='u=(x-945.5)/3904 right+, v=(4000-y)/3904 up+'),
 threshold='alpha>=128 (halo alpha 1..127 treated as background)',extremes=dict(top=[int(xs[ys.argmin()]),int(ys.min())],bottom=[int(xs[ys.argmax()]),int(ys.max())],left=[int(xs.min()),int(ys[xs.argmin()])],right=[int(xs.max()),int(ys[xs.argmax()])]),
 landmarks=lm,hull_concavities=P[:14],internal_holes=holes[:15],row_runs_src=rows,outline_eps3_src=ap.tolist(),outline_eps3_norm=[norm(p) for p in ap.tolist()]),open(OUT+'hero_landmarks.json','w'),indent=1)
Image.fromarray(m*255).save(OUT+'hero_silhouette_mask.png')
sp=np.full(m.shape+(3,),235,np.uint8);sp[m>0]=0;Image.fromarray(sp).resize((m.shape[1]//2,m.shape[0]//2),Image.LANCZOS).save(OUT+'hero_silhouette_black_half.png')
# overlay
S=0.5;bg=Image.new('RGBA',im.size,(230,222,200,255));bg.alpha_composite(rgba)
o=bg.resize((int(im.size[0]*S),int(im.size[1]*S)),Image.LANCZOS).convert('RGB');d=ImageDraw.Draw(o)
for x in range(0,im.size[0],200): d.line([(x*S,0),(x*S,o.height)],fill=(0,150,255));d.text((x*S+2,2),str(x),fill=(0,0,255),font=F(11))
for y in range(0,im.size[1],200): d.line([(0,y*S),(o.width,y*S)],fill=(0,150,255));d.text((2,y*S+2),str(y),fill=(0,0,255),font=F(11))
for k in range(-4,5):
    x=OX+k*0.1*H
    if 0<x<im.size[0]: d.line([(x*S,0),(x*S,o.height)],fill=(255,60,60));d.text((x*S+2,o.height-14),'u%.1f'%(k/10),fill=(200,0,0),font=F(11))
for k in range(0,11):
    y=OY-k*0.1*H
    d.line([(0,y*S),(o.width,y*S)],fill=(255,60,60));d.text((o.width-40,y*S+1),'v%.1f'%(k/10),fill=(200,0,0),font=F(11))
for i,n,p,k in LM:
    X,Y=p[0]*S,p[1]*S;col={'V':(255,255,0),'J':(0,255,255),'H':(255,0,0)}[k];d.ellipse([X-4,Y-4,X+4,Y+4],fill=col,outline=(0,0,0));d.text((X+5,Y-7),str(i),font=F(12),fill=col,stroke_width=2,stroke_fill=(0,0,0))
o.save(OUT+'hero_overlay_landmarks.png')
# negative space overlay
o2=bg.resize((int(im.size[0]*S),int(im.size[1]*S)),Image.LANCZOS).convert('RGBA');ov=Image.new('RGBA',o2.size,(0,0,0,0));od=ImageDraw.Draw(ov)
for j,p in enumerate(P[:10]):
    mk=(cc==p['id']).astype(np.uint8);mk=cv2.resize(mk,(o2.size[0],o2.size[1]),interpolation=cv2.INTER_NEAREST)
    arr=np.array(ov);col=[(255,0,0),(0,160,0),(0,0,255),(200,120,0),(160,0,160),(0,150,150),(120,120,0),(255,60,160),(90,90,255),(0,0,0)][j]
    arr[mk>0]=col+(110,);ov=Image.fromarray(arr);od=ImageDraw.Draw(ov)
    od.text((p['centroid_src'][0]*S-10,p['centroid_src'][1]*S-8),'P%d'%(j+1),font=F(18),fill=(0,0,0,255))
    p['label']='P%d'%(j+1)
o2.alpha_composite(ov);o2.convert('RGB').save(OUT+'hero_negative_space.png')
json.dump(dict(unit='area/H^2; pocket = convex-hull minus silhouette (open concavities, labels P1.. by area)',pockets=P[:10],internal_holes=holes[:15]),open(OUT+'hero_negative_space.json','w'),indent=1)
for p in P[:10]: print(p['label'],p['area_px'],p['area_H2'],p['bbox_src'])
print('holes',len(holes),holes[:5]); print('extremes',xs.min(),xs.max(),ys.min(),ys.max())
