"""Run Depth Anything V2 small on the REGISTERED v2 side head crop (so depth pixels map to (F,U) exactly) -> head_v6/depth/v2side_crop_depth.npz"""
import numpy as np, torch, os
from PIL import Image
from transformers import AutoImageProcessor, AutoModelForDepthEstimation
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')); R = ROOT + '/design/reference_gen/aruun/v2/'
PPM = 1626.667; AX = 536.0
x0, x1, y0, y1 = 250, 1000, 380, 980               # crop box in the 4096-tall v2 side frame
im = Image.open(R + 'aruun_v2_side_completed_4096.png').convert('RGBA'); bg = Image.new('RGBA', im.size, (230, 220, 200, 255)); bg.alpha_composite(im)
c = bg.convert('RGB').crop((x0, y0, x1, y1)); a = np.array(im)[y0:y1, x0:x1, 3] > 128
P = "depth-anything/Depth-Anything-V2-Small-hf"; proc = AutoImageProcessor.from_pretrained(P); m = AutoModelForDepthEstimation.from_pretrained(P).eval()
with torch.no_grad():
    d = m(**proc(images=c, return_tensors='pt')).predicted_depth
    d = torch.nn.functional.interpolate(d[None], size=c.size[::-1], mode='bicubic')[0, 0].numpy()
np.savez_compressed(ROOT + '/design/model_sheets/aruun/fidelity/head_v6/depth/v2side_crop_depth.npz', depth=d.astype(np.float32), mask=a, x0=x0, y0=y0, ax=AX, ppm=PPM)
v = (255 * (d - d.min()) / (d.max() - d.min())).astype(np.uint8); Image.fromarray(v).save(ROOT + '/design/model_sheets/aruun/fidelity/head_v6/depth/v2side_crop_depth.png'); c.save('/tmp/claude-0/w/v2side_crop_rgb.png')
print(d.min(), d.max())
