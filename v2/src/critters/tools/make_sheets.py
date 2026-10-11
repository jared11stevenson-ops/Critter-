#!/usr/bin/env python3
"""Compose shoot.gd tiles into labelled sheets (PIL).
Usage: make_sheets.py <tiles_dir> <out_dir> [--ids=a,b,c] [--tile=N]
Sheets per critter: turnaround (4 views), actions (8 poses), expressions (6), fx, film; plus the_seven.png and silhouettes.png."""
import sys, os, glob
from PIL import Image, ImageDraw, ImageFont

IDS = ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris"]
NAMES = {"aruun": "ARUUN - The Reacher", "cigarra": "CIGARRA - The Oracle Hopper", "bramvex": "BRAMVEX - The Quiet Command",
         "scarlith": "SCARLITH - The Fermented Kingpin", "mollusk": "MOLLUSK - The Weight of Tomorrow",
         "zephyr": "ZEPHYR - The Nectar Seeker", "nyxaris": "NYXARIS - The Frostbloom Weaver"}
BG = (34, 30, 36)
import colorsys
def _hex(h):
    return [int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
def _load_pals():
    import re
    src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../palettes.gd")).read()
    out = {}
    for m in re.finditer(r'"(\w+)": \{([^}]*)\}', src):
        kv = dict(re.findall(r'"(\w+)": "([0-9a-fA-F]{6})"', m.group(2)))
        if "main" in kv:
            d = {k: _hex("#" + v) for k, v in kv.items()}
            r, g, b = d["main"]
            h, sat, val = colorsys.rgb_to_hsv(r, g, b)
            d["ink"] = colorsys.hsv_to_rgb((h + 0.04) % 1.0, min(sat + 0.15, 1.0), 0.12)
            out[m.group(1)] = d
    return out
PALS = _load_pals()
SRC = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../../tools/source_art"))
# reference crops (file, (x0, y0, x1, y1)) from the approved sheets
REFS = {"aruun": ("aruun_nerit_sheet.jpg", (0, 0, 640, 510)), "cigarra": ("cigarra_sheet.jpg", (0, 0, 940, 530)),
        "bramvex": ("bramvex_sheet.png", (0, 0, 1030, 530)), "scarlith": ("scarlith_sheet.jpg", (0, 0, 1120, 480)),
        "mollusk": ("mollusk_sheet.png", (0, 0, 1110, 520)), "zephyr": ("zephyr_sheet.png", (0, 0, 930, 560)),
        "nyxaris": ("nyxaris_sheet.png", (0, 0, 1020, 535))}

KINDS = (("act", "actions", 4, "action poses", 1.0), ("expr", "expressions", 3, "expressions", 1.1),
         ("fx", "fx", 3, "fx: smear, spark, impact frame", 1.0), ("film", "film", 4, "heavy strike filmstrip", 1.0))


def font(sz):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()


def save(img, path):
    # 256-colour quantise keeps the cel look and the total under the 6 MB sheet budget
    img.convert("RGB").quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.FLOYDSTEINBERG).save(path, optimize=True)


