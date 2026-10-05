"""Debug: fracgrid.py out.png img... -> trimmed views side by side, each with its OWN 0..1 fraction grid (x every 0.1, y every 0.05) so detail boxes can be read directly as fractions."""
import sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from common import *
out, files = sys.argv[1], sys.argv[2:]
H = 1100; ims = []
for f in files:
    im = trim(Image.open(f).convert("RGBA")); w = int(im.width * H / im.height); ims.append(im.resize((w, H), Image.LANCZOS))
W = sum(i.width for i in ims) + 50 * len(ims) + 30
c = Image.new("RGB", (W, H + 40), (232, 223, 204)); d = ImageDraw.Draw(c); x = 20
for im in ims:
    c.paste(im, (x, 30), im)
    for k in range(0, 11):
        xx = x + im.width * k / 10; d.line((xx, 30, xx, 30 + H), fill=(0, 150, 255), width=1); d.text((xx + 2, 14), f"{k/10:.1f}", fill=(0, 0, 200), font=font(12))
    for k in range(0, 21):
        yy = 30 + H * k / 20; d.line((x, yy, x + im.width, yy), fill=(255, 0, 0) if k % 2 == 0 else (255, 160, 160), width=1)
        if k % 2 == 0: d.text((x + 2, yy + 1), f"{k/20:.2f}", fill=(200, 0, 0), font=font(12))
    x += im.width + 50
c.save(out)
