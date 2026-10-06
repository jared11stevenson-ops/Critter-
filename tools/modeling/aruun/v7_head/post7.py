"""overlay + compare sheets from render7 outputs (no bpy). usage: post7.py OUTDIR [views]"""
import sys, numpy as np
from PIL import Image
import json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import crops
out = sys.argv[1]; views = sys.argv[2].split(',') if len(sys.argv) > 2 else ['side', 'front', 'back']
VW = json.load(open(f'{out}/views.json'))
for vn in views:
    v = VW[vn]; crops.crop(v['ref'], tuple(v['box']), v['zoom'], 20, f'{out}/{vn}_ref.png', False)
    I = np.array(Image.open(f'{out}/{vn}_id.png').convert('RGB')).astype(int)
    key = I[:, :, 0] * 65536 + I[:, :, 1] * 256 + I[:, :, 2]; bg = key == 0
    H, W = key.shape; edge = np.zeros(key.shape, bool); sil = np.zeros(key.shape, bool)
    for dy, dx in ((0, 1), (1, 0)):
        a = key[:H - dy, :W - dx]; b = key[dy:, dx:]; diff = a != b
        edge[:H - dy, :W - dx] |= diff; sil[:H - dy, :W - dx] |= diff & (bg[:H - dy, :W - dx] | bg[dy:, dx:])
    ref = np.array(Image.open(f'{out}/{vn}_ref.png').convert('RGB'))
    ov = (ref * 0.85).astype(np.uint8); ov[edge & ~sil] = (40, 255, 40); ov[sil] = (0, 255, 255)
    Image.fromarray(ov).save(f'{out}/{vn}_overlay.png')
    ims = [Image.open(f'{out}/{vn}_{k}.png').convert('RGB') for k in ('ref', 'overlay', 'clay', 'parts')]
    w, h = ims[0].size; S = Image.new('RGB', (2 * w, 2 * h))
    for k, i in enumerate(ims): S.paste(i, ((k % 2) * w, (k // 2) * h))
    S.save(f'{out}/compare_{vn}.png'); print(vn, S.size)
