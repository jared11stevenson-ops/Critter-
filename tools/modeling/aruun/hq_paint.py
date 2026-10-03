"""Aruun HQ surface paint: per-vertex colour / roughness / metal / emission on the HIGH-poly components.

Painted in 3D (rest pose, Blender space: Z up, faces -Y, his left = +X) so patterns are seamless, then transferred
to the game mesh texels by hq_game.py. Colours are the sheet palette (design/model_sheets/aruun/palette.json,
detail_*.png): dark aubergine-navy body chitin with tan plates, cream specks and red-orange calf mottling; red
ladybug carapace (yellow + black spots, cream lower patch); cream bone; olive leaf skirt; dark olive cloak;
Morrow = dark stone ball, cream bone bosses, bronze spikes, red Thoughtstone core with glowing cracks.

All colours are sRGB 0..1. Values are pushed a little darker / more saturated than the flat sheet because the
Red Reaches key light + sky ambient + AgX tonemap lift and desaturate in-engine.
"""
import numpy as np
import torch

from common import sdf2


def hx(h):
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)])


# ------------------------------------------------------------------------------------------------ palette
NAVY = hx("#221a1e")        # body chitin (sheet #281e1e / #34282a, darkened)
NAVY2 = hx("#33262c")       # lighter body chitin sheen patches
TAN = hx("#b98a5e")         # tan plates (sheet #c69b70)
CREAM = hx("#d6bc8e")       # cream bone / bandage
CREAM_D = hx("#a88762")
RED = hx("#9a3426")         # carapace red (sheet #953d32)
RED_D = hx("#5e1d15")       # deep red (sheet #6d2a1b)
ORANGE = hx("#b5522f")      # calf / neck orange (sheet #a4553a)
YELLOW = hx("#e7ad55")      # ladybug spot (sheet #e3a865)
INK = hx("#140f12")         # outline / black spots
OLIVE = hx("#7b7a38")       # leaf panels
OLIVE_L = hx("#a9a253")
OLIVE_D = hx("#4a4526")
CLOAK = hx("#3a3528")
CLOAK_L = hx("#6b6247")
SASH = hx("#8c2c22")
LEATHER = hx("#4e3123")
GOLD = hx("#c99a3c")
STONE = hx("#2a2224")
STONE_L = hx("#4a3d3a")
BRONZE = hx("#9a7350")
CORE = hx("#c4271e")
CORE_HOT = hx("#ffb25a")
EYE = hx("#f0c63a")


def T(P):
    return torch.as_tensor(np.asarray(P, dtype=np.float32))


def nz(P, freq, seed, octaves=3):
    """fbm in roughly [-1, 1]."""
    with torch.no_grad():
        return (sdf2.fbm(T(P), freq, octaves, seed) * 2.0).numpy()


def vor(P, freq, seed):
    with torch.no_grad():
        f1, f2 = sdf2.voronoi(T(P), freq, seed)
    return f1.numpy(), f2.numpy()


def mix(a, b, t):
    t = np.asarray(t, dtype=np.float64)
    if t.ndim == 1:
        t = t[:, None]
    return a * (1 - t) + b * t


def ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def blob(P, freq, thr, seed, edge=0.06, warp=0.0):
    """Painterly patch mask: sharp-edged thresholded noise + an ink rim just outside the patch.
    Returns (inside 0..1, rim 0..1)."""
    Q = P
    if warp:
        Q = P + warp * np.stack([nz(P, freq * 0.7, seed + 101, 2), nz(P, freq * 0.7, seed + 102, 2),
                                 nz(P, freq * 0.7, seed + 103, 2)], 1)
    n = nz(Q, freq, seed, 3)
    inside = ss(thr - 0.02, thr + 0.02, n)
    rim = ss(thr - edge, thr - 0.02, n) * (1 - inside)
    return inside, rim


def specks(P, freq, seed, size=0.12, keep=0.35):
    """Sparse round dots (sheet's 'starry' cream specks)."""
    f1, _ = vor(P, freq, seed)
    sel = nz(P, freq * 0.5, seed + 7, 1) > (1 - 2 * keep)
    return ss(size, size * 0.6, f1) * sel


