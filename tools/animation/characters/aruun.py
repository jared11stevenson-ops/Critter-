"""Aruun (2.4 m, long neck, hunched, heavy; Morrow = spiked mace in the right hand, haft telescopes).

Every clip = CMU mocap segment (tools/animation/SOURCES.md) retargeted onto the 36-bone rig, then Aruun's
style layer (weight, hunch, wide arms clearing the pauldrons), foot-lock IK, Morrow momentum, and hand polish.
Pose offsets use the anims.py convention: (rx, ry, rz) degrees about armature axes; rx > 0 tips an upward bone
forward / swings a hanging limb back; ry > 0 tilts toward his left (+X); rz > 0 turns the front toward his left.
Character-frame directions: (x = his left, y = back, z = up), so forward is (0, -1, 0).
"""
import numpy as np

import lib
import retarget as rt
from retarget import FPS

CLIPS = ["idle", "walk", "jog", "run", "dash", "attack_1", "attack_2", "attack_3", "reaching_strike", "gravity_pull",
         "beetle_rage", "hit", "hit_back", "hit_left", "hit_right", "hit_heavy", "downed", "revive", "burden_hold",
         "talk_idle"]

# global style: arms out to clear the bulky torso, a bit more hunch, heavy head carriage
STYLE = {
    "upperarm.L": (0, -9, 0), "upperarm.R": (0, 9, 0),
    "forearm.L": (-6, 0, 0), "forearm.R": (-8, 0, 0),
    "chest": (4, 0, 0), "neck1": (3, 0, 0), "head": (-7, 0, 0),
}
# Morrow carried, not dragged: right elbow bent, haft angled forward/outward so the head clears the ground
CARRY = {"upperarm.R": (-6, 6, 0), "forearm.R": (-22, 0, 0)}
HAFT_CARRY = (-0.35, -0.42, -0.84)     # character frame: his right, forward, down
GRIP2 = 0.24                           # off-hand grip distance down the haft (m)
MORROW_HAFT = 0.78

_cache = {}


def jaw(tr, keys):
    """Open/close the mouth (jaw bone rx, degrees; + = open). keys: [(t, deg), ...]"""
    lib.layer(tr, {"jaw": [(t, (d, 0, 0)) for t, d in keys]})


def meta(tr, loop=False, impact=None, **kw):
    d = {"duration": round((tr.F - 1) / FPS, 4), "loop": loop, "impact": None if impact is None else round(impact, 3)}
    d.update(kw)
    return d


def mace_head(tr):
    sk = tr.sk
    i = sk.index["weapon_ext2"]
    return tr.P[:, i] + tr.W[:, i][:, :, 1] * MORROW_HAFT


def find_impact(tr, kind, near, win=0.15):
    """Measured impact time: 'sweep' = mace head crosses the front fastest, 'slam' = head bottoms out,
    'thrust' = haft fully extended forward. Searched within +-win of the authored guess `near`."""
    head = mace_head(tr)
    hip = tr.P[:, tr.sk.index["hips"]]
    t = np.arange(tr.F) / FPS
    m = np.abs(t - near) <= win
    rel = head - hip
    spd = np.linalg.norm(np.gradient(head, axis=0), axis=1) * FPS
    if kind == "sweep":
        ang = np.abs(np.degrees(np.arctan2(rel[:, 0], -rel[:, 1])))
        score = ang - 0.5 * spd
    elif kind == "slam":       # first frame the head is within 8 cm of its lowest point (contact, not settle)
        lo = np.min(np.where(m, head[:, 2], np.inf))
        score = np.where(head[:, 2] < lo + 0.08, t, np.inf)
    else:
        score = rel[:, 1]          # most forward (-Y)
    score = np.where(m, score, np.inf)
    return float(t[int(np.argmin(score))])


def ground_clamp(tr, r=0.26, floor=0.0):
    """Keep Morrow's head above the ground: rotate the weapon about the grip so the head rests on the floor."""
    sk = tr.sk
    i = sk.index["weapon"]
    for f in range(tr.F):
        h = mace_head(tr)[f]
        if h[2] >= floor + r:
            continue
        g = tr.P[f, i]
        v = h - g
        L = np.linalg.norm(v)
        zt = floor + r - g[2]
        if abs(zt) >= L:
            continue
        hor = v[:2] / max(np.linalg.norm(v[:2]), 1e-6) * np.sqrt(L * L - zt * zt)
        R = rt.swing(v[None], np.array([[hor[0], hor[1], zt]]))[0]
        rt._rot_frame(tr, f, i, R, g)


