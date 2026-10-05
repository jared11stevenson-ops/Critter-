import os, sys, numpy as np
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.join(HERE,"..",".."))
from common import splat
d=np.load(os.path.join(HERE,"..","work","v3","raw_mesh.npz")); V,T,fk=d["V"],d["T"],d["facekinds"]
COL={"trunk":(.45,.2,.2),"armL":(.5,.25,.2),"armR":(.5,.25,.2),"legL":(.3,.25,.3),"legR":(.3,.25,.3),"morrow":(.3,.3,.3),"card":(.5,.5,.3),"horn":(.8,.3,.2),"skull":(.8,.6,.5),"jaw":(.3,.3,.4),"eye":(1,.9,0),"tooth_up":(1,1,.9),"tooth_lo":(1,1,.9),"tongue":(.9,.3,.4)}
kinds=np.array([str(k).split("|")[1] for k in fk])
meshes=[(V,T[kinds==k],COL[k]) for k in COL if (kinds==k).any()]
mode=sys.argv[2] if len(sys.argv)>2 else "full"
if mode=="full":
    tiles=[splat.render(meshes,v,ppm=330,height=2.5,width=1.4) for v in ("side",0,"back",-35)]
else:
    sh=np.array([-0.085,-(-0.1),-1.8])
    mm=[(V+sh,t,c) for V,t,c in meshes]
    tiles=[splat.render(mm,v,ppm=1000,height=0.8,width=0.8) for v in ("side",0,-35,-70)]
W=sum(t.width for t in tiles); im=Image.new("RGB",(W,tiles[0].height),(220,210,195)); x=0
for t in tiles:
    bg=Image.new("RGBA",t.size,(220,210,195,255)); bg.alpha_composite(t); im.paste(bg.convert("RGB"),(x,0)); x+=t.width
im.save(sys.argv[1])
