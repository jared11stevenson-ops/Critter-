"""Build the Reaches world kit -> game/art/world/kit/*.glb  (python3 tools/modeling/world/build_reaches_kit.py [names...])"""
import os
import sys
import time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bpy
from kitlib import *
import pieces_rocks as R
try:
    import pieces_struct as S
except ImportError:
    S = None
try:
    import pieces_flora as F
except ImportError:
    F = None
try:
    import pieces_hub as H
except ImportError:
    H = None

OUT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "game", "art", "world", "kit"))

def registry():
    reg = {}
    reg["mesa_a"] = lambda: R.mesa("mesa_a", 11.0, 15.0, 3)
    reg["mesa_b"] = lambda: R.mesa("mesa_b", 10.0, 20.0, 8, layers=18, aspect=0.7)
    reg["mesa_c"] = lambda: R.mesa("mesa_c", 12.0, 9.0, 12, layers=11, aspect=1.3, taper=0.3)
    reg["butte_a"] = lambda: R.butte("butte_a", 5.5, 30.0, 21)
    reg["butte_b"] = lambda: R.butte("butte_b", 4.2, 22.0, 24, layers=8)
    reg["hoodoo_a"] = lambda: R.hoodoo("hoodoo_a", 1.6, 9.0, 31)
    reg["hoodoo_lo"] = lambda: R.hoodoo("hoodoo_lo", 1.5, 7.5, 33, N=10, n=4)
    reg["hoodoo_b"] = lambda: R.hoodoo("hoodoo_b", 1.3, 6.5, 32)
    reg["mesa_a_lo"] = lambda: R.mesa("mesa_a_lo", 11.0, 15.0, 3, layers=7, N=12)
    reg["mesa_b_lo"] = lambda: R.mesa("mesa_b_lo", 10.0, 20.0, 8, layers=8, aspect=0.7, N=12)
    reg["mesa_c_lo"] = lambda: R.mesa("mesa_c_lo", 12.0, 9.0, 12, layers=5, aspect=1.3, taper=0.3, N=12)
    reg["butte_a_lo"] = lambda: R.butte("butte_a_lo", 5.5, 30.0, 21, layers=5, N=12)
    reg["butte_b_lo"] = lambda: R.butte("butte_b_lo", 4.2, 22.0, 24, layers=4, N=12)
    reg["rock_arch"] = lambda: R.arch_rock("rock_arch", 4)
    reg["boulder_a"] = lambda: R.boulder("boulder_a", 1.2, 1.0, 0.9, 5, sub=3)
    reg["boulder_b"] = lambda: R.boulder("boulder_b", 0.9, 0.8, 1.3, 6, sub=3)
    reg["boulder_c"] = lambda: R.boulder("boulder_c", 1.4, 1.1, 0.6, 7, sub=3)
    reg["scree"] = lambda: R.scree("scree")
    reg["spoil_heap"] = lambda: R.spoil_heap("spoil_heap")
    reg["salt_crust"] = lambda: R.salt_crust("salt_crust")
    for mod in (S, F, H):
        if mod:
            reg.update(mod.registry())
    return reg

def main():
    names = sys.argv[1:] or None
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    reg = registry()
    tot = 0
    for n, fn in reg.items():
        if names and n not in names:
            continue
        t = time.time()
        km = fn()
        tri = export_piece(km, OUT, materials=getattr(km, "materials", ("kit",)))
        tot += tri
        print("%-18s %5d tris  %.1fs" % (n, tri, time.time() - t))
    print("total", tot)

main()
