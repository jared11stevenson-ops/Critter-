import sys; sys.path.insert(0,'tools/refgen')
import gen, cv2, numpy as np, json, time
from PIL import Image
W='design/reference_gen/aruun/_work/'
src=Image.open(W+'rage_x4.png').convert('RGB').crop((300,0,1800,1500)).resize((512,512),Image.LANCZOS)
src.save(W+'ab2_src.png')
e=cv2.Canny(np.array(src),50,130); e=cv2.dilate(e,np.ones((2,2),np.uint8)); ctrl=Image.fromarray(e).convert('RGB'); ctrl.save(W+'ab2_ctrl.png')
pr="front view of a reptile dragon creature head, open jaw with fangs and pink tongue, yellow eyes, orange-red crown plates, olive fringe"
res=[]
t0=time.time(); gen.pipe(); print('load',time.time()-t0,flush=True)
for name,kw in [("C_cn_ip_s30",dict(strength=0.3,cn_scale=1.0,ip_scale=0.6)),("C_cn_ip_s50",dict(strength=0.5,cn_scale=1.0,ip_scale=0.6)),("C_cn_ip_s70",dict(strength=0.7,cn_scale=1.0,ip_scale=0.6)),("A_i2i_s30",dict(strength=0.3,cn_scale=0.0,ip_scale=0.0))]:
    o,t=gen.run(src,ctrl,src,pr,**kw); o.save(W+f'ab2_{name}.png'); res.append((name,kw,round(t,1))); print(name,t,flush=True)
json.dump(res,open(W+'ab2.json','w'))
