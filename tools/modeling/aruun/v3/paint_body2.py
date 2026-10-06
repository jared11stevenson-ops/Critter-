"""Aruun v3 body paint, version 2: big deliberate plates (analytic regions, sheet-placed) + subtle plate segmentation lines.
Layers painted back to front: chitin base -> plate fills with shaded gradient -> dark outline -> cream rim -> spots/dots -> wear."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, "..", ".."))
from common.texbake import smooth, mix, hash1, vnoise, worley
from paint_head import DARK, PLUM, RED, REDHI, REDDK, CREAM, TAN, BONE, OLIVE, NAVY, NECK, line
from paint_body import OCHRE, CHITIN, WINE, SH, pauldron

INK = np.array([22, 15, 24.])


def band(x, a, b, s=0.0006):
    """1 inside [a,b] with ~s edge"""
    return smooth(a - s, a + s, x) * smooth(b + s, b - s, x)


class Painter:
    def __init__(self, P, N, kind, seed=0):
        self.P, self.N, self.kind = P, N, kind
        n = len(P); self.n = n
        self.col = np.tile(CHITIN, (n, 1)); self.rough = np.full(n, 0.34); self.hgt = np.zeros(n)
        # soft large-scale plum drift on the chitin (not noise-blotchy: very low frequency)
        self.col = mix(self.col, PLUM, 0.6 * smooth(0.35, 0.8, vnoise(P, 6, seed + 2)))
        self.seed = seed

    def fill(self, mask, color, rough=0.4, h=0.8, grad=None, outline=0.0, rim=None, rim_w=0.0, rim_soft=0.0):
        """mask: 0..1 coverage. grad: optional shading multiplier array. outline: half-width in metres is baked by caller via sd."""
        c = np.asarray(color, float)
        cc = np.tile(c, (self.n, 1)) if c.ndim == 1 else c
        if grad is not None: cc = cc * grad[:, None]
        self.col = mix(self.col, cc, mask)
        self.rough = np.where(mask > 0.5, rough, self.rough)
        self.hgt += h * mask

    def edge(self, sd, w=0.0022, color=INK, a=0.92):
        """dark outline where signed distance sd ~ 0 (metres)"""
        self.col = mix(self.col, color, line(sd, w, 0.0007) * a)

    def plate(self, sd, color, rough=0.4, h=0.8, w=0.0022, rimcol=None, rimw=0.005, shade=True, outline=True):
        """sd < 0 inside. fills, dark outline on the border, thin lighter rim inside."""
        m = smooth(0.0007, -0.0007, sd)
        base = np.asarray(color, float)
        g = None
        if shade:
            depth = np.clip(-sd / 0.05, 0, 1)
            g = 0.72 + 0.40 * smooth(0.0, 1.0, depth) + 0.10 * self.N[:, 2]
        self.fill(m, base, rough, h, g)
        if rimcol is not None:
            r = smooth(0.0007, 0.0007 + rimw, -sd) * 0 + (1 - smooth(0.0, rimw, -sd)) * m
            self.col = mix(self.col, rimcol, r * 0.55 * (1 - line(sd, w, 0.0007)))
        if outline:
            self.edge(sd, w)
        return m

    def spot(self, c, r, color=OCHRE, ring=True):
        d = np.linalg.norm(self.P - np.asarray(c), axis=1)
        if ring: self.col = mix(self.col, INK, line(d - r * 1.18, 0.0024) * 0.95)
        self.col = mix(self.col, color, smooth(r, r * 0.8, d))
        self.col = mix(self.col, INK, smooth(r * 0.35, r * 0.2, d) * 0.7)
        self.hgt += 0.4 * smooth(r, r * 0.8, d)

    def segments(self, mask, L=0.07, seed=0, strength=0.5):
        """subtle plate seams (thin dark lines on cell borders) inside a mask"""
        f1, f2, cid, cen = worley(self.P, L, seed=seed + 5)
        e = f2 - f1
        ln = 1 - smooth(0.0012, 0.0030, e)
        self.col = mix(self.col, self.col * 0.45, ln * mask * strength)
        self.hgt -= 0.5 * ln * mask
        return cid, cen

    def finish(self):
        # global: faint warm bounce + edge darkening by down-facing normals, keeps forms readable
        self.col = self.col * (0.86 + 0.14 * smooth(-1, 0.7, self.N[:, 2]))[:, None]
        return np.clip(self.col, 0, 255), self.rough, self.hgt


def paint(P, N, kind, seed=0):
    p = Painter(P, N, kind, seed)
    x, y, z = P[:, 0], P[:, 1], P[:, 2]; nx, ny, nz = N[:, 0], N[:, 1], N[:, 2]
    front = smooth(-0.1, -0.45, ny); back = smooth(0.1, 0.45, ny)
    if kind == "trunk":
        # neck handled separately (paint_body.neck_belt); here the torso
        torso = smooth(1.72, 1.66, z)
        # side plates (rib cage, red) left/right of the chest
        for sg in (-1, 1):
            sd = np.hypot((x - sg * 0.20) / 1.0, (z - 1.42) / 1.45) - 0.115
            p.plate(sd * 0.7, mix(RED, WINE, 0.35), 0.4, 0.7, rimcol=CREAM)
        # sternum plate (cream) + rib lines
        sd = np.maximum(np.abs(x) - 0.085, np.maximum(z - 1.67, 1.28 - z)) + 0.006 * np.abs(y + 0.2)
        sd = np.where(front > 0.2, sd, 1.0)
        p.plate(sd, mix(TAN, CREAM, 0.45), 0.6, 1.0, rimcol=BONE)
        insd = sd < -0.003
        for zr in (1.37, 1.44, 1.51, 1.58):
            p.col = mix(p.col, INK, line(z - zr, 0.0022) * insd * 0.8)
        # clavicle band
        p.plate(np.where(front > 0.2, np.maximum(np.abs(x) - 0.24, np.abs(z - 1.69) - 0.018), 1.0), TAN, 0.6, 0.6)
        # abdomen: dark with tan segment bands
        for zr in (1.255, 1.30):
            sdb = np.abs(z - zr) - 0.008
            p.plate(np.where(front > 0.2, sdb, 1.0), TAN * 0.85, 0.6, 0.5, outline=False)
        # back: red shoulder-blade plates with cream spots + tan spine plates
        for sg in (-1, 1):
            c = np.array([sg * 0.15, 0.10, 1.52])
            sd = np.where(back > 0.25, np.hypot(x - c[0], (z - c[2]) * 0.8) - 0.125, 1.0)
            p.plate(sd, RED, 0.38, 0.8, rimcol=CREAM)
            dd = np.hypot(x - c[0], z - 1.55) / 0.034
            p.col = mix(p.col, INK, line(dd - 1.2, 0.07) * (sd < 0) * 0.9); p.col = mix(p.col, mix(CREAM, OCHRE, 0.4), smooth(1.0, 0.8, dd) * (sd < 0))
        for k in range(6):
            zc = 1.66 - 0.065 * k
            sd = np.where(back > 0.25, np.maximum(np.abs(x) - 0.04 + 0.004 * k, np.abs(z - zc) - 0.026), 1.0)
            p.plate(sd, mix(TAN, CREAM, 0.3), 0.6, 0.9)
        # lower back / hips: red patches
        for sg in (-1, 1):
            sd = np.where(back > 0.25, np.hypot(x - sg * 0.16, (z - 1.22) * 1.2) - 0.07, 1.0)
            p.plate(sd, WINE, 0.4, 0.7, rimcol=TAN)
        p.segments(1.0 - torso * 0, L=0.12, seed=seed, strength=0.18)
    elif kind in ("armL", "armR"):
        sg = 1 if kind == "armL" else -1
        # upper arm: dark with a red plate on the outer-top; cream band below the pauldron
        out = smooth(0.0, 0.35, sg * nx)
        sd = np.where((z > 1.32) & (z < 1.58), np.hypot((z - 1.45) * 0.6, 0.0 * x) - 0.072 + 0.04 * (1 - out), 1.0)
        p.plate(sd, RED, 0.4, 0.7, rimcol=CREAM)
        p.plate(np.abs(z - 1.33) - 0.016, mix(TAN, CREAM, 0.3), 0.6, 0.8)
        # forearm vambrace: big red plate with cream end bands, ochre spots on the outer side
        sd = np.maximum(z - 1.26, 0.97 - z)
        p.plate(sd, mix(RED, WINE, 0.25), 0.38, 1.0, rimcol=CREAM)
        for zb in (1.255, 0.985):
            p.plate(np.abs(z - zb) - 0.012, mix(TAN, CREAM, 0.4), 0.6, 0.9)
        cid, cen = p.segments(smooth(0.001, -0.001, sd), L=0.09, seed=seed + 3, strength=0.5)
        for zs in (1.15, 1.04):
            c = np.array([0.0, 0.0, zs])
            d = np.hypot((np.arctan2(ny, nx) - (0.0 if sg > 0 else np.pi)) * 0.06, z - zs)
            p.col = mix(p.col, INK, line(d - 0.034, 0.0022) * smooth(0.001, -0.001, sd) * 0.9)
            p.col = mix(p.col, OCHRE, smooth(0.030, 0.026, d) * smooth(0.001, -0.001, sd))
        # hand: dark + tan knuckle/claw plates
        hand = smooth(0.97, 0.93, z)
        p.col = mix(p.col, CHITIN * 1.15, hand)
        p.col = mix(p.col, TAN, band(z, 0.88, 0.915) * hand)
        p.segments(hand, L=0.04, seed=seed + 9, strength=0.4)
    elif kind in ("legL", "legR"):
        sg = 1 if kind == "legL" else -1
        # thigh: big outer cream plate with a red spot, red hip plate on top
        outer = smooth(-0.1, 0.4, sg * nx)
        sd = np.where((z > 0.68) & (z < 1.02), np.maximum(np.abs(z - 0.86) - 0.15, -0.2 + 0.2 * (1 - outer)) + 0.0, 1.0)
        p.plate(sd, mix(TAN, CREAM, 0.4), 0.6, 1.0, rimcol=BONE)
        p.plate(np.where((z > 0.98) & (nz > -0.2), np.abs(z - 1.04) - 0.05, 1.0), WINE, 0.4, 0.8, rimcol=CREAM)
        # knee guard: red cap with cream rim
        p.plate(np.where((z > 0.5) & (z < 0.7), np.abs(z - 0.60) - 0.075, 1.0), RED, 0.36, 1.1, rimcol=CREAM)
        # shin: dark with a red front stripe; ankle tan wrap
        sdst = np.where((z > 0.30) & (z < 0.50), np.maximum(np.abs(z - 0.40) - 0.095, -0.2 + 0.9 * (1 - front)), 1.0)
        p.plate(sdst, WINE, 0.4, 0.7, rimcol=TAN)
        p.plate(np.abs(z - 0.27) - 0.014, TAN, 0.6, 0.9)
        # foot: dark with cream toe plates and claws
        foot = smooth(0.24, 0.20, z)
        p.col = mix(p.col, CHITIN * 1.2, foot)
        for k in range(3):
            p.plate(np.where(z < 0.17, np.abs(y - (P[:, 1].min() + 0.05 + 0.07 * k)) - 0.025, 1.0), mix(TAN, CREAM, 0.4), 0.6, 0.9)
        p.segments(1.0, L=0.12, seed=seed, strength=0.15)
    return p.finish()


ANCHORS = {}


def set_anchors(V, kinds_v):
    """pauldron anchor = outermost/upper shoulder surface point toward each pole"""
    body = V[np.isin(kinds_v, ["trunk", "armL", "armR"])]
    for k, c in SH.items():
        sg = 1 if k == "L" else -1
        pole = np.array([sg * 0.85, -0.25, 0.55]); pole /= np.linalg.norm(pole)
        m = np.linalg.norm(body - c, axis=1) < 0.28
        v = body[m]; ANCHORS[k] = v[np.argmax((v - c) @ pole)]
    print("pauldron anchors", {k: v.round(3) for k, v in ANCHORS.items()})


def pauldron2(P, N, col, hgt, rough):
    """red ladybug pauldron: circular patch on the surface around the anchor, cream rim, ink outline, big ochre spot"""
    for k, a in ANCHORS.items():
        d = np.linalg.norm(P - a, axis=1)
        R = 0.135
        m = smooth(R + 0.001, R - 0.001, d)
        base = mix(REDHI, RED, smooth(0.0, R, d) * 0.9)
        base = mix(base, WINE, smooth(R * 0.6, R, d) * 0.5)
        col = mix(col, base, m)
        col = mix(col, CREAM, line(d - (R - 0.012), 0.006) * m * 0.9)
        col = mix(col, INK, line(d - R - 0.004, 0.0035) * 0.95)
        col = mix(col, INK, line(d - 0.056, 0.0035) * m * 0.95)
        col = mix(col, mix(OCHRE, CREAM, 0.3), smooth(0.053, 0.046, d) * m)
        hgt += 1.2 * m
        rough = np.where(m > 0.5, 0.28, rough)
    return col, hgt, rough


def overlays(P, N, kind, col, hgt, rough):
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    front = smooth(-0.1, -0.45, N[:, 1])
    if kind == "trunk":
        # cream bandage strap crossing from his left shoulder to the right hip (front), stitched
        a = np.array([0.20, 1.66]); b_ = np.array([-0.16, 1.20]); ab = b_ - a
        t = np.clip(((x - a[0]) * ab[0] + (z - a[1]) * ab[1]) / (ab @ ab), 0, 1); d = np.hypot(x - (a[0] + t * ab[0]), z - (a[1] + t * ab[1]))
        m = smooth(0.034, 0.030, d) * front * smooth(0.0, 0.05, t) * smooth(1.0, 0.95, t)
        col = mix(col, mix(CREAM, TAN, 0.25 + 0.3 * vnoise(P, 40, 5)), m[:, None] * 0.95)
        col = mix(col, INK, line(d - 0.032, 0.0025) * front * 0.85); col = mix(col, TAN * 0.6, line(((t * 30) % 1.0) - 0.5, 0.06) * m * 0.5)
        hgt = hgt + 0.7 * m
        # red sash at the belt with a darker knot band
        sa = smooth(1.115, 1.13, z) * smooth(1.215, 1.20, z)
        col = mix(col, mix(WINE, RED, 0.35 + 0.3 * vnoise(P, 30, 6)), sa[:, None] * 0.95)
        col = mix(col, INK, (line(z - 1.118, 0.002) + line(z - 1.212, 0.002)) * 0.85); hgt = hgt + 0.5 * sa
    if kind == "trunk":
        # sternum plate, ink outlined, ribs
        sd = np.maximum(np.abs(x) - 0.045 - 0.02 * smooth(1.45, 1.3, z), np.maximum(z - 1.60, 1.30 - z))
        sd = np.where(front > 0.3, sd, 1.0)
        m = smooth(0.0007, -0.0007, sd)
        col = mix(col, mix(TAN, CREAM, 0.55) * (0.8 + 0.3 * smooth(0, -0.06, sd)[:, None]), m[:, None] * 1.0)
        for zr in (1.36, 1.43, 1.50, 1.57):
            col = mix(col, TAN * 0.55, line(z - zr, 0.0018) * m * 0.85)
        col = mix(col, INK, line(sd, 0.0028) * 0.95)
        hgt = hgt + 0.9 * m
        # spine plates (back)
        back = smooth(0.1, 0.45, N[:, 1])
        for k in range(5):
            zc = 1.62 - 0.07 * k
            sd = np.where(back > 0.3, np.maximum(np.abs(x) - 0.038 + 0.004 * k, np.abs(z - zc) - 0.024), 1.0)
            m = smooth(0.0007, -0.0007, sd)
            col = mix(col, mix(TAN, CREAM, 0.4), m[:, None]); col = mix(col, INK, line(sd, 0.0024) * 0.95); hgt = hgt + 0.8 * m
    if kind in ("legL", "legR"):
        # knee guard cap (front): red with cream rim and ochre spot
        pass
    col, hgt, rough = pauldron2(P, N, col, hgt, rough) if kind in ("trunk", "armL", "armR") else (col, hgt, rough)
    return col, hgt, rough


def accent_emis(P, kind, sp):
    """ice-teal emissive accents (the pop layer): horn joint bands, pauldron rim ring"""
    n = len(P); em = np.zeros((n, 3)); TEAL = np.array([70., 230., 255.])
    if kind == "horn":
        knob = (np.cos(2 * np.pi * sp * 3.0) ** 2) ** 2.5
        em = TEAL[None] * (smooth(0.80, 0.97, knob) * 0.32)[:, None]
    if kind in ("trunk", "armL", "armR"):
        for k, a in ANCHORS.items():
            d = np.linalg.norm(P - a, axis=1)
            em = np.maximum(em, TEAL[None] * (line(d - 0.123, 0.005) * 0.35)[:, None])
    return em
