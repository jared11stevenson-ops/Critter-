"""eyes, sockets, nostrils, mandible, tines, fringe cards, horn cups for head v7."""
import math, bpy, bmesh
from mathutils import Vector

PARENT = {}
def make(cage, LM, B):
    FX, UY, SX, UFY, FA = B.FX, B.UY, B.SX, B.UFY, B.FA
    out = []
    # ---- eyes / sockets (side-projected so they sit on the cheek, facing out like the side ref) ----
    sock = [(612,590),(630,577),(660,578),(684,600),(686,622),(665,634),(635,630),(615,612)]
    eye = [(628,600),(640,587),(656,588),(669,611),(660,623),(644,622)]
    pup = [(649,597),(656,598),(659,606),(655,613),(648,612),(645,604)]
    for nm, poly, lift, th, col in (('socket', sock, 0.003, 0.007, (0.04,0.04,0.05)), ('eye', eye, 0.0075, 0.004, (0.95,0.74,0.18)), ('pupil', pup, 0.0105, 0.003, (0.05,0.03,0.02))):
        P = [(FX(x), UY(y)) for x, y in poly]
        out.append(B.plate(nm + '_R', P, cage, 'side', lift, th, col))
        out.append(B.plate(nm + '_L', P, cage, 'side', lift, th, col, mirror_s=True))
    # ---- nostrils (front-projected small dark slots) ----
    for i, (x, y) in enumerate(LM['nostril_front_px']):
        sg = -1 if i == 0 else 1; u = UFY(y); cx = sg * 0.014
        P = [(cx + dx, u + dy) for dx, dy in ((-0.004, 0.010), (0.004, 0.010), (0.004, -0.010), (-0.004, -0.010))]
        out.append(B.plate('nostril_%s' % ('R' if i == 0 else 'L'), P, cage, 'front', 0.006, 0.004, (0.03, 0.03, 0.04)))
    # ---- mandible ----
    mr = LM['mandible']['rings']
    bm = B.loft(mr); mc = B.Cage(bm)
    piv = (0.03, 2.03, 0.0)
    m = B.new_obj('mandible', bm, (0.07, 0.07, 0.10)); B.recalc(m)
    P0 = B.W(piv)
    for v in m.data.vertices: v.co -= P0
    m.location = P0; out.append(m)
    hook = [(700,722),(760,727),(812,737),(846,742),(837,758),(800,767),(750,761),(700,746)]
    for nm, mir in (('plate_jaw_hook_R', False), ('plate_jaw_hook_L', True)):
        o = B.plate(nm, [(FX(x), UY(y)) for x, y in hook], mc, 'side', 0.005, 0.008, (0.56,0.18,0.12), mirror_s=mir)
        out.append(o); PARENT[o.name] = 'mandible'
    lip = [(715,740),(760,744),(800,752),(790,762),(750,760),(715,752)]
    out.append(B.plate('plate_jaw_cream', [(FX(x), UY(y)) for x, y in [(520,738),(600,742),(660,744),(700,742),(700,752),(640,756),(560,754)]], mc, 'side', 0.004, 0.006, (0.65,0.45,0.30)))
    PARENT[out[-1].name] = 'mandible'
    # ---- tines ----
    for t in LM['tines']:
        for sg, nm in ((-1, 'tine_R' if t['radius'] > 0.01 else 'tine2_R'), (1, 'tine_L' if t['radius'] > 0.01 else 'tine2_L')):
            pts = [(FX(t['base_px'][0]), UY(t['base_px'][1]), sg * t['s_base']), (FX(t['tip_px'][0]), UY(t['tip_px'][1]), sg * t['s_tip'])]
            bm = tube(pts, [t['radius'], 0.0015], 5, B, inset=0.012)
            o = B.new_obj(nm, bm, (0.82, 0.74, 0.55)); B.recalc(o); out.append(o)
    # ---- horn cups ----
    for hc in LM['horn_cups']:
        c = Vector((hc['F'], hc['U'], hc['s']))
        a = Vector((0.0, 1.0, 0.25 if hc['s'] > 0 else -0.25)).normalized()
        pts = [tuple(c - a * 0.016), tuple(c + a * 0.012)]
        bm = tube(pts, [hc['r'] * 1.15, hc['r'] * 0.85], 8, B, inset=0.0)
        o = B.new_obj(hc['name'], bm, (0.50, 0.16, 0.10)); B.recalc(o); out.append(o)
    # ---- fringe cards ----
    olive = (0.40, 0.38, 0.18); cream = (0.80, 0.70, 0.45)
    strands = [  # (name, pts(F,U,s), widths, color)
        ('fringe_nape_a', [(-0.015, 2.105, 0.0), (-0.060, 2.085, 0.0), (-0.115, 2.035, 0.0), (-0.150, 1.985, 0.0)], [0.026, 0.020, 0.012, 0.003], olive),
        ('fringe_nape_b', [(-0.010, 2.110, 0.040), (-0.055, 2.095, 0.065), (-0.100, 2.050, 0.085), (-0.125, 2.000, 0.090)], [0.022, 0.017, 0.010, 0.003], cream),
        ('fringe_nape_c', [(-0.010, 2.110, -0.040), (-0.055, 2.095, -0.065), (-0.100, 2.050, -0.085), (-0.125, 2.000, -0.090)], [0.022, 0.017, 0.010, 0.003], cream),
        ('fringe_cheek_R', [(-0.030, 2.098, -0.100), (-0.036, 2.060, -0.106), (-0.042, 2.020, -0.104), (-0.046, 1.990, -0.098)], [0.020, 0.018, 0.012, 0.003], olive),
        ('fringe_cheek_L', [(-0.030, 2.098, 0.100), (-0.036, 2.060, 0.106), (-0.042, 2.020, 0.104), (-0.046, 1.990, 0.098)], [0.020, 0.018, 0.012, 0.003], olive),
    ]
    for nm, pts, wd, col in strands:
        bm = strip(pts, wd, B)
        o = B.new_obj(nm, bm, col); B.solid(o, 0.003, 0.0006); out.append(o)
    return out

