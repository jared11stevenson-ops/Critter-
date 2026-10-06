"""GATE-1 PROXY of Aruun (reference pose). Pure silhouette volumes, flat clay. Source of numbers: design/model_sheets/aruun/fidelity/character_spec.json.
Run: python3 tools/modeling/aruun/v4_proxy/build_proxy.py  (needs `bpy` module; writes proxy.blend + proxy.glb into design/model_sheets/aruun/fidelity/proxy/)
Coordinates here: (F, U, L) = (forward, up, HIS LEFT) metres, origin on the ground at the side-view axis. Image-right in the BACK view = his RIGHT = negative L.
Every part is a swept elliptical tube: path points (F,U,L) with per-point radii (ra, rb) in a frame (u along `hint`, v = t x u)."""
import os, sys, numpy as np
import bpy
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..'))
OUT = os.path.join(ROOT, 'design/model_sheets/aruun/fidelity/proxy')
NSEG = 16
FW, UP, LF = np.array([1., 0, 0]), np.array([0, 1., 0]), np.array([0, 0, 1.])   # axes in (F,U,L) space

def cr(P, sub=6):
    P = np.asarray(P, float)
    if len(P) < 3: return np.linspace(P[0], P[-1], sub * 2)
    Q = np.vstack([2 * P[0] - P[1], P, 2 * P[-1] - P[-2]]); out = []
    for i in range(1, len(Q) - 2):
        p0, p1, p2, p3 = Q[i - 1], Q[i], Q[i + 1], Q[i + 2]
        for t in np.linspace(0, 1, sub, endpoint=False):
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    out.append(P[-1]); return np.array(out)

def tube(name, pts, rad, hint=FW, sub=6):
    """pts [(F,U,L)], rad [(ra,rb)] -> mesh object. ra along `hint` (orthogonalised), rb along the other axis."""
    pts = np.asarray(pts, float); rad = np.asarray(rad, float)
    C = cr(pts, sub); R = cr(rad, sub)[:len(C)]
    n = len(C); V = []
    T = np.gradient(C, axis=0); T /= np.linalg.norm(T, axis=1)[:, None]
    for i in range(n):
        u = hint - T[i] * np.dot(hint, T[i])
        if np.linalg.norm(u) < 1e-3: u = LF - T[i] * np.dot(LF, T[i])
        u /= np.linalg.norm(u); v = np.cross(T[i], u)
        for k in range(NSEG):
            a = 2 * np.pi * k / NSEG
            V.append(C[i] + np.cos(a) * R[i, 0] * u + np.sin(a) * R[i, 1] * v)
    V = np.array(V); F = []
    for i in range(n - 1):
        for k in range(NSEG):
            a, b = i * NSEG + k, i * NSEG + (k + 1) % NSEG
            F.append((a, b, b + NSEG, a + NSEG))
    V = np.vstack([V, C[0], C[-1]]); c0, c1 = len(V) - 2, len(V) - 1
    for k in range(NSEG):
        F.append((c0, (k + 1) % NSEG, k)); F.append((c1, (n - 1) * NSEG + k, (n - 1) * NSEG + (k + 1) % NSEG))
    # (F,U,L) -> glTF-style (x=L, y=U, z=F) -> Blender (x, -z, y)
    B = np.stack([V[:, 2], -V[:, 0], V[:, 1]], 1)
    me = bpy.data.meshes.new(name); me.from_pydata(B.tolist(), [], [list(f) for f in F]); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob)
    for p in me.polygons: p.use_smooth = True
    return ob

def ell(name, c, r, sub=6):
    """vertical ellipsoid: centre c=(F,U,L), radii r=(rf, ru, rl)"""
    c = np.array(c, float); t = np.linspace(0, 1, 9)[1:-1]
    pts = [c + [0, -r[1], 0]] + [c + [0, -r[1] * np.cos(np.pi * x), 0] for x in t] + [c + [0, r[1], 0]]
    rads = [(0.001, 0.001)] + [(r[0] * np.sin(np.pi * x), r[2] * np.sin(np.pi * x)) for x in t] + [(0.001, 0.001)]
    return tube(name, pts, rads, FW, sub=2)

