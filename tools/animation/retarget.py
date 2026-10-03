"""Mocap -> CRITTER rig retargeting, all numpy (no Blender needed until baking).

Pipeline per clip (see apply.py / configs in characters.py):
  1. Source: BVH segment resampled to 30 fps, converted to the rig frame (Z up, faces -Y), optional loop
     extraction + seam correction, heading straightening (curved mocap walks become straight).
  2. Retarget: rest-pose alignment (target bone rest direction swung onto the source T-pose bone direction) +
     per-frame global rotation deltas of the source joints. Spine/neck use pure deltas so the target's own
     posture (Aruun's hunch) is preserved. Root height/stride scaled by leg-length ratio.
  3. Style layers (character): additive local rotations (hunch, arm spread, weight) and hand-keyed polish.
  4. Foot cleanup: contact detection on the retargeted feet, contact positions locked (on the ground, no
     sliding relative to the root-motion path), two-bone leg IK, ankle/toe flattened during contact.
  5. Secondary: weapon pendulum lag (Morrow swings with momentum), optional two-hand grip IK for the off hand.
Outputs a Pose track: per-frame world rotations + positions for every target bone, convertible to local
Blender pose-bone quaternions (bake()).
"""
import numpy as np

from bvh import BVH

FPS = 30


# ------------------------------------------------------------------------------------------- math
def qmul(a, b):
    w1, x1, y1, z1 = np.moveaxis(a, -1, 0)
    w2, x2, y2, z2 = np.moveaxis(b, -1, 0)
    return np.stack([w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2, w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
                     w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2, w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2], -1)


