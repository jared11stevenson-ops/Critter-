"""Build R-HEAD deliverables. Run from repo root: python3 tools/recon/build_head.py"""
import sys,json,numpy as np,cv2
sys.path.insert(0,'tools/recon')
from PIL import Image,ImageDraw,ImageFont
from head_data import *
SRC='design/reference_packs/aruun/ortho/aruun_front_4096.png'
OUT='design/model_sheets/aruun/recon/analyst/'
F=lambda s:ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',s)
im=Image.open(SRC); rgba=im.convert('RGBA'); alpha=np.array(rgba)[:,:,3]
X0,Y0,X1,Y1=600,80,1500,880
bg=Image.new('RGBA',im.size,(230,222,200,255)); bg.alpha_composite(rgba)
def crop(x0,y0,x1,y1,S): return bg.crop((x0,y0,x1,y1)).resize(((x1-x0)*S,(y1-y0)*S),Image.LANCZOS).convert('RGB')
def P(p,x0,y0,S): return ((p[0]-x0)*S,(p[1]-y0)*S)
# ---- silhouette mask + outline
m=(alpha>=128).astype(np.uint8)
r=m[Y0:Y1,X0:X1].copy()
Image.fromarray(r*255).save(OUT+'head_silhouette_mask.png')   # white=inside, ROI x600-1500,y80-880 of source
cs,_=cv2.findContours(r,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE); c=max(cs,key=len)
full=(c[:,0,:]+[X0,Y0]); ap=cv2.approxPolyDP(c,1.5,True)[:,0,:]+[X0,Y0]
area=int(r.sum())
# halo stats
halo=int(((alpha>0)&(alpha<128))[Y0:Y1,X0:X1].sum())
sil=dict(source=SRC,roi_src=[X0,Y0,X1,Y1],threshold='alpha>=128 (palette alpha; 254/255 are opaque, 1..127 are background halo = treated as outside; halo px in ROI=%d)'%halo,
 mask_png='head_silhouette_mask.png',note='ROI is cut at y=880 through the neck; horns+head+fringe are one connected component (area_px=%d)'%area,
 outline_eps1p5_src=ap.tolist(),outline_eps1p5_norm=[norm(p) for p in ap.tolist()],n_points_full=len(full))
json.dump(sil,open(OUT+'head_silhouette.json','w'))
# solid black-on-flat silhouette picture
sp=np.full(r.shape+(3,),235,np.uint8); sp[r>0]=0; Image.fromarray(sp).save(OUT+'head_silhouette_black.png')
# ---- landmarks json
reg=json.load(open(OUT+'regions.json'))
eye=dict(centre_src=[1022,637.6],centre_norm=norm((1022,637.6)),iris_bbox_src=[1003,625,1043,651],iris_w_px=39,iris_h_px=26,iris_w_L=round(39/L,4),iris_h_L=round(26/L,4),
 fit_ellipse=dict(major_px=38.8,minor_px=23.4,major_axis_deg_from_horizontal=12.5,tilt='major axis rises toward screen-RIGHT (screen-left end lower) by ~12.5 deg'),
 socket_bbox_src=[983,603,1073,655],socket_w_L=round(90/L,4),socket_h_L=round(52/L,4))
lm=[dict(id=i,name=n,src=list(p),norm=list(norm(p)),kind=k,note=nt) for i,n,p,k,nt in LM]
json.dump(dict(image=SRC,coord_system=dict(origin_src=list(ORIGIN),origin_name='snout/mandible-hook tip',unit_L_px=L,unit_name='head length L = 633 px (snout tip x=811 to rightmost fringe tip x=1444)',axes='u = (x-811)/633 positive screen-RIGHT (toward back of head); v = (780-y)/633 positive UP; src pixel origin top-left, y down',hero_scale='L = %.4f of hero body height (3904 px, y96..4000)'%(L/3904)),
  eye=eye,landmarks=lm,polylines={k:dict(src=v,norm=[norm(p) for p in v]) for k,v in POLY.items()},regions=reg),open(OUT+'head_landmarks.json','w'),indent=1)
