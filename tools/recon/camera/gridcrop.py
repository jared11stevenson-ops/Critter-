#!/usr/bin/env python3
"""gridcrop.py IMG x0 y0 x1 y1 OUT [scale] [step] : crop (orig px) with labelled grid, composited on mid-gray where transparent."""
import sys, numpy as np, cv2
from PIL import Image
img, x0, y0, x1, y1, out = sys.argv[1], *map(int, sys.argv[2:6]), sys.argv[6]
sc = float(sys.argv[7]) if len(sys.argv) > 7 else 1.0; step = int(sys.argv[8]) if len(sys.argv) > 8 else 100
a = np.asarray(Image.open(img).convert('RGBA')).astype(float)
bg = np.full(a.shape[:3], 90.0); rgb = a[..., :3] * (a[..., 3:] / 255) + bg[..., :3] * (1 - a[..., 3:] / 255)
c = cv2.cvtColor(rgb[y0:y1, x0:x1].astype(np.uint8), cv2.COLOR_RGB2BGR)
c = cv2.resize(c, None, fx=sc, fy=sc, interpolation=cv2.INTER_CUBIC)
for x in range((x0 // step + 1) * step, x1, step):
    X = int((x - x0) * sc); cv2.line(c, (X, 0), (X, c.shape[0]), (0, 255, 255), 1); cv2.putText(c, str(x), (X + 2, 14), 0, 0.45, (0, 255, 255), 1)
for y in range((y0 // step + 1) * step, y1, step):
    Y = int((y - y0) * sc); cv2.line(c, (0, Y), (c.shape[1], Y), (0, 255, 255), 1); cv2.putText(c, str(y), (2, Y - 3), 0, 0.45, (0, 255, 255), 1)
cv2.imwrite(out, c)