def grid(files, cols, tile, labels=None, title=None):
    rows = (len(files) + cols - 1) // cols
    top = 34 if title else 0
    img = Image.new("RGB", (cols * tile, rows * tile + top), BG)
    d = ImageDraw.Draw(img)
    if title:
        d.text((10, 6), title, font=font(20), fill=(245, 215, 140))
    for i, f in enumerate(files):
        im = Image.open(f).convert("RGB").resize((tile, tile), Image.LANCZOS)
        x, y = (i % cols) * tile, top + (i // cols) * tile
        img.paste(im, (x, y))
        if labels:
            d.text((x + 8, y + tile - 22), labels[i], font=font(14), fill=(255, 255, 255), stroke_width=2, stroke_fill=(20, 20, 20))
    return img


def label_of(path, cid, kind):
    # <cid>_<kind>_<index>_<label>.png -> label
    name = os.path.basename(path)[:-4]
    rest = name[len(cid) + 1 + len(kind) + 1:]
    return rest.split("_", 1)[1] if "_" in rest else rest


def numkey(path):
    for p in os.path.basename(path).split("_"):
        if p.isdigit():
            return int(p)
    return 0


def board(tiles, out, cid, width=1500):
    """Side-by-side board: reference crop (left) vs in-engine turnaround (right), then action strip and expressions."""
    f, box = REFS[cid]
    ref = Image.open(os.path.join(SRC, f)).convert("RGB").crop(box)
    top_h = 520
    ref = ref.resize((int(ref.width * top_h / ref.height), top_h), Image.LANCZOS)
    views = ["front", "three_quarter", "side", "back"]
    tv = [Image.open(f"{tiles}/{cid}_turn_{v}.png").convert("RGB") for v in views]
    crop = lambda t: t.crop((int(t.width * 0.15), 0, int(t.width * 0.85), t.height)).resize((int(t.width * 0.7 * top_h / t.height), top_h), Image.LANCZOS)
    tv = [crop(t) for t in tv]
    width = ref.width + sum(t.width for t in tv)
    acts = sorted(glob.glob(f"{tiles}/{cid}_act_*.png"), key=numkey)
    exps = sorted(glob.glob(f"{tiles}/{cid}_expr_*.png"), key=numkey)
    atile = width // max(len(acts), 1)
    etile = width // max(len(exps), 1)
    H = 40 + top_h + atile + etile + 30
    img = Image.new("RGB", (width, H), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 8), NAMES[cid] + "   |   LEFT: approved reference   RIGHT: in-engine (front, 3/4, side, back)", font=font(18), fill=(245, 215, 140))
    img.paste(ref, (0, 40))
    x = ref.width
    for i, t in enumerate(tv):
        img.paste(t, (x, 40))
        d.text((x + 6, 40 + top_h - 22), views[i].replace("_", " "), font=font(14), fill=(255, 255, 255), stroke_width=2, stroke_fill=(20, 20, 20))
        x += t.width
    y0 = 40 + top_h
    d.text((10, y0 + 2), "action poses", font=font(14), fill=(245, 215, 140))
    for i, a in enumerate(acts):
        img.paste(Image.open(a).convert("RGB").resize((atile, atile), Image.LANCZOS), (i * atile, y0))
        d.text((i * atile + 6, y0 + atile - 20), label_of(a, cid, "act"), font=font(13), fill=(255, 255, 255), stroke_width=2, stroke_fill=(20, 20, 20))
    y1 = y0 + atile
    for i, a in enumerate(exps):
        img.paste(Image.open(a).convert("RGB").resize((etile, etile), Image.LANCZOS), (i * etile, y1))
        d.text((i * etile + 6, y1 + etile - 20), label_of(a, cid, "expr"), font=font(13), fill=(255, 255, 255), stroke_width=2, stroke_fill=(20, 20, 20))
    save(img, f"{out}/{cid}_board.png")


def modelsheet(tiles, out, cid, pal):
    """Orthographic front/side/back/top on a 0.25 m proportion grid, part labels at joint pivots, swatches, 1.7 m scale reference."""
    import json
    data = json.load(open(f"{tiles}/{cid}_ortho.json"))
    T = 560
    W, H = T * 4, T + 150
    img = Image.new("RGB", (W, H), (24, 22, 28))
    d = ImageDraw.Draw(img)
    d.text((12, 8), NAMES[cid] + "   |   MODEL SHEET   (A-pose, grid = 0.25 m, bar = 1.70 m human)", font=font(18), fill=(245, 215, 140))
    for i, v in enumerate(["front", "side", "back", "top"]):
        info = data[v]
        tile = Image.open(f"{tiles}/{cid}_ortho_{v}.png").convert("RGB").resize((T, T), Image.LANCZOS)
        g = ImageDraw.Draw(tile)
        ppm = info["px_per_m"] * T / 640.0
        gx, gy = info["ground"][0] * T, info["ground"][1] * T
        step = 0.25 * ppm
        k = 0
        x = gx % step
        while x < T:
            g.line([(x, 0), (x, T)], fill=(150, 160, 175) if abs(round((x - gx) / step)) % 4 else (110, 120, 140), width=1)
            x += step
        y = gy % step
        while y < T:
            g.line([(0, y), (T, y)], fill=(150, 160, 175) if round((gy - y) / step) % 4 else (110, 120, 140), width=1)
            y += step
        if v != "top":
            g.line([(0, gy), (T, gy)], fill=(200, 80, 80), width=2)
            hx = 22
            g.rectangle([hx, gy - 1.7 * ppm, hx + 14, gy], outline=(40, 40, 60), fill=(60, 60, 90))
            g.ellipse([hx - 2, gy - 1.7 * ppm - 10, hx + 16, gy - 1.7 * ppm + 8], fill=(60, 60, 90))
            g.text((hx + 20, gy - 1.7 * ppm), "1.70 m", font=font(11), fill=(40, 40, 60))
        # part labels
        if v in ("front", "side"):
            n = 0
            for name, (px, py) in info["parts"].items():
                if name.startswith("@"):
                    continue
                X, Y = px * T, py * T
                g.ellipse([X - 4, Y - 4, X + 4, Y + 4], fill=(220, 40, 40))
                g.text((X + 7, Y - 14 + (n % 3) * 9), name, font=font(12), fill=(160, 20, 20), stroke_width=2, stroke_fill=(235, 235, 240))
                n += 1
        g.text((6, T - 18), v.upper(), font=font(13), fill=(20, 20, 30))
        img.paste(tile, (i * T, 34))
    # swatches
    x = 12
    for k in ["main", "accent", "glow", "belly", "ink"]:
        c = tuple(int(v * 255) for v in pal[k][:3])
        d.rectangle([x, T + 44, x + 70, T + 114], fill=c, outline=(240, 240, 240))
        d.text((x, T + 118), k, font=font(13), fill=(240, 240, 240))
        x += 90
    d.text((x + 20, T + 50), "3 main colors (main, belly, ink) + 1 accent + 1 glow. Flat toon materials, vertex colors, no baked lighting.", font=font(14), fill=(220, 220, 220))
    save(img, f"{out}/{cid}_modelsheet.png")


