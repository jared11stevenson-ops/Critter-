"""Zoomed reference crops with labelled pixel grid (frame px of the v2 4096 tiles). usage: crops.py"""
import sys
from PIL import Image, ImageDraw
R='design/reference_gen/aruun/v2/aruun_v2_%s_4096.png'; OUT='design/model_sheets/aruun/fidelity/head_v7/'
def crop(name, box, zoom, step, out, grid=True):
    im=Image.open(R%name).convert('RGBA'); bg=Image.new('RGBA',im.size,(205,205,205,255)); bg.alpha_composite(im)
    c=bg.crop(box).convert('RGB').resize(((box[2]-box[0])*zoom,(box[3]-box[1])*zoom),Image.LANCZOS)
    if grid:
        d=ImageDraw.Draw(c)
        for x in range((box[0]//step+1)*step,box[2],step):
            X=(x-box[0])*zoom; d.line([(X,0),(X,c.height)],fill=(0,120,255) if x%(step*5) else (255,0,255),width=1); d.text((X+2,2),str(x),fill=(0,0,200))
        for y in range((box[1]//step+1)*step,box[3],step):
            Y=(y-box[1])*zoom; d.line([(0,Y),(c.width,Y)],fill=(0,120,255) if y%(step*5) else (255,0,255),width=1); d.text((2,Y+2),str(y),fill=(0,0,200))
    c.save(out); print(out,c.size)
if __name__=='__main__':
    crop('side_completed',(330,480,880,800),2,20,OUT+'crop_side_grid.png')
    crop('side_completed',(330,480,880,800),2,20,OUT+'crop_side_clean.png',False)
    crop('face_calm',(440,380,960,1200),1,20,OUT+'crop_front_grid.png')