class Paint:
    def __init__(self, n):
        self.rgb = np.zeros((n, 3))
        self.rough = np.full(n, 0.5)
        self.metal = np.zeros(n)
        self.emit = np.zeros((n, 3))


# ------------------------------------------------------------------------------------------------ body
def body(P, N, labels, curv):
    """labels: per-vertex nearest body sub-part (torso, neck, arm.L, hand.L, leg.L, foot.L, ...)."""
    out = Paint(len(P))
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    lab = np.asarray(labels)
    base = labels_is(lab, "torso", "arm", "leg", "hand")
    col = np.tile(NAVY, (len(P), 1))
    # subtle sheen variation in the dark chitin
    col = mix(col, NAVY2, np.clip(nz(P, 6.0, 3), 0, 1) * 0.8)
    rough = np.full(len(P), 0.42)
    # --- tan segmented abdomen plates (front torso)
    front = ss(-0.06, -0.11, y) * ss(1.08, 1.14, z) * ss(1.5, 1.44, z) * labels_is(lab, "torso")
    seg = np.abs(np.sin((z - 1.1) * np.pi / 0.075))
    abd = front * ss(0.18, 0.12, np.abs(x)) * (1 - 0.85 * ss(0.12, 0.04, seg))
    col = mix(col, TAN, abd)
    # ink lines between segments + midline
    col = mix(col, INK, front * ss(0.18, 0.12, np.abs(x)) * (ss(0.1, 0.03, seg) + ss(0.008, 0.003, np.abs(x))).clip(0, 1) * 0.8)
    # --- big painted patches: tan on thighs (front-outer + back hamstrings), arms (inner forearm), torso sides
    legs = labels_is(lab, "leg")
    arms = labels_is(lab, "arm")
    pin, prim = blob(P, 5.5, 0.18, 11, warp=0.03)
    ham = legs * ss(-0.02, 0.05, y - np.interp(z, [0.2, 1.0], [0.06, 0.02])) * ss(0.35, 0.5, z)   # back of the legs
    knee_front = legs * ss(0.0, -0.04, y) * ss(0.45, 0.55, z) * ss(0.75, 0.65, z)
    thigh_side = legs * ss(0.7, 0.8, z) * ss(0.1, 0.2, np.abs(x))
    tanmask = np.clip(ham * 0.9 + knee_front + thigh_side * pin + arms * pin * 0.9 + labels_is(lab, "torso") * pin * 0.5
                      * ss(1.15, 1.25, z), 0, 1)
    tanmask = np.clip(tanmask * (0.35 + 0.65 * pin) + ham * 0.25, 0, 1)
    tanmask = ss(0.35, 0.55, tanmask)
    col = mix(col, INK, prim * (legs + arms).clip(0, 1) * 0.7)
    col = mix(col, mix(TAN, CREAM, np.clip(nz(P, 9, 5), 0, 1) * 0.6), tanmask)
    # --- red-orange calf / shin mottling (sheet back + side view)
    calf = legs * ss(0.62, 0.5, z) * ss(0.12, 0.2, z)
    oin, orim = blob(P, 9.0, 0.05, 23, warp=0.02)
    col = mix(col, INK, orim * calf * 0.8)
    col = mix(col, mix(ORANGE, RED, np.clip(nz(P, 14, 9), 0, 1)), oin * calf)
    # red bands on the upper arm / forearm outer face (behind plates, reads between them)
    rin, _ = blob(P, 7.0, 0.3, 31)
    col = mix(col, RED, rin * arms * 0.85)
    # --- neck: orange-red front and sides, darker at the nape with spots
    neck = labels_is(lab, "neck")
    ncol = mix(ORANGE, RED, ss(-0.09, -0.04, y))
    sp_in, sp_rim = blob(P, 16.0, 0.35, 41)
    ncol = mix(ncol, INK, sp_in * 0.85)
    col = mix(col, ncol, neck)
    # --- hands: dark with tan knuckle scutes
    hands = labels_is(lab, "hand")
    col = mix(col, hx("#2a2124"), hands)
    kn = blob(P, 22.0, 0.25, 51)[0] * hands
    col = mix(col, TAN, kn * 0.8)
    # --- feet: tan/cream with red tarsal bands (sheet: pale feet with red marks, cream wraps)
    feet = labels_is(lab, "foot")
    fcol = mix(TAN, CREAM_D, np.clip(nz(P, 10, 61), 0, 1))
    fin, frim = blob(P, 12.0, 0.25, 63)
    fcol = mix(fcol, RED, fin * 0.9)
    fcol = mix(fcol, INK, frim * 0.6)
    col = mix(col, fcol, feet * ss(0.2, 0.12, z))
    col = mix(col, hx("#3a2c2c"), feet * ss(0.12, 0.2, z))
    # --- star specks over the dark body
    sk = specks(P, 38.0, 71, 0.1, 0.3) * base * (1 - tanmask)
    col = mix(col, hx("#e9d9ae"), sk)
    rough = np.where(tanmask > 0.5, 0.55, rough)
    rough = np.where(neck > 0.5, 0.4, rough)
    out.rgb = col
    out.rough = rough
    return out


