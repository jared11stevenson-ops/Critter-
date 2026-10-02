#!/usr/bin/env python3
"""Cut Red Reaches environment sprites (trees, plants, landmark rocks) from the regions sheet
(left third = Aruun Region / The Reacher Lands) and pack them into one atlas for MultiMesh scatter.

Usage: python3 tools/art_pipeline/cut_world.py [--preview out.png]
Writes game/art/world/reaches_atlas.png + reaches_atlas.json
  json: {"items": {name: {"uv": [u0,v0,u1,v1], "px": [w,h], "height_m": h, "kind": k}}}
"""
import json
import os
import sys
import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import matte  # noqa: E402

SHEET = "regions_aruun_cigarra_nerit.jpg"
OUT = os.path.join(matte.ROOT, "game", "art", "world")
UPSCALE = 2.0
# name: box (sheet px), world height m, scatter kind, seed point (optional)
ITEMS = {
	"tree_big":     {"box": [8, 350, 140, 493], "h": 9.0, "kind": "flat_tree", "seed": [80, 440], "exclude": [[8, 404, 47, 493], [8, 478, 60, 493], [116, 436, 140, 493]], "bg": [232, 214, 188]},
	"tree_small":   {"box": [8, 412, 50, 480], "h": 4.2, "kind": "flat_tree", "seed": [28, 440], "exclude": [[40, 436, 50, 480]]},
	"tree_bone":    {"box": [128, 358, 212, 514], "h": 8.0, "kind": "flat_tree", "seed": [170, 450]},
	"horn_hanging": {"box": [208, 352, 258, 440], "h": 3.5, "kind": "bone", "seed": [235, 400]},
	"shrub_red":    {"box": [198, 436, 254, 514], "h": 2.2, "kind": "shrub", "seed": [225, 480]},
	"rock_horn":    {"box": [264, 352, 312, 486], "h": 9.0, "kind": "rock_spire", "seed": [290, 420]},
	"rock_pillar":  {"box": [319, 352, 362, 462], "h": 8.0, "kind": "rock_spire", "seed": [340, 420]},
	"rock_arch":    {"box": [354, 354, 454, 458], "h": 10.0, "kind": "rock_arch", "seed": [400, 400]},
	"rock_pile":    {"box": [266, 466, 342, 514], "h": 2.6, "kind": "rock_small", "seed": [300, 495]},
	"rock_stone":   {"box": [344, 460, 380, 514], "h": 2.8, "kind": "rock_small", "seed": [362, 490]},
	"rock_needle":  {"box": [381, 466, 404, 514], "h": 2.4, "kind": "rock_small", "seed": [392, 495]},
	"rock_round":   {"box": [403, 469, 440, 514], "h": 2.0, "kind": "rock_small", "seed": [420, 495]},
	"plant_agave":  {"box": [10, 538, 92, 604], "h": 1.3, "kind": "shrub", "seed": [50, 580]},
	"plant_redbush":{"box": [91, 538, 184, 604], "h": 1.5, "kind": "shrub", "seed": [140, 590]},
	"plant_blue":   {"box": [182, 538, 262, 604], "h": 1.4, "kind": "shrub", "seed": [225, 590]},
	"plant_bulb":   {"box": [258, 538, 298, 582], "h": 1.0, "kind": "shrub", "seed": [276, 555]},
	"plant_orange": {"box": [294, 538, 382, 604], "h": 1.7, "kind": "shrub", "seed": [335, 590]},
	"plant_cone":   {"box": [381, 530, 427, 604], "h": 1.6, "kind": "shrub", "seed": [403, 580]},
}


