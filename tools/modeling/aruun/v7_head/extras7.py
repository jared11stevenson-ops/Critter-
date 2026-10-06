"""eyes, sockets, nostrils, mandible, tines, fringe cards, horn cups for head v7."""
import math, bpy, bmesh
from mathutils import Vector

PARENT = {}
def make(cage, LM, B):
    FX, UY, SX, UFY, FA = B.FX, B.UY, B.SX, B.UFY, B.FA
    out = []
    # ---- eye sockets (angular raised bowls) + almond eyes + pupils, axis 60 deg off forward ----
    for sg, side in ((-1, 'R'), (1, 'L')):
        for nm, parts, col in bowl_parts(cage, LM, B, sg): out.append(B.new_obj(nm + '_' + side, parts, col)); B.recalc(out[-1])
    # ---- nostrils (front-projected small dark slots) ----
    for i, (x, y) in enumerate(LM['nostril_front_px']):
        sg = -1 if i == 0 else 1; u = UFY(y); cx = sg * 0.014
        P = [(cx + dx, u + dy) for dx, dy in ((-0.004, 0.010), (0.004, 0.010), (0.004, -0.010), (-0.004, -0.010))]
        out.append(B.surf_plate('nostril_%s' % ('R' if i == 0 else 'L'), P, 5.0, 0.007, 0.004, (0.03, 0.03, 0.04), False, 0.03))
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
        a = Vector((0.0, 1.0, 0.1 if hc['s'] > 0 else -0.1)).normalized()
        pts = [tuple(c - a * 0.016), tuple(c + a * 0.012)]
        bm = tube(pts, [hc['r'] * 1.15, hc['r'] * 0.85], 8, B, inset=0.0)
        o = B.new_obj(hc['name'], bm, (0.50, 0.16, 0.10)); B.recalc(o); out.append(o)
    # ---- fringe cards ----
    olive = (0.40, 0.38, 0.18); cream = (0.80, 0.70, 0.45)
    strands = [  # (name, pts(F,U,s), widths, color)
        ('fringe_nape_a', [(-0.050, 2.090, 0.020), (-0.075, 2.070, 0.030), (-0.100, 2.045, 0.040)], [0.020, 0.016, 0.003], olive),
        ('fringe_wing_R', [(-0.005, 2.062, -0.060), (-0.045, 2.056, -0.092), (-0.080, 2.050, -0.110), (-0.108, 2.043, -0.120)], [0.026, 0.030, 0.020, 0.004], cream),
        ('fringe_wing_L', [(-0.005, 2.062, 0.060), (-0.045, 2.056, 0.092), (-0.080, 2.050, 0.110), (-0.108, 2.043, 0.120)], [0.026, 0.030, 0.020, 0.004], cream),
    ]
    strands += [
        ('fringe_flap_L', [(-0.030, 2.000, 0.070), (-0.045, 1.965, 0.105)], [0.040, 0.030], olive, (-1, 0, 0)),
        ('nape_mark', [(-0.062, 2.105, 0.0), (-0.062, 2.070, 0.0), (-0.062, 2.030, 0.0)], [0.020, 0.046, 0.008], (0.62, 0.45, 0.22), (-1, 0, 0)),
    ]
    for st in strands:
        nm, pts, wd, col = st[:4]
        bm = strip(pts, wd, B, st[4] if len(st) > 4 else None)
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

def strip(pts, widths, B, nrm=None):
    bm = bmesh.new(); P = [Vector(p) for p in pts]; rows = []
    for i, p in enumerate(P):
        t = (P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized()
        sg = 1 if p[2] >= 0 else -1
        side = t.cross(Vector(nrm).normalized() if nrm else Vector((0, 0.5, sg * 0.85)).normalized())  # card faces up/outward
        if abs(side.length) < 1e-3: side = Vector((1, 0, 0))
        side.normalize()
        rows.append((bm.verts.new(p - side * widths[i] / 2), bm.verts.new(p + side * widths[i] / 2)))
    for a, b in zip(rows[:-1], rows[1:]): bm.faces.new((a[0], a[1], b[1], b[0]))
    return bm

import math
def _basis(a):
    up = Vector((0, 1, 0)); w = a.cross(up).normalized(); u = w.cross(a).normalized(); return w, u
def ring_loft(rings, caps=True):
    bm = bmesh.new(); rs = [[bm.verts.new(p) for p in r] for r in rings]; n = len(rs[0])
    for a, b in zip(rs[:-1], rs[1:]):
        for i in range(n): bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
    if caps: bm.faces.new(rs[0][::-1]); bm.faces.new(rs[-1])
    return bm
def bowl_parts(cage, LM, B, sg):
    ex = LM['eyes']; cx, cy = ex['center_px']
    Fw, Uw = B.FX(cx), B.UY(cy)
    p, n = cage.hit((Fw, Uw, -1.0), (0, 0, 1))      # surface point on the right side
    C = Vector(p)
    az = math.radians(ex['azimuth_deg'])
    a = Vector((math.cos(az), 0.0, -math.sin(az))).normalized()   # outward axis (right side)
    w, u = _basis(a)
    def ring(r_w, r_u, d, nn=10, rot=0.0):
        pts = []
        for i in range(nn):
            ang = 2 * math.pi * i / nn + rot
            pts.append(tuple(C + a * d + w * (r_w * math.cos(ang)) + u * (r_u * math.sin(ang))))
        return pts
    # socket: outer skirt (r .034, d -.004), rim (r .031, d .012), floor (r .022, d .004)
    soc = ring_loft([ring(0.036, 0.030, -0.006), ring(0.033, 0.027, 0.012), ring(0.023, 0.018, 0.004)])
    # almond eye: 8 pts in (w,u), tilt
    tilt = math.radians(ex['tilt_deg']); L, H = ex['size_m']
    base = [(-0.5, 0.0), (-0.25, 0.42), (0.15, 0.5), (0.5, 0.05), (0.3, -0.42), (-0.15, -0.5)]
    def almond(d, k=1.0):
        pts = []
        for x, y in base:
            x, y = x * L * k, y * H * 2 * k
            xr = x * math.cos(tilt) - y * math.sin(tilt); yr = x * math.sin(tilt) + y * math.cos(tilt)
            pts.append(tuple(C + a * d + w * xr + u * yr))
        return pts
    eye = ring_loft([almond(0.0050), almond(0.0085, 0.96)])
    pw = 0.0055
    def pup(d):
        return [tuple(C + a * d + w * (0.002 + pw * math.cos(2 * math.pi * i / 8)) + u * (pw * math.sin(2 * math.pi * i / 8))) for i in range(8)]
    pupil = ring_loft([pup(0.0075), pup(0.0100)])
    res = []
    for nm, bm, col in (('socket', soc, (0.04, 0.04, 0.05)), ('eye', eye, (0.95, 0.74, 0.18)), ('pupil', pupil, (0.06, 0.04, 0.02))):
        if sg > 0:
            for v in bm.verts: v.co.z = -v.co.z
            bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
        res.append((nm, bm, col))
    return res
