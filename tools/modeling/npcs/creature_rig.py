"""Procedural gait clips for non-humanoid NPC rigs (multi-legged: Nyxaris, Solmara).

A spec supplies LEGS = [(bones tuple of 2-3 bone names, side +1/-1, phase 0..1, leg_len_m)], optional BODY bones
(hips/chest/head/arms) and tuning; clips are authored as per-frame armature-axis rotations (anims.py convention),
converted to bone-local quaternions and baked by tools/animation/apply.bake.
"""
import math

import numpy as np

import retarget as rt
from retarget import FPS


class Track:
    def __init__(self, sk, F, Q, locs):
        self.sk, self.F, self.Q, self.locs = sk, F, Q, locs

    def local_quats(self):
        return self.Q, self.locs


def _compose(sk, F, pose_fn):
    """pose_fn(f) -> {bone: (rx, ry, rz) deg, "hips_loc": (x, y, z)} for frame f."""
    nb = len(sk.names)
    Q = np.zeros((F, nb, 4))
    Q[:, :, 0] = 1.0
    locs = {}
    hl = np.zeros((F, 3))
    for f in range(F):
        p = pose_fn(f)
        for bn, v in p.items():
            if bn == "hips_loc":
                hl[f] = v
                continue
            if bn not in sk.index:
                continue
            i = sk.index[bn]
            R0 = sk.R0[i]
            E = rt.euler_zyx(*v)
            Q[f, i] = rt.m2q(R0.T @ E @ R0)
    if "hips" in sk.index:
        R0 = sk.R0[sk.index["hips"]]
        locs["hips"] = hl @ R0        # armature-space offset -> bone-local (R0^T v == v @ R0)
    return Q, locs


def _meta(F, loop, impact=None, **kw):
    d = {"duration": round((F - 1) / FPS, 4), "loop": loop, "impact": impact}
    d.update(kw)
    return d


def clips(spec, sk):
    legs = spec.LEGS
    speed = getattr(spec, "WALK_SPEED", 1.0)
    swing = getattr(spec, "SWING", 20.0)
    out = {}

    def leg_pose(phase_t, amp, lift, sw=swing):
        p = {}
        for bones, side, ph, L in legs:
            a = 2 * math.pi * (phase_t + ph)
            s = math.sin(a)
            c = math.cos(a)
            up = max(0.0, c)
            p[bones[0]] = (-sw * s * amp + lift * up * amp * 0.6, 0.0, 0.0)
            if len(bones) > 1:
                p[bones[1]] = (lift * up * amp * 0.9, 0, 0)
            if len(bones) > 2:
                p[bones[2]] = (-lift * up * amp * 0.5, 0, 0)
        return p

    def merge(*ds):
        o = {}
        for d in ds:
            for k, v in d.items():
                if k in o and isinstance(v, tuple) and isinstance(o[k], tuple) and k != "hips_loc":
                    o[k] = tuple(a + b for a, b in zip(o[k], v))
                elif k in o and k == "hips_loc":
                    o[k] = tuple(a + b for a, b in zip(o[k], v))
                else:
                    o[k] = v
        return o

    def body(t, T, amp, bob):
        w = 2 * math.pi * t / T
        d = {"hips_loc": (0, 0, bob * abs(math.sin(w * 2 * 0.5 * 2)) * -1.0 + 0.0)}
        d.update(getattr(spec, "body_pose", lambda w, amp: {})(w, amp))
        return d

    # idle (breathing, tiny weight shift), loops
    T = 3.2
    F = int(T * FPS) + 1
    out["idle"] = (Track(sk, F, *_compose(sk, F, lambda f: merge(
        leg_pose(f / FPS / T, 0.06, 4.0, 4.0), body(f / FPS, T, 0.0, 0.0),
        {"hips_loc": (0, 0, 0.012 * spec.HEIGHT * math.sin(2 * math.pi * f / FPS / T))},
        getattr(spec, "idle_pose", lambda w: {})(2 * math.pi * f / FPS / T)))), _meta(F, True))

    # walk: swing amplitude gives the speed; period from v = 4 s / T
    Lmean = float(np.mean([l[3] for l in legs]))
    s_half = Lmean * math.sin(math.radians(swing))
    T = max(0.5, 4 * s_half / speed)
    F = int(round(T * FPS))
    F += 1
    out["walk"] = (Track(sk, F, *_compose(sk, F, lambda f: merge(
        leg_pose((f % (F - 1)) / FPS / T, 1.0, swing * 1.2),
        {"hips_loc": (0, 0, -0.012 * spec.HEIGHT * abs(math.sin(2 * math.pi * f / FPS / T * 2)))},
        getattr(spec, "walk_pose", lambda w: {})(2 * math.pi * f / FPS / T)))), _meta(F, True, speed=round(speed, 3)))

    # talk_idle / gesture / react
    T = 2.4
    F = int(T * FPS) + 1
    out["talk_idle"] = (Track(sk, F, *_compose(sk, F, lambda f: merge(
        leg_pose(f / FPS / T, 0.05, 3.0, 3.0),
        getattr(spec, "talk_pose", lambda w: {})(2 * math.pi * f / FPS / T)))), _meta(F, True))
    T = 1.5
    F = int(T * FPS) + 1
    out["gesture"] = (Track(sk, F, *_compose(sk, F, lambda f: merge(
        getattr(spec, "gesture_pose", lambda u: {})(f / FPS / T)))), _meta(F, False, 0.5))
    out["wave"] = (Track(sk, F, *_compose(sk, F, lambda f: merge(
        getattr(spec, "gesture_pose", lambda u: {})(f / FPS / T)))), _meta(F, False, 0.5))
    T = 0.5
    F = int(T * FPS) + 1

    def react(f):
        u = f / FPS / T
        k = math.sin(math.pi * min(1.0, u * 1.0)) ** 1.5
        return merge({"hips_loc": (0, 0.03 * spec.HEIGHT * k, -0.02 * spec.HEIGHT * k)},
                     getattr(spec, "react_pose", lambda k: {})(k))
    out["react"] = (Track(sk, F, *_compose(sk, F, react)), _meta(F, False, 0.07))
    out["hit"] = out["react"]
    return out
