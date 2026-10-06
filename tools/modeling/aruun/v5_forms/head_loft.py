"""P1c skull: ONE smooth subdivision-surface skull lofted from cross-sections measured from the v2 side and back masks (replaces the voxel hull).
Stations every 5 mm along F; at each station the SIDE mask gives the vertical run(s) (-> ring height/centre), the BACK mask gives the half-width at the ring centre row (clipped to the skull half-width,
tapered to a slim muzzle beyond the skull). Rings are super-ellipses; end rings close to apex points; Catmull-Clark subdivision rounds it. The lower jaw (mandible) is a second loft from the lower run
(below the mouth line, plus the beak), with its object origin at the jaw pivot. Lower rows blend into the neck cross-section (no collar seam).  Coordinates (F,U,L); head line L=HL."""
import os, sys, numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../fidelity'))
os.environ.setdefault('FID_REF', 'v2')
import bpy, mathutils
import fid_common as fc

HL = 0.09; U_BOT, U_TOP = 1.945, 2.135
SK_HALF = float(os.environ.get('LOFT_SK_HALF', '0.114')); NRING = 28; EXP = 2.5
MOUTH_U = 2.045; F_UPPER_END = 0.158
JAW_PIVOT = (0.06, 2.03, HL)
_C = {}

def _masks():
    if not _C:
        _C['s'] = fc.clean_mask(fc.load_ref_alpha('side')[..., 3]); _C['b'] = fc.clean_mask(fc.load_ref_alpha('back')[..., 3])
        _C['axs'] = fc.view_info('side')['axis_x_px']; _C['axb'] = fc.view_info('back')['axis_x_px']
    return _C

def runs_at(F):
    C = _masks(); col = int(round(C['axs'] + F * fc.PPM)); r0 = int(round(fc.GROUND - U_TOP * fc.PPM)); r1 = int(round(fc.GROUND - U_BOT * fc.PPM))
    ys = np.nonzero(C['s'][r0:r1 + 1, col])[0]
    if len(ys) == 0: return []
    out = []; st = pv = ys[0]
    for y in ys[1:]:
        if y != pv + 1: out.append((st, pv)); st = y
        pv = y
    out.append((st, pv))
    return [((fc.GROUND - (b + r0) / 1.0) / fc.PPM, (fc.GROUND - (a + r0)) / fc.PPM) for a, b in out if b - a > 6]   # (Ubottom, Utop) m

def half_width(U, F):
    C = _masks(); row = int(round(fc.GROUND - U * fc.PPM)); cols = np.nonzero(C['b'][row, :])[0]
    if len(cols) == 0: return 0.03, HL
    Lmin = -(cols[-1] - C['axb']) / fc.PPM; Lmax = -(cols[0] - C['axb']) / fc.PPM         # back image x -> L = -x
    Lmin, Lmax = max(Lmin, HL - SK_HALF - 0.02), min(Lmax, HL + SK_HALF + 0.02)          # clip fringe/tines out of the skull core
    hw = max(0.03, 0.5 * (Lmax - Lmin)); Lc = 0.5 * (Lmax + Lmin)
    if F > 0.06:
        t = float(np.interp(F, [0.06, 0.16, 0.20], [1.0, 0.36, 0.18])); hw *= t; Lc = HL + (Lc - HL) * t
    return hw, Lc

def station_data(which):
    """list of (F, Ubot, Utop) for 'skull' or 'jaw'"""
    out = []
    for F in np.arange(-0.125, 0.205, 0.005):
        rs = runs_at(F)
        if not rs: continue
        rs = sorted(rs, key=lambda r: -r[1])               # highest run first
        sk = jw = None
        if len(rs) >= 2: sk, jw = rs[0], rs[-1]
        else:
            ub, ut = rs[0]
            if F <= 0.095: sk = (ub, ut)
            elif ut < 2.055: jw = (ub, ut)
            else:
                if ut - max(ub, MOUTH_U) > 0.012: sk = (max(ub, MOUTH_U), ut)
                if min(ut, MOUTH_U) - ub > 0.008: jw = (ub, min(ut, MOUTH_U))
        if which == 'skull' and sk and F <= F_UPPER_END: out.append((F,) + sk)
        if which == 'jaw' and jw and F >= 0.09: out.append((F,) + jw)
    return out