def m2q(M):
    """Rotation matrices (...,3,3) -> quaternions (...,4) wxyz (sign-continuous along axis 0 if 2D batch)."""
    M = np.asarray(M)
    sh = M.shape[:-2]
    M = M.reshape(-1, 3, 3)
    q = np.zeros((len(M), 4))
    tr = M[:, 0, 0] + M[:, 1, 1] + M[:, 2, 2]
    for i in range(len(M)):
        m = M[i]
        if tr[i] > 0:
            s = np.sqrt(tr[i] + 1.0) * 2
            q[i] = [0.25 * s, (m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s]
        elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
            s = np.sqrt(1.0 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
            q[i] = [(m[2, 1] - m[1, 2]) / s, 0.25 * s, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s]
        elif m[1, 1] > m[2, 2]:
            s = np.sqrt(1.0 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
            q[i] = [(m[0, 2] - m[2, 0]) / s, (m[0, 1] + m[1, 0]) / s, 0.25 * s, (m[1, 2] + m[2, 1]) / s]
        else:
            s = np.sqrt(1.0 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
            q[i] = [(m[1, 0] - m[0, 1]) / s, (m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, 0.25 * s]
    q /= np.linalg.norm(q, axis=1, keepdims=True)
    return q.reshape(sh + (4,))


def q2m(q):
    q = np.asarray(q, dtype=np.float64)
    q = q / np.linalg.norm(q, axis=-1, keepdims=True)
    w, x, y, z = np.moveaxis(q, -1, 0)
    M = np.stack([1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w),
                  2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w),
                  2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)], -1)
    return M.reshape(q.shape[:-1] + (3, 3))


def axis_angle(axis, ang):
    axis = np.asarray(axis, dtype=np.float64)
    axis = axis / max(np.linalg.norm(axis), 1e-12)
    K = np.array([[0, -axis[2], axis[1]], [axis[2], 0, -axis[0]], [-axis[1], axis[0], 0]])
    return np.eye(3) + np.sin(ang) * K + (1 - np.cos(ang)) * K @ K


def swing(a, b):
    """Minimal rotation taking direction a onto direction b (batched over leading axes)."""
    a = a / np.linalg.norm(a, axis=-1, keepdims=True)
    b = b / np.linalg.norm(b, axis=-1, keepdims=True)
    v = np.cross(a, b)
    c = np.sum(a * b, -1)
    s = np.linalg.norm(v, axis=-1)
    out = np.zeros(a.shape[:-1] + (3, 3))
    flat_v = v.reshape(-1, 3)
    flat_c = c.reshape(-1)
    flat_s = s.reshape(-1)
    fo = out.reshape(-1, 3, 3)
    fa = a.reshape(-1, 3)
    for i in range(len(fo)):
        if flat_s[i] < 1e-9:
            if flat_c[i] > 0:
                fo[i] = np.eye(3)
            else:
                ax = np.cross(fa[i], [1, 0, 0])
                if np.linalg.norm(ax) < 1e-6:
                    ax = np.cross(fa[i], [0, 1, 0])
                fo[i] = axis_angle(ax, np.pi)
        else:
            fo[i] = axis_angle(flat_v[i], np.arctan2(flat_s[i], flat_c[i]))
    return out


def slerp_mats(A, B, t):
    """Rotation interpolation between matrices A and B (batched), t scalar or array broadcastable."""
    qa, qb = m2q(A), m2q(B)
    d = np.sum(qa * qb, -1, keepdims=True)
    qb = np.where(d < 0, -qb, qb)
    t = np.asarray(t, dtype=np.float64)[..., None] if np.ndim(t) else t
    q = qa * (1 - t) + qb * t        # nlerp is enough for small corrections
    return q2m(q)


def euler_zyx(rx, ry, rz):
    """Degrees, rotation about armature axes applied X then Y then Z (matches anims.py convention)."""
    return axis_angle((0, 0, 1), np.radians(rz)) @ axis_angle((0, 1, 0), np.radians(ry)) @ \
        axis_angle((1, 0, 0), np.radians(rx))


def smooth(x, k):
    """Gaussian smoothing along axis 0 (k = sigma in frames)."""
    if k <= 0:
        return x
    r = int(3 * k) + 1
    w = np.exp(-0.5 * (np.arange(-r, r + 1) / k) ** 2)
    w /= w.sum()
    pad = np.concatenate([np.repeat(x[:1], r, 0), x, np.repeat(x[-1:], r, 0)])
    out = np.zeros_like(x)
    for i, wi in enumerate(w):
        out += wi * pad[i:i + len(x)]
    return out


def smooth_cyclic(x, k):
    if k <= 0:
        return x
    r = int(3 * k) + 1
    w = np.exp(-0.5 * (np.arange(-r, r + 1) / k) ** 2)
    w /= w.sum()
    out = np.zeros_like(x)
    for i, wi in enumerate(w):
        out += wi * np.roll(x, r - i, axis=0)
    return out


# ------------------------------------------------------------------------------------------- target skeleton
class Skeleton:
    """Target armature rest data (armature space, Blender bone matrices: Y along the bone)."""

    def __init__(self, bones):
        """bones: list of (name, parent or None, rest 4x4 matrix_local, length) in parent-first order."""
        self.names = [b[0] for b in bones]
        self.index = {n: i for i, n in enumerate(self.names)}
        self.parent = [self.index[b[1]] if b[1] else -1 for b in bones]
        self.rest = np.array([np.asarray(b[2], dtype=np.float64) for b in bones])
        self.length = np.array([b[3] for b in bones])
        self.R0 = self.rest[:, :3, :3]
        self.H0 = self.rest[:, :3, 3]
        # parent-relative rest transforms
        self.L = np.zeros_like(self.rest)
        for i, p in enumerate(self.parent):
            self.L[i] = self.rest[i] if p < 0 else np.linalg.inv(self.rest[p]) @ self.rest[i]

    @staticmethod
    def from_blender(rig):
        bl = []
        for b in rig.data.bones:          # bpy gives parents before children
            bl.append((b.name, b.parent.name if b.parent else None, [list(r) for r in b.matrix_local], b.length))
        # enforce parent-first order
        order, seen = [], set()
        byname = {b[0]: b for b in bl}

        def visit(n):
            if n in seen:
                return
            p = byname[n][1]
            if p:
                visit(p)
            seen.add(n)
            order.append(byname[n])
        for b in bl:
            visit(b[0])
        return Skeleton(order)

    def tail_rest(self, n):
        i = self.index[n]
        return self.H0[i] + self.R0[i][:, 1] * self.length[i]


class Track:
    """Per-frame world (armature-space) rotation W (F,J,3,3) and bone head positions P (F,J,3)."""

    def __init__(self, sk, F):
        self.sk = sk
        self.F = F
        J = len(sk.names)
        self.W = np.tile(sk.R0, (F, 1, 1, 1))
        self.P = np.tile(sk.H0, (F, 1, 1))
        self.loc = {}           # bone -> (F,3) extra local translation (e.g. weapon_ext telescoping)
        self.free = {sk.index[n] for n in ("hips",) if n in sk.index}   # bones whose head P is authoritative

    def copy(self):
        t = Track(self.sk, self.F)
        t.W = self.W.copy()
        t.P = self.P.copy()
        t.loc = {k: v.copy() for k, v in self.loc.items()}
        t.free = set(self.free)
        return t

    def fk(self, from_bones=None):
        """Recompute head positions from rotations (roots keep their P). Children follow parents."""
        sk = self.sk
        for i, p in enumerate(sk.parent):
            if p < 0 or i in self.free:
                continue
            off = sk.L[i][:3, 3]
            # parent's rest-relative rotation: W_p = Rp_world; head_i = P_p + W_p @ Rrest_p^T... use pose matrices:
            # M_p = [W_p, P_p]; M_i head = M_p @ L_i.t, with M_p's rotation expressed so that M_p @ Rest_p^-1 maps rest->pose
            Mp_rot = self.W[:, p]                         # world rotation of parent bone frame
            pos = self.P[:, p] + np.einsum("fij,j->fi", Mp_rot, off)
            if sk.names[i] in self.loc:
                pos = pos + np.einsum("fij,fj->fi", Mp_rot @ sk.L[i][:3, :3][None], self.loc[sk.names[i]])
            self.P[:, i] = pos

    def tail(self, n):
        i = self.sk.index[n]
        return self.P[:, i] + self.W[:, i][:, :, 1] * self.sk.length[i]

    def rotate_world(self, n, R, children=True):
        """Pre-multiply world rotation of bone n (and its descendants if children) by R (F,3,3) about its head."""
        sk = self.sk
        i = sk.index[n]
        ids = [i] + (self.descendants(i) if children else [])
        piv = self.P[:, i].copy()
        for j in ids:
            self.W[:, j] = R @ self.W[:, j]
            self.P[:, j] = piv + np.einsum("fij,fj->fi", R, self.P[:, j] - piv)

    def descendants(self, i):
        out = []
        for j, p in enumerate(self.sk.parent):
            if p == i:
                out += [j] + self.descendants(j)
        return out

    def local_quats(self):
        """Blender pose-bone basis quaternions (F,J,4) and hips/bone basis locations."""
        sk = self.sk
        F, J = self.F, len(sk.names)
        Q = np.zeros((F, J, 4))
        locs = {}
        for i, p in enumerate(sk.parent):
            Lr = sk.L[i][:3, :3]
            if p < 0:
                Wp = np.tile(np.eye(3), (F, 1, 1))
                Pp = np.zeros((F, 3))
            else:
                Wp = self.W[:, p] @ np.linalg.inv(sk.R0[p])[None] @ sk.R0[p][None]  # = W_p
                Wp = self.W[:, p]
                Pp = self.P[:, p]
            # W_i = W_p_poseframe @ Lr @ B ; parent pose frame for a non-root is W_p (bone frame) so:
            B = np.einsum("ij,fjk->fik", Lr.T, np.einsum("fji,fjk->fik", Wp, self.W[:, i]))
            Q[:, i] = m2q(B)
            # continuity
            for f in range(1, F):
                if np.dot(Q[f, i], Q[f - 1, i]) < 0:
                    Q[f, i] = -Q[f, i]
            # basis translation: head_i = P_p + W_p @ (L.t + Lr @ t)
            if p < 0:
                d = self.P[:, i] - sk.L[i][:3, 3]
            else:
                d = np.einsum("fji,fj->fi", Wp, self.P[:, i] - Pp) - sk.L[i][:3, 3]
            t = d @ Lr          # (Lr^T d)
            if np.abs(t).max() > 1e-5:
                locs[sk.names[i]] = t
        return Q, locs


# ------------------------------------------------------------------------------------------- source handling
CMU_MAP = {
    # target bone: (source joint, mode). mode "align": rest swing onto source T-pose dir + deltas;
    # "delta": source global delta applied on the target's own rest (keeps target posture).
    "hips": ("Hips", "delta"),
    "spine1": ("LowerBack", "delta"), "spine2": ("Spine", "delta"), "chest": ("Spine1", "delta"),
    "neck1": ("Neck", "delta"), "neck2": (("Neck", "Neck1"), "delta"), "neck3": ("Neck1", "delta"),
    "head": ("Head", "delta"),
}
for _s, _S in (("L", "Left"), ("R", "Right")):
    CMU_MAP.update({
        "clavicle." + _s: (_S + "Shoulder", "align"), "upperarm." + _s: (_S + "Arm", "align"),
        "forearm." + _s: (_S + "ForeArm", "align"), "hand." + _s: (_S + "Hand", "align"),
        "thigh." + _s: (_S + "UpLeg", "align"), "shin." + _s: (_S + "Leg", "align"),
        "foot." + _s: (_S + "Foot", "delta"), "toe." + _s: (_S + "ToeBase", "delta"),
    })
CMU_CHILD = {"LeftShoulder": "LeftArm", "LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand",
             "LeftHand": "LeftFingerBase", "LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "LeftFoot": "LeftToeBase",
             "LeftToeBase": None}
for _k, _v in list(CMU_CHILD.items()):
    CMU_CHILD[_k.replace("Left", "Right")] = _v.replace("Left", "Right") if _v else None

CMU_UNIT = 0.057   # metres per BVH unit (approx; legs are normalised anyway)


class Source:
    """A resampled, frame-converted mocap segment: global rotations Rg (F,J,3,3), positions Pg (F,J,3)."""

    def __init__(self, path, t0, t1=None, fps=FPS, times=None, offset=0.0):
        """Sample [t0, t1] at fps (or explicit `times`, seconds on the clip's original timeline).
        offset: original time of frame 1 for trimmed files (frame 0 is always the T-pose)."""
        b = BVH(path)
        self.bvh = b
        rest_R, rest_P = b.fk([0], CMU_UNIT)      # frame 0 = T-pose (cgspeed release)
        self.rest_R, self.rest_P = rest_R[0], rest_P[0]
        if times is None:
            times = t0 + np.arange(int(round((t1 - t0) * fps)) + 1) / fps
        times = np.asarray(times, dtype=np.float64)
        n = len(b.data)
        if offset:
            fr = 1 + np.round((times - offset) * b.fps).astype(int)
        else:
            fr = np.round(times * b.fps).astype(int)
        self.frames = np.clip(fr, 1, n - 1)
        self.times = times
        self.Rg, self.Pg = b.fk(self.frames, CMU_UNIT)
        self.index = b.index
        self.names = b.names
        self.F = len(self.frames)

    def joint_dir_rest(self, j):
        if j.endswith("Hand"):          # finger joints have zero offsets: hand continues the forearm
            j = j.replace("Hand", "ForeArm")
        c = CMU_CHILD.get(j)
        if c is None:
            return self.rest_R[self.index[j]] @ self._end(j)
        return self.rest_P[self.index[c]] - self.rest_P[self.index[j]]

    def _end(self, j):
        from bvh import C
        return C @ np.array(self.bvh.end.get(self.index[j], [0, 0, 1.0])) * CMU_UNIT

    def leg_length(self):
        i = self.index
        return np.linalg.norm(self.rest_P[i["LeftUpLeg"]] - self.rest_P[i["LeftLeg"]]) + \
            np.linalg.norm(self.rest_P[i["LeftLeg"]] - self.rest_P[i["LeftFoot"]])

    def hip_height(self):
        """Rest hip-joint height above the ankle-ground plane."""
        i = self.index
        return self.rest_P[i["LeftUpLeg"], 2] - self.rest_P[i["LeftFoot"], 2]

    # -------------------------------------------------- editing
    def straighten(self, smooth_s=0.6, face=None):
        """Remove path curvature: express motion in a smoothed heading frame, then re-lay along -Y.
        face: if given (deg), only rotate the whole clip so its average heading points to -Y."""
        root = self.Pg[:, 0]
        hips_fwd = -self.Rg[:, 0][:, :, 1]   # rest forward is -Y (rig frame); delta-rotated
        # heading from the hips orientation relative to rest
        Rrel = self.Rg[:, 0] @ self.rest_R[0].T
        fwd = Rrel @ np.array([0, -1.0, 0])
        h = np.arctan2(fwd[:, 0], -fwd[:, 1])         # 0 = facing -Y; positive toward +X
        h = np.unwrap(h)
        if face is not None or smooth_s is None:
            hs = np.full(self.F, np.mean(h) - (0 if face is None else np.radians(face)))
        else:
            hs = smooth(h[:, None], smooth_s * FPS)[:, 0]
        # integrate velocity in the heading frame
        vel = np.diff(root, axis=0, prepend=root[:1])
        newroot = np.zeros_like(root)
        newroot[0] = [0, 0, root[0, 2]]
        Rz = np.array([axis_angle((0, 0, 1), a) for a in hs])     # rotates -Y heading by +a ... undo with transpose
        for f in range(1, self.F):
            v = Rz[f].T @ vel[f]
            newroot[f] = newroot[f - 1] + v
            newroot[f, 2] = root[f, 2]
        for f in range(self.F):
            A = Rz[f].T
            self.Rg[f] = A @ self.Rg[f]
            self.Pg[f] = newroot[f] + (self.Pg[f] - root[f]) @ A.T

    def loop_fix(self):
        """Make frame F-1 == frame 0 + root advance (distribute the residual linearly across the clip)."""
        F = self.F
        t = np.arange(F) / (F - 1)
        # rotations: correction C = R0 R_end^T applied progressively
        for j in range(len(self.names)):
            Rend = self.Rg[-1, j]
            Corr = self.Rg[0, j] @ Rend.T
            for f in range(F):
                Cf = slerp_mats(np.eye(3), Corr, t[f])
                self.Rg[f, j] = Cf @ self.Rg[f, j]
        # root height loop
        root = self.Pg[:, 0]
        dz = root[0, 2] - root[-1, 2]
        dx = root[0, 0] - root[-1, 0]     # lateral drift removed
        self.Pg[:, :, 2] += (dz * t)[:, None]
        self.Pg[:, :, 0] += (dx * t)[:, None]

    def recompute_positions(self):
        """Rebuild joint positions from (edited) rotations + root positions using BVH offsets."""
        from bvh import C
        b = self.bvh
        for j, p in enumerate(b.parent):
            if p < 0:
                continue
            off = C @ b.offset[j] * CMU_UNIT
            # rotations are global; parent's rotation applies to the child offset in the parent's frame:
            # offsets are in the parent's local frame expressed in BVH coords; in the rig frame the parent's
            # global rotation Rg_p (converted) acts on C@offset.
            self.Pg[:, j] = self.Pg[:, p] + np.einsum("fij,j->fi", self.Rg[:, p], off)


def find_cycle(path, t_from, t_to, min_period=0.8, max_period=1.6):
    """Best loop window [a, b] inside [t_from, t_to] by pose + velocity similarity (seconds)."""
    s = Source(path, t_from, t_to)
    R = s.Rg
    # pose feature: joint rotations relative to the hips (heading invariant) + root height
    Rh = np.einsum("fji,fkjl->fkil", R[:, 0], R)
    feat = Rh.reshape(s.F, -1)
    best = (1e9, 0, 0)
    for a in range(s.F):
        for b in range(a + int(min_period * FPS), min(s.F, a + int(max_period * FPS) + 1)):
            d = np.linalg.norm(feat[a] - feat[b])
            if a + 1 < s.F and b + 1 < s.F:
                d += 0.5 * np.linalg.norm((feat[a + 1] - feat[a]) - (feat[b + 1] - feat[b])) * 5
            if d < best[0]:
                best = (d, a, b)
    d, a, b = best
    return t_from + a / FPS, t_from + b / FPS, d


# ------------------------------------------------------------------------------------------- retarget
def retarget(src, sk, cfg):
    """Map source motion onto skeleton sk. cfg keys: stride (multiplier on leg-ratio scaling), inplace,
    root_xy ('keep'|'inplace'|'damp'), arm_spread (deg)."""
    F = src.F
    tr = Track(sk, F)
    idx = src.index
    # leg-length scale
    leg_t = np.linalg.norm(sk.H0[sk.index["thigh.L"]] - sk.H0[sk.index["shin.L"]]) + \
        np.linalg.norm(sk.H0[sk.index["shin.L"]] - sk.H0[sk.index["foot.L"]])
    k = leg_t / src.leg_length()
    hip_t = sk.H0[sk.index["thigh.L"], 2] - sk.H0[sk.index["foot.L"], 2]
    for n in sk.names:
        if n not in CMU_MAP:
            continue
        j, mode = CMU_MAP[n]
        i = sk.index[n]
        if isinstance(j, tuple):
            D = slerp_mats(src.Rg[:, idx[j[0]]] @ src.rest_R[idx[j[0]]].T,
                           src.Rg[:, idx[j[1]]] @ src.rest_R[idx[j[1]]].T, 0.5)
        else:
            D = src.Rg[:, idx[j]] @ src.rest_R[idx[j]].T
        if mode == "align":
            sd = src.joint_dir_rest(j)
            A = swing(sk.R0[i][:, 1], sd)
            tr.W[:, i] = D @ (A @ sk.R0[i])[None]
        else:
            tr.W[:, i] = D @ sk.R0[i][None]
    # unmapped children with no source (jaw, weapon, cloak...) inherit their parent's delta
    for i, n in enumerate(sk.names):
        if n in CMU_MAP or sk.parent[i] < 0:
            continue
        p = sk.parent[i]
        tr.W[:, i] = tr.W[:, p] @ sk.R0[p].T @ sk.R0[i]
    # root position: hips joint (source Hips) scaled
    sh = src.Pg[:, idx["Hips"]].copy()
    rest_h = src.rest_P[idx["Hips"]]
    ground_s = src.rest_P[idx["LeftFoot"], 2]
    stride = cfg.get("stride", 1.0)
    pos = np.zeros((F, 3))
    pos[:, :2] = (sh[:, :2] - sh[:1, :2]) * k * stride
    pos[:, 2] = sk.H0[sk.index["hips"], 2] + (sh[:, 2] - rest_h[2]) * k
    tr.P[:, sk.index["hips"]] = pos + np.array([sk.H0[sk.index["hips"], 0], sk.H0[sk.index["hips"], 1], 0])
    tr.fk()
    tr.scale = k
    return tr


# ------------------------------------------------------------------------------------------- IK + cleanup
def two_bone_ik(tr, upper, lower, end, target, pole_dir=None, end_rot=None):
    """Place bone `end`'s head at target (F,3) by rotating upper/lower. Keeps knee plane near pole_dir
    (F,3 world direction from the hip toward where the knee should point); end_rot (F,3,3) sets end world rot."""
    sk = tr.sk
    iu, il, ie = sk.index[upper], sk.index[lower], sk.index[end]
    a = sk.length[iu]
    b = sk.length[il]
    for f in range(tr.F):
        A = tr.P[f, iu]
        B = tr.P[f, il]
        C = tr.P[f, ie]
        T = target[f]
        d = T - A
        dl = np.clip(np.linalg.norm(d), abs(a - b) + 1e-4, a + b - 1e-4)
        dn = d / max(np.linalg.norm(d), 1e-9)
        pole = (B - A) if pole_dir is None else pole_dir[f]
        # knee position: in the plane of (dn, pole)
        pn = pole - dn * np.dot(pole, dn)
        if np.linalg.norm(pn) < 1e-6:
            pn = np.cross(dn, [1, 0, 0])
        pn /= np.linalg.norm(pn)
        cosA = (a * a + dl * dl - b * b) / (2 * a * dl)
        ang = np.arccos(np.clip(cosA, -1, 1))
        K = A + a * (dn * np.cos(ang) + pn * np.sin(ang))
        Tc = A + dn * dl
        # rotate upper: from (B-A) to (K-A)
        R1 = swing((B - A)[None], (K - A)[None])[0]
        _rot_frame(tr, f, iu, R1, A)
        # lower now at K; rotate lower from (C'-K) to (Tc-K)
        C2 = tr.P[f, ie]
        R2 = swing((C2 - K)[None], (Tc - K)[None])[0]
        _rot_frame(tr, f, il, R2, K)
        if end_rot is not None:
            Rr = end_rot[f] @ tr.W[f, ie].T
            _rot_frame(tr, f, ie, Rr, tr.P[f, ie])


def _rot_frame(tr, f, i, R, piv):
    ids = [i] + tr.descendants(i)
    for j in ids:
        tr.W[f, j] = R @ tr.W[f, j]
        tr.P[f, j] = piv + R @ (tr.P[f, j] - piv)


def detect_contacts(tr, foot, toe, h_thresh=0.06, v_thresh=0.6, cyclic=False, inplace_v=None):
    """Boolean (F,) contact mask for a foot: low and slow (velocity in the clip's root-motion world)."""
    sk = tr.sk
    p = tr.P[:, sk.index[foot]]
    pt = tr.tail(toe)
    if inplace_v is not None:
        p = p + np.asarray(inplace_v)[None] * np.arange(tr.F)[:, None]
    low = np.minimum(p[:, 2] - sk.H0[sk.index[foot], 2], pt[:, 2] - sk.tail_rest(toe)[2])
    v = np.linalg.norm(np.gradient(p, axis=0)[:, :2], axis=1) * FPS
    lo = np.percentile(low, 10)
    c = (low < lo + h_thresh) & (v < v_thresh)
    # morphological cleanup (remove 1-2 frame blips)
    c = _clean(c, 3, cyclic)
    return c


def _clean(c, n, cyclic):
    c = c.copy()
    F = len(c)
    # close gaps < n, remove islands < n
    for val in (False, True):
        i = 0
        while i < F:
            if c[i] == val:
                j = i
                while j < F and c[j] == val:
                    j += 1
                if j - i < n and (i > 0 or cyclic) and (j < F or cyclic):
                    c[i:j] = not val
                i = j
            else:
                i += 1
    return c


def segments(c, cyclic):
    F = len(c)
    segs = []
    i = 0
    while i < F:
        if c[i]:
            j = i
            while j < F and c[j]:
                j += 1
            segs.append([i, j])
            i = j
        else:
            i += 1
    if cyclic and len(segs) > 1 and segs[0][0] == 0 and segs[-1][1] == F:
        segs[0][0] = segs[-1][0] - F
        segs.pop()
    return segs


def foot_lock(tr, side, inplace_v=None, cyclic=False, floor=0.0, blend=4, contacts=None):
    """Lock planted foot positions (no sliding). inplace_v: (3,) per-frame root velocity removed for in-place
    loops (planted feet then slide back at exactly -v, which the game's movement cancels)."""
    sk = tr.sk
    foot, toe, thigh, shin = "foot." + side, "toe." + side, "thigh." + side, "shin." + side
    F = tr.F
    c = detect_contacts(tr, foot, toe, cyclic=cyclic, inplace_v=inplace_v) if contacts is None else contacts
    ia = sk.index[foot]
    P = tr.P[:, ia].copy()
    rest_z = sk.H0[ia, 2]
    target = P.copy()
    w = np.zeros(F)
    ground_rot = tr.W[:, ia].copy()
    # flat-foot orientation during contact: remove pitch/roll of the foot relative to rest (keep yaw)
    for f in range(F):
        fwd = tr.W[f, ia] @ (sk.R0[ia].T @ np.array([0, -1.0, 0]))
        yaw = np.arctan2(fwd[0], -fwd[1])
        ground_rot[f] = axis_angle((0, 0, 1), yaw) @ sk.R0[ia]
    vt = np.zeros(3) if inplace_v is None else np.asarray(inplace_v)
    for a, b in segments(c, cyclic):
        fr = np.arange(a, b) % F
        # planted point = position at the middle of the contact, in "world" coordinates (add back root motion)
        tt = np.arange(a, b)
        world = P[fr] + vt[None] * tt[:, None]
        anchor = np.median(world, axis=0)
        anchor[2] = rest_z + floor
        for k, f in zip(tt, fr):
            target[f] = anchor - vt * k
            target[f, 2] = rest_z + floor
            ramp = min(1.0, (k - a + 1) / blend, (b - k) / blend)
            w[f] = max(w[f], ramp)
    # smooth weights and blend targets
    if cyclic:
        w = smooth_cyclic(w[:, None], 1.0)[:, 0]
    else:
        w = smooth(w[:, None], 1.0)[:, 0]
    w = np.clip(w * 1.15, 0, 1)
    # swing phase: keep foot above floor
    tgt = P * (1 - w[:, None]) + target * w[:, None]
    tgt[:, 2] = np.maximum(tgt[:, 2], rest_z + floor - 0.005)
    rot = slerp_mats(tr.W[:, ia], ground_rot, w)
    pole = tr.P[:, sk.index[shin]] - tr.P[:, sk.index[thigh]]
    # pole: knee forward relative to the hips facing
    hips_fwd = np.einsum("fij,j->fi", tr.W[:, sk.index["hips"]] @ sk.R0[sk.index["hips"]].T[None], np.array([0, -1.0, 0]))
    pole = hips_fwd * 0.7 + pole * 0.3
    two_bone_ik(tr, thigh, shin, foot, tgt, pole_dir=pole, end_rot=rot)
    # toe: flatten during contact
    it = sk.index[toe]
    for f in range(F):
        if w[f] > 0:
            yaw_rot = ground_rot[f] @ sk.R0[ia].T @ sk.R0[it]
            Rt = slerp_mats(tr.W[f, it][None], yaw_rot[None], w[f])[0]
            _rot_frame(tr, f, it, Rt @ tr.W[f, it].T, tr.P[f, it])
    return c


# ------------------------------------------------------------------------------------------- secondary
def pendulum(tr, bone, stiffness=60.0, damping=9.0, gravity=0.0, cyclic=False, amount=1.0, max_deg=35):
    """Lag a bone's world direction behind its animated (target) direction with a damped spring (momentum).
    The bone's rotation (and its children) is rotated by the lag swing."""
    sk = tr.sk
    i = sk.index[bone]
    L = max(sk.length[i], 0.3)
    tgt_dir = tr.W[:, i][:, :, 1].copy()
    base = tr.P[:, i].copy()
    tip_t = base + tgt_dir * L
    dt = 1.0 / FPS
    passes = 3 if cyclic else 1
    x = tip_t[0].copy()
    v = np.zeros(3)
    out = np.zeros_like(tip_t)
    for p in range(passes):
        for f in range(tr.F):
            sub = 4
            for s in range(sub):
                h = dt / sub
                acc = stiffness * (tip_t[f] - x) - damping * v + np.array([0, 0, -gravity])
                v += acc * h
                x += v * h
                # keep at bone length from base
                d = x - base[f]
                x = base[f] + d / max(np.linalg.norm(d), 1e-9) * L
            out[f] = x
    lag_dir = out - base
    for f in range(tr.F):
        R = swing(tgt_dir[f][None], lag_dir[f][None])[0]
        # limit
        ang = np.arccos(np.clip((np.trace(R) - 1) / 2, -1, 1))
        lim = np.radians(max_deg)
        k = amount * (min(1.0, lim / ang) if ang > 1e-6 else 1.0)
        R = slerp_mats(np.eye(3)[None], R[None], k)[0]
        _rot_frame(tr, f, i, R, base[f])


def apply_local(tr, offsets, frames=None):
    """offsets: {bone: (F,3,3) or (3,3)} rotation in armature axes applied in the bone's frame
    (anims.py convention: local basis gets R0^T @ E @ R0)."""
    sk = tr.sk
    for n in sk.names:          # parent-first so children inherit
        if n not in offsets:
            continue
        i = sk.index[n]
        E = np.asarray(offsets[n])
        if E.ndim == 2:
            E = np.tile(E, (tr.F, 1, 1))
        # new W_i = W_i @ R0^T @ E @ R0  -> world delta = W_i R0^T E R0 W_i^T
        Dw = tr.W[:, i] @ sk.R0[i].T[None] @ E @ sk.R0[i][None] @ np.transpose(tr.W[:, i], (0, 2, 1))
        for f in range(tr.F):
            _rot_frame(tr, f, i, Dw[f], tr.P[f, i])


def from_local(tr, Q, locs=None):
    """Rebuild world rotations/positions of tr from local basis quaternions Q (F,J,4) (+ basis locations)."""
    sk = tr.sk
    B = q2m(Q)
    locs = locs or {}
    for i, p in enumerate(sk.parent):
        Lr, Lt = sk.L[i][:3, :3], sk.L[i][:3, 3]
        t = locs.get(sk.names[i])
        if p < 0:
            tr.W[:, i] = Lr[None] @ B[:, i]
            tr.P[:, i] = Lt[None] + (0 if t is None else t @ Lr.T)
        else:
            tr.W[:, i] = tr.W[:, p] @ Lr[None] @ B[:, i]
            off = Lt[None] + (0 if t is None else t @ Lr.T)
            tr.P[:, i] = tr.P[:, p] + np.einsum("fij,fj->fi", tr.W[:, p], np.broadcast_to(off, (tr.F, 3)))


def blend_local(Q, i, target_q, k):
    """Blend bone i's local quats toward target_q (4,) or (F,4) by k (scalar/(F,))."""
    tq = np.broadcast_to(target_q, Q[:, i].shape).copy()
    d = np.sum(Q[:, i] * tq, -1, keepdims=True)
    tq = np.where(d < 0, -tq, tq)
    k = np.asarray(k, dtype=np.float64)
    k = k[:, None] if k.ndim else k
    q = Q[:, i] * (1 - k) + tq * k
    Q[:, i] = q / np.linalg.norm(q, axis=-1, keepdims=True)


def mean_quat(q):
    q = q.copy()
    for f in range(1, len(q)):
        if np.dot(q[f], q[0]) < 0:
            q[f] = -q[f]
    m = q.mean(0)
    return m / np.linalg.norm(m)


def facing_frame(tr):
    """(F,3,3) yaw-only frames of the hips (columns: right(+X), back(+Y), up) for character-relative directions."""
    sk = tr.sk
    hi = sk.index["hips"]
    D = tr.W[:, hi] @ sk.R0[hi].T[None]
    fwd = D @ np.array([0, -1.0, 0])
    yaw = np.arctan2(fwd[:, 0], -fwd[:, 1])
    return np.array([axis_angle((0, 0, 1), a) for a in yaw])


def aim(tr, bone, local_dir, weight=1.0, axis_bone=None, frame="hips"):
    """Rotate `bone` (with children) so that axis_bone's Y axis (default: bone's own) points along local_dir
    (F,3) or (3,) given in the character's yaw frame (x = his left, -y = forward, z = up). weight (F,) or scalar."""
    sk = tr.sk
    i = sk.index[bone]
    ab = sk.index[axis_bone or bone]
    Y = facing_frame(tr) if frame == "hips" else np.tile(np.eye(3), (tr.F, 1, 1))
    d = np.broadcast_to(np.asarray(local_dir, dtype=np.float64), (tr.F, 3))
    tgt = np.einsum("fij,fj->fi", Y, d)
    w = np.broadcast_to(np.asarray(weight, dtype=np.float64), (tr.F,))
    for f in range(tr.F):
        if w[f] <= 1e-4:
            continue
        cur = tr.W[f, ab][:, 1]
        R = swing(cur[None], tgt[f][None])[0]
        if w[f] < 1:
            R = slerp_mats(np.eye(3)[None], R[None], w[f])[0]
        _rot_frame(tr, f, i, R, tr.P[f, i])
