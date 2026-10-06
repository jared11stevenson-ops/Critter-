#!/usr/bin/env python3
"""Aruun part breakdown: numbered parts on the aligned clean ortho views. Positions = fractions (x of view width, y of view height 0..1, the 4096 views in
design/reference_packs/aruun/ortho). Colours are SAMPLED from the art (median of a 15 px disc). Writes review/aruun_parts_{front,side,back}.jpg and
parts.json (used by design/ARUUN_BRIEF.md)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from common import *

# id, name, group, material, layer (1 = innermost), {view: (x, y)}
P = [
 (1, "Horn A (thick, hooked, jointed; char-left in back view)", "horn", "chitin satin", 9, {"front": (.52, .10), "side": (.62, .06), "back": (.45, .10)}),
 (2, "Horn B (thinner, longer arch; cream shaft in back view)", "horn", "chitin satin", 9, {"front": (.38, .10), "side": (.93, .045), "back": (.30, .08)}),
 (3, "Horn knob rings / side tines (cream-tan)", "horn", "chitin satin", 9, {"front": (.585, .06), "side": (.62, .06), "back": (.45, .06)}),
 (4, "Red crown plates / horn cups", "head", "chitin gloss", 8, {"front": (.55, .135), "side": (.45, .125), "back": (.37, .13)}),
 (5, "Cream temple tines + brow ridge", "head", "bone", 8, {"front": (.66, .12), "side": (.56, .16), "back": (.50, .135)}),
 (6, "Eye (yellow, dark pupil ring, white glint)", "head", "glass", 8, {"front": (.545, .155), "side": (.57, .150)}),
 (7, "Snout / nose pad / mandible hook (cream-tan face plate)", "head", "bone + chitin", 8, {"front": (.50, .175), "side": (.65, .165)}),
 (8, "Fang (white) at mouth corner", "head", "bone", 8, {"side": (.67, .175)}),
 (9, "Pale-yellow nape fringe + dark navy lower head", "head", "fibre / hair", 8, {"front": (.76, .16), "side": (.42, .14), "back": (.35, .16)}),
 (10, "Neck (long, orange-red, cream gloss streaks)", "body", "soft chitin / skin", 3, {"front": (.63, .23), "side": (.38, .225), "back": (.34, .22)}),
 (11, "Pauldron red ladybug disc (yellow spot, black holes), tan underplate", "armour", "chitin gloss", 7, {"front": (.81, .30), "side": (.19, .295), "back": (.12, .31)}),
 (12, "Hooded mantle / cloak (dark brown-aubergine, cream fringe edge)", "cloth", "cloth", 10, {"front": (.33, .37), "back": (.64, .31)}),
 (13, "Chest wrap + cream straps + knot", "cloth", "cloth", 6, {"front": (.58, .39), "side": (.50, .33), "back": (.30, .35)}),
 (14, "Tan back/chest plates (carapace)", "armour", "bone / dry chitin", 5, {"front": (.52, .43), "side": (.45, .38), "back": (.30, .36)}),
 (15, "Red waist sash + belt", "cloth", "cloth", 7, {"front": (.45, .455), "side": (.50, .50), "back": (.50, .47)}),
 (16, "Brass ring + boss belt ornament", "metal", "aged brass", 8, {"front": (.40, .495)}),
 (17, "Cream tassels / hanging strips (belt)", "cloth", "cloth", 8, {"front": (.52, .52), "side": (.57, .33), "back": (.68, .50)}),
 (18, "Leaf pendant (olive) hanging at hip", "cloth", "leaf / fibre", 8, {"front": (.73, .50)}),
 (19, "Elbow disc pad (red, yellow spot)", "armour", "chitin gloss", 7, {"front": (.82, .475), "side": (.15, .47), "back": (.07, .47)}),
 (20, "Forearm guard (red + tan)", "armour", "chitin / bone", 6, {"front": (.83, .55), "side": (.06, .55), "back": (.05, .55)}),
 (21, "Hand L (viewer-left in front): three long pointed claws", "hand", "chitin", 4, {"front": (.05, .60)}),
 (22, "Hand R: gloved fist gripping Morrow haft", "hand", "chitin + wrap", 4, {"front": (.82, .60), "back": (.07, .62)}),
 (23, "Dark under-armour (aubergine suit with cream star specks)", "body", "matte chitin / suit", 2, {"front": (.55, .58), "side": (.30, .45), "back": (.45, .55)}),
 (24, "Thigh plate (tan) with red patch", "armour", "bone", 5, {"front": (.75, .66), "side": (.50, .62), "back": (.20, .65)}),
 (25, "Olive leaf skirt strips (front, hanging from waist)", "cloth", "leaf / fibre", 8, {"front": (.55, .75)}),
 (26, "Dark ragged skirt/cloak strips (outer, both sides)", "cloth", "cloth", 9, {"front": (.93, .72), "back": (.80, .66)}),
 (27, "Tan/olive skirt strips (back view, right side)", "cloth", "leaf / fibre", 8, {"back": (.75, .72)}),
 (28, "Knee guard (dark)", "armour", "matte chitin", 6, {"front": (.40, .73), "side": (.36, .73), "back": (.30, .75)}),
 (29, "Shin plate (orange-red) / red calf plate", "armour", "chitin gloss", 6, {"front": (.38, .81), "side": (.15, .78), "back": (.27, .86)}),
 (30, "Ankle wrap / bone plates", "armour", "bone", 6, {"front": (.42, .87), "side": (.15, .91), "back": (.28, .90)}),
 (31, "Foot with large claws / blunt toe", "foot", "chitin", 4, {"front": (.30, .93), "side": (.38, .955), "back": (.27, .96)}),
 (32, "Second foot", "foot", "chitin", 4, {"front": (.88, .93), "back": (.80, .95)}),
 (33, "Red hanging fringe tail (shoulder tassel, side view)", "cloth", "cloth", 9, {"side": (.88, .395)}),
]


def sample(im, fx, fy, r=22):
    """most common colour (quantised) in a 2r box, ignoring ink-black outline pixels (lum < 24) and transparent pixels."""
    W, H = im.size; x, y = int(fx * W), int(fy * H)
    a = np.asarray(im.crop((max(x - r, 0), max(y - r, 0), x + r, y + r)).convert("RGBA")).reshape(-1, 4); a = a[a[:, 3] > 200][:, :3].astype(int)
    a = a[a.mean(1) >= 24]
    if not len(a): return None
    q = (a // 6) * 6 + 3; k, c = np.unique(q, axis=0, return_counts=True)
    return "#%02x%02x%02x" % tuple(k[c.argmax()])


def main():
    ims = {v: Image.open(f"{PACKS}/aruun/ortho/aruun_{v}_4096.png").convert("RGBA") for v in ("front", "side", "back")}
    out = []; os.makedirs(f"{PACKS}/aruun/review", exist_ok=True)
    for pid, name, grp, mat, layer, pos in P:
        hexes = {v: sample(ims[v], *p) for v, p in pos.items()}
        out.append(dict(id=pid, name=name, group=grp, material=mat, layer=layer, pos=pos, hex=hexes))
    json.dump(out, open(f"{PACKS}/aruun/parts.json", "w"), indent=1)
    for v, im in ims.items():
        s = 2200 / im.height; r = im.resize((int(im.width * s), 2200), Image.LANCZOS); bg = Image.new("RGB", r.size, BG); bg.paste(r, (0, 0), r); d = ImageDraw.Draw(bg)
        for p in out:
            if v in p["pos"]:
                x, y = p["pos"][v][0] * r.width, p["pos"][v][1] * r.height
                d.ellipse((x - 17, y - 17, x + 17, y + 17), fill=(255, 255, 255), outline=(200, 0, 0), width=3)
                d.text((x - (6 if p["id"] < 10 else 11), y - 10), str(p["id"]), font=font(19), fill=(200, 0, 0))
        d.text((10, 8), f"ARUUN {v.upper()} - numbered parts (see design/ARUUN_BRIEF.md)", font=font(30), fill=INK)
        bg.save(f"{PACKS}/aruun/review/aruun_parts_{v}.jpg", quality=90)
    return out


if __name__ == "__main__":
    for p in main(): print(p["id"], p["hex"])
