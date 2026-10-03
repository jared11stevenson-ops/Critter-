"""Cut hi-res views from a Real-ESRGAN x4 sheet; background removed with rembg (isnet-anime). usage: hires_cut.py x4.png outdir name:x0,y0,x1,y1 ...  (boxes in 1280/1400-px sheet coords x4)"""
import sys, os
from PIL import Image
from rembg import remove, new_session
src, out = sys.argv[1], sys.argv[2]; im = Image.open(src).convert('RGB'); os.makedirs(out, exist_ok=True)
sess = new_session('isnet-anime')
for spec in sys.argv[3:]:
    n, b = spec.split(':'); b = [4*int(v) for v in b.split(',')]
    c = im.crop(b); c.save(f'{out}/{n}_x4_raw.png')
    remove(c, session=sess, post_process_mask=True).save(f'{out}/{n}_x4.png')
