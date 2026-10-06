"""Head FEATURES on top of the visual hull (all separate objects, positions read off the v2 side/back head crops; F,U,L metres; head centre line L=HL).
eye sockets + large eyes on the SIDES, heavy angled brow ridges, nose pad + nostrils, ANGULAR cheek plates (extruded polygons), stepped red crown plates,
horn cups at the horn roots, curved temple tines. The jaw (mandible with pivot) is split from the hull in head_hull.build_hull(split_jaw=True)."""
import os, sys, json, numpy as np
import bpy
import head_hull as HH
import build_forms as BF
from build_forms import tube, ell, nm, FW, UP, LF, HL

def to_bl(F, U, L): return (L, -F, U)

def prism(name, poly_FU, off_fn, thick, side):
    """flat angular plate: polygon in the (F,U) plane, placed on the lateral surface at L = HL + side*off_fn(F), extruded `thick` outward."""
    n = len(poly_FU); V = []
    for (f, u) in poly_FU: V.append(to_bl(f, u, HL + side * (off_fn(f, u, side) - thick * 0.5)))
    for (f, u) in poly_FU: V.append(to_bl(f, u, HL + side * (off_fn(f, u, side) + thick * 0.5)))
    F = [list(range(n))[::-1] if side > 0 else list(range(n)), [n + i for i in range(n)] if side > 0 else [n + i for i in range(n)][::-1]]
    for i in range(n):
        j = (i + 1) % n; F.append([i, j, n + j, n + i] if side > 0 else [j, i, n + i, n + j])
    me = bpy.data.meshes.new(name); me.from_pydata(V, [], F); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob); return ob

def surf(f, u=2.07, side=1):   # lateral hull surface offset at (F,U) read from the actual head hull
    return HH.surface_offset(f, u, side)

def build(parts):
    add = []
    for s, n in ((1, 'L'), (-1, 'R')):
        so = surf(0.07, 2.087, s) - 0.010
        add.append(nm(ell('eye_socket_' + n, (0.070, 2.087, HL + s * so), (0.030, 0.024, 0.010)), 'eye_socket_' + n))
        add.append(nm(ell('eyeball_' + n, (0.072, 2.087, HL + s * (so + 0.012)), (0.021, 0.017, 0.016)), 'eyeball_' + n))
        add.append(nm(tube('brow_' + n, [(0.010, 2.110, HL + s * (surf(0.01, 2.10, s) - 0.002)), (0.045, 2.118, HL + s * (surf(0.045, 2.10, s) - 0.002)), (0.085, 2.112, HL + s * (surf(0.085, 2.09, s) - 0.002)), (0.125, 2.072, HL + s * (surf(0.125, 2.06, s) - 0.002))],
                       [(0.012, 0.016), (0.015, 0.017), (0.014, 0.015), (0.008, 0.010)], hint=UP), 'brow_' + n))
        add.append(nm(prism('cheek_plate_' + n, [(0.012, 2.062), (0.048, 2.072), (0.098, 2.040), (0.092, 2.012), (0.046, 1.990), (0.012, 2.004)], surf, 0.008, s), 'cheek_plate_' + n))
        add.append(nm(prism('cheek_plate2_' + n, [(0.030, 2.000), (0.085, 2.015), (0.075, 1.975), (0.035, 1.968)], surf, 0.008, s), 'cheek_plate2_' + n))
    # nose pad at the end of the upper muzzle + nostrils
    add.append(nm(ell('nose_pad', (0.143, 2.082, HL), (0.020, 0.017, 0.022)), 'nose_pad'))
    for s, n in ((1, 'L'), (-1, 'R')): add.append(nm(ell('nostril_' + n, (0.158, 2.080, HL + s * 0.010), (0.007, 0.006, 0.006)), 'nostril_' + n))
    # stepped red crown plates (three slabs stepping up and inward)
    for i, (f, u, rf, rl) in enumerate(((0.015, 2.122, 0.080, 0.095), (0.035, 2.130, 0.058, 0.070), (0.050, 2.137, 0.036, 0.046))):
        add.append(nm(ell('crown_plate%d' % (i + 1), (f, u, HL), (rf, 0.008, rl)), 'crown_plate%d' % (i + 1)))
    # horn cups: sleeves around the horn roots, read from the extracted curves
    C = json.load(open(os.environ.get('HORN_CURVES', os.path.join(BF.P.ROOT, 'design/model_sheets/aruun/fidelity/forms/horn_curves.json'))))
    for n in ('A', 'B'):
        p = np.array(C[n]['points_FUL']); r = np.array(C[n]['radii_FL'])
        add.append(nm(ell('horn_cup_' + n, tuple(p[2] + [0, 0.004, 0]), (r[2][0] + 0.014, 0.022, r[2][1] + 0.014)), 'horn_cup_' + n))
    # curved temple tines (outward and down; left long, right short as in the back crop)
    add.append(nm(tube('temple_tine_L', [(0.000, 2.098, HL + 0.085), (-0.016, 2.100, HL + 0.105), (-0.035, 2.096, HL + 0.130), (-0.050, 2.090, HL + 0.155)],
                       [(0.018, 0.012), (0.014, 0.010), (0.010, 0.008), (0.003, 0.003)], hint=UP), 'temple_tine_L'))
    add.append(nm(tube('temple_tine_R', [(0.000, 2.100, HL - 0.085), (0.010, 2.108, HL - 0.115), (0.020, 2.116, HL - 0.145), (0.030, 2.124, HL - 0.168)],
                       [(0.016, 0.011), (0.012, 0.009), (0.009, 0.007), (0.003, 0.003)], hint=UP), 'temple_tine_R'))
    skip = [x for x in os.environ.get('FEAT_SKIP', '').split(',') if x]
    for o in list(add):
        if any(o.name.startswith(k) for k in skip): add.remove(o); bpy.data.objects.remove(o, do_unlink=True)
    parts.extend(add)
