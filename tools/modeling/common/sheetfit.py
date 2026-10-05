"""Sheet registration: orthographic sheet views (hires/*.png, RGBA cut-outs) <-> Blender world space.

World: Z up, character faces -Y, his LEFT is +X.  Views (same conventions as common/raster.py):
  side  : faces screen-right, camera at -X.  u = u0 - y*ppm
  back  : camera at +Y.                        u = u0 - x*ppm
  front : camera at -Y.                        u = u0 + x*ppm
Row v = v0 - z*ppm.  ppm is derived from the alpha bbox height == total height (horn tip -> sole).
A View carries the RGBA image, mask, ppm, (u0, v0) and projects world points to pixels.
"""
import json
import os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))


class View:
    def __init__(self, path, kind, height_m, u0=None, y_shift=0.0):
        im = Image.open(path).convert("RGBA")
        self.im = im
        self.rgb = np.asarray(im)[:, :, :3]
        a = np.asarray(im)[:, :, 3]
        self.mask = a > 128
        ys, xs = np.where(self.mask)
        self.kind = kind
        self.top, self.bot = ys.min(), ys.max()
        self.ppm = (self.bot - self.top + 1) / height_m
        self.v0 = float(self.bot + 1)
        self.u0 = float((xs.min() + xs.max()) / 2) if u0 is None else u0
        self.H, self.W = self.mask.shape

    # world -> pixel
    def project(self, P):
        P = np.asarray(P, dtype=np.float64)
        if self.kind == "side":
            u = self.u0 - P[:, 1] * self.ppm
        elif self.kind == "back":
            u = self.u0 - P[:, 0] * self.ppm
        else:
            u = self.u0 + P[:, 0] * self.ppm
        v = self.v0 - P[:, 2] * self.ppm
        return u, v

    def inside(self, P):
        u, v = self.project(P)
        ui = np.round(u - 0.5).astype(int)
        vi = np.round(v - 0.5).astype(int)
        ok = (ui >= 0) & (ui < self.W) & (vi >= 0) & (vi < self.H)
        out = np.zeros(len(P), bool)
        out[ok] = self.mask[vi[ok], ui[ok]]
        return out

    def sample(self, P, order=1):
        """bilinear RGB(A) sample at world points (N,3) -> (N,4) float 0..255"""
        from scipy.ndimage import map_coordinates
        u, v = self.project(P)
        arr = np.asarray(self.im).astype(np.float32)
        out = np.stack([map_coordinates(arr[:, :, c], [v - 0.5, u - 0.5], order=order, mode="nearest") for c in range(4)], 1)
        return out
