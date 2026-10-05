import os, sys, numpy as np
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.join(HERE,"..",".."))
from common import splat
d=np.load(os.path.join(HERE,"..","work","v3","head_raw.npz")); o=d["origin"]
sh=np.array([-o[0],-o[1],0.3-o[2]+0.0])
def m(k,col): return (d["V"+k]+sh, d["F"+k], col)
meshes=[m("s",(.8,.55,.45)),m("j",(.35,.3,.35)),m("u",(1,1,.9)),m("l",(1,1,.9)),m("e",(.9,.8,.1)),m("t",(.8,.3,.4))]
tiles=[splat.render(meshes,v,ppm=1000,height=0.6,width=0.6) for v in ("side",0,-35,-70)]
W=sum(t.width for t in tiles); im=Image.new("RGB",(W,tiles[0].height),(220,210,195)); x=0
for t in tiles:
    bg=Image.new("RGBA",t.size,(220,210,195,255)); bg.alpha_composite(t); im.paste(bg.convert("RGB"),(x,0)); x+=t.width
im.save(sys.argv[1])