def clean(im, kill_pale=False):
	"""Hard matte (alpha scissor friendly): drop specks, kill parchment-coloured fringe, ink the rim."""
	from scipy import ndimage as ndi
	arr = np.asarray(im).astype(np.float32)
	rgb = arr[..., :3]
	a = arr[..., 3] > 127
	# parchment-ish fringe pixels (light, low saturation) on the border of the matte
	mx = rgb.max(-1)
	mn = rgb.min(-1)
	pale = (mx > 185) & ((mx - mn) < 70)
	border = a & ~ndi.binary_erosion(a, iterations=2)
	a = a & ~(pale & border)
	if kill_pale:
		# enclosed parchment pockets between leaves/branches
		par = np.sqrt(((rgb - np.array([232, 214, 188])) ** 2).sum(-1)) < 48
		a = a & ~ndi.binary_dilation(ndi.binary_opening(par, iterations=1), iterations=1)
	a = ndi.binary_opening(a, iterations=1)
	lab, n = ndi.label(a)
	if n > 1:
		sizes = ndi.sum(a, lab, index=np.arange(1, n + 1))
		big = max(sizes)
		a = np.isin(lab, np.nonzero(sizes >= max(40, big * 0.02))[0] + 1)
	rim = a & ~ndi.binary_erosion(a, iterations=1)
	rgb = np.where(rim[..., None], rgb * 0.45 + np.array([20, 12, 12]) * 0.55, rgb)
	out = np.dstack([rgb, a * 255.0]).clip(0, 255).astype(np.uint8)
	return matte.rebleed(Image.fromarray(out, "RGBA"))


def pack(images, width=1024):
	"""Simple shelf packer; returns positions and used height."""
	order = sorted(images.keys(), key=lambda k: -images[k].height)
	x = y = shelf = 0
	pos = {}
	for k in order:
		im = images[k]
		if x + im.width + 2 > width:
			x = 0
			y += shelf + 2
			shelf = 0
		pos[k] = (x, y)
		x += im.width + 2
		shelf = max(shelf, im.height)
	return pos, y + shelf


def main():
	sh = matte.sheet(SHEET)
	cuts = {}
	for name, spec in ITEMS.items():
		kw = {}
		if "exclude" in spec:
			kw["exclude"] = spec["exclude"]
		if "bg" in spec:
			kw["bg"] = spec["bg"]
		im = matte.cut(sh, spec["box"], seed=spec.get("seed"), method=spec.get("method", "flood"),
			flood_thr=spec.get("thr", 40.0), join_dist=3, **kw)
		im = clean(im, spec["kind"] in ("shrub",))
		im = matte.trim_pad(im, pad=3)
		W, H = int(im.width * UPSCALE), int(im.height * UPSCALE)
		rgb = im.convert("RGB").resize((W, H), Image.LANCZOS).filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
		al = im.split()[3].resize((W, H), Image.BILINEAR).point(lambda v: 255 if v > 127 else 0)
		im = Image.merge("RGBA", (*rgb.split(), al))
		im = matte.rebleed(im)
		cuts[name] = im
		print("cut", name, im.size, im.info.get("method", ""))
	pos, used_h = pack(cuts)
	H = 1 << (used_h - 1).bit_length()
	atlas = Image.new("RGBA", (1024, H), (0, 0, 0, 0))
	meta = {"_doc": "generated by tools/art_pipeline/cut_world.py", "items": {}}
	for k, im in cuts.items():
		x, y = pos[k]
		atlas.paste(im, (x, y))
		meta["items"][k] = {"uv": [x / 1024.0, y / H, (x + im.width) / 1024.0, (y + im.height) / H],
			"px": [im.width, im.height], "height_m": ITEMS[k]["h"], "kind": ITEMS[k]["kind"]}
	atlas = matte.rebleed(atlas)
	os.makedirs(OUT, exist_ok=True)
	atlas.save(os.path.join(OUT, "reaches_atlas.png"), optimize=True)
	with open(os.path.join(OUT, "reaches_atlas.json"), "w") as f:
		json.dump(meta, f, indent=1)
	print("atlas", atlas.size)
	if "--preview" in sys.argv:
		p = sys.argv[sys.argv.index("--preview") + 1]
		matte.composite_preview(list(cuts.values()), list(cuts.keys()), cell_h=260).save(p)


if __name__ == "__main__":
	main()
