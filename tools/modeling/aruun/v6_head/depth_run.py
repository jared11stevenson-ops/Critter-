"""Depth Anything V2 SMALL (Apache-2.0) relative depth on head references. usage: depth_run.py OUTDIR img..."""
import sys, os, numpy as np, torch
from PIL import Image
from transformers import AutoImageProcessor, AutoModelForDepthEstimation
P = "depth-anything/Depth-Anything-V2-Small-hf"
proc = AutoImageProcessor.from_pretrained(P); m = AutoModelForDepthEstimation.from_pretrained(P).eval()
out = sys.argv[1]
for f in sys.argv[2:]:
    im = Image.open(f).convert('RGB')
    with torch.no_grad():
        x = proc(images=im, return_tensors='pt', size={'height':770,'width':770}) if False else proc(images=im, return_tensors='pt')
        d = m(**x).predicted_depth
        d = torch.nn.functional.interpolate(d[None], size=im.size[::-1], mode='bicubic')[0,0].numpy()
    n = os.path.splitext(os.path.basename(f))[0]
    np.save(f'{out}/{n}_depth.npy', d.astype(np.float32))
    v = (255*(d-d.min())/(d.max()-d.min()+1e-9)).astype(np.uint8)
    Image.fromarray(v).save(f'{out}/{n}_depth.png'); print(n, d.min(), d.max())
