import sys, os
import numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common import splat
def board(V, T, out, views=(0, 45, 90, 180), ppm=200, col=(0.75, 0.7, 0.65)):
    tiles = [splat.render([(V, T, col)], v, ppm=ppm, height=2.5, width=1.3) for v in views]
    W = sum(t.width for t in tiles); im = Image.new("RGBA", (W, tiles[0].height), (236, 228, 214, 255)); x = 0
    for t in tiles: im.alpha_composite(t, (x, 0)); x += t.width
    im.convert("RGB").save(out); return out
if __name__ == "__main__":
    W = os.path.join(HERE, "..", "work", "v2")
    o = np.load(W + "/old.npz", allow_pickle=True); f = np.load(W + "/fit.npz")
    board(f["V"], o["T"], "/tmp/claude-0/s/fit_view.png")