def base(sk, clip, t0=None, t1=None, warp=None, timescale=1.0, face=0.0, loop=False, style=True):
    src = lib.source(clip, t0, t1, timescale=timescale, warp=warp)
    src.straighten(face=face)
    if loop:
        src.loop_fix()
    src.recompute_positions()
    tr = rt.retarget(src, sk, {})
    if style:
        lib.layer(tr, STYLE)
    return tr


def carry(tr, d=HAFT_CARRY, w=1.0):
    rt.aim(tr, "weapon", d, w, axis_bone="weapon_ext1")


def haft_dir(tr):
    i = tr.sk.index["weapon_ext1"]
    return tr.W[:, i][:, :, 1]


def swing_weapon(tr, w=1.0, radial=0.65, lift=0.0):
    """Haft along the radial line chest->right hand (centrifugal), blended with the forearm axis."""
    sk = tr.sk
    hand = tr.P[:, sk.index["hand.R"]]
    piv = tr.P[:, sk.index["chest"]]
    rad = hand - piv
    rad /= np.linalg.norm(rad, axis=1, keepdims=True)
    fa = tr.W[:, sk.index["forearm.R"]][:, :, 1]
    d = radial * rad + (1 - radial) * fa
    d[:, 2] += lift
    d /= np.linalg.norm(d, axis=1, keepdims=True)
    rt.aim(tr, "weapon", d, w, axis_bone="weapon_ext1", frame="world")


def grip_left(tr, w, along=GRIP2):
    """Two-handed grip: left wrist IK'd onto Morrow's haft (weight curve w)."""
    sk = tr.sk
    w = np.broadcast_to(np.asarray(w, dtype=np.float64), (tr.F,))
    g = tr.P[:, sk.index["weapon"]] + haft_dir(tr) * along
    wrist = tr.P[:, sk.index["hand.L"]]
    tgt = wrist * (1 - w[:, None]) + g * w[:, None]
    Y = rt.facing_frame(tr)
    pole = np.einsum("fij,j->fi", Y, np.array([0.6, 0.1, -0.8]))
    rt.two_bone_ik(tr, "upperarm.L", "forearm.L", "hand.L", tgt, pole_dir=pole)
    # hand wraps the haft: point the hand along the haft direction
    hd = haft_dir(tr)
    i = sk.index["hand.L"]
    for f in range(tr.F):
        if w[f] > 0.05:
            R = rt.swing(tr.W[f, i][:, 1][None], hd[f][None])[0]
            R = rt.slerp_mats(np.eye(3)[None], R[None], w[f] * 0.7)[0]
            rt._rot_frame(tr, f, i, R, tr.P[f, i])


def plant(tr, cyclic=False, v=None, floor=0.0):
    for s in ("L", "R"):
        rt.foot_lock(tr, s, inplace_v=v, cyclic=cyclic, floor=floor)


def idle_pose(sk):
    if "idle" not in _cache:
        _cache["idle"] = idle(sk)[0]
    tr = _cache["idle"]
    return tr.local_quats()


def _blend_idle(tr, sk, k):
    Qi, li = idle_pose(sk)
    Q, locs = tr.local_quats()
    for i in range(Q.shape[1]):
        rt.blend_local(Q, i, Qi[0, i], k)
    for b, L in list(locs.items()) + [(b, np.zeros((tr.F, 3))) for b in li if b not in locs]:
        tgt = li.get(b, np.zeros((1, 3)))[0]
        locs[b] = L * (1 - k[:, None]) + tgt[None] * k[:, None]
    rt.from_local(tr, Q, locs)


def settle(tr, sk, t_from, t_to=None):
    """Blend the tail of a clip into idle frame 0 (seamless return to locomotion)."""
    t = np.arange(tr.F) / FPS
    t_to = (tr.F - 1) / FPS if t_to is None else t_to
    _blend_idle(tr, sk, lib.smoothstep(np.clip((t - t_from) / max(t_to - t_from, 1e-3), 0, 1)))


