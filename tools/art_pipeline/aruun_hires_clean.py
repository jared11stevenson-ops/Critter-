"""Aruun hi-res clean views: front = Morrow erased (polygon below grip), mask of erased px saved;
back = largest alpha component (drops the unlabeled grey sketch)."""
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
D = 'design/model_sheets/aruun/hires/'
def largest(a):
    lab, n = ndimage.label(a[..., 3] > 20)
    if n > 1:
        s = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1)); keep = 1 + int(np.argmax(s))
        a[lab != keep, 3] = 0
    return a
f = Image.open(D + 'front_x4.png').convert('RGBA')
k = 1100 / 825.
poly = [(x * k, y * k + 900) for x, y in [(0, 771), (0, 290), (450, 285), (500, 305), (565, 290), (595, 330), (598, 771)]]
m = Image.new('L', f.size, 0); ImageDraw.Draw(m).polygon(poly, fill=255)
ImageDraw.Draw(m).rectangle((0, 0, 260, 1900), fill=255)          # mace/haft left margin
a = np.asarray(f).copy(); mm = np.asarray(m) > 0
a[mm, 3] = 0; a = largest(a)
Image.fromarray(a).save(D + 'front_clean_x4.png'); Image.fromarray((mm * 255).astype(np.uint8)).save(D + 'front_morrow_mask.png')
b = largest(np.asarray(Image.open(D + 'back_x4.png').convert('RGBA')).copy()); Image.fromarray(b).save(D + 'back_x4.png')
s = largest(np.asarray(Image.open(D + 'side_x4.png').convert('RGBA')).copy()); Image.fromarray(s).save(D + 'side_x4.png')