# ---- overlays
def draw_grid(d,x0,y0,x1,y1,S,step,font):
    for x in range((x0//step+1)*step,x1,step):
        X=(x-x0)*S; d.line([(X,0),(X,(y1-y0)*S)],fill=(0,150,255),width=1); d.text((X+2,2),str(x),fill=(0,0,255),font=font)
    for y in range((y0//step+1)*step,y1,step):
        Y=(y-y0)*S; d.line([(0,Y),((x1-x0)*S,Y)],fill=(0,150,255),width=1); d.text((2,Y+2),str(y),fill=(0,0,255),font=font)
def draw_norm(d,x0,y0,x1,y1,S):
    f=F(11)
    for k in range(-2,12):
        u=k/10; x=ORIGIN[0]+u*L
        if x0<x<x1: X=(x-x0)*S; d.line([(X,0),(X,(y1-y0)*S)],fill=(255,60,60),width=1); d.text((X+2,(y1-y0)*S-14),'u%.1f'%u,fill=(200,0,0),font=f)
    for k in range(-3,10):
        v=k/10; y=ORIGIN[1]-v*L
        if y0<y<y1: Y=(y-y0)*S; d.line([(0,Y),((x1-x0)*S,Y)],fill=(255,60,60),width=1); d.text(((x1-x0)*S-34,Y+1),'v%.1f'%v,fill=(200,0,0),font=f)
def landmark_img(x0,y0,x1,y1,S,out,grid=True,step=50):
    c=crop(x0,y0,x1,y1,S); d=ImageDraw.Draw(c)
    if grid: draw_grid(d,x0,y0,x1,y1,S,step,F(11)); draw_norm(d,x0,y0,x1,y1,S)
    cols=[(0,200,0),(255,0,255),(0,130,255),(255,140,0),(0,200,200)]
    for j,(k,v) in enumerate(POLY.items()):
        d.line([P(p,x0,y0,S) for p in v],fill=cols[j%5],width=2)
    f=F(13)
    for i,n,p,k,nt in LM:
        if not(x0<=p[0]<=x1 and y0<=p[1]<=y1): continue
        X,Y=P(p,x0,y0,S); col={'V':(255,255,0),'J':(0,255,255),'H':(255,0,0)}[k]
        d.ellipse([X-4,Y-4,X+4,Y+4],outline=(0,0,0),fill=col); d.text((X+5,Y-7),str(i),font=f,fill=col,stroke_width=2,stroke_fill=(0,0,0))
    c.save(out)
landmark_img(X0,Y0,X1,Y1,2,OUT+'head_overlay_landmarks_full.png',grid=False)
landmark_img(770,540,1460,880,3,OUT+'head_overlay_landmarks_core_grid_x3.png',step=25)
landmark_img(600,80,1420,560,2,OUT+'head_overlay_landmarks_horns_grid_x2.png',step=50)
# ---- negative space
bgm=(alpha<128)
negs=[];ov=crop(X0,Y0,X1,Y1,2); ovd=ImageDraw.Draw(ov,'RGBA')
pal=[(255,0,0),(0,160,0),(0,0,255),(200,120,0),(160,0,160),(0,150,150),(120,120,0),(255,60,160),(90,90,255)]
for j,(k,poly) in enumerate(NEG.items()):
    mk=np.zeros(alpha.shape,np.uint8); cv2.fillPoly(mk,[np.array(poly,np.int32)],1)
    inter=(mk>0)&bgm
    ap_=int(inter.sum()); pa=int(mk.sum())
    ys,xs=np.nonzero(inter)
    cnts,_=cv2.findContours(inter.astype(np.uint8),cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)
    big=max(cnts,key=cv2.contourArea)[:,0,:]
    # equivalent width: area / chord length
    chord=float(np.hypot(poly[0][0]-poly[-1][0],poly[0][1]-poly[-1][1]))
    negs.append(dict(id=k.split(' ')[0],name=k,polygon_src=poly,polygon_norm=[norm(p) for p in poly],chord_closing_src=[poly[-1],poly[0]],
      area_px=ap_,area_L2=round(ap_/L/L,5),bbox_src=[int(xs.min()),int(ys.min()),int(xs.max()),int(ys.max())],bbox_norm_w=round((xs.max()-xs.min())/L,4),bbox_norm_h=round((ys.max()-ys.min())/L,4),
      chord_len_L=round(chord/L,4),mean_width_L=round(ap_/max(chord,1)/L,4)))
    col=pal[j%len(pal)]
    ovd.polygon([((x-X0)*2,(y-Y0)*2) for x,y in poly],fill=col+(90,),outline=col+(255,))
    q=np.array(poly).mean(0); ovd.text(((q[0]-X0)*2-8,(q[1]-Y0)*2-8),k.split(' ')[0],font=F(18),fill=(0,0,0))
ov.save(OUT+'head_negative_space.png')
json.dump(dict(unit='areas normalised by L^2 (L=633 px); mean_width_L = area/chord (typical gap width in head lengths); the polygon walks the silhouette and is closed by a chord across the open side, area = polygon intersect transparent background',gaps=negs),open(OUT+'head_negative_space.json','w'),indent=1)
for g in negs: print(g['id'],g['area_px'],g['area_L2'],g['bbox_norm_w'],g['bbox_norm_h'],g['mean_width_L'])
print('mask area',area,'halo',halo,'eps1.5 pts',len(ap))