def labels_is(lab, *prefixes):
    m = np.zeros(len(lab))
    for p in prefixes:
        m = np.maximum(m, np.char.startswith(lab.astype(str), p).astype(float))
    return m


# ------------------------------------------------------------------------------------------------ head
def head(P, N, c, part):
    """c: HEAD_C. part: head|jaw|eyes|fangs|horns|tines|fringe."""
    out = Paint(len(P))
    L = P - c
    x, y, z = L[:, 0], L[:, 1], L[:, 2]
    if part == "head":
        col = np.tile(RED, (len(P), 1))
        # cream face plate along the snout sides and the nasal ridge
        face = ss(-0.02, -0.06, y) * ss(-0.08, -0.04, z)
        face *= 1 - ss(0.025, 0.04, z + 0.6 * (y + 0.06))
        fin, frim = blob(P, 18.0, -0.1, 81)
        col = mix(col, INK, frim * face)
        col = mix(col, mix(CREAM, TAN, np.clip(nz(P, 30, 83), 0, 1)), np.clip(face * (0.5 + fin), 0, 1))
        # dark eye socket band and under-side
        eyeband = ss(0.03, 0.05, np.abs(x)) * ss(0.05, 0.0, np.abs(y + 0.035)) * ss(0.045, 0.0, np.abs(z - 0.018))
        col = mix(col, INK, eyeband * 0.9)
        under = ss(-0.02, -0.05, z) * ss(-0.05, 0.0, y)
        col = mix(col, NAVY, under)
        # nape cap: dark with a yellow four-point star (sheet back view)
        nape = ss(0.02, 0.06, y) * ss(-0.06, 0.0, z)
        col = mix(col, NAVY, nape)
        ang = np.arctan2(z + 0.0, x)
        rr = np.sqrt(x ** 2 + (z + 0.0) ** 2)
        star = ss(0.03, 0.02, rr / (0.4 + 0.6 * np.abs(np.cos(2 * ang)) ** 4)) * ss(0.06, 0.08, y)
        col = mix(col, YELLOW, star)
        # crown keel deeper red with cream specks
        crown = ss(0.035, 0.06, z)
        col = mix(col, RED_D, crown * 0.6)
        col = mix(col, CREAM, specks(P, 60, 85, 0.12, 0.4) * (1 - face) * 0.9)
        out.rgb, out.rough = col, np.full(len(P), 0.3)
    elif part == "jaw":
        col = mix(np.tile(NAVY2, (len(P), 1)), CREAM_D, ss(-0.07, -0.11, y) * 0.7)
        out.rgb, out.rough = col, np.full(len(P), 0.35)
    elif part == "eyes":
        # yellow eye, dark pupil ring facing outward-forward
        s = np.sign(x)
        d = np.stack([s * 0.8, -np.ones_like(s) * 0.6, np.zeros_like(s)], 1)
        d /= np.linalg.norm(d, axis=1, keepdims=True)
        e0 = np.stack([s * 0.055, -0.035 * np.ones_like(s), 0.018 * np.ones_like(s)], 1)
        v = L - e0
        v /= np.maximum(np.linalg.norm(v, axis=1, keepdims=True), 1e-9)
        dd = (v * d).sum(1)
        col = np.tile(EYE, (len(P), 1))
        col = mix(col, hx("#ff8a2a"), ss(0.6, 0.85, dd) * 0.5)
        col = mix(col, INK, ss(0.88, 0.93, dd) * (1 - ss(0.96, 0.985, dd)) + ss(0.985, 0.995, dd))
        out.rgb, out.rough = col, np.full(len(P), 0.08)
        out.emit = col * 0.35 * (1 - ss(0.88, 0.93, dd))[:, None]
    elif part == "fangs":
        out.rgb, out.rough = np.tile(hx("#eee4cc"), (len(P), 1)), np.full(len(P), 0.3)
    elif part == "horns":
        t = ss(0.04, 0.3, z)
        col = mix(RED, RED_D, t * 0.7)
        hin, hrim = blob(P, 25.0, 0.3, 91)
        col = mix(col, ORANGE, hin * 0.7)
        col = mix(col, INK, ss(0.27, 0.31, z) * 0.85)
        col = mix(col, CREAM, specks(P, 70, 93, 0.1, 0.3) * 0.8)
        out.rgb, out.rough = col, np.full(len(P), 0.28)
    elif part == "tines":
        r = np.linalg.norm(L[:, [0, 2]], axis=1)
        col = mix(CREAM, CREAM_D, ss(0.07, 0.11, np.abs(x)))
        col = mix(col, hx("#5a4030"), ss(0.095, 0.115, np.abs(x)) * 0.7)
        out.rgb, out.rough = col, np.full(len(P), 0.45)
    elif part == "fringe":
        ang = np.arctan2(x, y)
        strand = (np.floor((ang + 1.6) / (3.2 / 15)) % 3)
        col = np.where((strand == 1)[:, None], OLIVE, hx("#d7bd6a"))
        col = mix(col, hx("#5a5530"), ss(0.0, -0.05, z) * 0.4)
        out.rgb, out.rough = col, np.full(len(P), 0.7)
    return out


