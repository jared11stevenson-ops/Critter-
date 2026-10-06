"""R-HEAD region atlas: posterised palette regions (connected components) in the head ROI. Writes regions.json + atlas png."""
import json,sys,numpy as np,cv2
from PIL import Image,ImageDraw
SRC='design/reference_packs/aruun/ortho/aruun_front_4096.png'
OUT='design/model_sheets/aruun/recon/analyst/'
X0,Y0,X1,Y1=600,80,1500,880
im=Image.open(SRC); idx=np.array(im); pal=np.array(im.getpalette()).reshape(-1,3)
a=idx[Y0:Y1,X0:X1]; rgb=pal[a]
alpha=np.array(im.convert('RGBA'))[Y0:Y1,X0:X1,3]; fg=alpha>=128  # silhouette threshold alpha>=128 (alpha 1..127 = halo, treated as background)
# merge near-identical palette entries by quantising colour to a coarse class so regions are meaningful
q=(rgb//24).astype(int); key=q[...,0]*10000+q[...,1]*100+q[...,2]
regs=[];lab=np.zeros(a.shape,int);n=0
for k in np.unique(key[fg]):
    m=((key==k)&fg).astype(np.uint8)
    nc,cc,st,ce=cv2.connectedComponentsWithStats(m,connectivity=4)
    for i in range(1,nc):
        if st[i,4]<250: continue
        n+=1; lab[cc==i]=n
        col=rgb[cc==i].mean(0).round().astype(int).tolist()
        regs.append(dict(id=n,area_px=int(st[i,4]),bbox_src=[int(st[i,0]+X0),int(st[i,1]+Y0),int(st[i,0]+st[i,2]+X0),int(st[i,1]+st[i,3]+Y0)],centroid_src=[round(ce[i][0]+X0,1),round(ce[i][1]+Y0,1)],mean_rgb=col))
json.dump(regs,open(OUT+'regions.json','w'))
S=3
big=Image.fromarray(np.where(fg[...,None],rgb,np.array([230,222,200])).astype(np.uint8)).resize((a.shape[1]*S//1,a.shape[0]*S//1),Image.NEAREST)
d=ImageDraw.Draw(big)
for r in regs:
    if r['area_px']<700: continue
    cx,cy=r['centroid_src']; d.text(((cx-X0)*S-6,(cy-Y0)*S-5),str(r['id']),fill=(255,255,255) if sum(r['mean_rgb'])<300 else (0,0,0))
big.save(OUT+'atlas_regions_x3.png'); print(n)
