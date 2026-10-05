"""Stage 4: phone-friendly review set: <id>_pack_overview.png (2400 px wide) + per-view full-res review images in design/reference_packs/<id>/review/."""
import sys, os, json, datetime
sys.path.insert(0, os.path.dirname(__file__))
from common import *
from cast import CAST, LM_ORDER
import ortho as O, packs as P

W = 2400
PAPER = BG


def fit_h(im, h):
    return im.resize((max(1, int(im.width * h / im.height)), h), Image.LANCZOS)


def fit_w(im, w):
    return im.resize((w, max(1, int(im.height * w / im.width))), Image.LANCZOS)


def flat(im):
    if im.mode == "RGBA":
        bg = Image.new("RGB", im.size, BG); bg.paste(im, (0, 0), im); return bg
    return im.convert("RGB")


def opt(path, im):
    im.convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)


def section_title(txt):
    cv = Image.new("RGB", (W, 64), (60, 45, 40)); ImageDraw.Draw(cv).text((30, 14), txt, font=font(32), fill=(240, 228, 205)); return cv


def legend_block(w, derived):
    cv = Image.new("RGB", (w, 400), PAPER); d = ImageDraw.Draw(cv)
    d.text((10, 6), "Derivation overlay legend", font=font(26), fill=INK)
    for i, (col, t) in enumerate(((P.GREEN, "GREEN = directly from the original art (1:1 pixels)"), (P.YELLOW, "YELLOW = inferred from another view (row-remapped)"), (P.RED, "RED = unknown - NOT invented, asked in QUESTIONS"))):
        d.rectangle((10, 50 + i * 44, 50, 86 + i * 44), fill=col); d.text((64, 54 + i * 44), t, font=font(21, False), fill=INK)
    P.wrap(d, (10, 184), derived, 18, 62, fill=(90, 70, 60))
    return cv