def from_idle(tr, sk, t_to):
    """Blend the head of a clip out of idle frame 0 (no pop when the clip starts)."""
    t = np.arange(tr.F) / FPS
    _blend_idle(tr, sk, lib.smoothstep(1 - np.clip(t / max(t_to, 1e-3), 0, 1)))


def telescope(tr, keys):
    """Morrow reach: keys [(t, length_factor)] -> weapon_ext1/2 slide along the haft (like anims.py)."""
    v = lib.curve(tr.F, [(t, (s,)) for t, s in keys])[:, 0]
    e = (v - 1.0) * MORROW_HAFT * 0.5
    for b in ("weapon_ext1", "weapon_ext2"):
        tr.loc[b] = np.stack([np.zeros(tr.F), e, np.zeros(tr.F)], 1)
    tr.fk()


def curve1(tr, keys):
    return lib.curve(tr.F, [(t, (v,)) for t, v in keys])[:, 0]


# ------------------------------------------------------------------------------------------- locomotion
def walk(sk):
    tr = base(sk, "35_01", 1.7667, 2.9, timescale=1.12, loop=True)   # slower cadence: bigger body
    lib.hold_local(tr, ["upperarm.R", "forearm.R", "hand.R"], 0.45)    # heavy weapon arm swings less
    lib.layer(tr, CARRY)
    carry(tr)
    lib.layer(tr, {"spine1": (5, 0, 0)})
    lib.shift(tr, (0, 0, -0.04))          # sink the hips: knees stay soft under the weight
    v = lib.make_inplace(tr)
    plant(tr, cyclic=True, v=v)
    rt.pendulum(tr, "weapon", stiffness=55, damping=7, cyclic=True, max_deg=25)
    lib.loop_blend(tr, 3)
    lib.phase_to_left_contact(tr, v)
    return tr, meta(tr, True, speed=round(float(np.linalg.norm(v)) * FPS, 3))


def _gait(sk, clip, t0, t1, lean, hold, haft, stiff, ts=1.0, sink=0.05):
    tr = base(sk, clip, t0, t1, timescale=ts, loop=True)
    lib.hold_local(tr, ["upperarm.R", "forearm.R", "hand.R"], hold)
    lib.layer(tr, CARRY)
    carry(tr, haft)
    lib.layer(tr, lean)
    lib.shift(tr, (0, 0, -sink))
    v = lib.make_inplace(tr)
    plant(tr, cyclic=True, v=v)
    rt.pendulum(tr, "weapon", stiffness=stiff, damping=6, cyclic=True, max_deg=35)
    lib.loop_blend(tr, 3)
    lib.phase_to_left_contact(tr, v)
    return tr, meta(tr, True, speed=round(float(np.linalg.norm(v)) * FPS, 3))


def jog(sk):
    return _gait(sk, "35_17", 0.6, 1.3667, {"spine1": (10, 0, 0), "chest": (4, 0, 0), "head": (-10, 0, 0)},
                 0.35, (-0.62, 0.1, -0.78), 45)


def run(sk):
    # heavy run: strong forward lean from the hips, head held level, Morrow trailing low
    return _gait(sk, "09_01", 0.4, 1.1333, {"spine1": (14, 0, 0), "chest": (6, 0, 0), "neck1": (-4, 0, 0),
                                            "head": (-14, 0, 0)}, 0.4, (-0.78, 0.25, -0.58), 40, sink=0.07)


def idle(sk):
    tr = base(sk, "137_41", 4.3, 7.2333, loop=True)
    lib.layer(tr, CARRY)
    carry(tr)
    lib.layer(tr, {"spine1": (4, 0, 0), "neck1": (0, 0, 12), "head": (30, 0, 22)})      # head turns back toward the camera/viewer (face readable)
    lib.shift(tr, (0, 0, -0.03))
    # slow breathing on top of the mocap weight shifts (2 breaths per loop)
    t = lib.timeline(tr.F)
    br = np.sin(t / ((tr.F - 1) / FPS) * 2 * np.pi * 2)
    z = np.zeros_like(br)
    lib.layer(tr, {"chest": np.stack([-1.6 * br, z, z], 1), "neck1": np.stack([0.8 * br, z, z], 1)})
    lib.remove_root_xy(tr, keep=0.3)
    plant(tr, cyclic=True)
    rt.pendulum(tr, "weapon", stiffness=40, damping=6, cyclic=True, max_deg=10)
    lib.loop_blend(tr, 8)
    return tr, meta(tr, True)


