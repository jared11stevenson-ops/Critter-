#!/usr/bin/env python3
"""Download (if needed) and trim the CMU BVH clips used by the character configs into tools/animation/mocap/cmu/.

    python3 tools/animation/trim_mocap.py aruun [cigarra ...]

Raw files come from the CMU Graphics Lab Motion Capture Database, cgspeed BVH conversion, mirrored at
https://github.com/una-dinosauria/cmu-mocap (data/NNN/NN_NN.bvh). Each trimmed file keeps the T-pose frame 0 plus the
used window +-0.5 s resampled to 60 fps; manifest.json records the original time of trimmed frame 1 ("offset").
"""
import importlib
import json
import os
import sys
import urllib.request

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lib  # noqa: E402
import retarget as rt  # noqa: E402
from bvh import BVH  # noqa: E402

URL = "https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/%03d/%s.bvh"


def raw_path(clip):
    p = os.path.join(lib.RAW, "%03d" % int(clip.split("_")[0]), clip + ".bvh")
    if not os.path.exists(p):
        os.makedirs(os.path.dirname(p), exist_ok=True)
        print("download", clip)
        urllib.request.urlretrieve(URL % (int(clip.split("_")[0]), clip), p)
    return p


def main(chars):
    out_dir = os.path.join(lib.MOCAP, "cmu")
    os.makedirs(out_dir, exist_ok=True)
    # build from RAW so windows are on the original timelines
    if os.path.exists(lib.MANIFEST):
        os.rename(lib.MANIFEST, lib.MANIFEST + ".old")
    try:
        for c in chars:
            cfg = importlib.import_module("characters." + c)
            sk = rt.Skeleton(json.load(open(os.path.join(HERE, "characters", c + "_skeleton.json"))))
            for name in cfg.CLIPS:
                cfg.build(name, sk)
    finally:
        if os.path.exists(lib.MANIFEST + ".old"):
            os.rename(lib.MANIFEST + ".old", lib.MANIFEST)
    man = {}
    for clip, (a, b) in sorted(lib.USED.items()):
        p = raw_path(clip)
        bv = BVH(p)
        a, b = max(0.0, a - 0.5), b + 0.5
        times = a + np.arange(int((b - a) * 60) + 1) / 60.0
        fr = np.clip(np.round(times * bv.fps).astype(int), 1, len(bv.data) - 1)
        out = object.__new__(BVH)
        out.__dict__.update(bv.__dict__)
        out.dt = 1.0 / 60
        frames = np.concatenate([[0], fr])
        out.write(os.path.join(out_dir, clip + ".bvh"), frames, p)
        man[clip] = {"offset": round(a, 4), "source": URL % (int(clip.split("_")[0]), clip), "window": [round(a, 3), round(b, 3)]}
        print("%-8s %.2f-%.2f s (%d frames)" % (clip, a, b, len(frames)))
    json.dump(man, open(lib.MANIFEST, "w"), indent=1)


if __name__ == "__main__":
    main(sys.argv[1:] or ["aruun"])
