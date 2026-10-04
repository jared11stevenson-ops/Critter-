"""Reusable mobile-cheap 3D NPC pipeline (Blender 5.0 as a python module, headless).

A character is a small python spec (tools/modeling/npcs/specs/<id>.py) that calls Builder helpers
(ball / limb / spike / strip / box / tube) on a standard humanoid joint layout (or a creature layout). The
Builder collects everything into ONE skinned mesh with ONE material (palette atlas albedo + emission, WebP),
so every NPC is one draw call. Bone names follow tools/animation (hips/spine1/spine2/chest/neck1/head,
clavicle/upperarm/forearm/hand, thigh/shin/foot/toe .L/.R + per-character extras), so mocap clips retarget
through tools/animation (characters/npc.py) and the glb plays under game/art/models/character_model.gd.

Character frame (same as tools/animation): x = character's left, -y = forward, z = up, metres.
"""
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
ANIM = os.path.join(ROOT, "tools", "animation")
for p in (ANIM,):
    if p not in sys.path:
        sys.path.insert(0, p)

import bmesh  # noqa: E402
import bpy  # noqa: E402
from mathutils import Euler, Matrix, Vector  # noqa: E402

V = np.array


def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


# ------------------------------------------------------------------------------------------- joints
def humanoid_joints(H, legs=1.0, torso=1.0, neck=1.0, head=1.0, shoulders=1.0, hipw=1.0, arms=1.0, stoop=0.0,
                    headfwd=0.0):
    """Joint dict for the standard humanoid. Everything is scaled so that the head top sits at H."""
    leg = 0.50 * legs
    tor = 0.29 * torso
    nk = 0.045 * neck
    hd = 0.14 * head
    raw = leg + tor + nk + hd
    k = H / raw
    hz = leg * k
    T = tor * k
    N = nk * k
    HD = hd * k
    sw = 0.105 * H * shoulders
    hw = 0.052 * H * hipw
    ua = 0.165 * H * arms
    fa = 0.150 * H * arms
    hdl = 0.055 * H * arms
    J = {}

    def fwd(z):
        return -stoop * max(0.0, z - hz) / max(T, 1e-3) * 0.12 * H

    J["hips"] = (0, 0, hz)
    J["spine1"] = (0, fwd(hz + T * 0.22), hz + T * 0.22)
    J["spine2"] = (0, fwd(hz + T * 0.50), hz + T * 0.50)
    J["chest"] = (0, fwd(hz + T * 0.72), hz + T * 0.72)
    nz = hz + T
    J["neck1"] = (0, fwd(nz) - headfwd * H, nz)
    J["head"] = (0, fwd(nz + N) - headfwd * H * 1.5, nz + N)
    J["head_end"] = (0, fwd(nz + N) - headfwd * H * 1.5, nz + N + HD)
    sz = hz + T * 0.90
    sy = fwd(sz)
    for s, sg in ((".L", 1), (".R", -1)):
        J["clav" + s] = (sg * 0.03 * H, sy, sz)
        J["shoulder" + s] = (sg * sw, sy, sz - 0.005)
        J["elbow" + s] = (sg * (sw + 0.02 * H), sy + 0.012 * H, sz - ua)
        J["wrist" + s] = (sg * (sw + 0.03 * H), sy - 0.005, sz - ua - fa)
        J["hand_end" + s] = (sg * (sw + 0.032 * H), sy - 0.012, sz - ua - fa - hdl)
        J["hip" + s] = (sg * hw, 0.0, hz - 0.01 * H)
        J["knee" + s] = (sg * (hw + 0.005 * H), -0.01 * H, hz * 0.52)
        J["ankle" + s] = (sg * (hw + 0.008 * H), 0.012 * H, 0.05 * H)
        J["ball" + s] = (sg * (hw + 0.01 * H), -0.055 * H, 0.015 * H)
        J["toe_end" + s] = (sg * (hw + 0.012 * H), -0.095 * H, 0.012 * H)
    J["_H"] = H
    J["_hz"] = hz
    J["_T"] = T
    return J