def talk_idle(sk):
    tr = base(sk, "139_25", 2.0333, 5.0333, loop=True)
    lib.layer(tr, CARRY)
    lib.layer(tr, {"spine1": (-10, 0, 0), "chest": (-4, 0, 0), "head": (4, 0, 0)})
    carry(tr)
    lib.remove_root_xy(tr, keep=0.0)
    lib.match_hip_height(tr, sk.H0[sk.index["hips"], 2] - 0.05)
    plant(tr, cyclic=True)
    rt.pendulum(tr, "weapon", stiffness=40, damping=6, cyclic=True, max_deg=12)
    lib.loop_blend(tr, 10)
    return tr, meta(tr, True)


def burden_hold(sk):
    """Arms braced overhead under a collapsing structure, legs wide and bent (push high object 81_11)."""
    tr = base(sk, "81_11", 7.2, 10.0, loop=True)
    lib.layer(tr, {"thigh.L": (-10, 6, 0), "thigh.R": (-10, -6, 0), "spine1": (-4, 0, 0), "head": (6, 0, 0)})
    lib.shift(tr, (0, 0, -0.12))
    lib.remove_root_xy(tr, keep=0.0)
    plant(tr, cyclic=True)
    swing_weapon(tr, 1.0, radial=0.2)     # Morrow stays in the fist, haft along the raised forearm
    lib.loop_blend(tr, 10)
    return tr, meta(tr, True)


# ------------------------------------------------------------------------------------------- combat
def attack_1(sk):
    """Horizontal right-to-left sweep (baseball swing 124_07), compressed anticipation."""
    warp = [(0.0, 2.30), (0.16, 2.72), (0.22, 2.86), (0.27, 2.98), (0.38, 3.10), (0.55, 3.25), (0.85, 3.50)]
    tr = base(sk, "124_07", warp=warp, face=-70)
    lib.remove_root_xy(tr, keep=0.2)
    swing_weapon(tr, 1.0, radial=0.75, lift=-0.45)
    grip_left(tr, curve1(tr, [(0, 0.6), (0.12, 1.0), (0.42, 1.0), (0.62, 0.0)]))
    from_idle(tr, sk, 0.12)
    settle(tr, sk, 0.5)
    carry(tr, w=curve1(tr, [(0, 1.0), (0.14, 0.0), (0.55, 0.0), (0.8, 1.0)]))
    plant(tr)
    ground_clamp(tr)
    jaw(tr, [(0, 0), (0.12, 14), (0.27, 30), (0.5, 12), (0.8, 0)])
    return tr, meta(tr, impact=find_impact(tr, "sweep", 0.27), cancel=0.4)


def attack_2(sk):
    """Overhead diagonal chop (wood chopping 79_01)."""
    warp = [(0.0, 0.55), (0.12, 0.80), (0.18, 0.90), (0.26, 1.03), (0.40, 1.20), (0.75, 1.55)]
    tr = base(sk, "79_01", warp=warp, face=0)
    lib.remove_root_xy(tr, keep=0.2)
    swing_weapon(tr, 1.0, radial=0.7)
    grip_left(tr, curve1(tr, [(0, 0.4), (0.12, 1.0), (0.45, 1.0), (0.65, 0.0)]))
    from_idle(tr, sk, 0.08)
    settle(tr, sk, 0.48)
    carry(tr, w=curve1(tr, [(0, 1.0), (0.08, 0.0), (0.5, 0.0), (0.75, 1.0)]))
    plant(tr)
    ground_clamp(tr)
    jaw(tr, [(0, 0), (0.14, 12), (0.30, 30), (0.55, 10), (0.7, 0)])
    return tr, meta(tr, impact=find_impact(tr, "slam", 0.30), cancel=0.4)


