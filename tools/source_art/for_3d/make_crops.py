"""Crops each character's single figures out of the original reference sheets (one clean figure per image, overlapping text painted out) so they can be
fed to an image-to-3D generator. Boxes are in the 1200px-wide preview space of each sheet; run from the repo root: python3 tools/source_art/for_3d/make_crops.py"""
from PIL import Image
import os
SRC = "tools/source_art"; OUT = "tools/source_art/for_3d"
# id: (sheet file, [ (name, box, [whiteout boxes]) ])   boxes = (x0, y0, x1, y1) in preview space
J = {
 "aruun": ("aruun_nerit_sheet.jpg", [("hero_with_mace", (0, 0, 375, 468), [(0, 0, 200, 290), (0, 290, 110, 325), (328, 0, 375, 94)])]),
 "bramvex": ("bramvex_sheet.png", [("hero", (165, 15, 520, 410), [(455, 5, 600, 60), (518, 60, 600, 410), (165, 280, 178, 330)]), ("turn_front", (498, 25, 590, 195), []), ("turn_side", (590, 25, 685, 195), []), ("turn_back", (685, 25, 790, 195), [])]),
 "cigarra": ("cigarra_sheet.jpg", [("front", (172, 0, 445, 435), [(172, 100, 222, 165)]), ("back", (440, 0, 655, 435), []), ("side", (650, 20, 745, 435), [])]),
 "scarlith": ("scarlith_sheet.jpg", [("hero", (40, 5, 490, 410), [(40, 5, 245, 66), (40, 66, 190, 268), (40, 270, 128, 350)]), ("turn_front", (495, 15, 625, 185), []), ("turn_side", (625, 15, 745, 185), []), ("turn_back", (745, 15, 875, 185), [])]),
 "mollusk": ("mollusk_sheet.png", [("hero", (130, 0, 552, 405), [(130, 0, 250, 85), (130, 85, 190, 240), (470, 0, 600, 160)]), ("turn_front", (555, 160, 665, 400), []), ("turn_back", (640, 160, 790, 400), []), ("turn_side", (785, 160, 855, 400), [])]),
 "zephyr": ("zephyr_sheet.png", [("front", (170, 100, 420, 425), [(170, 100, 214, 158)]), ("side", (405, 140, 560, 425), []), ("back", (555, 140, 715, 425), [])]),
 "nyxaris": ("nyxaris_sheet.png", [("hero", (165, 5, 500, 400), [(165, 5, 218, 95), (165, 95, 188, 232), (455, 5, 520, 242)]), ("turn_front", (460, 25, 562, 240), []), ("turn_side", (562, 25, 705, 240), []), ("turn_back", (705, 25, 810, 240), [])]),
 "pharilux": ("pharilux_sheet.png", [("hero", (130, 0, 482, 412), [(130, 0, 300, 75), (130, 85, 180, 240), (476, 0, 490, 412)]), ("turn_front", (415, 25, 545, 205), []), ("turn_side", (545, 25, 690, 205), []), ("turn_back", (690, 25, 805, 205), [])]),
}
for cid, (fn, crops) in J.items():
    im = Image.open(os.path.join(SRC, fn)).convert("RGB")
    k = im.width / 1200.0
    paper = im.getpixel((int(im.width * 0.5), int(im.height * 0.505)))
    for name, box, wipe in crops:
        c = im.copy()
        for w in wipe:
            c.paste(paper, tuple(int(v * k) for v in w))
        out = c.crop(tuple(int(v * k) for v in box))
        out.save(os.path.join(OUT, f"{cid}_{name}.png"))
        print(cid, name, out.size)
