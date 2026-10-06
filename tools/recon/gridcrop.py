"""Labeled-grid crop. usage: gridcrop.py src.png x0 y0 x1 y1 scale step out.png  (coords in src pixels; src composited on cream)"""
import sys
from PIL import Image, ImageDraw
src,x0,y0,x1,y1,sc,step,out=sys.argv[1:9]
x0,y0,x1,y1,sc,step=map(int,(x0,y0,x1,y1,sc,step))
im=Image.open(src).convert('RGBA')
bg=Image.new('RGBA',im.size,(230,222,200,255)); bg.alpha_composite(im)
c=bg.crop((x0,y0,x1,y1)).resize(((x1-x0)*sc,(y1-y0)*sc),Image.LANCZOS).convert('RGB')
d=ImageDraw.Draw(c)
for x in range((x0//step+1)*step,x1,step):
    X=(x-x0)*sc; d.line([(X,0),(X,c.height)],fill=(0,160,255),width=1); d.text((X+2,2),str(x),fill=(0,0,255))
for y in range((y0//step+1)*step,y1,step):
    Y=(y-y0)*sc; d.line([(0,Y),(c.width,Y)],fill=(0,160,255),width=1); d.text((2,Y+2),str(y),fill=(0,0,255))
c.save(out)
