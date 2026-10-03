#!/usr/bin/env python3
"""Bake tileable helper textures for the toon terrain shader.
  game/art/world/terrain_noise.png  RGBA: R=low fbm, G=mid fbm, B=high fbm, A=crack/cell edges (tileable 512)
  game/art/world/flagstone.png      RGBA: RGB=stone tint variation, A=mortar/ink line mask (tileable 512)
Usage: python3 tools/art_pipeline/bake_world_textures.py
"""
import os
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "game", "art", "world")
N = 512
rng = np.random.default_rng(7)


def tile_noise(freq, octaves=4):
	acc = np.zeros((N, N))
	amp = 1.0
	tot = 0.0
	for o in range(octaves):
		f = freq * (2 ** o)
		g = rng.random((f, f))
		# bicubic-ish periodic upsample via FFT-free interpolation
		x = np.arange(N) * f / N
		i0 = np.floor(x).astype(int)
		t = x - i0
		t = t * t * (3 - 2 * t)
		i1 = (i0 + 1) % f
		a = g[i0][:, i0] * (1 - t)[None, :] + g[i0][:, i1] * t[None, :]
		b = g[i1][:, i0] * (1 - t)[None, :] + g[i1][:, i1] * t[None, :]
		acc += amp * (a * (1 - t)[:, None] + b * t[:, None])
		tot += amp
		amp *= 0.5
	acc /= tot
	acc = (acc - acc.min()) / (acc.max() - acc.min())
	return acc


def voronoi(cells, jitter=0.8, warp=None):
	pts = (np.stack(np.meshgrid(np.arange(cells), np.arange(cells), indexing="ij"), -1) + 0.5
		+ (rng.random((cells, cells, 2)) - 0.5) * jitter) / cells
	yy, xx = np.meshgrid(np.arange(N) / N, np.arange(N) / N, indexing="ij")
	if warp is not None:
		yy = yy + warp[0]
		xx = xx + warp[1]
	d1 = np.full((N, N), 9.0)
	d2 = np.full((N, N), 9.0)
	idx = np.zeros((N, N), int)
	P = pts.reshape(-1, 2)
	for k, (py, px) in enumerate(P):
		for oy in (-1, 0, 1):
			for ox in (-1, 0, 1):
				dy = yy - (py + oy)
				dx = xx - (px + ox)
				d = np.sqrt(dy * dy + dx * dx)
				m = d < d1
				d2 = np.where(m, d1, np.minimum(d2, d))
				idx = np.where(m, k, idx)
				d1 = np.where(m, d, d1)
	return d1, d2, idx


def main():
	os.makedirs(OUT, exist_ok=True)
	r = tile_noise(4, 4)
	g = tile_noise(12, 3)
	b = tile_noise(40, 2)
	w = (tile_noise(6, 2) - 0.5) * 0.04
	d1, d2, _ = voronoi(9, 0.9, (w, w.T))
	crack = np.clip(1.0 - (d2 - d1) * N / 3.0, 0, 1)
	crack *= (tile_noise(5, 2) > 0.45)  # cracks only in some places
	img = np.dstack([r, g, b, crack]) * 255
	Image.fromarray(img.astype(np.uint8), "RGBA").save(os.path.join(OUT, "terrain_noise.png"))
	# flagstones: irregular cells, ink mortar lines, per-stone tint
	w2 = (tile_noise(8, 2) - 0.5) * 0.03
	d1, d2, idx = voronoi(7, 0.75, (w2, w2.T))
	line = np.clip(1.0 - ((d2 - d1) * N - 2.0) / 3.0, 0, 1)
	tint = rng.random(49)[idx]
	edge_shade = np.clip((d2 - d1) * N / 20.0, 0, 1)  # bevel: darker near mortar
	rgb = np.dstack([tint, edge_shade, tile_noise(30, 2)])
	img = np.dstack([rgb, line[..., None]]) * 255
	Image.fromarray(img.astype(np.uint8), "RGBA").save(os.path.join(OUT, "flagstone.png"))
	print("baked")


if __name__ == "__main__":
	main()
