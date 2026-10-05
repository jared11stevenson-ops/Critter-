import sys,os,numpy as np
HERE=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0,os.path.join(HERE,'..','..'))
from common import splat
from PIL import Image
d=np.load(os.path.join(HERE,'..','work','v2','head_raw.npz'))
sh=np.array([0,0.0,0.3-1.55])
ms=[(d['Vs']+sh,d['Fs'],(.85,.62,.45)),(d['Ve']+sh,d['Fe'],(.9,.8,.1))]
tiles=[splat.render(ms,v,ppm=1500,height=0.5,width=0.5) for v in (0,-35,'side')]
W=sum(t.width for t in tiles); im=Image.new('RGB',(W,tiles[0].height),(220,210,195)); x=0
for t in tiles:
    bg=Image.new('RGBA',t.size,(220,210,195,255)); bg.alpha_composite(t); im.paste(bg.convert('RGB'),(x,0)); x+=t.width
im.save(sys.argv[1])
