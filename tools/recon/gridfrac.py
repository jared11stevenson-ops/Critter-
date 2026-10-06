"""fractional-scale labeled grid crop: gridfrac.py src x0 y0 x1 y1 scale step out"""
import sys
from PIL import Image,ImageDraw,ImageFont
src,x0,y0,x1,y1=sys.argv[1],*map(int,sys.argv[2:6]);sc=float(sys.argv[6]);step=int(sys.argv[7]);out=sys.argv[8]
im=Image.open(src).convert('RGBA');bg=Image.new('RGBA',im.size,(230,222,200,255));bg.alpha_composite(im)
c=bg.crop((x0,y0,x1,y1)).resize((int((x1-x0)*sc),int((y1-y0)*sc)),Image.LANCZOS).convert('RGB');d=ImageDraw.Draw(c);f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',11)
for x in range((x0//step+1)*step,x1,step):
    X=(x-x0)*sc;d.line([(X,0),(X,c.height)],fill=(0,150,255));d.text((X+2,2),str(x),fill=(0,0,255),font=f)
for y in range((y0//step+1)*step,y1,step):
    Y=(y-y0)*sc;d.line([(0,Y),(c.width,Y)],fill=(0,150,255));d.text((2,Y+2),str(y),fill=(0,0,255),font=f)
c.save(out)
