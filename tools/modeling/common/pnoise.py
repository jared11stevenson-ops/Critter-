"""Procedural 3D noise helpers for texture painting (numpy)."""
import numpy as np


def noise3(P, freq, seed):
    """Cheap deterministic smooth 3D noise in [-1,1] (sum of random-direction sines)."""
    rng = np.random.default_rng(seed)
    acc = np.zeros(len(P))
    amp = 1.0
    tot = 0.0
    for octave in range(4):
        for _ in range(3):
            d = rng.normal(size=3)
            d /= np.linalg.norm(d)
            acc += amp * np.sin(P @ d * freq * (2 ** octave) * 6.283 + rng.uniform(0, 6.283))
            tot += amp
        amp *= 0.55
    return acc / tot * 1.6




def worley(P, size, seed=0, chunk=400000):
    """3D cellular noise. Returns F1, F2 (distances in cell units) and a per-cell hash in [0,1)."""
    F1 = np.empty(len(P), np.float32)
    F2 = np.empty(len(P), np.float32)
    H = np.empty(len(P), np.float32)
    offs = np.array([(i, j, k) for i in (-1, 0, 1) for j in (-1, 0, 1) for k in (-1, 0, 1)], np.float32)
    for s in range(0, len(P), chunk):
        Q = P[s:s + chunk].astype(np.float32) / size
        B = np.floor(Q)
        d1 = np.full(len(Q), 9.0, np.float32)
        d2 = np.full(len(Q), 9.0, np.float32)
        hh = np.zeros(len(Q), np.float32)
        for o in offs:
            C = B + o
            h = np.sin(C @ np.array([127.1, 311.7, 74.7], np.float32) + seed) * 43758.5453
            h = h - np.floor(h)
            h2 = np.sin(C @ np.array([269.5, 183.3, 246.1], np.float32) + seed) * 43758.5453
            h2 = h2 - np.floor(h2)
            h3 = np.sin(C @ np.array([113.5, 271.9, 124.6], np.float32) + seed) * 43758.5453
            h3 = h3 - np.floor(h3)
            Fp = C + np.stack([h, h2, h3], 1)
            d = np.linalg.norm(Q - Fp, axis=1)
            m = d < d1
            d2 = np.where(m, d1, np.minimum(d2, d))
            hh = np.where(m, h, hh)
            d1 = np.where(m, d, d1)
        F1[s:s + chunk], F2[s:s + chunk], H[s:s + chunk] = d1, d2, hh
    return F1, F2, H


