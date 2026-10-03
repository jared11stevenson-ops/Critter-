#!/usr/bin/env python3
"""Bake tileable PBR texture sets for the painterly-realism Red Reaches (Agent 1, v0.7).

Palette sampled from the Red Reaches "Terrain & Ground Textures" swatches on
tools/source_art/regions_aruun_cigarra_nerit.jpg; high-frequency detail generated procedurally.

Outputs (game/art/world/pbr/):
  <set>_albedo.png  RGB = albedo (sRGB), A = height (0..1)
  <set>_normal.png  RGB = tangent-space normal (OpenGL, +Y up)
Sets: ground_dirt (cracked red earth + pebbles), ground_flag (Spanwright flagstones),
      cliff_rock (strata rock; u = horizontal, v = world height), scrub (dusty mesa top grit)
  prop_detail.png   RGBA heights for props: R rock grain, G wood grain, B metal scratches/grime, A weave
  macro_var.png     RGBA low-frequency tileable variation (R,G,B independent fbm, A = large dust patches)
Usage: python3 tools/art_pipeline/make_pbr_textures.py
"""
import os
import numpy as np
from PIL import Image
from scipy.spatial import cKDTree
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "game", "art", "world", "pbr")
os.makedirs(OUT, exist_ok=True)


def fbm(n, beta=2.0, seed=0, lo=1.0, hi=None):
	"""Tileable power-law noise via random-phase spectrum, normalised 0..1."""
	r = np.random.default_rng(seed)
	fx = np.fft.fftfreq(n)[:, None] * n
	fy = np.fft.fftfreq(n)[None, :] * n
	f = np.sqrt(fx * fx + fy * fy)
	f[0, 0] = 1.0
	amp = f ** (-beta / 2.0 * 2.0 / 2.0 * 2.0) if False else f ** (-beta)
	amp[f < lo] = 0.0
	if hi is not None:
		amp[f > hi] = 0.0
	ph = r.random((n, n)) * 2 * np.pi
	spec = amp * np.exp(1j * ph)
	v = np.real(np.fft.ifft2(spec))
	v = (v - v.min()) / (v.max() - v.min() + 1e-9)
	return v


def worley(n, cells, seed=0, jitter=1.0, stretch=(1.0, 1.0), warp=None):
	"""Tileable Worley noise: returns F1, F2, cell index (pixels-normalised by cell size)."""
	r = np.random.default_rng(seed)
	pts = r.random((cells, 2))
	if jitter < 1.0:
		g = int(np.ceil(np.sqrt(cells)))
		base = np.stack(np.meshgrid(np.arange(g), np.arange(g), indexing="ij"), -1).reshape(-1, 2)[:cells]
		pts = (base + 0.5 + (r.random((cells, 2)) - 0.5) * jitter) / g
	tiles = []
	for oy in (-1, 0, 1):
		for ox in (-1, 0, 1):
			tiles.append(pts + np.array([oy, ox]))
	allp = np.concatenate(tiles) * np.array(stretch)
	tree = cKDTree(allp)
	yy, xx = np.meshgrid(np.arange(n) / n, np.arange(n) / n, indexing="ij")
	if warp is not None:
		yy = yy + warp[0]
		xx = xx + warp[1]
	q = np.stack([yy.ravel() * stretch[0], xx.ravel() * stretch[1]], -1)
	d, i = tree.query(q, k=2)
	cs = np.sqrt(1.0 / cells)
	f1 = (d[:, 0] / cs).reshape(n, n)
	f2 = (d[:, 1] / cs).reshape(n, n)
	idx = (i[:, 0] % cells).reshape(n, n)
	return f1, f2, idx


def smooth(e0, e1, x):
	t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
	return t * t * (3 - 2 * t)


def normal_from_height(h, strength):
	gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
	gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
	nx = -gx * strength
	ny = gy * strength   # OpenGL: +Y up in texture = -row
	nz = np.ones_like(h)
	L = np.sqrt(nx * nx + ny * ny + nz * nz)
	return np.stack([nx / L, ny / L, nz / L], -1)