HUMANOID_BONES = [
    ("hips", "hips", "spine1", "root"), ("spine1", "spine1", "spine2", "hips"),
    ("spine2", "spine2", "chest", "spine1"), ("chest", "chest", "neck1", "spine2"),
    ("neck1", "neck1", "head", "chest"), ("head", "head", "head_end", "neck1"),
    ("clavicle.L", "clav.L", "shoulder.L", "chest"), ("upperarm.L", "shoulder.L", "elbow.L", "clavicle.L"),
    ("forearm.L", "elbow.L", "wrist.L", "upperarm.L"), ("hand.L", "wrist.L", "hand_end.L", "forearm.L"),
    ("thigh.L", "hip.L", "knee.L", "hips"), ("shin.L", "knee.L", "ankle.L", "thigh.L"),
    ("foot.L", "ankle.L", "ball.L", "shin.L"), ("toe.L", "ball.L", "toe_end.L", "foot.L"),
]


def mirror_bones(bones):
    out = list(bones)
    for n, h, t, p in bones:
        if n.endswith(".L"):
            f = lambda s: s[:-2] + ".R" if s.endswith(".L") else s  # noqa: E731
            out.append((f(n), f(h), f(t), f(p)))
    return out


# ------------------------------------------------------------------------------------------- builder
class Builder:
    def __init__(self, cid, H, joints, bones, palette):
        self.cid = cid
        self.H = H
        self.J = dict(joints)
        self.bones = list(bones)          # (name, head_joint, tail_joint, parent)
        self.bm = bmesh.new()
        self.vbone = []                   # per vertex {bone: w}
        self.pal = {}
        self.pal_order = []
        for k, v in palette.items():
            glow = False
            if isinstance(v, (tuple, list)) and len(v) == 2 and isinstance(v[1], str) and v[1] == "glow":
                glow = True
                v = v[0]
            self.pal[k] = (hex2rgb(v), glow)
            self.pal_order.append(k)
        self.uvl = self.bm.loops.layers.uv.new("UVMap")
        self.matl = None
        self.skip_mirror = False

    # -- joint access
    def j(self, name):
        return V(self.J[name], dtype=float)

    def add_joint(self, name, p):
        self.J[name] = tuple(p)

    def add_bone(self, name, head, tail, parent):
        """head/tail: joint names or xyz tuples. Returns bone name."""
        for tag, pt in (("h", head), ("t", tail)):
            if not isinstance(pt, str):
                self.J["_%s_%s" % (name, tag)] = tuple(pt)
        hn = head if isinstance(head, str) else "_%s_h" % name
        tn = tail if isinstance(tail, str) else "_%s_t" % name
        self.bones.append((name, hn, tn, parent))
        return name

    def add_bone_pair(self, name, head, tail, parent):
        """Adds name.L (given coords, x>0) and name.R (mirrored)."""
        self.add_bone(name + ".L", head, tail, parent + ".L" if parent in self._sided else parent)
        h = V(head, float) * (-1, 1, 1)
        t = V(tail, float) * (-1, 1, 1)
        self.add_bone(name + ".R", tuple(h), tuple(t), parent + ".R" if parent in self._sided else parent)

    _sided = {"clavicle", "upperarm", "forearm", "hand", "thigh", "shin", "foot", "toe"}

    # -- low level
    def _wt(self, bone, p):
        if callable(bone):
            return bone(p)
        if isinstance(bone, dict):
            return bone
        return {bone: 1.0}

    def _vert(self, p, bone):
        v = self.bm.verts.new(tuple(float(x) for x in p))
        self.vbone.append(self._wt(bone, p))
        return v

    def _face(self, vs, col, smooth=True):
        try:
            f = self.bm.faces.new(vs)
        except ValueError:
            return None
        f.smooth = smooth
        c, _g = self.pal[col]
        idx = self.pal_order.index(col)
        u = ((idx % 8) + 0.5) / 8.0
        v = 1.0 - ((idx // 8) + 0.5) / 8.0
        for lp in f.loops:
            lp[self.uvl].uv = (u, v)
        return f

    def _lr(self, fn, *a, **kw):
        fn(*a, **kw)

    # -- primitives (all take world/character-frame coordinates)
    def ball(self, c, r, bone, col, seg=8, rings=5, smooth=True, rot=(0, 0, 0), squash=None, bands=None):
        """Ellipsoid. r = radius or (rx, ry, rz) in character axes; rot = euler degrees applied about centre."""
        c = V(c, float)
        r = V(r if hasattr(r, "__len__") else (r, r, r), float)
        R = Euler([math.radians(a) for a in rot], "XYZ").to_matrix()
        rows = []
        top = self._vert(c + (R @ Vector((0, 0, r[2]))), bone)
        for i in range(1, rings):
            th = math.pi * i / rings
            ring = []
            for s in range(seg):
                ph = 2 * math.pi * s / seg
                p = Vector((r[0] * math.sin(th) * math.cos(ph), r[1] * math.sin(th) * math.sin(ph), r[2] * math.cos(th)))
                ring.append(self._vert(c + (R @ p), bone))
            rows.append(ring)
        bot = self._vert(c + (R @ Vector((0, 0, -r[2]))), bone)
        for s in range(seg):
            s2 = (s + 1) % seg
            bc = (lambda i: bands[i % len(bands)]) if bands else (lambda i: col)
            self._face([top, rows[0][s2], rows[0][s]], bc(0), smooth)
            for i in range(len(rows) - 1):
                self._face([rows[i][s], rows[i][s2], rows[i + 1][s2], rows[i + 1][s]], bc(i + 1), smooth)
            self._face([bot, rows[-1][s], rows[-1][s2]], bc(len(rows)), smooth)

    def limb(self, a, b, ra, rb, bone, col, seg=7, cap_a=True, cap_b=True, smooth=True, flat=None):
        """Tapered capsule between points (names or xyz). Radii may be (rx, ry) elliptical across the axis."""
        a = self.j(a) if isinstance(a, str) else V(a, float)
        b = self.j(b) if isinstance(b, str) else V(b, float)
        ax = b - a
        L = np.linalg.norm(ax)
        if L < 1e-5:
            return
        z = ax / L
        x = np.cross(z, [0, 0, 1.0]) if abs(z[2]) < 0.9 else np.cross(z, [1.0, 0, 0])
        x /= np.linalg.norm(x)
        y = np.cross(z, x)
        ra = ra if hasattr(ra, "__len__") else (ra, ra)
        rb = rb if hasattr(rb, "__len__") else (rb, rb)
        rings = []
        for t, rr in ((0.0, ra), (1.0, rb)):
            ring = []
            for s in range(seg):
                ang = 2 * math.pi * s / seg
                p = a + z * (t * L) + x * math.cos(ang) * rr[0] + y * math.sin(ang) * rr[1]
                ring.append(self._vert(p, bone))
            rings.append(ring)
        for s in range(seg):
            s2 = (s + 1) % seg
            self._face([rings[0][s], rings[0][s2], rings[1][s2], rings[1][s]], col, smooth)
        if cap_a:
            self._dome(a, -z, x, y, ra, rings[0], bone, col, seg, smooth)
        if cap_b:
            self._dome(b, z, x, y, rb, rings[1], bone, col, seg, smooth)

    def _dome(self, c, d, x, y, r, base, bone, col, seg, smooth):
        ring = []
        for s in range(seg):
            ang = 2 * math.pi * s / seg
            p = c + x * math.cos(ang) * r[0] * 0.75 + y * math.sin(ang) * r[1] * 0.75 + d * min(r) * 0.55
            ring.append(self._vert(p, bone))
        pole = self._vert(c + d * min(r) * 0.95, bone)
        for s in range(seg):
            s2 = (s + 1) % seg
            self._face([base[s], ring[s], ring[s2], base[s2]], col, smooth)
            self._face([ring[s], pole, ring[s2]], col, smooth)

    def spike(self, base, tip, r, bone, col, seg=5, smooth=False, tipbone=None):
        base = V(base, float)
        tip = V(tip, float)
        ax = tip - base
        L = np.linalg.norm(ax)
        if L < 1e-5:
            return
        z = ax / L
        x = np.cross(z, [0, 0, 1.0]) if abs(z[2]) < 0.9 else np.cross(z, [1.0, 0, 0])
        x /= np.linalg.norm(x)
        y = np.cross(z, x)
        r = r if hasattr(r, "__len__") else (r, r)
        ring = []
        for s in range(seg):
            ang = 2 * math.pi * s / seg
            ring.append(self._vert(base + x * math.cos(ang) * r[0] + y * math.sin(ang) * r[1], bone))
        t = self._vert(tip, tipbone or bone)
        for s in range(seg):
            self._face([ring[s], ring[(s + 1) % seg], t], col, smooth)
        self._face(ring[::-1], col, smooth)

    def box(self, c, size, bone, col, rot=(0, 0, 0), taper=1.0, smooth=False):
        """Box centred at c, size (sx, sy, sz); taper scales the top face."""
        c = V(c, float)
        s = V(size, float) / 2
        R = Euler([math.radians(a) for a in rot], "XYZ").to_matrix()
        pts = []
        for zz in (-1, 1):
            tp = taper if zz > 0 else 1.0
            for (xx, yy) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                p = Vector((xx * s[0] * tp, yy * s[1] * tp, zz * s[2]))
                pts.append(self._vert(c + (R @ p), bone))
        for q in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
            self._face([pts[i] for i in q], col, smooth)

    def quad(self, p0, p1, p2, p3, bone, col, smooth=False):
        """Single-sided-geometry two-sided-material quad (cloth, wings, leaves)."""
        vs = [self._vert(p, bone) for p in (p0, p1, p2, p3)]
        self._face(vs, col, smooth)

    def tri(self, p0, p1, p2, bone, col):
        vs = [self._vert(p, bone) for p in (p0, p1, p2)]
        self._face(vs, col, False)

    def strip(self, top, bottom, bone, col, smooth=False):
        """Quad strip between two polylines (same length)."""
        for i in range(len(top) - 1):
            self.quad(top[i], top[i + 1], bottom[i + 1], bottom[i], bone, col, smooth)

    def tatter(self, c, w, h, bone, col, n=1, jag=0.35, rot=(0, 0, 0), sway=0.0):
        """Hanging ragged cloth strip(s): top edge centred at c, width w, length h, pointed jagged bottom."""
        c = V(c, float)
        R = Euler([math.radians(a) for a in rot], "XYZ").to_matrix()
        wi = w / n
        for i in range(n):
            x0 = -w / 2 + i * wi
            x1 = x0 + wi
            l = h * (1.0 - jag * (0.5 + 0.5 * math.sin(i * 2.7 + c[0] * 9)))
            top0 = c + (R @ Vector((x0, 0, 0)))
            top1 = c + (R @ Vector((x1, 0, 0)))
            tip = c + (R @ Vector(((x0 + x1) / 2 + sway * wi, 0, -l)))
            mid0 = c + (R @ Vector((x0 + wi * 0.05, 0, -l * 0.55)))
            mid1 = c + (R @ Vector((x1 - wi * 0.05, 0, -l * 0.55)))
            self.quad(top0, top1, mid1, mid0, bone, col)
            self.tri(mid0, mid1, tip, bone, col)

    def leaf(self, base, tip, width, wdir, bone, col, n=3, bend=(0, 0, 0), col2=None, smooth=False):
        """Leaf / wing blade: spine base->tip (+ bend bulge), widest ~40% along, two-sided. wdir = width axis."""
        base, tip, bend = V(base, float), V(tip, float), V(bend, float)
        wd = V(wdir, float)
        wd = wd / np.linalg.norm(wd)
        pts = []
        for k in range(n + 1):
            t = k / n
            p = base + (tip - base) * t + bend * math.sin(math.pi * t)
            w = width * 0.5 * (math.sin(math.pi * min(1.0, 0.18 + 0.82 * t)) ** 0.8) if k < n else 0.0
            pts.append((p - wd * w, p + wd * w))
        for k in range(n):
            c = col2 if (col2 and k % 2) else col
            self.quad(pts[k][0], pts[k][1], pts[k + 1][1], pts[k + 1][0], bone, c, smooth)

    def ring_skirt(self, c, r_top, r_bot, z_top, z_bot, bone, cols, n=10, sag=(0, 0), jag=0.0, front_slit=0.0, wobble=0.0):
        """Open cone of quads around the vertical axis through c (hips cloth / coat skirt). cols: list cycled per panel.
        bone may be a callable p -> weights. front_slit: skip panels whose angle is within +-slit rad of forward (-y)."""
        c = V(c, float)
        for i in range(n):
            a0 = 2 * math.pi * i / n
            a1 = 2 * math.pi * (i + 1) / n
            am = (a0 + a1) / 2
            if front_slit and abs(((am - 1.5 * math.pi + math.pi) % (2 * math.pi)) - math.pi) < front_slit:
                continue
            wob = 1.0 + wobble * math.sin(i * 2.3)
            zb = z_bot + jag * ((i * 7) % 5) / 5.0 * (z_top - z_bot)
            def P(a, r, z):
                return c + V((math.cos(a) * r, math.sin(a) * r, 0)) + V((sag[0] * (z_top - z) , sag[1] * (z_top - z), z - c[2]))
            p00, p01 = P(a0, r_top, z_top), P(a1, r_top, z_top)
            p10, p11 = P(a0, r_bot * wob, zb), P(a1, r_bot * wob, zb)
            self.quad(p00, p01, p11, p10, bone, cols[i % len(cols)])

    def tube(self, pts, radii, bone, col, seg=5, smooth=True, bones=None):
        """Chain of tapered segments (antennae, tails, vines). bones: per-point bone names or None."""
        for i in range(len(pts) - 1):
            bn = bones[i] if bones else bone
            self.limb(pts[i], pts[i + 1], radii[i], radii[i + 1], bn, col, seg=seg, cap_a=(i == 0), cap_b=(i == len(pts) - 2),
                      smooth=smooth)

    def mirror_call(self, fn, *a, **kw):
        fn(*a, **kw)


# ------------------------------------------------------------------------------------------- textures
def write_atlas(b, outdir):
    from PIL import Image
    cell = 16
    alb = Image.new("RGB", (8 * cell, 8 * cell), (255, 0, 255))
    emi = Image.new("RGB", (8 * cell, 8 * cell), (0, 0, 0))
    for i, k in enumerate(b.pal_order):
        c, glow = b.pal[k]
        px = tuple(int(round(255 * x)) for x in c)
        box = ((i % 8) * cell, (i // 8) * cell, (i % 8 + 1) * cell, (i // 8 + 1) * cell)
        alb.paste(px, box)
        if glow:
            emi.paste(px, box)
    pa = os.path.join(outdir, "%s_albedo.png" % b.cid)
    pe = os.path.join(outdir, "%s_emissive.png" % b.cid)
    alb.save(pa)
    emi.save(pe)
    return pa, pe


def make_material(b, pa, pe, rough=0.85, emit=1.6):
    m = bpy.data.materials.new(b.cid)
    m.use_nodes = True
    m.use_backface_culling = False
    nt = m.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = rough
    bs.inputs["Metallic"].default_value = 0.0
    ta = nt.nodes.new("ShaderNodeTexImage")
    ta.image = bpy.data.images.load(pa)
    ta.interpolation = "Closest"
    nt.links.new(ta.outputs["Color"], bs.inputs["Base Color"])
    te = nt.nodes.new("ShaderNodeTexImage")
    te.image = bpy.data.images.load(pe)
    te.interpolation = "Closest"
    nt.links.new(te.outputs["Color"], bs.inputs["Emission Color"])
    bs.inputs["Emission Strength"].default_value = emit
    return m


# ------------------------------------------------------------------------------------------- rig
def build_armature(name, J, B):
    arm = bpy.data.armatures.new(name + "Rig")
    ob = bpy.data.objects.new(name + "_Rig", arm)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.edit_bones
    r = eb.new("root")
    r.head, r.tail = Vector((0, 0, 0)), Vector((0, 0.3, 0))
    for n, h, t, p in B:
        b = eb.new(n)
        b.head, b.tail = Vector(J[h]), Vector(J[t])
        if (b.tail - b.head).length < 1e-4:
            b.tail = b.head + Vector((0, 0, 0.02))
        b.parent = eb[p]
        if n not in ("thigh.L", "thigh.R", "clavicle.L", "clavicle.R", "hips") and \
                p != "root" and (b.head - eb[p].tail).length < 1e-4:
            b.use_connect = True
        b.align_roll(Vector((0, -1, 0)) if abs(b.vector.normalized().y) < 0.9 else Vector((0, 0, 1)))
    bpy.ops.object.mode_set(mode="OBJECT")
    return ob


def finish_mesh(b):
    """bmesh -> object with vertex groups (normalised, <=4 influences)."""
    me = bpy.data.meshes.new(b.cid)
    bmesh.ops.recalc_face_normals(b.bm, faces=list(b.bm.faces))
    b.bm.to_mesh(me)
    b.bm.free()
    ob = bpy.data.objects.new(b.cid.capitalize(), me)
    bpy.context.scene.collection.objects.link(ob)
    vg = {}
    for i, w in enumerate(b.vbone):
        items = sorted(w.items(), key=lambda kv: -kv[1])[:4]
        tot = sum(x for _, x in items) or 1.0
        for bn, x in items:
            if bn not in vg:
                vg[bn] = ob.vertex_groups.new(name=bn)
            vg[bn].add([i], x / tot, "REPLACE")
    return ob


def tri_count(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)
