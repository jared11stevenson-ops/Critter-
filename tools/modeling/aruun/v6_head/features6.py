import os, numpy as np, bpy
from mathutils import Vector
import head6 as H
from head6 import HL, B
NAMES = []
import re
def reg(ob, name): ob.name = name; ob.data.name = name; NAMES.append(name); return ob
C0 = Vector(B(0.03, 2.06, HL))
def surf_dir(bvh, d):
    d = Vector(d).normalized(); r = bvh.ray_cast(C0 + d * 0.5, -d)
    return (r[0], r[1]) if r[0] is not None else None
def orient(ob, n): ob.rotation_mode = 'QUATERNION'; ob.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(n)
def lat(bvh, F, U, side, off=0.0):
    p, n = H.hit(bvh, F, U, None, 'L', side); return p + n * off, n
EYE_DIR = lambda s: (s * 0.74, -0.46, 0.36)          # blender (L,-F,U) direction from head centre to the eye centre on the surface (side-set, up/forward slope)
def build(STEP):
    sk = reg(H.skull_loft(), 'skull')
    amp = float(os.environ.get('DEPTH_AMP', '0.005'))
    if amp: H.displace(sk, H.depth_relief(amp)(sk))
    bvh = H.bvh_of(sk)
    if STEP >= 2:
        eyes = {}
        for s, n in ((1, 'L'), (-1, 'R')):
            p, nr = surf_dir(bvh, EYE_DIR(s)); eyes[n] = (p, nr)
        # sockets: smooth dents around each eye + a raised orbital rim ring (so the eye reads as sunk into a bony socket)
        def sock(P):
            t = np.zeros(len(P))
            for n, (p, nr) in eyes.items():
                d = np.linalg.norm(P - np.array(p), axis=1); t += -0.0085 * np.exp(-(d / 0.024) ** 2) + 0.0035 * np.exp(-((d - 0.036) / 0.011) ** 2)
            return t
        H.displace(sk, sock); bvh = H.bvh_of(sk)
        for s, n in ((1, 'L'), (-1, 'R')):
            p, nr = surf_dir(bvh, EYE_DIR(s))
            e = H.ell('eye_' + n, p + nr * 0.002, (0.019, 0.0145, 0.0095)); orient(e, nr)
            # rotate so the long axis runs along the (F) direction tilted: almond pointing forward-down
            reg(e, 'eye_' + n)
            tf = (Vector((0, -1, 0)) - nr * nr.dot(Vector((0, -1, 0)))).normalized(); tu = nr.cross(tf) if nr.cross(tf).z > 0 else tf.cross(nr)
            P = []
            for (f, u) in ((-0.034, 0.016), (-0.012, 0.025), (0.014, 0.028), (0.040, 0.020), (0.062, 0.004), (0.078, -0.018)):
                o = p + tf * f + tu * u; r = bvh.ray_cast(o + nr * 0.12, -nr)
                if r[0] is None: continue
                P.append(r[0] + r[1] * 0.002)
            reg(H.tube('brow_' + n, P, [(0.006, 0.008), (0.009, 0.011), (0.010, 0.012), (0.009, 0.011), (0.007, 0.008), (0.004, 0.005)], up=(0, 0, 1)), 'brow_' + n)
    if STEP >= 3:
        mj = reg(H.mandible_loft(), 'mandible')
        p, nr = surf_dir(bvh, (0, -0.96, 0.22))
        pad = H.ell('nose_pad', p + nr * -0.004, (0.016, 0.019, 0.013)); orient(pad, nr); reg(pad, 'nose_pad')
        for s in (1, -1):
            q = bvh.ray_cast(Vector(B(0.22, 2.087, HL + s * 0.013)), Vector((0, 1, 0)))
            if q[0] is not None:
                nos = H.ell('nostril_' + ('L' if s > 0 else 'R'), q[0] + q[1] * -0.001, (0.0055, 0.004, 0.005)); orient(nos, q[1]); reg(nos, nos.name)
    if STEP >= 4:
        for s, n in ((1, 'L'), (-1, 'R')):
            reg(H.plate('cheek_' + n, [(0.018, -8), (0.050, 10), (0.098, 4), (0.106, -20), (0.076, -42), (0.036, -50), (0.014, -28)], bvh, 'R', s, 0.007, 0.011, cuts=3), 'cheek_' + n)
            reg(H.plate('cheek2_' + n, [(0.114, 10), (0.150, 26), (0.167, 16), (0.158, -10), (0.120, -26)], bvh, 'R', s, 0.006, 0.009, cuts=3), 'cheek2_' + n)
        cr = []
        for i, (f0, f1, w0, w1, off) in enumerate(((0.050, 0.098, 0.034, 0.048, 0.003), (0.002, 0.056, 0.050, 0.064, 0.007), (-0.048, 0.008, 0.060, 0.072, 0.011))):
            pg = [(f1, -w0), (f1, w0), (f0, w1), (f0, -w1)]
            cr.append(H.plate('crown_plate%d' % (i + 1), pg, bvh, 'U', 1, off, 0.007, cuts=3))
        bpy.ops.object.select_all(action='DESELECT')
        for c in cr: c.select_set(True)
        bpy.context.view_layer.objects.active = cr[0]; bpy.ops.object.join(); reg(bpy.context.active_object, 'crown_plates')
        reg(H.tube('temple_tine_L', [B(0.002, 2.088, HL + 0.080), B(-0.020, 2.094, HL + 0.110), B(-0.052, 2.094, HL + 0.150), B(-0.075, 2.082, HL + 0.158)],
                   [(0.022, 0.015), (0.017, 0.013), (0.012, 0.010), (0.003, 0.003)]), 'temple_tine_L')
        reg(H.tube('temple_tine_R', [B(0.002, 2.095, HL - 0.080), B(0.010, 2.110, HL - 0.112), B(0.020, 2.124, HL - 0.148), B(0.030, 2.136, HL - 0.180)],
                   [(0.018, 0.013), (0.014, 0.011), (0.010, 0.008), (0.003, 0.003)]), 'temple_tine_R')
        reg(H.tube('nape_fringe_L', [B(-0.040, 2.000, HL + 0.070), B(-0.044, 1.992, HL + 0.105), B(-0.046, 1.980, HL + 0.140), B(-0.046, 1.966, HL + 0.122)],
                   [(0.020, 0.012), (0.018, 0.011), (0.014, 0.009), (0.004, 0.004)]), 'nape_fringe_L')
        reg(H.tube('nape_fringe_C', [B(-0.060, 2.020, HL), B(-0.085, 2.025, HL), B(-0.105, 2.026, HL), B(-0.124, 2.020, HL)],
                   [(0.030, 0.016), (0.022, 0.012), (0.014, 0.008), (0.004, 0.004)], up=(1, 0, 0)), 'nape_fringe_C')
        reg(H.tube('horn_cup_A', [B(-0.034, 2.098, HL - 0.080), B(-0.044, 2.112, HL - 0.122)], [(0.026, 0.022), (0.020, 0.018)], nring=14), 'horn_cup_A')
        reg(H.tube('horn_cup_B', [B(0.096, 2.100, HL + 0.034), B(0.108, 2.126, HL + 0.046)], [(0.026, 0.022), (0.020, 0.018)], nring=14), 'horn_cup_B')
