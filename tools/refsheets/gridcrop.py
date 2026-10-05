"""Debug: gridcrop.py img x0 y0 x1 y1 out [scale] -> crop with labelled pixel grid (source coords) to read panel boxes."""
import sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from common import *
f, x0, y0, x1, y1, out = sys.argv[1], *map(int, sys.argv[2:6]), sys.argv[6]
s = float(sys.argv[7]) if len(sys.argv) > 7 else 2
step = 20
im = Image.open(f).convert("RGB").crop((x0, y0, x1, y1)); c = im.resize((int(im.width * s), int(im.height * s)), Image.LANCZOS); d = ImageDraw.Draw(c)
for x in range((x0 // step + 1) * step, x1, step):
    d.line(((x - x0) * s, 0, (x - x0) * s, c.height), fill=(255, 0, 0) if x % 100 == 0 else (0, 150, 255)); d.text(((x - x0) * s + 2, 2), str(x), fill=(255, 0, 0))
for y in range((y0 // step + 1) * step, y1, step):
    d.line((0, (y - y0) * s, c.width, (y - y0) * s), fill=(255, 0, 0) if y % 100 == 0 else (0, 150, 255)); d.text((2, (y - y0) * s + 2), str(y), fill=(255, 0, 0))
c.save(out)