def tube(pts, radii, n, B, inset=0.0):
    """tapered n-gon tube along pts [(F,U,s)...]; first ring pushed `inset` back along the axis (rooted)."""
    import math
    bm = bmesh.new(); P = [Vector(p) for p in pts]; rings = []
    ax0 = (P[-1] - P[0]).normalized()
    P[0] = P[0] - ax0 * inset
    for i, p in enumerate(P):
        ax = (P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized()
        u = ax.cross(Vector((0, 1, 0)))
        if u.length < 1e-3: u = ax.cross(Vector((1, 0, 0)))
        u.normalize(); v = ax.cross(u).normalized()
        rings.append([bm.verts.new(p + (u * math.cos(2 * math.pi * k / n) + v * math.sin(2 * math.pi * k / n)) * radii[i]) for k in range(n)])
    for a, b in zip(rings[:-1], rings[1:]):
        for k in range(n): bm.faces.new((a[k], a[(k + 1) % n], b[(k + 1) % n], b[k]))
    bm.faces.new(rings[0][::-1]); bm.faces.new(rings[-1])
    return bm

def strip(pts, widths, B):
    bm = bmesh.new(); P = [Vector(p) for p in pts]; rows = []
    for i, p in enumerate(P):
        t = (P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized()
        sg = 1 if p[2] >= 0 else -1
        side = t.cross(Vector((0, 0.5, sg * 0.85)).normalized())  # card faces up/outward
        if abs(side.length) < 1e-3: side = Vector((1, 0, 0))
        side.normalize()
        rows.append((bm.verts.new(p - side * widths[i] / 2), bm.verts.new(p + side * widths[i] / 2)))
    for a, b in zip(rows[:-1], rows[1:]): bm.faces.new((a[0], a[1], b[1], b[0]))
    return bm
