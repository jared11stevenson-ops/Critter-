"""Clip-building helpers shared by character configs (characters/<id>.py)."""
import os

import numpy as np

import retarget as rt
from retarget import FPS

HERE = os.path.dirname(os.path.abspath(__file__))
MOCAP = os.path.join(HERE, "mocap")
RAW = os.environ.get("CMU_BVH_DIR", "/tmp/claude-0/mocap/cmu-mocap/data")
MANIFEST = os.path.join(MOCAP, "manifest.json")


def mocap_file(clip):
    """Trimmed committed copy (tools/animation/mocap/cmu/<clip>.bvh, see fetch_mocap.py) or the raw download."""
    import json
    p = os.path.join(MOCAP, "cmu", clip + ".bvh")
    if os.path.exists(p) and os.path.exists(MANIFEST):
        off = json.load(open(MANIFEST))[clip]["offset"]
        return p, off
    s = clip.split("_")[0]
    return os.path.join(RAW, "%03d" % int(s), clip + ".bvh"), 0.0


USED = {}     # clip -> [min_t, max_t] of every source window read (for trim_mocap.py)


def source(clip, t0, t1=None, timescale=1.0, warp=None):
    """warp: [(out_t, src_t), ...] piecewise-linear time map (overrides t0/t1/timescale)."""
    path, off = mocap_file(clip)
    if warp is not None:
        w = np.array(warp, dtype=np.float64)
        out = np.arange(0, w[-1, 0] + 1e-6, 1.0 / FPS)
        times = np.interp(out, w[:, 0], w[:, 1])
    else:
        n = int(round((t1 - t0) * FPS * timescale))
        times = t0 + np.arange(n + 1) / (FPS * timescale)
    u = USED.setdefault(clip, [1e9, -1e9])
    u[0] = min(u[0], float(times.min()))
    u[1] = max(u[1], float(times.max()))
    return rt.Source(path, None, times=times, offset=off)


def smoothstep(x):
    x = np.clip(x, 0, 1)
    return x * x * (3 - 2 * x)


def curve(F, keys, ease=True, cyclic=False):
    """keys [(t, value-tuple), ...] -> (F, n) per-frame values, eased between keys."""
    t = np.arange(F) / FPS
    ks = sorted(keys, key=lambda k: k[0])
    vals = np.array([k[1] for k in ks], dtype=np.float64)
    ts = np.array([k[0] for k in ks])
    out = np.zeros((F, vals.shape[1]))
    for f in range(F):
        x = t[f]
        if x <= ts[0]:
            out[f] = vals[0]
        elif x >= ts[-1]:
            out[f] = vals[-1]
        else:
            j = np.searchsorted(ts, x) - 1
            u = (x - ts[j]) / (ts[j + 1] - ts[j])
            out[f] = vals[j] + (vals[j + 1] - vals[j]) * (smoothstep(u) if ease else u)
    return out


def euler_track(vals):
    """(F,3) degrees -> (F,3,3)."""
    return np.array([rt.euler_zyx(*v) for v in vals])


def layer(tr, poses):
    """Additive local rotations. poses: {bone: (rx,ry,rz) | [(t,(rx,ry,rz)),...] | (F,3) array}."""
    offs = {}
    for b, v in poses.items():
        if b not in tr.sk.index:
            continue
        if isinstance(v, np.ndarray) and v.ndim == 2:
            offs[b] = euler_track(v)
        elif isinstance(v, list):
            offs[b] = euler_track(curve(tr.F, v))
        else:
            offs[b] = rt.euler_zyx(*v)
    rt.apply_local(tr, offs)


def shift(tr, d):
    """Translate the whole skeleton by d ((3,) or (F,3))."""
    d = np.broadcast_to(np.asarray(d, dtype=np.float64), (tr.F, 3))
    m = _movable(tr)
    tr.P[:, m] += d[:, None, :]


def _movable(tr):
    """All bones except armature roots (their head is fixed; they are not animated)."""
    return np.array([p >= 0 for p in tr.sk.parent])