# ------------------------------------------------------------------------------------------------ plates
def plate(name, P, N, curv):
    out = Paint(len(P))
    c = P.mean(0)
    base_name = name.split(".")[0]
    seed = sum(map(ord, name)) % 997
    col = np.tile(RED, (len(P), 1))
    rough = np.full(len(P), 0.26)
    if base_name == "pauldron":
        # ladybug elytron: red dome, yellow spot up-front, black spot on the outer side, cream lower-back patch
        s = 1 if name.endswith(".L") else -1
        L = P - c
        d = L / np.maximum(np.linalg.norm(L, axis=1, keepdims=True), 1e-9)
        ys = ss(0.42, 0.36, np.linalg.norm(d - np.array([s * 0.35, -0.55, 0.75]) / np.linalg.norm([0.35, 0.55, 0.75]), axis=1))
        bs = ss(0.5, 0.42, np.linalg.norm(d - np.array([s * 0.95, 0.15, 0.1]) / np.linalg.norm([0.95, 0.15, 0.1]), axis=1))
        cin, crim = blob(P, 9.0, 0.15, seed, warp=0.02)
        cream = cin * ss(0.0, -0.4, d[:, 2] - 0.3 * d[:, 1])
        col = mix(col, RED_D, ss(0.2, -0.4, d[:, 2]) * 0.5)
        col = mix(col, INK, crim * ss(0.0, -0.4, d[:, 2] - 0.3 * d[:, 1]))
        col = mix(col, mix(CREAM, TAN, 0.4), cream)
        col = mix(col, ORANGE, ss(0.5, 0.42, np.linalg.norm(d - np.array([s * 0.35, -0.55, 0.75]) /
                                                             np.linalg.norm([0.35, 0.55, 0.75]), axis=1)) * 0.6)
        col = mix(col, YELLOW, ys)
        col = mix(col, INK, bs)
    elif base_name in ("bracer", "armplate", "elbowcap", "lame", "thighplate", "handplate"):
        cin, crim = blob(P, 11.0, 0.22, seed, warp=0.02)
        col = mix(col, RED_D, np.clip(nz(P, 8, seed + 1), 0, 1) * 0.6)
        col = mix(col, INK, crim)
        col = mix(col, mix(CREAM, TAN, 0.5), cin)
        col = mix(col, INK, specks(P, 30, seed + 3, 0.16, 0.25))
        if base_name == "handplate":
            col = mix(col, NAVY2, 0.4)
    elif base_name in ("kneecap", "shinplate", "footplate", "sternum"):
        col = np.tile(TAN, (len(P), 1))
        col = mix(col, CREAM, np.clip(nz(P, 10, seed), 0, 1))
        rin, rrim = blob(P, 10.0, 0.25, seed + 5, warp=0.02)
        col = mix(col, INK, rrim * 0.8)
        col = mix(col, mix(RED, ORANGE, 0.5), rin * (0.6 if base_name == "sternum" else 1.0))
        rough[:] = 0.4
    elif base_name == "carapace":
        # back: tan scapula plates on red, black specks (sheet back view)
        cin, crim = blob(P, 6.5, 0.05, seed, warp=0.03)
        col = mix(col, RED_D, np.clip(nz(P, 5, seed + 1), 0, 1) * 0.6)
        col = mix(col, INK, crim)
        col = mix(col, mix(TAN, CREAM, 0.4), cin)
        col = mix(col, INK, specks(P, 26, seed + 3, 0.15, 0.3))
    elif base_name == "neckrings":
        col = mix(RED, ORANGE, np.clip(nz(P, 12, seed), 0, 1) * 0.8)
        col = mix(col, INK, specks(P, 40, seed + 3, 0.18, 0.3) * 0.9)
    # worn convex edges lighter, cavities darker
    k = np.clip(curv, -1, 1)
    col = col * (1 + 0.22 * np.clip(k, 0, 1))[:, None] * (1 - 0.35 * np.clip(-k, 0, 1))[:, None]
    rough = rough + 0.15 * np.clip(k, 0, 1)
    out.rgb, out.rough = np.clip(col, 0, 1), rough
    return out