STRIP_MASS = os.environ.get('ARUUN_PROXY_STRIPS', '1') == '1'
def build():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o)
    parts = []
    # ---------- HEAD (centre L ~ +0.09: head sits toward his left in the back view). Narrow in F at the chin row (side shows only neck there), wide in L (back).
    HL = 0.09
    parts.append(tube('cranium', [(0.0, 1.955, HL), (0.0, 1.98, HL), (-0.015, 2.04, HL), (0.03, 2.10, HL), (0.035, 2.118, HL), (0.03, 2.13, HL)],
                      [(0.035, 0.07), (0.045, 0.095), (0.095, 0.10), (0.075, 0.115), (0.06, 0.135), (0.02, 0.06)]))
    parts.append(tube('snout', [(0.0, 2.065, HL), (0.07, 2.05, HL), (0.13, 2.03, HL), (0.19, 2.0, HL)],
                      [(0.055, 0.075), (0.048, 0.06), (0.036, 0.045), (0.012, 0.02)], hint=UP))
    # ---------- NECK (thin, leaning forward) with trapezius/hood flare at the base
    parts.append(ell('neckbase', (-0.035, 1.745, -0.02), (0.135, 0.10, 0.175)))
    parts.append(tube('neck', [(-0.03, 1.74, 0.03), (-0.02, 1.82, 0.05), (0.01, 1.90, 0.07), (0.0, 1.99, HL)],
                      [(0.08, 0.08), (0.058, 0.06), (0.055, 0.06), (0.054, 0.062)]))
    # ---------- HORNS  A thick/short (his RIGHT, L<0), B thin/long (his LEFT, L>0). Tip heights: compromise between side (2.40) and back (2.36) per ruling 5.
    parts.append(tube('hornA', [(-0.02, 2.13, 0.0), (0.0, 2.26, 0.0), (0.05, 2.32, 0.0), (0.11, 2.36, 0.0), (0.19, 2.385, 0.0)],
                      [(0.029, 0.029), (0.025, 0.025), (0.020, 0.020), (0.015, 0.015), (0.007, 0.007)], hint=LF))
    parts.append(tube('hornB', [(0.07, 2.12, 0.04), (0.12, 2.20, 0.13), (0.16, 2.27, 0.18), (0.275, 2.32, 0.195), (0.32, 2.35, 0.24), (0.29, 2.39, 0.33), (0.27, 2.375, 0.365)],
                      [(0.027, 0.027), (0.023, 0.023), (0.019, 0.019), (0.016, 0.016), (0.012, 0.012), (0.009, 0.009), (0.005, 0.005)], hint=LF))
    # Horn B inner tooth: back view shows a bar from B's crest running toward A and hooking down (closes the horn loop / above_crown_horn_gap).
    parts.append(tube('hornB_tooth', [(0.30, 2.36, 0.22), (0.27, 2.35, 0.13), (0.25, 2.335, 0.07), (0.24, 2.30, 0.05), (0.23, 2.27, 0.06)],
                      [(0.016, 0.016), (0.016, 0.016), (0.013, 0.013), (0.010, 0.010), (0.005, 0.005)], hint=LF))
    # ---------- TRUNK (pelvis -> neck base)
    parts.append(tube('trunk', [(-0.07, 0.88, 0.0), (-0.07, 0.92, 0.0), (-0.055, 0.97, 0.0), (-0.01, 1.10, 0.0), (0.0, 1.25, 0.0), (-0.01, 1.32, 0.0),
                                (-0.01, 1.40, 0.0), (0.0, 1.46, 0.0), (0.0, 1.54, 0.0), (-0.03, 1.62, 0.0), (-0.075, 1.69, 0.0), (-0.05, 1.77, 0.0)],
                      [(0.12, 0.14), (0.17, 0.22), (0.20, 0.245), (0.22, 0.245), (0.22, 0.25), (0.21, 0.25),
                       (0.178, 0.25), (0.19, 0.25), (0.21, 0.255), (0.185, 0.26), (0.145, 0.22), (0.12, 0.12)]))
    parts.append(ell('pauldronL', (-0.10, 1.58, 0.22), (0.14, 0.15, 0.10)))
    parts.append(tube('mantleR', [(-0.07, 1.30, -0.20), (-0.08, 1.45, -0.20), (-0.09, 1.60, -0.19), (-0.08, 1.69, -0.16), (-0.07, 1.775, -0.13)],
                      [(0.09, 0.11), (0.10, 0.11), (0.13, 0.12), (0.10, 0.10), (0.05, 0.07)]))
    # ---------- ARMS hanging (reference pose). Left fist is hidden inside the thigh depth in the side view (side xmin jumps at U 0.82); right fist at ~0.86.
    parts.append(tube('armL', [(-0.10, 1.52, 0.19), (-0.12, 1.40, 0.205), (-0.12, 1.34, 0.225), (-0.12, 1.28, 0.29), (-0.07, 1.05, 0.32), (-0.04, 0.90, 0.325)],
                      [(0.07, 0.07), (0.07, 0.07), (0.07, 0.07), (0.075, 0.08), (0.065, 0.065), (0.06, 0.06)]))
    parts.append(ell('fistL', (-0.04, 0.85, 0.325), (0.08, 0.10, 0.07)))
    parts.append(tube('armR', [(-0.10, 1.55, -0.22), (-0.12, 1.40, -0.25), (-0.145, 1.31, -0.295), (-0.18, 1.05, -0.295), (-0.18, 0.99, -0.295)],
                      [(0.07, 0.07), (0.07, 0.07), (0.07, 0.07), (0.07, 0.07), (0.06, 0.065)]))
    parts.append(ell('fistR', (-0.175, 0.93, -0.31), (0.08, 0.075, 0.07)))
    # ---------- LEGS: image-left leg = his LEFT (L>0). Right thigh outer bulge at 0.67-0.74 follows the back silhouette (strips region; no strip geometry).
    parts.append(tube('legL', [(0.0, 0.92, 0.17), (-0.03, 0.74, 0.18), (-0.112, 0.60, 0.15), (-0.135, 0.50, 0.125), (-0.155, 0.40, 0.115), (-0.162, 0.30, 0.14), (-0.162, 0.22, 0.17), (-0.162, 0.15, 0.175)],
                      [(0.09, 0.10), (0.075, 0.105), (0.085, 0.10), (0.07, 0.095), (0.05, 0.07), (0.045, 0.065), (0.075, 0.075), (0.075, 0.085)]))
    parts.append(tube('legR', [(0.0, 0.92, -0.26), (-0.03, 0.74, -0.29), (-0.068, 0.67, -0.30), (-0.112, 0.60, -0.305), (-0.135, 0.50, -0.30), (-0.155, 0.40, -0.33), (-0.162, 0.30, -0.335), (-0.162, 0.22, -0.335), (-0.162, 0.15, -0.34)],
                      [(0.09, 0.13), (0.075, 0.16), (0.075, 0.17), (0.085, 0.105), (0.07, 0.10), (0.05, 0.07), (0.045, 0.06), (0.075, 0.065), (0.075, 0.075)]))
    # ---------- STRIP MASS (STRUCTURAL parts 26/27): ONE flat volume standing in for the ragged strips hanging inside his RIGHT thigh in the back view.
    # Thin in depth and kept inside the leg depth so the SIDE silhouette stays bare-thigh (ruling 6). Set STRIP_MASS=False to drop it.
    if STRIP_MASS:
        parts.append(tube('stripmassR', [(-0.03, 0.95, -0.07), (-0.05, 0.82, -0.12), (-0.10, 0.62, -0.20), (-0.13, 0.46, -0.245), (-0.14, 0.40, -0.25)],
                          [(0.03, 0.09), (0.03, 0.08), (0.025, 0.055), (0.02, 0.03), (0.01, 0.015)]))
    for nm, c, rl in (('L', 0.21, 0.125), ('R', -0.35, 0.11)):
        parts.append(tube('foot' + nm, [(-0.24, 0.09, c), (-0.15, 0.10, c), (-0.03, 0.07, c), (0.10, 0.035, c), (0.155, 0.025, c)],
                          [(0.075, rl), (0.08, rl), (0.05, rl * 0.95), (0.03, rl * 0.7), (0.02, rl * 0.4)], hint=UP))
        parts.append(tube('sole' + nm, [(-0.25, 0.035, c), (-0.1, 0.035, c), (0.05, 0.03, c), (0.14, 0.022, c)],
                          [(0.035, rl * 0.92), (0.035, rl * 0.92), (0.03, rl * 0.85), (0.02, rl * 0.5)], hint=UP))
    return parts

def main():
    os.makedirs(OUT, exist_ok=True)
    parts = build()
    mat = bpy.data.materials.new('clay'); mat.diffuse_color = (0.55, 0.55, 0.55, 1)
    for o in parts: o.data.materials.append(mat)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'proxy.blend'))
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, 'proxy.glb'), export_format='GLB', use_selection=True)
    print('wrote', OUT)
if __name__ == '__main__': main()