def make_inplace(tr):
    """Remove the average horizontal root velocity; returns per-frame velocity (3,) (metres/frame)."""
    hi = tr.sk.index["hips"]
    r = tr.P[:, hi]
    v = (r[-1] - r[0]) / (tr.F - 1)
    v[2] = 0
    shift(tr, -v[None] * np.arange(tr.F)[:, None])
    # centre the loop on the origin (horizontal)
    c = tr.P[:, hi, :2].mean(0) - tr.sk.H0[hi, :2]
    tr.P[:, _movable(tr), :2] -= c
    return v


def remove_root_xy(tr, keep=0.0, smooth_s=0.0):
    """Non-looping clips: keep `keep` fraction of horizontal root motion relative to frame 0."""
    hi = tr.sk.index["hips"]
    r = tr.P[:, hi, :2] - tr.P[:1, hi, :2]
    d = -r * (1 - keep)
    full = np.zeros((tr.F, 3))
    full[:, :2] = d
    shift(tr, full)
    tr.P[:, _movable(tr), :2] -= tr.P[:1, hi, :2] - tr.sk.H0[hi, :2]


def loop_blend(tr, n=6):
    """Force exact seam: last frame := first, blending the last n frames toward the start (local space)."""
    Q, locs = tr.local_quats()
    F = tr.F
    for k in range(1, n + 1):
        f = F - k
        w = rt.smoothstep(1 - (k - 1) / n) if hasattr(rt, "smoothstep") else smoothstep(1 - (k - 1) / n)
        for i in range(Q.shape[1]):
            rt.blend_local(Q[f:f + 1], i, Q[0, i], w)
        for b in locs:
            locs[b][f] = locs[b][f] * (1 - w) + locs[b][0] * w
    rt.from_local(tr, Q, locs)


def hold_local(tr, bones, k, frames=None):
    """Damp bone motion: blend bone local rotation toward its clip mean by k (scalar or (F,))."""
    Q, locs = tr.local_quats()
    for b in bones:
        i = tr.sk.index[b]
        m = rt.mean_quat(Q[:, i])
        rt.blend_local(Q, i, m, k)
    rt.from_local(tr, Q, locs)
    return Q


def pose_blend(tr, Qpose, k):
    """Blend whole local pose toward Qpose ((J,4) or (F,J,4)) by k ((F,) weights)."""
    Q, locs = tr.local_quats()
    Qp = np.broadcast_to(Qpose, Q.shape)
    for i in range(Q.shape[1]):
        rt.blend_local(Q, i, Qp[:, i], k)
    rt.from_local(tr, Q, locs)


def timeline(F):
    return np.arange(F) / FPS


def ground_body(tr, clearance=None, sigma=1.5, only_below=False):
    """Shift the body vertically per frame so its lowest contact point (knees, feet, toes, hands) touches z=0.
    clearance: per-point radius (m). only_below: only lift parts that penetrate (never pull down)."""
    sk = tr.sk
    pts = []
    for s in ("L", "R"):
        pts += [(tr.P[:, sk.index["shin." + s]], 0.09), (tr.P[:, sk.index["foot." + s]], 0.16),
                (tr.tail("toe." + s), 0.02), (tr.tail("hand." + s), 0.03)]
    lo = np.min(np.stack([p[:, 2] - r for p, r in pts], 1), axis=1)
    d = -lo
    if only_below:
        d = np.maximum(d, 0)
    d = rt.smooth(d[:, None], sigma)[:, 0]
    shift(tr, np.c_[np.zeros(tr.F), np.zeros(tr.F), d])
    return d


def match_hip_height(tr, z, k=1.0):
    """Raise/lower the hips so their mean height is z (legs then re-straightened by foot IK)."""
    hi = tr.sk.index["hips"]
    dz = (z - tr.P[:, hi, 2].mean()) * k
    shift(tr, (0, 0, dz))
