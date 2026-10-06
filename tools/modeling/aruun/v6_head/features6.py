import os, numpy as np, bpy
from mathutils import Vector
import head6 as H
from head6 import HL, B
NAMES = []
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
