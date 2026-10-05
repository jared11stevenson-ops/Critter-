"""Debug: render views side by side with a 5% height grid to read landmark rows. usage: gridview.py out.png img1 img2 ..."""
import sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from common import *
out, files = sys.argv[1], sys.argv[2:]
H = 1000; ims = []
for f in files:
    im = Image.open(f).convert("RGBA"); im = trim(im)
    w = int(im.width * H / im.height); ims.append(im.resize((w, H), Image.LANCZOS))
W = sum(i.width for i in ims) + 60 * len(ims) + 20
c = Image.new("RGB", (W, H + 20), (232, 223, 204)); d = ImageDraw.Draw(c); x = 20
for im in ims:
    c.paste(im, (x, 10), im)
    for k in range(0, 101, 5):
        y = 10 + int(H * k / 100); d.line((x - 15, y, x + im.width, y), fill=(200, 0, 0) if k % 10 == 0 else (0, 120, 200), width=1)
        d.text((x + im.width + 2, y - 5), str(k), fill=(0, 0, 0), font=font(10))
    x += im.width + 60
c.save(out)
