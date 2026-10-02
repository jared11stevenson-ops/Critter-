#!/usr/bin/env python3
"""Cut character billboard sprites from the approved model sheets.

Usage: python3 tools/art_pipeline/cut_sprites.py [character_id ...] [--preview out.png]
Writes game/art/characters/<id>/{front,side,back}.png + meta.json.
Requires: pillow numpy scipy rembg onnxruntime (isnet-anime model auto-downloads to ~/.rembg).
"""
import json
import os
import sys
from PIL import Image, ImageOps

sys.path.insert(0, os.path.dirname(__file__))
import matte  # noqa: E402

ROOT = matte.ROOT
OUT = os.path.join(ROOT, "game", "art", "characters")


def canon():
    with open(os.path.join(ROOT, "game", "canon", "canon.json")) as f:
        return json.load(f)["characters"]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    preview = None
    if "--preview" in sys.argv:
        preview = sys.argv[sys.argv.index("--preview") + 1]
        args = [a for a in args if a != preview]
    with open(os.path.join(os.path.dirname(__file__), "sprite_boxes.json")) as f:
        table = json.load(f)
    cn = canon()
    ids = args or [k for k in table if not k.startswith("_")]
    previews, labels = [], []
    for cid in ids:
        spec = table[cid]
        sh = matte.sheet(spec["sheet"])
        if "bg_sample" in spec:
            import numpy as np
            bx, by = spec["bg_sample"]
            bgc = np.median(np.asarray(sh.crop((bx - 3, by - 3, bx + 4, by + 4))).reshape(-1, 3), axis=0).tolist()
        else:
            bgc = None
        odir = os.path.join(OUT, cid)
        os.makedirs(odir, exist_ok=True)
        views = []
        sizes = {}
        for view in ("front", "side", "back"):
            v = spec["views"].get(view)
            if not v:
                continue
            kw = {k: v[k] for k in ("exclude", "include", "flood_thr", "join_dist", "min_frac", "use_flood",
                                     "alpha_lo", "alpha_hi", "seed", "erode", "fill_holes_max", "flood_regions", "hole_regions", "method", "pocket_k", "pocket_min", "bg", "dark_regions", "dark_color", "dark_thr") if k in v}
            box = v["box"]
            if bgc is not None and "bg" not in kw:
                kw["bg"] = bgc
            im = matte.cut(sh, box, **kw)
            used = im.info.get("method", "?")
            ax = v.get("anchor_x")
            im = matte.trim_pad(im, pad=4, bottom_pad=0, anchor_x=None if ax is None else ax - box[0])
            if v.get("flip"):
                im = ImageOps.mirror(im)
            im.save(os.path.join(odir, view + ".png"), optimize=True)
            views.append(view)
            sizes[view] = list(im.size)
            previews.append(im)
            labels.append("%s/%s %dx%d" % (cid, view, im.width, im.height))
            print("cut", cid, view, im.size, used)
        meta = {"height_m": cn.get(cid, {}).get("height_m", 1.8), "views": views, "px": sizes,
                "feet_y_px": sizes["front"][1] if "front" in sizes else None,
                "source": {k: spec["views"][k].get("source", "") for k in views}, "sheet": spec["sheet"]}
        with open(os.path.join(odir, "meta.json"), "w") as f:
            json.dump(meta, f, indent=1)
    if preview:
        matte.composite_preview(previews, labels, cell_h=300).save(preview)
        print("preview", preview)


if __name__ == "__main__":
    main()