def cavity(h, sigma):
	b = ndimage.gaussian_filter(h, sigma, mode="wrap")
	return h - b


def save_set(name, albedo, height, nstrength):
	a = np.clip(albedo, 0, 1)
	hh = np.clip(height, 0, 1)
	rgba = np.concatenate([a, hh[..., None]], -1)
	Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + "_albedo.png"))
	nm = normal_from_height(height, nstrength)
	Image.fromarray(((nm * 0.5 + 0.5) * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(OUT, name + "_normal.png"))
	print("wrote", name)


def col(*c):
	return np.array(c, dtype=np.float64) / 255.0


def lerp(a, b, t):
	t = t[..., None] if np.ndim(t) == 2 else t
	return a + (b - a) * t


def pebbles(n, count, rmin, rmax, seed):
	"""Height bumps + id map for scattered pebbles (tileable)."""
	r = np.random.default_rng(seed)
	h = np.zeros((n, n))
	ids = np.zeros((n, n))
	for k in range(count):
		cy, cx = r.random(2) * n
		rad = r.uniform(rmin, rmax)
		ell = r.uniform(0.6, 1.0)
		ang = r.random() * np.pi
		R = int(rad) + 2
		ys = (np.arange(-R, R + 1) + int(cy)) % n
		xs = (np.arange(-R, R + 1) + int(cx)) % n
		dy, dx = np.meshgrid(np.arange(-R, R + 1) + int(cy) - cy, np.arange(-R, R + 1) + int(cx) - cx, indexing="ij")
		u = dx * np.cos(ang) + dy * np.sin(ang)
		v = (-dx * np.sin(ang) + dy * np.cos(ang)) / ell
		d = np.sqrt(u * u + v * v) / rad
		bump = np.sqrt(np.clip(1 - d * d, 0, 1))
		sub = h[np.ix_(ys, xs)]
		m = bump > sub
		sub = np.where(m, bump, sub)
		h[np.ix_(ys, xs)] = sub
		idsub = ids[np.ix_(ys, xs)]
		ids[np.ix_(ys, xs)] = np.where(m & (bump > 0), r.random() * 0.999 + 0.001, idsub)
	return h, ids


# ---------------------------------------------------------------------------------------------- dirt
def make_dirt(n=1024):
	base = fbm(n, 1.6, 1, lo=2)
	mid = fbm(n, 1.1, 2, lo=8)
	grit = fbm(n, 0.4, 3, lo=64)
	wy = (fbm(n, 2.0, 4, lo=2) - 0.5) * 0.05
	wx = (fbm(n, 2.0, 5, lo=2) - 0.5) * 0.05
	f1, f2, idx = worley(n, 46, seed=6, warp=(wy, wx))
	edge = f2 - f1
	crack = 1.0 - smooth(0.0, 0.018 + 0.03 * mid, edge)
	crack_lip = smooth(0.0, 0.12, edge) * (1.0 - smooth(0.12, 0.3, edge))
	fine_f1, fine_f2, _ = worley(n, 220, seed=7, warp=(wy * 2, wx * 2))
	fcrack = (1.0 - smooth(0.0, 0.05, fine_f2 - fine_f1)) * smooth(0.45, 0.7, mid)
	plate = smooth(0.0, 0.25, edge)
	peb, pid = pebbles(n, 900, 1.5, 6.5, 8)
	peb2, _ = pebbles(n, 3000, 0.8, 2.0, 9)
	h = 0.45 + 0.18 * (base - 0.5) + 0.08 * plate + 0.05 * (mid - 0.5) + 0.04 * (grit - 0.5)
	h -= crack * 0.3 + fcrack * 0.1
	h += crack_lip * 0.04
	h = np.maximum(h, 0.42 + peb * 0.35 * (1 - crack))
	h += peb2 * 0.05
	# palette (sheet swatch 1 / 4): warm red earth
	c_a = col(160, 74, 48)
	c_b = col(186, 98, 64)
	c_dust = col(206, 142, 104)
	c_dark = col(86, 36, 26)
	cell_v = (np.random.default_rng(11).random(46))[idx]
	t = np.clip(base * 0.7 + cell_v * 0.4 - 0.1, 0, 1)
	alb = lerp(c_a, c_b, t)
	alb = lerp(alb, c_dust, smooth(0.55, 0.85, mid) * 0.45 * plate)
	alb *= (0.9 + 0.2 * grit)[..., None]
	alb = lerp(alb, c_dark, np.clip(crack * 0.85 + fcrack * 0.4, 0, 1))
	# pebbles: varied stones
	pr = np.random.default_rng(12)
	pal = np.array([col(150, 120, 104), col(118, 58, 44), col(196, 160, 128), col(92, 70, 64), col(170, 88, 60)])
	pc = pal[(pid * 5).astype(int) % 5]
	pm = smooth(0.05, 0.25, peb)[..., None]
	shade = (0.75 + 0.35 * peb)[..., None]
	alb = alb * (1 - pm) + pc * shade * pm
	alb = alb * (1 - 0.4 * smooth(0.0, 0.2, peb2)[..., None]) + col(200, 150, 120) * 0.4 * smooth(0.0, 0.2, peb2)[..., None]
	cav = cavity(h, 6)
	alb *= np.clip(1.0 + cav[..., None] * 2.2, 0.55, 1.15)
	save_set("ground_dirt", alb, h, 26.0)


# ---------------------------------------------------------------------------------------------- flag
def make_flag(n=1024):
	wy = (fbm(n, 2.0, 21, lo=2) - 0.5) * 0.06
	wx = (fbm(n, 2.0, 22, lo=2) - 0.5) * 0.06
	cells = 22
	f1, f2, idx = worley(n, cells, seed=23, jitter=0.9, warp=(wy, wx))
	edge = f2 - f1
	grit_pre = fbm(n, 0.8, 20, lo=40)
	stone = smooth(0.035, 0.075, edge + (grit_pre - 0.5) * 0.03)
	surf = fbm(n, 1.3, 24, lo=4)
	grit = fbm(n, 0.5, 25, lo=80)
	bevel = smooth(0.035, 0.16, edge)
	chips = smooth(0.62, 0.8, fbm(n, 1.0, 26, lo=16))
	rr = np.random.default_rng(27)
	tilt_y = (rr.random(cells) - 0.5)[idx]
	tilt_x = (rr.random(cells) - 0.5)[idx]
	yy, xx = np.meshgrid(np.linspace(0, 1, n), np.linspace(0, 1, n), indexing="ij")
	lvl = (rr.random(cells))[idx]
	h_stone = 0.5 + 0.14 * bevel + 0.06 * lvl + 0.06 * (surf - 0.5) + 0.02 * (grit - 0.5) - chips * 0.06
	h_stone += 0.03 * np.sin(yy * 40 * tilt_y + xx * 37 * tilt_x)
	peb, pid = pebbles(n, 1400, 1.0, 4.5, 28)
	h_gap = 0.30 + 0.08 * peb + 0.04 * (grit - 0.5)
	h = h_gap * (1 - stone) + h_stone * stone
	# palette (swatches 1 / 3): salmon / cream flagstones, dark sandy joints
	pal = np.array([col(190, 114, 88), col(178, 104, 80), col(200, 132, 102), col(168, 96, 74), col(206, 146, 112), col(184, 120, 94)])
	sv = (rr.random(cells) * 6).astype(int)[idx]
	sc = pal[sv]
	sc = sc * (0.88 + 0.22 * surf)[..., None]
	sc = lerp(sc, col(232, 196, 160), smooth(0.035, 0.07, edge) * (1 - smooth(0.07, 0.16, edge)) * 0.3)   # worn edges
	sc = lerp(sc, col(120, 62, 46), chips * 0.5)
	stain = smooth(0.55, 0.85, fbm(n, 1.8, 29, lo=2))
	sc = lerp(sc, col(132, 70, 50), stain * 0.35)
	gap = lerp(col(98, 52, 38), col(150, 96, 70), peb)
	alb = gap * (1 - stone)[..., None] + sc * stone[..., None]
	cav = cavity(h, 5)
	alb *= np.clip(1.0 + cav[..., None] * 1.8, 0.5, 1.12)
	save_set("ground_flag", alb, h, 22.0)


# ---------------------------------------------------------------------------------------------- cliff
def make_cliff(n=1024):
	# v (rows) = world height; strata bands with warped thickness, protruding hard layers, vertical joints
	warp = (fbm(n, 2.2, 31, lo=1) - 0.5) * 0.9 + (fbm(n, 1.5, 32, lo=4) - 0.5) * 0.25
	yy = np.linspace(0, 1, n, endpoint=False)[:, None] * np.ones((1, n))
	bands = 9
	s = yy * bands + warp
	band = np.floor(s)
	fr = s - band
	rr = np.random.default_rng(33)
	hard = rr.random(64)
	bid = (band.astype(int) % 64)
	hb = hard[bid]
	# per-band profile: hard layers protrude with rounded lips; soft layers recessed + crumbly
	prof = np.where(hb > 0.5, 0.65 + 0.15 * np.sin(fr * np.pi) ** 0.6, 0.38 + 0.08 * fr)
	lip = smooth(0.0, 0.08, fr) * smooth(1.0, 0.9, fr)
	prof *= 0.85 + 0.15 * lip
	# vertical joints (stretched worley): blocky fractures
	wy = (fbm(n, 2.0, 34, lo=2) - 0.5) * 0.04
	wx = (fbm(n, 2.0, 35, lo=2) - 0.5) * 0.04
	f1, f2, idx = worley(n, 36, seed=36, stretch=(0.5, 1.0), warp=(wy, wx))
	joint = (1.0 - smooth(0.0, 0.025, f2 - f1)) * np.where(hb > 0.5, 1.0, 0.35)
	lam = np.sin((s * 7.0 + (fbm(n, 1.5, 40, lo=6) - 0.5) * 1.5) * np.pi * 2) * 0.5 + 0.5
	blk = (rr.random(60))[idx]
	rough = fbm(n, 1.0, 37, lo=8)
	grit = fbm(n, 0.4, 38, lo=96)
	h = prof + 0.08 * (blk - 0.5) * (hb > 0.5) + 0.04 * (lam - 0.5) + 0.12 * (rough - 0.5) + 0.03 * (grit - 0.5) - joint * 0.22
	h = np.clip(h, 0, 1)
	# albedo: neutral-warm sandstone luminance with band tint; shader multiplies a strata palette on top
	tint = np.array([col(196, 110, 80), col(170, 84, 62), col(214, 150, 112), col(150, 70, 56), col(204, 128, 92), col(226, 176, 136)])
	tb = tint[(hard[bid] * 997).astype(int) % 6]
	alb = tb * (0.82 + 0.3 * rough[..., None]) * (0.92 + 0.12 * lam[..., None]) * (0.92 + 0.12 * grit[..., None])
	streak = fbm(n, 1.4, 39, lo=2)
	# vertical streaks: stretch noise in v
	streak = ndimage.zoom(streak[:n // 8, :], (8, 1), order=1)[:n, :]
	alb *= (0.85 + 0.25 * streak)[..., None]
	alb = lerp(alb, col(70, 30, 26), joint * 0.8)
	cav = cavity(h, 4)
	alb *= np.clip(1.0 + cav[..., None] * 2.0, 0.5, 1.15)
	save_set("cliff_rock", alb, h, 30.0)


# ---------------------------------------------------------------------------------------------- scrub
def make_scrub(n=1024):
	base = fbm(n, 1.5, 41, lo=2)
	mid = fbm(n, 1.0, 42, lo=10)
	grit = fbm(n, 0.3, 43, lo=90)
	peb, pid = pebbles(n, 2600, 0.8, 3.5, 44)
	f1, f2, _ = worley(n, 30, seed=45)
	crack = (1 - smooth(0.0, 0.05, f2 - f1)) * smooth(0.4, 0.6, mid)
	h = 0.45 + 0.12 * (base - 0.5) + 0.05 * (grit - 0.5) + peb * 0.22 - crack * 0.15
	c_a = col(176, 104, 70)
	c_b = col(198, 140, 96)
	c_olive = col(130, 112, 70)
	alb = lerp(c_a, c_b, base)
	alb = lerp(alb, c_olive, smooth(0.62, 0.9, mid) * 0.5)
	alb *= (0.88 + 0.22 * grit)[..., None]
	pal = np.array([col(210, 180, 150), col(120, 70, 56), col(160, 140, 126), col(96, 60, 48)])
	pc = pal[(pid * 4).astype(int) % 4]
	pm = smooth(0.05, 0.3, peb)[..., None]
	alb = alb * (1 - pm) + pc * (0.8 + 0.3 * peb[..., None]) * pm
	alb = lerp(alb, col(90, 44, 32), crack * 0.7)
	save_set("scrub", alb, h, 22.0)


# ---------------------------------------------------------------------------------------------- props
def make_prop_detail(n=512):
	rock = fbm(n, 1.2, 51, lo=4) * 0.6 + fbm(n, 0.5, 52, lo=48) * 0.4
	f1, f2, _ = worley(n, 40, seed=53)
	rock -= (1 - smooth(0.0, 0.05, f2 - f1)) * 0.35
	# wood grain: long fibres along v with knots
	yy, xx = np.meshgrid(np.arange(n) / n, np.arange(n) / n, indexing="ij")
	w = fbm(n, 2.0, 54, lo=2)
	grain = np.sin((xx * 38 + w * 6.0) * np.pi * 2) * 0.5 + 0.5
	fib = fbm(n, 0.6, 55, lo=32)
	fib = ndimage.zoom(fib[:n // 16, :], (16, 1), order=1)[:n, :]
	wood = grain * 0.45 + fib * 0.55
	# metal: fine scratches + dents + grime
	sc = np.zeros((n, n))
	r = np.random.default_rng(56)
	for k in range(260):
		y0, x0 = r.random(2) * n
		ang = r.normal(0.2, 0.5)
		L = r.uniform(10, 80)
		for t in np.linspace(0, L, int(L * 2)):
			y = int(y0 + np.sin(ang) * t) % n
			x = int(x0 + np.cos(ang) * t) % n
			sc[y, x] = 1.0
	sc = ndimage.gaussian_filter(sc, 0.6, mode="wrap")
	dents = fbm(n, 2.2, 57, lo=3)
	metal = np.clip(0.5 + (dents - 0.5) * 0.6 - sc * 1.5, 0, 1)
	# weave (rope / canvas)
	weave = (np.sin(xx * n / 6 * np.pi) * np.sin(yy * n / 6 * np.pi)) * 0.5 + 0.5
	weave = weave * 0.6 + fbm(n, 0.8, 58, lo=24) * 0.4
	def nz(a):
		return (a - a.min()) / (a.max() - a.min() + 1e-9)
	rgba = np.stack([nz(rock), nz(wood), nz(metal), nz(weave)], -1)
	Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, "prop_detail.png"))
	# matching normal for the rock channel (props/structures get a real normal map for stone)
	nm = normal_from_height(nz(rock), 9.0)
	Image.fromarray(((nm * 0.5 + 0.5) * 255 + 0.5).astype(np.uint8), "RGB").save(os.path.join(OUT, "prop_rock_normal.png"))
	print("wrote prop_detail")


def make_macro(n=512):
	r = fbm(n, 2.4, 61, lo=1)
	g = fbm(n, 2.0, 62, lo=1)
	b = fbm(n, 1.6, 63, lo=2)
	a = smooth(0.5, 0.8, fbm(n, 2.2, 64, lo=1))
	rgba = np.stack([r, g, b, a], -1)
	Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, "macro_var.png"))
	print("wrote macro_var")


if __name__ == "__main__":
	make_dirt()
	make_flag()
	make_cliff()
	make_scrub()
	make_prop_detail()
	make_macro()