def attack_3(sk):
    """Finisher: big overhead wind-up, full-body slam into the ground (79_01 2nd chop, deeper + held)."""
    warp = [(0.0, 2.30), (0.18, 2.62), (0.30, 2.70), (0.38, 2.80), (0.44, 2.86), (0.62, 3.00), (1.0, 3.35)]
    tr = base(sk, "79_01", warp=warp, face=0)
    lib.layer(tr, {"spine1": [(0, (0, 0, 0)), (0.3, (-8, 0, 0)), (0.44, (18, 0, 0)), (0.7, (14, 0, 0)), (1.0, (0, 0, 0))],
                   "chest": [(0, (0, 0, 0)), (0.3, (-6, 0, 0)), (0.44, (10, 0, 0)), (1.0, (0, 0, 0))]})
    lib.shift(tr, lib.curve(tr.F, [(0, (0, 0, 0)), (0.3, (0, 0, 0.03)), (0.44, (0, 0, -0.16)), (0.7, (0, 0, -0.12)),
                                   (1.0, (0, 0, 0))]))
    lib.remove_root_xy(tr, keep=0.2)
    swing_weapon(tr, 1.0, radial=0.8)
    grip_left(tr, curve1(tr, [(0, 0.4), (0.15, 1.0), (0.6, 1.0), (0.85, 0.0)]))
    from_idle(tr, sk, 0.1)
    settle(tr, sk, 0.68)
    carry(tr, w=curve1(tr, [(0, 1.0), (0.1, 0.0), (0.72, 0.0), (1.0, 1.0)]))
    plant(tr)
    ground_clamp(tr)
    jaw(tr, [(0, 0), (0.2, 16), (0.47, 36), (0.8, 22), (1.0, 0)])
    return tr, meta(tr, impact=find_impact(tr, "slam", 0.47), cancel=0.62)


def hand_ik(tr, side, keys, w):
    """IK the wrist to character-frame targets keys [(t, (x, y, z))] (relative to the hips xy, absolute z)."""
    sk = tr.sk
    Y = rt.facing_frame(tr)
    loc = lib.curve(tr.F, keys)
    hip = tr.P[:, sk.index["hips"]].copy()
    tgt = np.einsum("fij,fj->fi", Y, np.c_[loc[:, :2], np.zeros(tr.F)]) + np.c_[hip[:, :2], loc[:, 2]]
    wr = tr.P[:, sk.index["hand." + side]]
    w = np.broadcast_to(np.asarray(w, dtype=np.float64), (tr.F,))
    tgt = wr * (1 - w[:, None]) + tgt * w[:, None]
    sx = 1 if side == "L" else -1
    pole = np.einsum("fij,j->fi", Y, np.array([0.7 * sx, 0.2, -0.7]))
    rt.two_bone_ik(tr, "upperarm." + side, "forearm." + side, "hand." + side, tgt, pole_dir=pole)


def reaching_strike(sk):
    """Lunge thrust (karate oi-zuki 135_09) - Morrow's haft telescopes forward to 2.3x."""
    warp = [(0.0, 2.20), (0.14, 2.42), (0.26, 2.56), (0.34, 2.64), (0.60, 2.85), (0.95, 3.2)]
    tr = base(sk, "135_09", warp=warp, face=0)
    lib.remove_root_xy(tr, keep=0.15)
    carry(tr)
    # draw back at hip height, then drive the fist straight out at chest height
    hand_ik(tr, "R", [(0, (-0.3, -0.3, 1.0)), (0.16, (-0.32, 0.25, 1.25)), (0.3, (-0.12, -0.78, 1.42)),
                      (0.6, (-0.12, -0.74, 1.42)), (0.9, (-0.3, -0.3, 1.0))],
            curve1(tr, [(0, 0.0), (0.12, 1.0), (0.65, 1.0), (0.9, 0.0)]))
    w_aim = curve1(tr, [(0, 0.0), (0.12, 1.0), (0.65, 1.0), (0.9, 0.0)])
    d = lib.curve(tr.F, [(0, HAFT_CARRY), (0.14, (-0.3, 0.75, 0.3)), (0.28, (0.05, -1.0, -0.06)),
                         (0.62, (0.05, -1.0, -0.06)), (0.9, HAFT_CARRY)])
    d /= np.linalg.norm(d, axis=1, keepdims=True)
    rt.aim(tr, "weapon", d, w_aim, axis_bone="weapon_ext1")
    telescope(tr, [(0, 1.0), (0.27, 1.0), (0.34, 2.3), (0.6, 2.3), (0.8, 1.0)])
    from_idle(tr, sk, 0.08)
    settle(tr, sk, 0.7)
    plant(tr)
    jaw(tr, [(0, 0), (0.14, 10), (0.34, 32), (0.7, 14), (0.9, 0)])
    return tr, meta(tr, impact=find_impact(tr, "thrust", 0.36), cancel=0.6)


