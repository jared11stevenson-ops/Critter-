"""Per-character source map + measured landmarks for the reference packs.
Boxes are in ORIGINAL source-sheet pixel coords (x0,y0,x1,y1). `lm` = landmark rows as FRACTION of total silhouette height from the
top of the silhouette (0) to the sole/ground (1), read off the art with tools/refsheets/gridview.py (aruun: design/model_sheets/aruun/landmarks.json).
Measurement error is about +-1% of height; every landmark is labelled MEASURED (json) or READ (eyeballed on the gridded art)."""

LM_ORDER = ["top", "crown", "eyes", "chin", "neck", "shoulder", "elbow", "wrist", "waist", "crotch", "knee", "ankle", "ground"]

CAST = {
 "aruun": dict(
    name="Aruun", title="The Reacher", height_m=2.40, height_note="horn tip to sole (sheet: 240 cm / 7'10\")",
    sheet="tools/source_art/aruun_nerit_sheet.jpg", sheet_box=(0, 0, 640, 500),
    views={  # existing ESRGAN+rembg cuts are re-used for aruun (they are the audited ones; front has Morrow erased)
        "front": dict(box=(8, 0, 400, 500), near=3, pose="3/4 torso, head in profile, Morrow (mace) erased (NOT orthographic)", ortho=False,
                      erase=dict(ref="design/model_sheets/aruun/hires/front_x4.png", mask="design/model_sheets/aruun/hires/front_morrow_mask.png")),
        "side":  dict(box=(538, 100, 648, 497), near=3, pose="side, faces screen-right", ortho=True),
        "back":  dict(box=(386, 96, 542, 497), near=3, pose="back", ortho=True),
    },
    lm={  # fractions: json view_rows_px / sole row
        "front": dict(top=0, crown=50/486, eyes=(50+0.33*50)/486, chin=100/486, neck=128/486, shoulder=140/486, elbow=225/486, wrist=0.60, waist=240/486, crotch=330/486, knee=385/486, ankle=440/486, ground=1),
        "side":  dict(top=0, crown=45/386, eyes=(45+0.33*27)/386, chin=72/386, neck=100/386, shoulder=120/386, elbow=172/386, wrist=0.57, waist=185/386, crotch=240/386, knee=285/386, ankle=340/386, ground=1),
        "back":  dict(top=0, crown=42/379, eyes=(42+0.33*23)/379, chin=65/379, neck=100/379, shoulder=125/379, elbow=175/379, wrist=0.58, waist=185/379, crotch=240/379, knee=290/379, ankle=345/379, ground=1),
    },
    lm_src="landmarks.json (side+back+front rows); eyes and wrist READ",
    canon_m=dict(top=2.4, crown=2.127, chin=1.97, neck=1.772, shoulder=1.631, elbow=1.311, waist=1.239, crotch=0.894, knee=0.596, ankle=0.251, ground=0.0),
    head=dict(front=(0.12, 0.0, 0.62, 0.22), side=(0.10, 0.0, 1.0, 0.24), back=(0.0, 0.0, 1.0, 0.25)),
    sheet_panels=dict(  # name: (box, rembg?)
        head_details=((528, 23, 633, 99), False),
        horn_inspiration=((350, 20, 470, 100), False),
        mace_states=((8, 512, 314, 645), False),
        expr_calm=((331, 522, 384, 640), "center"), expr_focused=((386, 522, 441, 640), "center"), expr_rage=((441, 522, 498, 640), "center"),
        expr_amused=((497, 522, 551, 640), "center"), expr_aggressive=((553, 522, 634, 640), "center"),
    ),
    expressions=["calm", "focused", "rage", "amused", "aggressive"],
    view_details={
        "hand_L_claws": ("front", .00, .53, .23, .72), "hand_R_fist": ("front", .74, .56, .94, .71),
        "foot_front_L": ("front", .17, .89, .47, .995), "foot_front_R": ("front", .76, .87, 1.0, 1.0),
        "hand_side": ("side", .0, .52, .22, .66), "foot_side": ("side", .0, .87, .74, 1.0),
        "hand_back": ("back", .0, .57, .14, .71), "feet_back": ("back", .04, .87, .96, 1.0),
        "costume_torso_front": ("front", .15, .21, .96, .52), "costume_skirt_front": ("front", .08, .52, .96, .90), "costume_cloak_back": ("back", .04, .21, .92, .55),
    },
    material_view="side",
    materials=[
        dict(name="Red carapace discs (shoulder / hip / elbow)", cls="glossy chitin", sample=("side", .15, .285), rough=.30, metal=0.0, note="cream spot highlight painted; dark holes are recesses"),
        dict(name="Orange neck / limb skin", cls="soft chitin / skin", sample=("side", .43, .20), rough=.50, metal=0.0, note="smooth orange gradient with painted gloss streaks"),
        dict(name="Dark under-armour", cls="matte chitin / suit", sample=("side", .56, .40), rough=.45, metal=0.0, note="navy-black with tiny cream star speckles (paint)"),
        dict(name="Tan bone plates (thigh, arm guards)", cls="bone / dry chitin", sample=("side", .37, .65), rough=.55, metal=0.0, note="cream-tan plates with red rim"),
        dict(name="Horns", cls="chitin (matte-satin)", sample=("side", .56, .06), rough=.40, metal=0.0, note="red-brown with orange base, jointed knobs"),
        dict(name="Cream wraps / straps", cls="cloth", sample=("side", .56, .375), rough=.85, metal=0.0, note="chest wrap, hanging tassels"),
        dict(name="Brass rings / belt ornaments", cls="metal (aged brass)", sample=("front", .38, .52), rough=.35, metal=.85, note="belt ring + buckle ornament, small"),
        dict(name="Hood / cloak", cls="cloth", sample=("back", .60, .28), rough=.90, metal=0.0, note="dark olive-grey, ragged edge, over RIGHT shoulder in back view"),
        dict(name="Olive skirt strips", cls="cloth / leaf-like fibre", sample=("front", .785, .78), rough=.90, metal=0.0, note="tattered olive-green strips"),
        dict(name="Morrow mace core (red orb)", cls="glossy red gem / psionic", hex="#c8462b", sample=("side", .15, .285), rough=.15, metal=0.0, emi=0.4, note="hex = canon palette (not in these views); emissive is a SUGGESTION pending Q6"),
    ],
    layers=["Skin / chitin body (orange neck, dark under-armour)", "Tan bone plates on thighs, shins and arms", "Red carapace discs (shoulders, hips, elbows) and shin armour", "Belt with brass ring ornament and hanging tassels", "Olive tattered skirt strips (over thighs)", "Chest wraps / straps (over torso)", "Hood + cloak (hood from front art; cloak over RIGHT shoulder in back art)", "Horns (rooted in skull cups) + head frill"],
    callouts={"eye (yellow, slit)": (.55, .42, .88, .72), "snout / jaw": (.58, .62, 1.0, .97), "brow + horn base + frill": (.18, .02, .90, .50)},
    style=dict(
        line="Heavy black ink silhouette (thickest around the horns, carapace discs and boots), hairline interior lines; line breaks where plates overlap.",
        color="Blocked in 4 families: red-orange carapace (#9c2f22 #c8462b #d9803a), tan/cream bone plates, near-black navy under-armour, olive cloth (#6b6a3a) - each plate is one flat colour with a cream rim-light.",
        shading="Flat cel with one hard-edged shadow tone, small cream/yellow gloss ovals on the carapace discs, scattered tiny cream star-dots on dark plates (texture, not geometry).",
        shape="Tall, narrow and elongated (giraffe-beetle): very long orange neck, small head with a long down-curved snout, two long hooked lyre horns, huge round shoulder discs, columnar legs with armoured shins and clawed feet. Strong top-heavy triangle silhouette: wide shoulders, narrow waist, tattered skirt flare.",
        locks=["Horn pair: long, hooked forward, jointed with knobs and small side tines (do not shorten or straighten)", "Round red shoulder discs with cream spot and dark holes", "Very long orange neck", "Overall height 2.40 m horn tip to sole; head about 0.16 m crown-to-chin", "Morrow: spiked dark sphere with a red glowing core on a jointed haft (telescoping)", "Palette #9c2f22 / #c8462b / #d9803a / #6b6a3a / #4a3226"]),
    questions=[
        "True front: the sheet's FRONT is a 3/4 torso with the head in profile (and Morrow in hand). The face seen straight-on (eye spacing, snout width, how the two horns spread in front view) does not exist. Can the creator supply or approve a true orthographic front head/torso? Until then the front head is RED/unknown.",
        "Cloak: the views disagree (front: hood + cloak behind both shoulders; back: cloak draped over his RIGHT shoulder only; side: no cloak). spec.md records a Lead ruling (back-view cloak on the right shoulder + front-view hood). Is that ruling still the creator's intent?",
        "Side-view horns: the tips of both horns touch the sheet's page edge and may be cut. Is the horn length shown in the side/back views (about 0.27 m above the cranium) the intended full length?",
        "Morrow (mace): the front sheet draws it from a low camera, so its size is unreliable. Please confirm the head diameter (this pack assumes about 0.5 m; the sheet shows head about 2x the fist-to-elbow length) and whether the telescoping haft states on the MACE panel (retracted / extended / floating) are all needed in the model.",
        "Hands/feet: the front shows the viewer-left hand with three long pointed claw fingers and the right hand as a gloved fist; feet have large claws in front view but a blunt toe in side view. Is the claw hand/foot design symmetric (both sides) or intentionally different?",
        "Emissive: should the red discs and Morrow's red core glow in game, or is the gloss painted only? (Suggested emissive 0.4 on Morrow's core only; nothing in the art glows.)",
    ],
    derived_note="Greybox clay views are silhouette visual hulls of the aligned side+back art (shape only). No view was painted over: every colour in ortho/ is original art. The true front head is RED (unknown) - see Q1.",
    review=[
        "FIDELITY: all three views are the original paint; nothing redrawn. FRONT was re-cut from the sheet (the older hires cut clipped the viewer-right foot and claws flat at the crop edge; they are complete now). Morrow was removed with the audited mask from design/model_sheets/aruun/hires/front_morrow_mask.png, re-registered to the new cut (shift -46,+10 px); a short brown haft stub remains in the viewer-left hand (it is the grip, not invented).",
        "ALIGNMENT: crown, eyes, chin, neck base, shoulder, elbow, waist, crotch, knee, ankle and sole are on identical pixel rows in all three views by construction (piecewise-linear row warp from landmarks.json; max warp about 2.5 % of height). The FRONT is drawn larger/from a lower camera, so it is wider than side/back at the same height - never take widths from it.",
        "CLEANLINESS: rembg left a hard 1-px dark edge on some outlines (inherits the sheet's black ink, acceptable); a few cream star dots are smoothed by the upscaler. Side horn tips touch the sheet edge (Q3). Second ESRGAN pass (side/back) makes flat colour fields slightly posterised - lines are cleaner than a plain Lanczos stretch.",
        "EXPRESSIONS: sheet heads touch their neighbours, so rembg isolates one head per tile and its far edges are clipped by the neighbour (FOCUSED, AMUSED). Open-mouth views for the jaw: RAGE and AGGRESSIVE show fangs/tongue/lower jaw hinge.",
        "GREYBOX: a silhouette visual hull, deliberately crude (boxy torso because the back silhouette includes the cloak). Use it only for volume/pose checks, not as a sculpt base.",
        "FIXED during review: horn tips clipped in the side cut (box widened), duplicate detail exports removed, expression tiles re-cut with centre-component isolation, head-detail panel title removed.",
    ],
 ),
 "cigarra": dict(
    name="Cigarra", title="The Oracle Hopper", height_m=1.65, height_note="sheet: 165 cm (5'5\"); board states 'incl. crown'",
    sheet="tools/source_art/cigarra_sheet.jpg", sheet_box=(0, 0, 940, 540),
    views={
        "front": dict(box=(165, 0, 520, 535), pose="3/4 front, wing cloak spread, hero pose (not orthographic)", ortho=False),
        "side":  dict(box=(770, 0, 940, 535), pose="side, faces screen-right", ortho=True),
        "back":  dict(box=(505, 0, 800, 535), pose="back, wing cloak folded", ortho=True),
    },
    lm={
        "front": dict(top=0, crown=0.095, eyes=0.20, chin=0.25, neck=0.27, shoulder=0.315, elbow=0.53, wrist=0.60, waist=0.43, crotch=0.64, knee=0.80, ankle=0.91, ground=1),
        "side":  dict(top=0, crown=0.085, eyes=0.20, chin=0.26, neck=0.28, shoulder=0.31, elbow=0.50, wrist=0.575, waist=0.44, crotch=0.66, knee=0.80, ankle=0.91, ground=1),
        "back":  dict(top=0, crown=0.11, eyes=0.20, chin=0.245, neck=0.26, shoulder=0.30, elbow=0.50, wrist=0.575, waist=0.45, crotch=0.66, knee=0.82, ankle=0.91, ground=1),
    },
    lm_src="READ off the gridded x4 art (+-1.5%); crown spheres count toward 165 cm per the existing board",
    head=dict(front=(0.0, 0.0, 1.0, 0.30), side=(0.0, 0.0, 1.0, 0.30), back=(0.0, 0.0, 1.0, 0.32)),
    sheet_panels=dict(
        head_details=((952, 32, 1074, 202), False), crown_structure=((1090, 22, 1240, 215), False),
        crown_states=((1255, 130, 1400, 222), False), eye_detail=((584, 612, 739, 683), False),
        expr_neutral=((1020, 238, 1137, 346), False), expr_curious=((1140, 238, 1262, 346), False), expr_unhinged=((1265, 238, 1390, 346), False),
        expr_annoyed=((1007, 368, 1102, 492), False), expr_happy=((1105, 368, 1198, 492), False), expr_focused=((1202, 368, 1297, 492), False), expr_shocked=((1300, 368, 1390, 492), False),
        wing_cloak_folded=((15, 548, 148, 672), True), jacket_detail=((138, 543, 212, 690), True), belt_charms=((192, 605, 290, 680), True),
        belt_closeup=((260, 538, 372, 600), False), hand_wrist=((372, 572, 425, 668), True), boot_detail=((298, 600, 365, 700), True),
        wing_cloak_open=((392, 540, 562, 690), True), palette_strip=((582, 548, 742, 596), False),
    ),
    expressions=["neutral", "curious", "unhinged", "annoyed", "happy", "focused", "shocked"],
    derived_note="Greybox clay views are silhouette visual hulls of the aligned side+back art (shape only). No view was painted over: every colour in ortho/ is original art. Clipped wing-tip edges are YELLOW/RED candidates (Q4) but left empty, not invented.",
    style=dict(
        line="Clean black ink contour of medium-heavy weight, slightly heavier on cloak panels and boots; hairline vein lines inside the wings (yellow-green, not black).",
        color="Four blocks: near-black violet cloth (#3f3330/#181512), olive/cream accents (#a7945e #c0b374 #d3bb99), lime-green translucent wing membranes, warm tan skin; black glossy crown spheres with yellow-green glints; pale shaggy hair with lime tips.",
        shading="Soft-cel paint: wings are painted with gradients (yellow-green to olive) and visible vein structure; cloth is flat 2-tone; spheres have a hard painted highlight.",
        shape="Small, slim body hidden under a huge silhouette: crown of ~7 black spheres on a branching stalk, wide wing cloak that spreads to a triangle, baggy cuffed harem trousers, leaf-trimmed boots. Top-heavy (crown) and bottom-wide (wings, trousers); the waist/midriff is the only narrow part.",
        locks=["Crown of black glossy spheres on a dark branching stalk (treehopper)", "Third-eye spot on forehead + black face markings + gold-yellow eyes", "Two-pair translucent lime wing cloak with dark veins and black spots; hood with gold sigil tab at the back", "Cropped top with bare midriff; baggy violet-black trousers cuffed at the shin; bandaged shins/wrists", "Belt with hanging gourd charms and orange cords", "165 cm tall (see Q1 about crown)"]),
    review=[
        "FIDELITY: front, side and back were RE-CUT from the original sheet because the older hires cuts were clipped at their crop edges (front: crown sphere + right boot cut flat; side: hood/sphere cut). All three are now complete except at the neighbour-overlap edges noted below. Nothing redrawn.",
        "ALIGNMENT: crown (hair top), eyes, chin, neck, shoulder, waist, crotch, knee, ankle, sole on identical rows in all views (row warp max about 3 % of height). Elbow/wrist rows are valid for the hanging arm only: the hip-hand pose puts the other wrist about 15 % higher.",
        "KNOWN CLIPPING: the FRONT's viewer-right wing and the BACK's viewer-left wing end in a straight vertical edge because the two figures overlap on the sheet (Q4). The SIDE view's far hood edge is intact.",
        "CLEANLINESS: background removal is clean on the pale hair; thin yellow-green hair tips lose a little alpha. Face markings and eye details survive the x4 pass; the small leaf/charm details are slightly smoothed.",
        "HEAD PACK: face callouts come from the sheet's HEAD DETAILS panel (best resolution available, 120 px wide on the sheet); expression sheet = 7 original panels. No true open-mouth view except UNHINGED (shouting) and HAPPY (grin, teeth).",
        "GREYBOX: crude hull, wings make the back silhouette a block. Use for volume only.",
    ],
    view_details={  # (cut view, fx0, fy0, fx1, fy1) as fractions of the trimmed x4 cut image
        "hand_hip_L": ("front", .28, .38, .50, .62), "hand_hanging_R": ("front", .76, .52, .96, .78),
        "foot_front_L": ("front", .25, .85, .50, 1.0), "foot_front_R": ("front", .69, .86, .93, 1.0),
        "foot_side": ("side", .16, .85, .66, 1.0), "feet_back": ("back", .10, .85, .92, 1.0),
        "crown_back_view": ("back", .22, 0.0, .95, .23),
    },
    callouts={"left eye + liner": (.12, .34, .50, .52), "third eye spot + brow": (.38, .18, .68, .38), "right eye + liner": (.58, .40, .96, .58), "nose": (.38, .50, .66, .68), "mouth + chin marking": (.26, .66, .70, .92)},
    material_view="side",
    materials=[
        dict(name="Hair (shaggy, pale)", cls="fibre / hair", sample=("side", .50, .093), rough=.55, metal=0.0, note="cel-lit, stylised clumps; olive-lime tips are painted into the hair"),
        dict(name="Skin (face, hands)", cls="skin", sample=("side", .28, .19), rough=.50, metal=0.0, note="warm tan; black face markings are paint, not geometry"),
        dict(name="Crown spheres (treehopper)", cls="glossy black lacquer chitin", sample=("side", .46, .04), rough=.12, metal=0.0, note="very glossy, yellow-green glint is a painted highlight; stalk = matte dark wood-like chitin rough .5"),
        dict(name="Hooded jacket", cls="cloth", sample=("side", .72, .247), rough=.85, metal=0.0, note="deep violet-black, moss-olive edging"),
        dict(name="Cropped top (olive/cream)", cls="cloth", sample=("side", .23, .37), rough=.85, metal=0.0, note="dark trim at hem"),
        dict(name="Belt / leather", cls="leather", sample=("side", .30, .48), rough=.55, metal=0.0, note="brown leather, buckle dark metal rough .4 metal .8"),
        dict(name="Charms (gourds / egg pod)", cls="dried gourd / bone", sample=("side", .21, .60), rough=.60, metal=0.0, note="pale skull-like gourds, orange cords"),
        dict(name="Baggy trousers", cls="cloth", sample=("side", .50, .75), rough=.90, metal=0.0, note="violet-black harem pants, cuffed at the shin"),
        dict(name="Shin bandage", cls="cloth wrap", sample=("side", .49, .88), rough=.9, metal=0.0, note="cream/olive wrap"),
        dict(name="Boots (leaf-trimmed)", cls="leather", sample=("side", .52, .965), rough=.6, metal=0.0, note="dark brown with olive leaf trim"),
        dict(name="Wing cloak (translucent panels)", cls="translucent membrane", sample=("back", .17, .68), rough=.35, metal=0.0, note="lime membrane with dark veins/spots; alpha/transmission ~0.5; dark violet outer panels are opaque cloth"),
    ],
    layers=["Skin / body", "Cropped top + bandaged wrists/forearms", "Harem trousers (cuffed) + shin bandages + boots", "Belt with charms and cords (over trousers)",
            "Hooded jacket (sleeves rolled, moss edging)", "Wing cloak: two pairs of translucent panels hanging from shoulders/back, hood with gold sigil tab", "Crown stalk with ~7 spheres (rooted at back of head, over the hair)"],
    questions=[
        "Height: the board states 165 cm 'incl. crown'. Is 165 cm to the top of the crown spheres (as modelled in these packs) or to the top of the head? If to the head, the body is about 1.47 m and the crown adds ~0.18 m.",
        "True front: the sheet's FRONT is a 3/4 hero pose (hip-cocked, one arm on hip), not orthographic. Do you want a true neutral front (A/T-pose) painted by the original artist, or may the modellers treat 3/4 as authority for costume only?",
        "Crown: how many spheres on the model? The sheet shows ~7 (front 4-5 visible, back 6-7). Does the crown rest on the head or is it a separate floating/retractable rig (sheet shows 'retracted' and 'expanded' states)?",
        "Wing cloak: the left edge of the BACK view and the right edge of the FRONT view are clipped where the sheet's figures overlap each other; the clipped wing-tip silhouette (about 3-4% of width) is therefore unknown. OK to mirror from the opposite wing?",
        "Emissive: nothing in the art glows (gold sigil and sphere highlights are painted). Confirm the model should have NO emissive, or tell us which parts glow in game.",
        "Hands: only the front 3/4 shows hands (bandaged left, bare right with long dark nails). The hands in side/back are hidden. OK to model symmetric hands from the front art?",
    ],
 ),
}


try:                                   # remaining characters (sources first; landmarks/materials/questions added per pack)
    from cast2 import SRC
    from cast3 import EXTRA
except ImportError:
    from cast2 import SRC
    EXTRA = {}
for _k, _v in SRC.items():
    CAST.setdefault(_k, {}).update(_v)
    CAST[_k].update(EXTRA.get(_k, {}))
