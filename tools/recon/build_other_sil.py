import json,numpy as np,cv2
from PIL import Image
OUT='design/model_sheets/aruun/recon/analyst/'
V='design/reference_gen/aruun/v2/aruun_v2_%s_4096.png'
res={}
for nm in ['face_calm','face_rage','side_completed','back_completed']:
    im=Image.open(V%nm).convert('RGBA');a=np.array(im)[:,:,3];m=(a>=128).astype(np.uint8)
    ys,xs=np.nonzero(m);cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE);c=max(cs,key=len)
    ap=cv2.approxPolyDP(c,3.0,True)[:,0,:]
    Image.fromarray(m*255).resize((m.shape[1]//2,m.shape[0]//2)).save(OUT+'mask_%s_half.png'%nm)
    res[nm]=dict(source=V%nm,size=im.size,threshold='alpha>=128',bbox=[int(xs.min()),int(ys.min()),int(xs.max()),int(ys.max())],area_px=int(m.sum()),outline_eps3_src=ap.tolist())
    print(nm,res[nm]['bbox'],len(ap))
json.dump(res,open(OUT+'other_views_silhouettes.json','w'))
