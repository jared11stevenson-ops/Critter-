#!/usr/bin/env python3
"""Aruun HQ pipeline, stage 1: sculpt components -> high-poly meshes (work/hq/<name>.npz) + preview board.

  python3 tools/modeling/aruun/hq.py sculpt [name ...]   # (re)mesh all or some components
  python3 tools/modeling/aruun/hq.py preview             # splat board vs sheet -> qa/hq_preview.png
"""
import os
import sys
import time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, HERE)
from common import sdf2, splat  # noqa: E402

WORK = os.path.join(HERE, "work", "hq")
SHEET = os.path.join(ROOT, "design", "model_sheets", "aruun")
os.makedirs(WORK, exist_ok=True)

KIND_COL = {"skin": (0.22, 0.2, 0.26), "chitin": (0.62, 0.22, 0.16), "claw": (0.12, 0.1, 0.1),
            "bone": (0.85, 0.76, 0.6), "eye": (0.95, 0.8, 0.2), "horn": (0.6, 0.2, 0.14), "fringe": (0.8, 0.75, 0.45),
            "cloth": (0.75, 0.66, 0.5), "leaf": (0.55, 0.55, 0.3), "cloak": (0.3, 0.25, 0.2), "gold": (0.8, 0.6, 0.3),
            "morrow": (0.18, 0.16, 0.18), "stone": (0.8, 0.15, 0.12), "leather": (0.45, 0.2, 0.15)}
SHEET_CENTER = {"side": 0.25}     # metres from the cut-out's left edge to the world origin (foot centre)
NAME_COL = {"sternum": (0.85, 0.75, 0.6), "carapace": (0.45, 0.15, 0.12), "neckrings": (0.8, 0.35, 0.18)}


def sculpt(names=None):
    import sculpt as S
    C = S.components()
    for name, c in C.items():
        if names and name not in names:
            continue
        t = time.time()
        lo, hi = c["lo"], c["hi"]
        if lo is None:
            b = sdf2.auto_bounds(c["field"], (-0.6, -0.5, 0.0), (0.6, 0.5, 2.5), 0.02)
            if b is None:
                print("EMPTY", name)
                continue
            lo, hi = b
        v, f = sdf2.mesh(c["field"], lo, hi, c["step"])
        np.savez_compressed(os.path.join(WORK, name + ".npz"), V=v, F=f, kind=c["kind"], bind=c["bind"])
        print("%-18s %8d tris  %.1fs" % (name, len(f), time.time() - t), flush=True)


def load_all():
    out = {}
    for fn in sorted(os.listdir(WORK)):
        if fn.endswith(".npz"):
            d = np.load(os.path.join(WORK, fn))
            out[fn[:-4]] = (d["V"], d["F"], str(d["kind"]), str(d["bind"]))
    return out


def preview(out=None, ppm=260, extra=None, views=None):
    M = load_all()
    meshes = []
    for n, (v, f, kind, bind) in M.items():
        col = NAME_COL.get(n.split(".")[0], KIND_COL.get(kind, (0.5, 0.5, 0.5)))
        meshes.append((v, f, col))
    pairs = []
    files = {"front": "front_clean_x4.png", "side": "side_x4.png", "back": "back_x4.png"}
    for view in ("front", "side", "back"):
        r = splat.render(meshes, view, ppm=ppm)
        s = splat.sheet_view(os.path.join(SHEET, "hires", files[view]), ppm, center=SHEET_CENTER.get(view))
        pairs.append((view, s, r))
    r = splat.render(meshes, 35, ppm=ppm)
    pairs.append(("3/4", None, r))
    r2 = splat.render(meshes, -140, ppm=ppm)
    pairs.append(("back 3/4", None, r2))
    out = out or os.path.join(SHEET, "qa", "hq_preview.png")
    splat.board(pairs, out, ppm, "tris=%d" % sum(len(m[1]) for m in M.values()))
    for p in pairs[:3]:
        splat.board([p], out.replace(".png", "_%s.png" % p[0]), ppm, "")
    splat.board(pairs[3:], out.replace(".png", "_34.png"), ppm, "")
    print("wrote", out)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "sculpt"
    if cmd == "sculpt":
        sculpt(sys.argv[2:] or None)
    elif cmd == "preview":
        preview(ppm=int(sys.argv[2]) if len(sys.argv) > 2 else 400)