def build(cid, status="ready for review"):
    c = CAST[cid]; pk = os.path.join(PACKS, cid); rv = os.path.join(pk, "review"); os.makedirs(rv, exist_ok=True)
    meta = json.load(open(os.path.join(pk, "metadata.json"))); al, _ = P.load_aligned(cid)
    cj = P.canon_json(cid); blocks = []
    # header
    hd = Image.new("RGB", (W, 150), (40, 30, 28)); d = ImageDraw.Draw(hd)
    d.text((30, 14), f"{c['name'].upper()}  -  {c['title']}", font=font(60), fill=(240, 228, 205))
    d.text((30, 90), f"{cj.get('class','')} / {cj.get('role','')}   height {c['height_m']} m ({c['height_note']})   reference pack REVIEW SET   {datetime.date.today()}   status: {status.upper()}", font=font(24, False), fill=(215, 200, 170))
    blocks.append(hd)
    # ortho + right column
    blocks.append(section_title("1  ORTHO VIEWS - same scale, aligned on measured landmark lines (clean + overlay in ortho/)"))
    lu = Image.open(os.path.join(pk, "ortho", f"{cid}_ortho_lineup_landmarks.jpg")).convert("RGB"); lu = fit_h(lu, 1150)
    col_w = W - lu.width - 60
    row = Image.new("RGB", (W, max(lu.height, 1000) + 20), PAPER); row.paste(lu, (20, 10)); d = ImageDraw.Draw(row); x = lu.width + 40; y = 20
    rows = json.load(open(os.path.join(pk, "proportions.json")))["rows"]
    d.text((x, y), "Proportions (from canon + measured)", font=font(28), fill=INK); y += 44
    short = ["Total height", "Body (to crown)", "Head", "Heads tall", "Neck", "Torso", "Arm", "Upper arm", "Forearm+hand", "Leg", "Thigh", "Shin", "Ankle h.", "Leg:torso"]
    for (a, b), sh in zip(rows, short):
        d.text((x, y), sh, font=font(19, False), fill=INK); d.text((x + 215, y), b.split("(")[0].strip()[:26], font=font(19), fill=INK); y += 28
    y += 14; d.text((x, y), "Views in this pack", font=font(26), fill=INK); y += 38
    for v, m in meta["views"].items():
        d.text((x, y), f"{v}: {m['pose']}" + ("" if m["orthographic"] else "  [NOT ortho]"), font=font(18, False), fill=INK); y += 26
    y += 16
    pal = Image.open(os.path.join(pk, "swatches", f"{cid}_palette.png")).convert("RGB").crop((0, 0, 1400, 260)); pal = fit_w(pal, min(col_w, 1000)); row.paste(pal, (x, y)); y += pal.height + 10
    blocks.append(row)
    # head
    blocks.append(section_title("2  HEAD PACK - turnaround on shared rows, expressions, face callouts (head/)"))
    ht = Image.open(os.path.join(pk, "head", f"{cid}_head_turnaround_landmarks.jpg")).convert("RGB"); ht = fit_h(ht, 560) if ht.width * 560 / ht.height <= W - 40 else fit_w(ht, W - 40)
    r2 = Image.new("RGB", (W, ht.height + 20), PAPER); r2.paste(ht, (20, 10)); blocks.append(r2)
    ex = os.path.join(pk, "head", f"{cid}_expressions.jpg")
    if os.path.exists(ex):
        e = Image.open(ex).convert("RGB"); e = fit_w(e, W) if e.width * 700 / e.height > W else fit_h(e, 700)
        r3 = Image.new("RGB", (W, e.height + 10), PAPER); r3.paste(e, (0, 5)); blocks.append(r3)
    fc = os.path.join(pk, "head", f"{cid}_face_callouts.jpg")
    if os.path.exists(fc): blocks.append(fit_w(Image.open(fc).convert("RGB"), W))
    # details
    blocks.append(section_title("3  DETAILS & MATERIALS - hands/feet/costume/props (details/), PBR callouts"))
    ds = os.path.join(pk, "details", f"{cid}_detail_sheet.jpg")
    if os.path.exists(ds): blocks.append(fit_w(Image.open(ds).convert("RGB"), W))
    blocks.append(fit_w(Image.open(os.path.join(pk, "details", f"{cid}_materials.jpg")).convert("RGB"), W))
    # greybox + legend + questions
    blocks.append(section_title("4  MISSING / DERIVED VIEWS (design-locked) + OPEN QUESTIONS FOR THE LEAD"))
    gdir = os.path.join(pk, "greybox"); tiles = []
    for n in ("front", "side", "back", "q34_front", "q34_back"):
        f = os.path.join(gdir, f"{cid}_clay_{n}.png")
        if os.path.exists(f): tiles.append((n, Image.open(f).convert("RGBA")))
    r4 = Image.new("RGB", (W, 640), PAPER); d = ImageDraw.Draw(r4)
    if tiles:
        for i, (n, im) in enumerate(tiles):
            bb = im.getchannel("A").getbbox(); im = im.crop(bb); im = fit_h(im, 560); x = 20 + i * 250
            bg = Image.new("RGB", (240, 580), (205, 205, 200)); bg.paste(im.resize((min(im.width, 240), int(im.height * min(im.width, 240) / im.width))), (0, 0), im.resize((min(im.width, 240), int(im.height * min(im.width, 240) / im.width)))) if False else None
            t = fit_h(im, 560); t = t if t.width <= 240 else fit_w(im, 240)
            bgc = Image.new("RGB", (240, 580), (205, 205, 200)); bgc.paste(t, ((240 - t.width) // 2, 580 - t.height), t); r4.paste(bgc, (x, 20)); d.text((x, 604), n, font=font(18), fill=INK)
    r4.paste(legend_block(1100, c.get("derived_note", "No view was painted over: all ortho views are original art. Greybox = clay visual hull from the side+back silhouettes (shape only, no colour).")), (1290, 20))
    blocks.append(r4)
    q = c.get("questions", [])
    qh = 70 + sum(len(__import__("textwrap").wrap(t, 150)) * 28 + 10 for t in q)
    qb = Image.new("RGB", (W, max(qh, 120)), (250, 244, 232)); d = ImageDraw.Draw(qb); d.text((30, 10), f"Open questions for the Lead ({len(q)}) - see QUESTIONS.md", font=font(30), fill=(150, 30, 30)); y = 56
    for i, t in enumerate(q): y = P.wrap(d, (30, y), f"Q{i+1}. {t}", 22, 150) + 8
    blocks.append(qb)
    H = sum(b.height for b in blocks); ov = Image.new("RGB", (W, H), PAPER); y = 0
    for b in blocks: ov.paste(b, (0, y)); y += b.height
    opt(os.path.join(rv, f"{cid}_pack_overview.png"), ov)
    # per-view full-resolution review images (2048 tall, flattened, landmark overlay), jpg for phones
    canon = O.canon_fracs(c)
    for guides in (False, True):
        pass
    for v, (im, ax) in al.items():
        f = 2048 / O.CANVAS_H; r = im.resize((int(im.width * f), 2048), Image.LANCZOS); cv = Image.new("RGB", (r.width + 260, 2048 + 20), BG); cv.paste(r, (0, 10), r); d = ImageDraw.Draw(cv)
        for k in LM_ORDER:
            y = 10 + (O.TOP + canon[k] * (O.GROUND - O.TOP)) * f; d.line((0, y, cv.width, y), fill=O.LM_COL[k], width=1); d.text((r.width + 6, y - 9), f"{k} {(1-canon[k])*c['height_m']:.2f}m", fill=O.LM_COL[k], font=font(15))
        cv.save(os.path.join(rv, f"{cid}_{v}_view_2048_landmarks.jpg"), quality=90)
    return ov.size


if __name__ == "__main__":
    print(build(sys.argv[1]))
