"""aruun_zoom.py view y0 y1 [x0 x1] out : crop of aligned ortho view with a labelled fraction grid (fractions of the 4096-row view / its width)."""
import sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from common import *
v, y0, y1 = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]); x0, x1 = float(sys.argv[4]), float(sys.argv[5]); out = sys.argv[6]
im = Image.open(f"{PACKS}/aruun/ortho/aruun_{v}_4096.png").convert("RGBA"); W, H = im.size
box = (int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H)); c = im.crop(box); bg = Image.new("RGBA", c.size, (232, 223, 204, 255)); bg.alpha_composite(c); c = bg.convert("RGB")
s = 1300 / max(c.size); c = c.resize((int(c.width * s), int(c.height * s)), Image.LANCZOS); d = ImageDraw.Draw(c)
for k in range(int(x0 * 20) + 1, int(x1 * 20) + 1):
    x = (k / 20 - x0) * W * s; d.line((x, 0, x, c.height), fill=(0, 140, 255)); d.text((x + 2, 2), f"{k/20:.2f}", fill=(0, 0, 200))
for k in range(int(y0 * 40) + 1, int(y1 * 40) + 1):
    y = (k / 40 - y0) * H * s; d.line((0, y, c.width, y), fill=(255, 0, 0)); d.text((2, y + 1), f"{k/40:.3f}", fill=(200, 0, 0))
c.save(out)
