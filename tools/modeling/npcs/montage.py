#!/usr/bin/env python3
"""python3 montage.py out.png in1.png in2.png ...  -> horizontal contact sheet (each scaled to height 420)."""
import sys
from PIL import Image
ims = [Image.open(p).convert("RGB") for p in sys.argv[2:]]
ims = [i.resize((int(i.width * 420 / i.height), 420)) for i in ims]
out = Image.new("RGB", (sum(i.width for i in ims), 420))
x = 0
for i in ims:
    out.paste(i, (x, 0)); x += i.width
out.save(sys.argv[1])