def ring(F, ub, ut, tscale, neck_blend=True):
    Uc = 0.5 * (ub + ut); hu = 0.5 * (ut - ub); pts = []
    for k in range(NRING):
        a = 2 * np.pi * k / NRING; c, s_ = np.cos(a), np.sin(a)
        e = lambda v: np.sign(v) * abs(v) ** (2.0 / EXP)
        U = Uc + hu * e(s_) * tscale
        hw, Lc = half_width(U, F); hw *= tscale; Lc = HL + (Lc - HL) * tscale
        if neck_blend and U < 1.995: hw *= 0.88 + 0.12 * np.clip((U - U_BOT) / 0.05, 0, 1) ** 1.5
        pts.append((F, U, Lc + hw * e(c)))
    return pts

def loft(which, name):
    st = station_data(which); n = len(st)
    if n < 3: return None
    V = []; Fq = []
    for i, (F, ub, ut) in enumerate(st):
        edge = min(i, n - 1 - i); t = float(np.clip(edge / 3.0, 0, 1)); t = max(t, 0.18) if edge == 0 else t
        t = np.sqrt(max(t, 0.0)) if edge < 3 else 1.0
        V.extend(ring(F, ub, ut, t, neck_blend=(which == 'skull')))
    nv = len(V)
    for i in range(n - 1):
        for k in range(NRING):
            a, b = i * NRING + k, i * NRING + (k + 1) % NRING
            Fq.append([a, b, b + NRING, a + NRING])
    V.append((st[0][0] - 0.004, 0.5 * (st[0][1] + st[0][2]), HL)); V.append((st[-1][0] + 0.004, 0.5 * (st[-1][1] + st[-1][2]), HL))
    for k in range(NRING):
        Fq.append([nv, (k + 1) % NRING, k]); Fq.append([nv + 1, (n - 1) * NRING + k, (n - 1) * NRING + (k + 1) % NRING])
    B = [(L, -F, U) for (F, U, L) in V]
    me = bpy.data.meshes.new(name); me.from_pydata(B, [], Fq); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    m = ob.modifiers.new('sub', 'SUBSURF'); m.levels = 2; m.render_levels = 2
    bpy.ops.object.modifier_apply(modifier='sub')
    for p in ob.data.polygons: p.use_smooth = True
    return ob

def skull_surface(F, U, side):
    """analytic lateral surface offset (from the head line) of the skull loft at (F,U) for plate conforming; falls back to 0 outside."""
    st = {round(s[0], 3): s for s in station_data('skull')}
    Fk = min(st.keys(), key=lambda k: abs(k - F)); _, ub, ut = st[Fk]
    if not (ub <= U <= ut): return None
    Uc = 0.5 * (ub + ut); hu = 0.5 * (ut - ub); v = min(abs((U - Uc) / max(hu, 1e-4)), 0.999)
    hw0, Lc = half_width(U, Fk); hw = hw0 * (1 - v ** EXP) ** (1.0 / EXP)
    if U < 1.995: hw *= 0.88 + 0.12 * np.clip((U - U_BOT) / 0.05, 0, 1) ** 1.5
    return hw, Lc - HL

def build_loft(parts):
    for o in list(parts):
        if o.name in ('cranium', 'snout', 'skull_hull', 'mandible'):
            parts.remove(o); bpy.data.objects.remove(o, do_unlink=True)
    sk = loft('skull', 'skull'); parts.append(sk)
    jw = loft('jaw', 'mandible')
    if jw is not None:
        pv = mathutils.Vector((JAW_PIVOT[2], -JAW_PIVOT[0], JAW_PIVOT[1]))
        for v in jw.data.vertices: v.co = v.co - pv
        jw.location = pv; parts.append(jw)
