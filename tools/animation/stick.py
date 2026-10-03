"""Stick-figure strips of BVH clips (source-motion browsing / segment picking).
python3 stick.py out.png file.bvh[:start:end] ... [--step 0.25] [--view side|front]"""
import sys
import numpy as np
from PIL import Image, ImageDraw
from bvh import BVH


def strip(path, t0=0.0, t1=None, step=0.25, view="side", cell=110, label=""):
    b = BVH(path)
    n = len(b.data)
    f0 = max(1, int(t0 * b.fps))
    f1 = n if t1 is None else min(n, int(t1 * b.fps))
    frames = np.arange(f0, f1, max(1, int(step * b.fps)))
    _, P = b.fk(frames, scale=0.057)
    cols = len(frames)
    img = Image.new("RGB", (cols * cell, cell + 14), (250, 250, 245))
    d = ImageDraw.Draw(img)
    d.text((2, 0), label or path.split("/")[-1], fill=(0, 0, 0))
    ax = (1, 2) if view == "side" else (0, 2)
    sgn = -1 if view == "side" else 1
    for k, f in enumerate(frames):
        root = P[k, 0]
        ox = k * cell + cell / 2
        oy = cell + 10
        s = cell / 2.2

        def xy(p):
            q = p - root
            return ox + sgn * q[ax[0]] * s, oy - p[2] * s
        for j, par in enumerate(b.parent):
            if par < 0:
                continue
            nm = b.names[j]
            c = (200, 40, 40) if nm.startswith("Left") or nm.startswith("L") else (40, 40, 200) if nm.startswith(("Right", "R")) else (0, 0, 0)
            d.line([xy(P[k, par]), xy(P[k, j])], fill=c, width=2)
        d.line([(ox - cell / 2, oy), (ox + cell / 2, oy)], fill=(150, 150, 150))
        d.text((ox - cell / 2 + 2, 12), "%.2f" % (f / b.fps), fill=(90, 90, 90))
    return img


if __name__ == "__main__":
    out = sys.argv[1]
    step, view = 0.25, "side"
    items = []
    a = sys.argv[2:]
    i = 0
    while i < len(a):
        if a[i] == "--step":
            step = float(a[i + 1]); i += 2; continue
        if a[i] == "--view":
            view = a[i + 1]; i += 2; continue
        items.append(a[i]); i += 1
    ims = []
    for it in items:
        p = it.split(":")
        ims.append(strip(p[0], float(p[1]) if len(p) > 1 else 0, float(p[2]) if len(p) > 2 else None, step, view))
    W = max(i.width for i in ims)
    H = sum(i.height for i in ims)
    o = Image.new("RGB", (W, H), (255, 255, 255))
    y = 0
    for im in ims:
        o.paste(im, (0, y)); y += im.height
    o.save(out)
