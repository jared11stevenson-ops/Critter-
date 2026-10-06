"""Real-ESRGAN x4plus_anime_6B (BSD-3) CPU upscaler. usage: upscale.py in.png out.png [tile]"""
import sys, types, time, numpy as np, torch
import torchvision.transforms.functional as F
sys.modules['torchvision.transforms.functional_tensor'] = types.SimpleNamespace(rgb_to_grayscale=F.rgb_to_grayscale)
from basicsr.archs.rrdbnet_arch import RRDBNet
from realesrgan import RealESRGANer
from PIL import Image
W = '/tmp/claude-0/work/w/x4anime6B.pth'
def up(img, tile=200):
    m = RRDBNet(num_in_ch=3, num_out_ch=3, num_feat=64, num_block=6, num_grow_ch=32, scale=4)
    u = RealESRGANer(scale=4, model_path=W, model=m, tile=tile, tile_pad=10, pre_pad=0, half=False)
    o, _ = u.enhance(np.array(img.convert('RGB'))[:, :, ::-1], outscale=4)
    return Image.fromarray(o[:, :, ::-1])
if __name__ == '__main__':
    t = time.time(); up(Image.open(sys.argv[1])).save(sys.argv[2]); print('upscale s', time.time() - t)