# ------------------------------------------------------------------------------------------------ costume
def costume(name, kind, P, N, UV=None):
    out = Paint(len(P))
    seed = sum(map(ord, name)) % 997
    n1 = nz(P, 20, seed)
    rough = np.full(len(P), 0.88)
    metal = np.zeros(len(P))
    if kind == "cloth":
        weave = 0.06 * np.sin(P[:, 2] * 1400) * np.sin(P[:, 0] * 1400 + P[:, 1] * 1400)
        col = mix(CREAM, CREAM_D, np.clip(n1, 0, 1) * 0.8) * (1 + weave)[:, None]
        if UV is not None:      # sheet strips: grime toward the torn hem
            col = mix(col, hx("#6e5638"), ss(0.55, 1.0, UV[:, 1]) * 0.55)
        if name == "talisman":
            col = mix(col, RED, blob(P, 60, 0.3, seed)[0])
    elif kind == "cloth_red":
        col = mix(SASH, RED_D, np.clip(-n1, 0, 1) * 0.7)
        if UV is not None:
            col = mix(col, hx("#3a1a14"), ss(0.5, 1.0, UV[:, 1]) * 0.5)
    elif kind == "cloak":
        col = mix(CLOAK, hx("#2a271e"), np.clip(n1, 0, 1))
        if UV is not None:      # frayed lighter hem and a faded band near the top (sheet back)
            col = mix(col, CLOAK_L, ss(0.42, 0.62, UV[:, 1]) * 0.55)
            col = mix(col, hx("#7d7150"), ss(0.06, 0.0, np.abs(UV[:, 1] - 0.16)) * 0.5)
        rough[:] = 0.92
    elif kind == "leaf":
        col = mix(OLIVE, OLIVE_L, np.clip(n1, 0, 1) * 0.7)
        if UV is not None:
            vein = ss(0.03, 0.0, np.abs(UV[:, 0] - 0.5))
            col = mix(col, hx("#c4b968"), vein * 0.6)
            ribs = ss(0.08, 0.0, np.abs(((UV[:, 1] * 9 + np.abs(UV[:, 0] - 0.5) * 6) % 1) - 0.5) - 0.42)
            col = mix(col, OLIVE_D, ribs * 0.35)
            col = mix(col, hx("#3b2a1c"), ss(0.65, 1.0, UV[:, 1]) * 0.75)      # dark tips (sheet skirt)
            col = mix(col, OLIVE_D, ss(0.35, 0.5, np.abs(UV[:, 0] - 0.5)) * 0.6)
        rough[:] = 0.75
    elif kind == "leather":
        col = mix(LEATHER, hx("#2e1d15"), np.clip(n1, 0, 1))
        rough[:] = 0.6
    elif kind == "gold":
        col = mix(GOLD, hx("#7a5a22"), np.clip(n1, 0, 1) * 0.6)
        rough[:], metal[:] = 0.3, 0.9
    elif kind == "bone":
        col = mix(CREAM, CREAM_D, np.clip(n1, 0, 1))
        rough[:] = 0.5
        if name == "medallion":
            c = P.mean(0)
            r = np.linalg.norm((P - c)[:, [0, 2]], axis=1)
            col = mix(col, hx("#2a2020"), ss(0.034, 0.028, r))           # dark boss
            col = mix(col, GOLD, ss(0.012, 0.008, r))
        if name == "beads":
            col = np.where((np.floor((P[:, 2] - 0.85) / 0.022) % 3 == 0)[:, None], CREAM, hx("#8f2a22"))
            rough[:] = 0.35
    elif kind == "claw":
        col = mix(hx("#2b2020"), CREAM_D, 0.25 + 0.3 * np.clip(n1, 0, 1))
        rough[:] = 0.3
    else:
        col = np.tile(np.array([0.5, 0.5, 0.5]), (len(P), 1))
    out.rgb, out.rough, out.metal = np.clip(col, 0, 1), rough, metal
    return out


