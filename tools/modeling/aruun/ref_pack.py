#!/usr/bin/env python3
"""Aruun 3D reference pack -> design/model_sheets/aruun/

Run: python3 tools/modeling/aruun/ref_pack.py
Builds the orthographic turnaround board (identical scale, landmark lines), detail boards and a sampled
palette from the APPROVED sheet only (tools/source_art/aruun_nerit_sheet.jpg and its 1400 px copy
bible_media/image37.jpg). Crops/upscales/annotations only -- nothing is invented here.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from common import refboard as rb  # noqa: E402

OUT = rb.rpath("design", "model_sheets", "aruun")
SHEET = "tools/source_art/bible_media/image37.jpg"   # same sheet as aruun_nerit_sheet.jpg, 1400 px wide
SW = 1280                                            # crop boxes below are in 1280-px sheet coordinates
H_M = 2.4

# Landmarks measured on the clean cut-outs (pixel rows, cut-out coordinates). Front view is drawn with a low
# camera / slight perspective and a 3/4 torso, so its rows differ; side & back are the proportion authority.
LANDMARKS = {
    #            horn  cranium jaw  neck_base shoulder elbow waist crotch knee ankle sole
    "side":  dict(horn_tip=0, cranium_top=45, jaw=72, neck_base=100, shoulder=120, elbow=172, waist=185,
                  crotch=240, knee=285, ankle=340, sole=386),
    "back":  dict(horn_tip=0, cranium_top=42, jaw=65, neck_base=100, shoulder=125, elbow=175, waist=185,
                  crotch=240, knee=290, ankle=345, sole=379),
    "front": dict(horn_tip=0, cranium_top=50, jaw=100, neck_base=128, shoulder=140, elbow=225, waist=240,
                  crotch=330, knee=385, ankle=440, sole=486),
}
LM_COL = {"horn_tip": (150, 40, 30), "cranium_top": (180, 60, 40), "jaw": (200, 90, 40), "neck_base": (160, 120, 30),
          "shoulder": (40, 110, 60), "elbow": (40, 90, 140), "waist": (120, 50, 140), "crotch": (30, 120, 150),
          "knee": (20, 80, 160), "ankle": (100, 100, 100), "sole": (0, 0, 0)}


def turnaround():
    H = 1300           # px for 2.4 m
    top = 140
    views = [("front", "FRONT (3/4 torso, head in profile, holding Morrow)"), ("side", "SIDE (faces right)"),
             ("back", "BACK")]
    ims = {v: rb.load("game/art/characters/aruun/%s.png" % v) for v, _ in views}
    widths = {v: int(ims[v].width * H / ims[v].height) for v in ims}
    W = 260 + sum(widths.values()) + 140 * 3 + 200
    img = Image.new("RGBA", (W, top + H + 220), rb.BG)
    rb.title_bar(img, "ARUUN - orthographic turnaround", "all views scaled to identical height 2.40 m (horn tip -> sole)")
    d = ImageDraw.Draw(img)
    x = 260
    # meter ruler
    for i in range(0, 25):
        z = i * 0.1
        y = top + H - int(z / H_M * H)
        d.line([(170, y), (200 if i % 5 else 215, y)], fill=rb.INK, width=2)
        if i % 5 == 0:
            rb.label(d, (160, y), "%.1f m" % z, 18, anchor="rm")
    d.line([(200, top), (200, top + H)], fill=rb.INK, width=2)
    rb.label(d, (160, top), "2.4 m", 18, anchor="rm")
    # canonical landmark lines (averaged side/back, metres)
    canon = {}
    for k in LANDMARKS["side"]:
        zs = [H_M * (1 - LANDMARKS[v][k] / float(ims[v].height)) for v in ("side", "back")]
        canon[k] = sum(zs) / len(zs)
    for k, z in canon.items():
        y = top + H - int(z / H_M * H)
        d.line([(205, y), (W - 20, y)], fill=LM_COL[k] + (110,), width=1)
        rb.label(d, (W - 24, y - 2), "%s %.2f m" % (k, z), 15, fill=LM_COL[k] + (255,), anchor="rb")
    for v, cap in views:
        im = ims[v].resize((widths[v], H), Image.LANCZOS)
        img.alpha_composite(im, (x, top))
        # view-specific landmark ticks
        for k, py in LANDMARKS[v].items():
            y = top + int(py * H / ims[v].height)
            d.line([(x - 30, y), (x - 6, y)], fill=LM_COL[k] + (255,), width=3)
        rb.label(d, (x + widths[v] // 2, top + H + 20), v.upper(), 26, bold=True, anchor="ma")
        rb.label(d, (x + widths[v] // 2, top + H + 56), cap, 15, anchor="ma")
        x += widths[v] + 140
    notes = ["Measured proportions (side+back average): " + ", ".join("%s %.2f" % (k, z) for k, z in canon.items()),
             "Front view is drawn larger and from a lower camera (perspective); use side/back for heights, front for widths/costume.",
             "Views disagree on the cloak: front = hood + cloak behind both shoulders; back = cloak draped over his RIGHT shoulder only; side = no cloak visible."]
    for i, n in enumerate(notes):
        rb.label(d, (40, top + H + 100 + i * 28), n, 17)
    img.convert("RGB").save(os.path.join(OUT, "turnaround.png"))
    return canon


def board(name, title, sub, items, cols=3, cell=(620, 520)):
    """items: list of (caption, image)."""
    rows = (len(items) + cols - 1) // cols
    W = cols * cell[0] + (cols + 1) * 30
    H = 90 + rows * (cell[1] + 70) + 30
    img = Image.new("RGBA", (W, H), rb.BG)
    rb.title_bar(img, title, sub)
    d = ImageDraw.Draw(img)
    for i, (cap, im) in enumerate(items):
        cx = 30 + (i % cols) * (cell[0] + 30)
        cy = 100 + (i // cols) * (cell[1] + 70)
        d.rectangle([cx - 2, cy - 2, cx + cell[0] + 2, cy + cell[1] + 2], outline=(120, 100, 90, 255), width=2)
        s = min(cell[0] / im.width, cell[1] / im.height)
        r = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
        img.alpha_composite(r, (cx + (cell[0] - r.width) // 2, cy + (cell[1] - r.height) // 2))
        y = cy + cell[1] + 8
        for line in cap.split("\n"):
            rb.label(d, (cx, y), line, 15)
            y += 19
    img.convert("RGB").save(os.path.join(OUT, name))


def C(box, k=4):
    return rb.sheet_crop(SHEET, box, SW, k)


def detail_boards():
    board("detail_head.png", "ARUUN - head, horns, neck", "sheet crops x4-6 (LANCZOS)", [
        ("HEAD DETAILS panel: yellow eye w/ dark pupil ring, cream/tan face plate,\nred crown plates, pale-yellow fringe sweeping back, white fang", C((530, 20, 632, 120), 6)),
        ("Front view head (profile, facing screen-left): long snout, mandible hook,\ntwo red horns w/ knobbed tines, bone tines at temples", C((225, 18, 330, 112), 5)),
        ("Side view head (faces right): horns sweep back, olive fringe at nape", C((548, 104, 622, 192), 6)),
        ("Back view head: dark nape cap, horns diverge, olive/yellow fringe at sides", C((404, 104, 470, 175), 6)),
        ("Expressions CALM / FOCUSED: front-on skull, eyes on the sides of the head,\nhorns are near-parallel columns with flat notched tips", C((335, 520, 455, 645), 4)),
        ("Expressions RAGE / AMUSED / AGGRESSIVE: jaw hinges wide, rows of fangs,\npink tongue/inner mouth, fringe = cream strands + olive strands", C((455, 520, 640, 645), 3)),
        ("Beetle inspiration (giraffe weevil) + horn silhouettes", C((345, 18, 470, 100), 4)),
        ("Dark silhouette studies beside the beetle photo (unlabeled on sheet:\nhorn or haft profile)", C((470, 18, 530, 100), 5)),
        ("Unlabeled grey sketch beside the back view (mantle/hood flat?)", C((500, 120, 540, 250), 4)),
    ])
    board("detail_hands_feet.png", "ARUUN - hands / claws / feet", "", [
        ("Front: left hand (hangs) - dark plated fingers, tan claw tips,\nred forearm plate w/ yellow dot", C((335, 300, 385, 362), 7)),
        ("Front: right hand gripping Morrow", C((140, 305, 200, 365), 7)),
        ("Back view: left hand, 3 fingers + thumb, tan knuckle plates", C((385, 330, 428, 392), 7)),
        ("Side view: hand + forearm bracer", C((540, 300, 582, 362), 7)),
        ("Front feet: armoured sabaton, tan plates banded with dark,\n2-3 forward toe-claws + rear spur", C((170, 430, 265, 496), 5)),
        ("Front right-side foot", C((325, 425, 385, 496), 6)),
        ("Back view feet: heel spurs, tan plate bands", C((384, 430, 534, 496), 4)),
        ("Side view foot: long toe claw forward, ankle cuff", C((532, 430, 615, 496), 6)),
        ("Side view lower leg: orange mottled shin plate, tan calf", C((532, 330, 600, 440), 4)),
    ])
    board("detail_morrow.png", "MORROW - Thoughtstone mace (psionic link)", "states: retracted / extended / floating", [
        ("RETRACTED: short haft, head ~1/3 of length", C((15, 525, 100, 640), 5)),
        ("EXTENDED: haft telescopes (segments slide), red psionic arcs", C((100, 525, 175, 640), 5)),
        ("Vertical: full haft - knotted segmented column,\npommel spike, tendrils wrap the neck", C((175, 525, 225, 650), 5)),
        ("PSIONIC CONTROL (FLOATING): head detaches, red aura,\nhaft trails like a tail", C((225, 525, 330, 645), 4)),
        ("Front turnaround: Morrow head (big red core eye,\nconical tan spikes, ring studs w/ dark center)", C((0, 340, 165, 495), 4)),
        ("Front turnaround: haft + grip, organic knots / tendrils", C((120, 280, 200, 400), 5)),
        ("Ability: Reaching Strike", C((10, 682, 140, 760), 4)),
        ("Ability: Gravity Pull", C((382, 682, 512, 760), 4)),
        ("Ability: Beetle Rage / Unbreakable", C((142, 682, 380, 760), 3)),
    ])
    board("detail_costume.png", "ARUUN - carapace, costume & belt items", "", [
        ("Chest: tan segmented abdomen plates, cream bandage straps\ncrossing L-shoulder->R-hip, gold ring pendant", C((228, 135, 330, 235), 5)),
        ("Belt: red sash, bone ring buckle (dark centre), hanging bone\nmedallion w/ gold, cream loincloth strips, red bead strings", C((215, 225, 320, 335), 5)),
        ("Shoulder: red ladybug pauldron (yellow spot + black spot),\ncream wraps, olive tassel talisman", C((320, 115, 375, 270), 4)),
        ("Back: cloak/mantle over RIGHT shoulder, tan scapula plates,\nred sash knot, cloth tails", C((384, 190, 534, 330), 3)),
        ("Skirt: olive-green leaf panels (front/side), dark cloak tails behind", C((185, 320, 385, 445), 3)),
        ("Hood/collar (front view, behind neck)", C((205, 140, 265, 230), 5)),
        ("Side: torso depth, pauldron, sash, hanging cloth at front", C((532, 150, 625, 290), 4)),
        ("Legs front: dark navy thigh carapace, tan knee plates,\norange/red mottling, tiny light speckles", C((190, 320, 390, 440), 3)),
        ("Back legs: tan hamstring plates, red-orange calf mottling", C((384, 300, 534, 440), 3)),
    ])


# material -> list of sheet boxes (1280 coords) that are dominated by that material
PALETTE_REGIONS = {
    "carapace_red":     [(326, 146, 342, 158), (350, 258, 362, 272)],
    "carapace_spot_yellow": [(341, 139, 346, 144)],
    "carapace_orange":  [(296, 108, 303, 125), (430, 180, 440, 195)],
    "chitin_navy":      [(322, 205, 338, 220), (232, 382, 250, 398)],
    "plate_tan":        [(258, 203, 272, 215)],
    "cloth_cream":      [(288, 194, 300, 200)],
    "skirt_olive":      [(272, 365, 292, 385), (210, 375, 222, 395)],
    "cloak_dark":       [(465, 220, 485, 240)],
    "sash_red":         [(255, 230, 268, 238)],
    "horn_red":         [(262, 30, 270, 45)],
    "head_crown_red":   [(560, 33, 575, 40)],
    "face_tan":         [(603, 75, 615, 85)],
    "jaw_navy":         [(585, 75, 595, 85)],
    "eye_yellow":       [(600, 62, 604, 66)],
    "fringe_cream":     [(568, 52, 578, 62)],
    "morrow_head":      [(30, 455, 45, 470)],
    "morrow_core":      [(42, 400, 58, 415)],
    "morrow_stud":      [(70, 380, 80, 388)],
}
SHEET_SWATCHES = [(27, 175), (27, 205), (27, 235), (27, 265), (27, 295)]


def palette():
    im = rb.load(SHEET)
    f = im.width / float(SW)
    bg = np.array([238, 226, 205])
    res = {}
    rows = []
    for name, boxes in PALETTE_REGIONS.items():
        px = []
        crops = []
        for b in boxes:
            bb = tuple(int(v * f) for v in b)
            p = rb.region_pixels(im, bb)
            p = p[np.abs(p.astype(int) - bg).sum(1) > 40]
            px.append(p)
            crops.append(im.crop(bb))
        P = np.concatenate(px)
        cols = rb.kmeans_colors(P, 3) if len(P) > 10 else []
        main = tuple(np.median(P, 0).astype(int)) if len(P) else (0, 0, 0)
        res[name] = {"median": rb.hexc(main), "clusters": [[rb.hexc(c), n] for c, n in cols]}
        rows.append((name, crops, main, cols))
    sheet_sw = []
    for (x, y) in SHEET_SWATCHES:
        p = rb.region_pixels(im, (int((x - 3) * f), int((y - 3) * f), int((x + 4) * f), int((y + 4) * f)))
        sheet_sw.append(rb.hexc(np.median(p, 0)))
    res["_sheet_palette_dots"] = sheet_sw
    with open(os.path.join(OUT, "palette.json"), "w") as fp:
        json.dump(res, fp, indent=1)
    W, RH = 1500, 92
    img = Image.new("RGBA", (W, 100 + RH * (len(rows) + 1) + 40), rb.BG)
    rb.title_bar(img, "ARUUN - sampled palette", "median + k-means clusters of sheet pixels per material (bg excluded)")
    d = ImageDraw.Draw(img)
    y = 100
    rb.label(d, (20, y + 30), "sheet palette dots", 18, bold=True)
    for i, h in enumerate(sheet_sw):
        x = 330 + i * 170
        d.rectangle([x, y + 10, x + 70, y + 80], fill=h)
        rb.label(d, (x + 78, y + 38), h, 16)
    y += RH
    for name, crops, main, cols in rows:
        rb.label(d, (20, y + 30), name, 18, bold=True)
        x = 260
        for c in crops[:2]:
            c2 = c.resize((70, 70), Image.NEAREST)
            img.alpha_composite(c2, (x, y + 10))
            x += 76
        d.rectangle([420, y + 10, 520, y + 80], fill=tuple(int(v) for v in main))
        rb.label(d, (530, y + 38), "median " + rb.hexc(main), 16)
        x = 760
        for c, n in cols:
            d.rectangle([x, y + 18, x + 54, y + 72], fill=tuple(int(v) for v in c))
            rb.label(d, (x + 60, y + 38), rb.hexc(c), 15)
            x += 220
        y += RH
    img.convert("RGB").save(os.path.join(OUT, "palette.png"))
    return res


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    canon = turnaround()
    detail_boards()
    pal = palette()
    with open(os.path.join(OUT, "landmarks.json"), "w") as fp:
        json.dump({"height_m": H_M, "canonical_heights_m": {k: round(v, 3) for k, v in canon.items()},
                   "view_rows_px": LANDMARKS}, fp, indent=1)
    print("ok", OUT)
