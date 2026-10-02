#!/usr/bin/env python3
"""Force texture import flags for 3D art (mipmaps on, lossless) after Godot generated the .import files.
Run after the first import (tools/validate.sh) and re-run the import: python3 tools/art_pipeline/set_imports.py
"""
import glob
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MIP_GLOBS = ["game/art/characters/*/*.png.import", "game/art/world/*.png.import", "game/art/vfx/*.png.import",
             "game/art/creatures/*.png.import"]

n = 0
for g in MIP_GLOBS:
    for f in glob.glob(os.path.join(ROOT, g)):
        s = open(f).read()
        s2 = s.replace("mipmaps/generate=false", "mipmaps/generate=true")
        s2 = re.sub(r"detect_3d/compress_to=\d", "detect_3d/compress_to=0", s2)
        if s2 != s:
            open(f, "w").write(s2)
            n += 1
print("updated", n, "import files")