def gravity_pull(sk):
    """Left hand reaches out to the point (Morrow floats there), then hauls back."""
    tr = base(sk, "137_41", 4.3, 5.35)        # idle body as the base (weight shift), arms are keyed
    lib.layer(tr, CARRY)
    carry(tr)
    lib.layer(tr, {
        "spine1": [(0, (0, 0, 0)), (0.3, (8, 0, 14)), (0.45, (9, 0, 14)), (0.6, (-10, 0, -16)), (1.05, (0, 0, 0))],
        "chest": [(0, (0, 0, 0)), (0.3, (4, 0, 8)), (0.6, (-8, 0, -10)), (1.05, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (0.3, (-6, 0, -6)), (0.6, (4, 0, 6)), (1.05, (0, 0, 0))],
        "thigh.L": [(0, (0, 0, 0)), (0.3, (-12, 0, 0)), (0.6, (10, 0, 0)), (1.05, (0, 0, 0))],
    })
    lib.shift(tr, lib.curve(tr.F, [(0, (0, 0, 0)), (0.3, (0, 0, -0.03)), (0.6, (0, 0, -0.08)), (1.05, (0, 0, 0))]))
    lib.remove_root_xy(tr, keep=0.0)
    # open hand thrust out toward the pull point, then a hard haul back to the chest
    hand_ik(tr, "L", [(0, (0.3, -0.2, 0.95)), (0.28, (0.3, -0.95, 1.6)), (0.45, (0.3, -1.0, 1.62)),
                      (0.58, (0.25, -0.25, 1.45)), (0.75, (0.3, -0.15, 1.2)), (1.05, (0.3, -0.2, 0.95))],
            curve1(tr, [(0, 0.0), (0.12, 1.0), (0.8, 1.0), (1.05, 0.0)]))
    lib.layer(tr, {"hand.L": [(0, (0, 0, 0)), (0.28, (40, 0, 0)), (0.45, (35, 0, 0)), (0.58, (-30, 0, 0)), (1.05, (0, 0, 0))]})
    plant(tr)
    jaw(tr, [(0, 0), (0.3, 18), (0.55, 26), (1.05, 0)])
    return tr, meta(tr, impact=0.55, cancel=0.75)


def beetle_rage(sk):
    """Crouch, then rear up and roar with arms flung wide (gorilla 80_49 for the body weight)."""
    warp = [(0.0, 4.0), (0.35, 4.35), (0.6, 4.62), (0.9, 4.85), (1.2, 5.1), (1.5, 5.6)]
    tr = base(sk, "80_49", warp=warp, face=0)
    lib.layer(tr, CARRY)
    lib.layer(tr, {
        "spine1": [(0, (0, 0, 0)), (0.35, (22, 0, 0)), (0.6, (-14, 0, 0)), (1.15, (-12, 0, 0)), (1.5, (0, 0, 0))],
        "chest": [(0, (0, 0, 0)), (0.35, (12, 0, 0)), (0.6, (-10, 0, 0)), (1.15, (-8, 0, 0)), (1.5, (0, 0, 0))],
        "neck1": [(0, (0, 0, 0)), (0.35, (8, 0, 0)), (0.6, (-10, 0, 0)), (1.15, (-8, 0, 0)), (1.5, (0, 0, 0))],
        "head": [(0, (0, 0, 0)), (0.35, (10, 0, 0)), (0.6, (-28, 0, 0)), (1.15, (-24, 0, 0)), (1.5, (0, 0, 0))],
        "jaw": [(0, (0, 0, 0)), (0.5, (0, 0, 0)), (0.62, (32, 0, 0)), (1.1, (28, 0, 0)), (1.3, (0, 0, 0))],
        "upperarm.L": [(0, (0, 0, 0)), (0.35, (-20, 10, 0)), (0.6, (-40, -70, 0)), (1.15, (-35, -65, 0)), (1.5, (0, 0, 0))],
        "upperarm.R": [(0, (0, 0, 0)), (0.35, (-20, -10, 0)), (0.6, (-40, 70, 0)), (1.15, (-35, 65, 0)), (1.5, (0, 0, 0))],
        "forearm.L": [(0, (0, 0, 0)), (0.35, (-80, 0, 0)), (0.6, (-40, 0, 0)), (1.5, (0, 0, 0))],
        "forearm.R": [(0, (0, 0, 0)), (0.35, (-80, 0, 0)), (0.6, (-40, 0, 0)), (1.5, (0, 0, 0))],
    })
    lib.shift(tr, lib.curve(tr.F, [(0, (0, 0, 0)), (0.35, (0, 0, -0.18)), (0.6, (0, 0, 0.02)), (1.15, (0, 0, 0)),
                                   (1.5, (0, 0, 0))]))
    lib.remove_root_xy(tr, keep=0.0)
    carry(tr)
    swing_weapon(tr, curve1(tr, [(0, 0.0), (0.45, 1.0), (1.15, 1.0), (1.45, 0.0)]), radial=0.5)
    from_idle(tr, sk, 0.1)
    settle(tr, sk, 1.2)
    plant(tr)
    return tr, meta(tr, impact=0.6, cancel=1.2)


def dash(sk):
    """Heavy forward burst: low drive step, body leading, Morrow trailing (49_04 run-leap drive phase)."""
    warp = [(0.0, 1.05), (0.08, 1.17), (0.22, 1.32), (0.32, 1.42), (0.45, 1.6)]
    tr = base(sk, "49_04", warp=warp, face=0)
    lib.layer(tr, CARRY)
    lib.layer(tr, {"spine1": [(0, (0, 0, 0)), (0.08, (24, 0, 0)), (0.3, (20, 0, 0)), (0.45, (6, 0, 0))],
                   "head": [(0, (0, 0, 0)), (0.08, (-20, 0, 0)), (0.3, (-16, 0, 0)), (0.45, (-6, 0, 0))]})
    lib.remove_root_xy(tr, keep=0.0)
    hz = tr.P[:, tr.sk.index["hips"], 2]
    top = sk.H0[sk.index["hips"], 2] - 0.06       # no airborne hop: a heavy body stays low
    lib.shift(tr, np.stack([np.zeros(tr.F), np.zeros(tr.F), -np.clip(hz - top, 0, None)], 1))
    carry(tr, (-0.4, 0.55, -0.7))
    rt.pendulum(tr, "weapon", stiffness=40, damping=5, max_deg=30)
    from_idle(tr, sk, 0.06)
    settle(tr, sk, 0.32)
    jaw(tr, [(0, 0), (0.08, 24), (0.3, 18), (0.45, 0)])
    return tr, meta(tr, impact=0.08, cancel=0.3)


# ------------------------------------------------------------------------------------------- reactions
def _hit(sk, recoil, dur=0.45, peak=0.07, hips=(0, 0.06, -0.03), scale=1.0):
    tr = base(sk, "137_41", 4.3, 4.3 + dur)
    lib.layer(tr, CARRY)
    carry(tr)

    def keys(v):
        v = np.array(v) * scale
        return [(0, (0, 0, 0)), (peak, tuple(v)), (peak + 0.12, tuple(v * 0.55)), (dur, (0, 0, 0))]
    lib.layer(tr, {b: keys(v) for b, v in recoil.items()})
    lib.shift(tr, lib.curve(tr.F, [(0, (0, 0, 0)), (peak, tuple(np.array(hips) * scale)), (dur, (0, 0, 0))]))
    jaw(tr, [(0, 0), (peak, 26 * scale), (peak + 0.15, 14 * scale), (dur, 0)])
    rt.pendulum(tr, "weapon", stiffness=70, damping=11, max_deg=20)
    settle(tr, sk, dur * 0.6)
    plant(tr)
    return tr, meta(tr, impact=peak)


def hit(sk):        # struck from the front: chest and head snap back
    return _hit(sk, {"spine1": (-12, 0, 4), "chest": (-8, 0, 0), "neck1": (-6, 0, 0), "head": (-16, 0, 6),
                     "upperarm.L": (12, -16, 0), "upperarm.R": (10, 6, 0)})


def hit_back(sk):   # from behind: pitched forward
    return _hit(sk, {"spine1": (14, 0, 0), "chest": (8, 0, 0), "head": (12, 0, 0), "upperarm.L": (-18, -10, 0),
                     "upperarm.R": (-14, 10, 0)}, hips=(0, -0.06, -0.04))


def hit_left(sk):   # from his left: bends away to the right
    return _hit(sk, {"spine1": (-4, -12, -10), "chest": (0, -8, -6), "head": (0, -12, -10), "upperarm.L": (0, -28, 0)},
                hips=(-0.06, 0, -0.03))


def hit_right(sk):
    return _hit(sk, {"spine1": (-4, 12, 10), "chest": (0, 8, 6), "head": (0, 12, 10), "upperarm.R": (0, 28, 0)},
                hips=(0.06, 0, -0.03))


def hit_heavy(sk):  # stagger: bigger, slower recoil + knees buckle
    return _hit(sk, {"spine1": (-18, 0, 6), "chest": (-10, 0, 0), "neck1": (-8, 0, 0), "head": (-22, 0, 8),
                     "upperarm.L": (18, -24, 0), "upperarm.R": (14, 8, 0)}, dur=0.8, peak=0.12, hips=(0, 0.1, -0.12))


def revive(sk):
    """Hands-and-knees -> push up -> stand (get up from ground 139_16), heavy and deliberate."""
    warp = [(0.0, 1.8), (0.5, 2.3), (0.9, 2.75), (1.3, 3.3), (1.6, 3.7)]
    tr = base(sk, "139_16", warp=warp, face=0)
    lib.remove_root_xy(tr, keep=0.0)
    lib.ground_body(tr)
    carry(tr)
    settle(tr, sk, 1.3)
    plant(tr)
    ground_clamp(tr)
    return tr, meta(tr, impact=1.3)


def downed(sk):
    """Collapse: knees buckle, falls forward onto hands (139_16 get-up, reversed and accelerated)."""
    warp = [(0.0, 3.7), (0.15, 3.45), (0.45, 2.75), (0.7, 2.25), (0.85, 1.95), (1.1, 1.8)]
    tr = base(sk, "139_16", warp=warp, face=0)
    lib.layer(tr, {"spine1": [(0, (0, 0, 0)), (0.12, (-10, 0, 6)), (0.4, (6, 0, 0)), (1.1, (0, 0, 0))],
                   "head": [(0, (0, 0, 0)), (0.12, (-14, 0, 8)), (0.6, (10, 0, 0)), (1.1, (14, 0, 0))]})
    lib.remove_root_xy(tr, keep=0.0)
    from_idle(tr, sk, 0.1)
    lib.ground_body(tr)
    carry(tr, w=curve1(tr, [(0, 1.0), (0.5, 0.0)]))
    jaw(tr, [(0, 0), (0.15, 22), (0.6, 12), (1.1, 6)])
    plant(tr)
    ground_clamp(tr)
    return tr, meta(tr, impact=0.85)


def cloak_lag(tr, cyclic=False):
    """Secondary motion (idempotent): the ragged cloak is a two-bone chain; each bone lags the body with its own spring,
    so a turn or a swing whips the hem after the shoulders (follow-through)."""
    if getattr(tr, "_cloak", False) or "cloak" not in tr.sk.index:
        return
    tr._cloak = True
    rt.pendulum(tr, "cloak", stiffness=36, damping=5, cyclic=cyclic, max_deg=24)
    if "cloak2" in tr.sk.index:
        rt.pendulum(tr, "cloak2", stiffness=24, damping=4, cyclic=cyclic, max_deg=38)


def build(name, sk):
    if name == "idle":
        _cache.clear()
    tr, m = globals()[name](sk)
    cloak_lag(tr, cyclic=bool(m.get("loop")))
    return tr, m
