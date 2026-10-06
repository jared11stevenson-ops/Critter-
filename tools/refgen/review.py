"""Contact sheet: original crop | generated view for each pair. pairs: list of (label, original_path, generated_path, note)."""
import json, sys
from PIL import Image, ImageDraw
OUT='design/reference_gen/aruun/'
def fit(im,h):
    return im.resize((max(1,int(im.width*h/im.height)),h),Image.LANCZOS)
def sheet(pairs,path=OUT+'review/aruun_generated_overview.png',cell=640,maxw=2400):
    rows=[]
    for lab,o,g,note in pairs:
        a=fit(Image.open(o).convert('RGB'),cell); b=fit(Image.open(g).convert('RGB'),cell); rows.append((lab,a,b,note))
    colw=max(max(a.width+b.width for _,a,b,_ in rows)+30, 400)
    per=max(1,maxw//colw)
    n=len(rows); r=(n+per-1)//per
    W=min(maxw,per*colw); H=r*(cell+50)+50
    S=Image.new('RGB',(W,H),(233,225,200)); d=ImageDraw.Draw(S)
    d.text((10,10),'ARUUN generated references vs ORIGINAL (left = original sheet crop, right = generated). NOT approved - for fidelity review.',fill=(30,20,20))
    for i,(lab,a,b,note) in enumerate(rows):
        x=(i%per)*colw+10; y=50+(i//per)*(cell+50)
        S.paste(a,(x,y+20)); S.paste(b,(x+a.width+10,y+20)); d.text((x,y+4),lab+'  '+note,fill=(30,20,20))
    S.save(path); print(S.size)
if __name__=='__main__':
    sheet([tuple(p) for p in json.load(open(sys.argv[1]))])