def poses(tiles, out, cid, width=1600):
    """8 move poses (2 rows) + 6 expressions."""
    acts = sorted(glob.glob(f"{tiles}/{cid}_act_*.png"), key=numkey)
    exps = sorted(glob.glob(f"{tiles}/{cid}_expr_*.png"), key=numkey)
    at = width // 4
    et = width // 6
    H = 36 + 2 * at + et
    img = Image.new("RGB", (width, H), BG)
    d = ImageDraw.Draw(img)
    d.text((10, 8), NAMES[cid] + "   |   8 move poses + 6 expressions", font=font(18), fill=(245, 215, 140))
    for i, a in enumerate(acts[:8]):
        x, y = (i % 4) * at, 36 + (i // 4) * at
        img.paste(Image.open(a).convert("RGB").resize((at, at), Image.LANCZOS), (x, y))
        d.text((x + 6, y + at - 20), label_of(a, cid, "act"), font=font(13), fill=(255, 255, 255), stroke_width=2, stroke_fill=(20, 20, 20))
    for i, a in enumerate(exps[:6]):
        x, y = i * et, 36 + 2 * at
        img.paste(Image.open(a).convert("RGB").resize((et, et), Image.LANCZOS), (x, y))
        d.text((x + 6, y + et - 20), label_of(a, cid, "expr"), font=font(13), fill=(255, 255, 255), stroke_width=2, stroke_fill=(20, 20, 20))
    save(img, f"{out}/{cid}_poses.png")
    st = sorted(glob.glob(f"{tiles}/{cid}_state_*.png"), key=numkey)
    if st:
        save(grid(st, len(st), 420, [label_of(f, cid, "state") for f in st], NAMES[cid] + "  -  gameplay states (rage + cracked plates / detached part / ghosts)"), f"{out}/{cid}_states.png")


def main():
    tiles, out = sys.argv[1], sys.argv[2]
    ids, tile = IDS, 300
    for a in sys.argv[3:]:
        if a.startswith("--ids="):
            ids = a[6:].split(",")
        if a.startswith("--tile="):
            tile = int(a[7:])
    os.makedirs(out, exist_ok=True)
    for cid in ids:
        if os.path.exists(f"{tiles}/{cid}_ortho.json"):
            modelsheet(tiles, out, cid, PALS[cid])
        if os.path.exists(f"{tiles}/{cid}_turn_front.png") and glob.glob(f"{tiles}/{cid}_act_*.png") and glob.glob(f"{tiles}/{cid}_expr_*.png"):
            poses(tiles, out, cid)
        if False and cid in REFS and os.path.exists(f"{tiles}/{cid}_turn_front.png") and glob.glob(f"{tiles}/{cid}_act_*.png") and glob.glob(f"{tiles}/{cid}_expr_*.png"):
            board(tiles, out, cid)
        views = ["front", "three_quarter", "side", "back"]
        fs = [f"{tiles}/{cid}_turn_{v}.png" for v in views]
        if all(os.path.exists(f) for f in fs):
            save(grid(fs, 4, int(tile * 1.15), [v.replace("_", " ") for v in views], NAMES[cid] + "  -  turnaround"), f"{out}/{cid}_turnaround.png")
        for kind, fname, cols, title, mul in KINDS:
            files = sorted(glob.glob(f"{tiles}/{cid}_{kind}_*.png"), key=numkey)
            if files:
                save(grid(files, cols, int(tile * mul), [label_of(f, cid, kind) for f in files], NAMES[cid] + "  -  " + title),
                     f"{out}/{cid}_{fname}.png")
    if os.path.exists(f"{tiles}/lineup.png"):
        im = Image.open(f"{tiles}/lineup.png").convert("RGB")
        w = 1600
        save(im.resize((w, int(im.height * w / im.width)), Image.LANCZOS), f"{out}/the_seven.png")
    sil = [f"{tiles}/{c}_sil.png" for c in ids if os.path.exists(f"{tiles}/{c}_sil.png")]
    if sil:
        save(grid(sil, len(sil), 200, ids, "silhouettes (flat black)"), f"{out}/silhouettes.png")


main()