# ------------------------------------------------------------------------------------------------ Morrow
def morrow(name, P, N, curv, core_dir=None, head_c=None):
    out = Paint(len(P))
    seed = sum(map(ord, name)) % 997
    k = np.clip(curv, -1, 1)
    if name == "morrow_head":
        f1, f2 = vor(P, 30.0, seed)
        col = mix(STONE, STONE_L, ss(0.08, 0.0, f2 - f1) * 0.6 + np.clip(nz(P, 12, seed), 0, 1) * 0.3)
        # bone bosses: points further out than the ball radius
        r = np.linalg.norm(P - head_c, axis=1)
        boss = ss(0.252, 0.258, r)
        ring = np.abs(np.sin((r - 0.25) * 420))
        col = mix(col, mix(CREAM, CREAM_D, ss(0.4, 0.9, ring)), boss)
        col = mix(col, INK, boss * ss(0.264, 0.27, r) * 0.0)
        rough = np.where(boss > 0.5, 0.5, 0.62)
        metal = np.zeros(len(P))
    elif name == "morrow_spikes":
        r = np.linalg.norm(P - head_c, axis=1)
        col = mix(hx("#3a2c26"), BRONZE, ss(0.27, 0.31, r))
        col = mix(col, hx("#d8c39a"), ss(0.31, 0.34, r) * 0.6)
        rough, metal = np.full(len(P), 0.38), np.full(len(P), 0.55)
    elif name == "morrow_core":
        f1, f2 = vor(P, 22.0, seed)
        crack = ss(0.07, 0.015, f2 - f1)
        col = mix(CORE, hx("#ff5a3a"), np.clip(nz(P, 25, seed), 0, 1) * 0.5)
        col = mix(col, CORE_HOT, crack)
        out.emit = mix(CORE * 0.35, CORE_HOT * 1.0, crack)
        rough, metal = np.full(len(P), 0.12), np.zeros(len(P))
    elif name in ("morrow_bezel", "morrow_seg1", "morrow_seg2"):
        col = mix(hx("#3b302b"), hx("#6a5240"), np.clip(nz(P, 25, seed), 0, 1) * 0.5)
        col = mix(col, BRONZE, np.clip(k, 0, 1) * 0.8)
        rough, metal = np.full(len(P), 0.4), np.full(len(P), 0.65)
    else:   # grip: leather wrap + bone pommel
        col = mix(LEATHER, hx("#24170f"), np.clip(nz(P, 60, seed), 0, 1))
        rough, metal = np.full(len(P), 0.65), np.zeros(len(P))
    col = col * (1 + 0.25 * np.clip(k, 0, 1))[:, None] * (1 - 0.3 * np.clip(-k, 0, 1))[:, None]
    out.rgb, out.rough, out.metal = np.clip(col, 0, 1), rough, metal
    return out
