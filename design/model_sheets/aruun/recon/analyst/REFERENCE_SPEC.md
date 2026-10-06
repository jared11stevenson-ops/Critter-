# ARUUN - REFERENCE SPECIFICATION (Agent 1, Reference Analyst)

Binding context: `design/EXACT_RECONSTRUCTION_PROTOCOL.md`. Nothing here models anything. Everything is measured from the artwork; where the art cannot decide a feature it is listed in section 8 as an ambiguity and is NOT filled in.
All files live in `design/model_sheets/aruun/recon/analyst/`; scripts in `tools/recon/` (re-runnable: `head_regions.py`, `build_head.py`, `measure_head.py`, `build_lineclass.py`, `build_hero.py`, `build_other_sil.py`, `write_spec.py`).

## 0. Which pixels are the reference (read this first)

| ref | what it is | file used | quality |
|---|---|---|---|
| **R-HEAD** | the head PROFILE (faces screen-left) = the head of the sheet's hero full-body drawing = the tile 'Front view head (profile, facing screen-left)' of `detail_head.png` | `design/reference_packs/aruun/ortho/aruun_front_4096.png` (ESRGAN-x4 of `tools/source_art/aruun_nerit_sheet.jpg`, 1280 px sheet; posterised, 224-colour palette, clean alpha). The same head in `detail_head.png` tile 2 is a blurrier Lanczos crop of the same sheet pixels (identical geometry; verified by eye). | highest available; the sheet head is only ~75 px long, so every contour is an upscale of a ~1/4 resolution drawing (+-3 px at 4096 scale) |
| **R-HERO** | full-body hero 3/4 front drawing | same file (the head IS the hero's head) | same |
| R-FACE | straight-on calm / rage faces | `design/reference_gen/aruun/v2/aruun_v2_face_{calm,rage}_4096.png` | GENERATED/completed view (calm 82.8 % original pixels, rage 98.8 %); coarse landmarks only |
| R-SIDE/BACK | orthographic side / back | `aruun_v2_side_completed_4096.png`, `aruun_v2_back_completed_4096.png` | silhouette masks/outlines only (not landmarked, out of priority) |

`aruun_head_profile_left.png` in `design/reference_gen/aruun/head/` is a re-draw of the same head (it matches the hero head contour) and was NOT used for measurement; the hero image is the ground truth.

## 1. Coordinate systems (R-HEAD first)

**R-HEAD.** Source pixel space of `aruun_front_4096.png` (origin top-left, x right, y down; head ROI x600-1500, y80-880). Normalised: origin O = snout / mandible-hook tip **(811, 780) px**; unit **L = head length = 633 px** (horizontal distance from the snout tip x=811 to the right-most fringe tip x=1444; this includes the fringe but not horns/blades). `u = (x-811)/633` (positive = screen-right = toward back of head), `v = (780-y)/633` (positive up). Conversion for other uses: L = 0.1621 of hero body height. Grid images carry BOTH the pixel grid (blue) and the u/v grid (red, every 0.1 L).
**R-HERO.** same file; origin = image centre x=945.5 at ground row y=4000; unit **H = 3904 px** (horn top y=96 to ground y=4000). `u=(x-945.5)/3904`, `v=(4000-y)/3904`.
**R-FACE.** pixel space of the face PNG (1400x4096); axis x~700.

Silhouette threshold: palette alpha **>= 128** is inside. Palette alpha values 254/255 are opaque; 1..127 is anti-alias halo (11,422 px inside the head ROI) and is counted as BACKGROUND (so the silhouette is the inner edge of the dark outline halo; the black ink outline of ~3-4 px is INSIDE the mask). Largest connected component; the head ROI cut is at y=880 through the neck.

## 2. Files

| file | content |
|---|---|
| `head_landmarks.json` | coordinate system, eye ellipse, 99 landmarks (src+norm+kind), 20 polylines (src+norm), 114 colour regions |
| `head_overlay_landmarks_full.png` | numbered markers + polylines, whole head+horns, x2 |
| `head_overlay_landmarks_core_grid_x3.png` | **labelled-grid crop** of skull/face/neck/fringe, x3, px grid + u/v grid + numbered landmarks |
| `head_overlay_landmarks_horns_grid_x2.png` | labelled-grid crop of both horns + blade D |
| `head_negative_space.png/json` | nine negative-space polygons N1-N9 with areas |
| `head_line_classification.png/json` | A/B/C/D classification overlay + legend |
| `head_silhouette_mask.png`, `head_silhouette_black.png`, `head_silhouette.json` | black silhouette, thresholded mask, outline polyline (358 pts, eps 1.5 px; src+norm) |
| `head_measurements.json` | computed angles / radii / lengths quoted below |
| `atlas_regions_x3.png`, `regions.json` | numbered posterised colour regions (ids used in classification) |
| `hero_landmarks.json`, `hero_overlay_landmarks.png` (grid), `hero_negative_space.png/json`, `hero_silhouette_mask.png`, `hero_silhouette_black_half.png` | R-HERO |
| `face_landmarks.json`, `face_{calm,rage}_overlay_landmarks.png`, `other_views_silhouettes.json`, `mask_*_half.png` | R-FACE / SIDE / BACK |

## 3. R-HEAD landmark table

kind: V visible, J visible junction of two painted shapes, H hidden (position implied only). `(u,v)` in head lengths from the snout tip.

| # | landmark | src px | (u, v) | kind | note |
|---|---|---|---|---|---|
| 1 | extreme_top (horn A distal knob) | (1138, 96) | (0.517, 1.081) | V |  |
| 2 | extreme_bottom of head = mandible-hook underside | (854, 822) | (0.068, -0.066) | V | neck continues below; crop cut y=879 |
| 3 | extreme_left (horn B elbow) | (626, 493) | (-0.292, 0.453) | V |  |
| 4 | extreme_right (long dark fringe streak tip) | (1444, 626) | (1.000, 0.243) | V |  |
| 5 | snout tip / mandible-hook tip | (811, 780) | (0.000, 0.000) | V | left-most face point |
| 6 | hook underside lowest point | (854, 822) | (0.068, -0.066) | V |  |
| 7 | hook underside step (down->up) | (880, 802) | (0.109, -0.035) | V | small step before jaw underside rises |
| 8 | snout dorsal edge: hook top-front | (815, 774) | (0.006, 0.009) | V |  |
| 9 | snout dorsal edge: mid | (842, 776) | (0.049, 0.006) | V |  |
| 10 | snout dorsal edge: rise | (862, 763) | (0.081, 0.027) | V |  |
| 11 | snout dorsal edge: top of rise / vertical edge bottom | (878, 740) | (0.106, 0.063) | V | then edge is VERTICAL x=878 up to y=705 |
| 12 | snout dorsal edge: vertical-edge top (meets blade F underside) | (878, 705) | (0.106, 0.118) | V | dorsal snout edge is NOT a smooth curve: step then vertical |
| 13 | jaw ventral edge: rising | (922, 784) | (0.175, -0.006) | V |  |
| 14 | jaw ventral edge: (955,759) | (955, 759) | (0.228, 0.033) | V |  |
| 15 | jaw ventral edge bump (966,755)-(984,758) | (975, 757) | (0.259, 0.036) | V |  |
| 16 | under-jaw gape apex (highest point of the throat notch) | (1009, 746) | (0.313, 0.054) | V | jaw front->neck-front concave corner |
| 17 | neck front edge start (descends) | (1047, 787) | (0.373, -0.011) | V |  |
| 18 | neck front edge: (1035,828) | (1035, 828) | (0.354, -0.076) | V |  |
| 19 | neck front edge at crop cut | (1048, 879) | (0.374, -0.156) | V | neck front widens again below y=845 |
| 20 | neck back edge top (under fringe) | (1247, 741) | (0.689, 0.062) | V | neck attaches under fringe here |
| 21 | neck back edge | (1256, 785) | (0.703, -0.008) | V |  |
| 22 | neck back edge at crop cut | (1260, 879) | (0.709, -0.156) | V |  |
| 23 | eye centre (yellow iris) | (1022, 638) | (0.333, 0.224) | V | fit ellipse |
| 24 | eye iris left extreme | (1003, 640) | (0.303, 0.221) | V |  |
| 25 | eye iris right extreme | (1043, 636) | (0.366, 0.228) | V |  |
| 26 | eye iris top | (1022, 625) | (0.333, 0.245) | V |  |
| 27 | eye iris bottom | (1022, 651) | (0.333, 0.204) | V |  |
| 28 | eye socket (dark) left | (983, 640) | (0.272, 0.221) | V | region 26 brown ring bbox x 983-1029 |
| 29 | eye socket (dark) right (end of black lid arc) | (1073, 630) | (0.414, 0.237) | V | region 3 |
| 30 | eye socket top (dark arc) | (1033, 609) | (0.351, 0.270) | V | region 17 bbox top |
| 31 | brow peak = top of dark brow/lid band above eye | (1073, 581) | (0.414, 0.314) | V | region 36 top y=581 (x 1021-1118) |
| 32 | brow line left end (cream strip 96 lower-left) | (953, 647) | (0.224, 0.210) | V | cream band 96 rises up-right over eye |
| 33 | brow line mid (cream 101) | (1014, 594) | (0.321, 0.294) | V |  |
| 34 | brow line right (cream 104) | (1086, 576) | (0.434, 0.322) | V |  |
| 35 | upper eyelid line start (left end of black arc) | (990, 628) | (0.283, 0.240) | J | black arc over iris; tilts up to right |
| 36 | upper eyelid line end (right, curls down) | (1073, 632) | (0.414, 0.234) | J |  |
| 37 | lower cheek-ridge cream strip 97 left end | (997, 668) | (0.294, 0.177) | J | cream strip under eye, region 97 bbox 995-1079 x 627-683 |
| 38 | cream eye-ridge hook top (rises right of eye) | (1065, 615) | (0.401, 0.261) | J | region 97 upper right horn, bbox top y627? hook tip near (1070,612) |
| 39 | forehead-to-snout transition: cream 96 -> red 70 corner | (953, 660) | (0.224, 0.190) | J | no continuous dorsal line; plates step down-left |
| 40 | muzzle red plate 70 left corner | (885, 690) | (0.117, 0.142) | J | region 70 bbox 885-970 x 661-723 |
| 41 | muzzle red plate 71 upper edge at eye | (1000, 688) | (0.299, 0.145) | J |  |
| 42 | muzzle/cheek red plate 71 rear tip (near ear area) | (1122, 668) | (0.491, 0.177) | J | region 47 pocket |
| 43 | cheek red plate 4/71 lower edge passes jaw -> neck | (1120, 722) | (0.488, 0.092) | J | red plate lower edge runs (975,745)-(1173,690) approx, black outline under it |
| 44 | lower jaw cream plate 103 front end (above hook) | (900, 770) | (0.141, 0.016) | J |  |
| 45 | lower jaw cream plate 103 rear end | (984, 712) | (0.273, 0.107) | J | joins 102 |
| 46 | mandible hook red 9: top edge front | (822, 775) | (0.017, 0.008) | V |  |
| 47 | mouth line (visible dark seam between cream 103 and red 71 / hook) | (940, 735) | (0.204, 0.071) | J | only seam visible; no open mouth, no teeth in this view |
| 48 | fang (white): small cream-white dot just under hook | (843, 798) | (0.051, -0.028) | V | tiny light mark at (843-846,795-800), region ~ 5 px; could be tooth |
| 49 | horn A base knob (centre of rounded knob at joint) | (885, 533) | (0.117, 0.390) | V | knob at x 852-900,y 520-548 |
| 50 | horn A base junction with brow plate (hidden under base) | (950, 585) | (0.220, 0.308) | H | base overlaps cream brow plate; true root hidden |
| 51 | horn A shaft left edge at y=400 | (858, 400) | (0.074, 0.600) | V |  |
| 52 | horn A shaft right edge at y=400 | (945, 400) | (0.212, 0.600) | V | shaft width 87px |
| 53 | horn A elbow outer corner | (846, 240) | (0.055, 0.853) | V |  |
| 54 | horn A elbow cap dark (top of vertical shaft) | (880, 204) | (0.109, 0.910) | V |  |
| 55 | horn A upper arc (1033,138) | (1033, 138) | (0.351, 1.014) | V |  |
| 56 | horn A arm top knob/joint (extreme top) | (1138, 96) | (0.517, 1.081) | V |  |
| 57 | horn A distal segment mid upper edge | (1251, 133) | (0.695, 1.022) | V |  |
| 58 | horn A tine claw tip (black) | (1394, 191) | (0.921, 0.930) | V |  |
| 59 | horn A claw underside base | (1285, 187) | (0.749, 0.937) | V |  |
| 60 | horn A arm underside at spur root | (996, 236) | (0.292, 0.859) | V |  |
| 61 | horn A spur tip (black blade pointing right-down) | (1081, 300) | (0.426, 0.758) | V |  |
| 62 | horn A spur base lower (junction w/ shaft) | (964, 292) | (0.242, 0.771) | J |  |
| 63 | horn B top knob tip | (766, 259) | (-0.071, 0.823) | V |  |
| 64 | horn B top knob inner | (790, 284) | (-0.033, 0.784) | V |  |
| 65 | horn B elbow knob (left) | (628, 460) | (-0.289, 0.505) | V |  |
| 66 | horn B elbow spur (right of knob, small dark tab) | (742, 472) | (-0.109, 0.487) | V |  |
| 67 | horn B outer edge at y=383 | (680, 383) | (-0.207, 0.627) | V |  |
| 68 | horn B inner edge at y=386 | (722, 386) | (-0.141, 0.622) | V | shaft width ~42px at y~386 |
| 69 | horn B arm underside mid | (704, 593) | (-0.169, 0.295) | V |  |
| 70 | horn B arm underside near root | (746, 641) | (-0.103, 0.220) | V |  |
| 71 | horn B arm upper edge at root junction w/ horn A base | (832, 601) | (0.033, 0.283) | J | horn B passes behind horn A base |
| 72 | horn B root (hidden behind cheek/olive collar) | (900, 625) | (0.141, 0.245) | H | arm disappears under region 43/51/15 |
| 73 | spike C top (small dark-capped tine between horns and crest) | (1025, 488) | (0.338, 0.461) | V |  |
| 74 | spike C base | (1005, 541) | (0.306, 0.378) | J |  |
| 75 | crown top edge (dark cranium dorsal line) left | (1026, 544) | (0.340, 0.373) | V | flat run y~544 from x=1026 to 1131 |
| 76 | crown top edge right end / temple blade D base | (1131, 543) | (0.505, 0.374) | V |  |
| 77 | temple blade D apex | (1241, 429) | (0.679, 0.554) | V |  |
| 78 | temple blade D base outer (lower-left edge) | (1193, 483) | (0.604, 0.469) | V |  |
| 79 | temple blade D right/lower edge base | (1210, 540) | (0.630, 0.379) | V |  |
| 80 | bone stub E right tip (rounded) | (1319, 480) | (0.802, 0.474) | V |  |
| 81 | bone stub E root at blade D | (1255, 471) | (0.701, 0.488) | J |  |
| 82 | bay between blade D and fringe: deepest point | (1186, 568) | (0.592, 0.335) | V |  |
| 83 | olive blade F tip (left, drooping appendage under horn B) | (773, 704) | (-0.060, 0.120) | V |  |
| 84 | olive blade F upper edge | (818, 678) | (0.011, 0.161) | V |  |
| 85 | olive blade F root (meets cheek patch) | (866, 700) | (0.087, 0.126) | J |  |
| 86 | fringe strand tip upper (dark) | (1301, 594) | (0.774, 0.294) | V |  |
| 87 | fringe notch between upper and long streak | (1262, 609) | (0.713, 0.270) | V |  |
| 88 | fringe long streak: lower edge midpoint | (1340, 631) | (0.836, 0.235) | V |  |
| 89 | fringe long streak tip | (1444, 626) | (1.000, 0.243) | V |  |
| 90 | fringe bluegray lock tip | (1410, 686) | (0.946, 0.148) | V |  |
| 91 | fringe lock notch | (1370, 667) | (0.883, 0.178) | V |  |
| 92 | fringe lower lobe edge | (1339, 723) | (0.834, 0.090) | V |  |
| 93 | fringe lower lobe tip | (1295, 745) | (0.765, 0.055) | V |  |
| 94 | cream fringe strands lower end (hang onto neck) | (1210, 745) | (0.630, 0.055) | V | cream regions 99/113 end at y~766, overlapping neck red 88 |
| 95 | cheek: black mass top boundary (under red plate) | (1060, 730) | (0.393, 0.079) | J | black mass region 20 bbox 1030-1169 x 711-789 |
| 96 | cheek: black mass right boundary vs neck red column | (1160, 760) | (0.551, 0.032) | J |  |
| 97 | bluegray cheek patch (behind snout) upper | (912, 657) | (0.160, 0.194) | J | regions 31/39 bbox 877-951 x 630-700 |
| 98 | olive collar patch behind horn root | (937, 616) | (0.199, 0.259) | J | regions 43/51 |
| 99 | occiput / skull rear: hidden behind fringe | (1180, 640) | (0.583, 0.221) | H | skull rear contour not visible; fringe hangs over it |

Eye (fit on the iris colour region): centre **(1022, 637.6) px = (0.333, 0.224) L**; iris bbox 1003-1043 x 625-651 = **0.062 L wide x 0.041 L high**; fitted ellipse 38.8 x 23.4 px, **major axis tilted +12.5 deg (rises toward the back/screen-right)**. Dark socket (regions 26/17/3) bbox 983-1073 x 603-655 = 0.142 x 0.082 L. The iris is round-ish and tiny; the socket (black arc + brown ring) is 2.3x the iris.

Silhouette extremes (head+horns ROI): top (1138, 96) horn A knob; left (626, 493) horn B elbow; right (1444, 626) fringe streak tip; bottom of the head proper (854, 822) hook underside (neck continues).

Key polylines (full lists in `head_landmarks.json`): `snout_dorsal_edge`, `blade_F_underside`, `snout_ventral_edge`, `throat_to_neck_front`, `neck_back_edge`, `crown_top_edge`, `skull_rear_fringe_upper (occiput as visible)`, `fringe_long_streak_*`, `fringe_lower_lobe`, `horn_A_left_edge/right_edge/upper_arc/underside_arc/spur`, `horn_B_outer/inner`, `blade_F_upper`, `spike_C`, `temple_blade_D_E`.

### 3.1 Structures, as drawn (names are the drawing's, not anatomy)
- **Snout / mandible**: a wedge pointing screen-left and DOWN. Tip-to-eye distance 0.402 L at 33.9 deg below horizontal. It ends in a **down-turned red hook** (region 9): hook height 0.074 L (47 px), hook length 95 px (0.15 L), underside radius ~34 px (0.054 L, a tight round heel), upper (dorsal) edge of the hook is flat then rises in a 35 px step to a **vertical edge x=878 (y705-740)**. There is NO smooth dorsal snout curve in the silhouette; the upper snout edge is hidden behind/under olive blade F and the horn B root.
- **Under-jaw/ventral edge** rises from the hook (854,822) to the throat apex (1009,746) at a mean 26.1 deg, with a small step at x~880-906 (y802-805) and a shallow bump at x 955-984 (y755-759).
- **Throat/neck front**: from apex (1009,746) the edge turns down and slightly RIGHT-then-LEFT: (1027,756) (1047,787) (1045,804) (1035,828) (1035,844) (1048,879): i.e. a rounded concave throat corner, then a near-vertical front edge.
- **Face plates**: cream brow band (regions 96/101/104) arches over the eye from the left-front (953,647) up to (1086,576) and continues back as a long cream bar to the base of blade D; red muzzle plates (70 front, 71/4 back) run from (885,690) to (1122,668); cream lower-jaw plate (103) lies under the red plate down to the hook; cream cheek/eye-ridge plate (97/102) hooks around below and behind the eye. The seam between cream 103 and red 71 is the only 'mouth line' visible; no open mouth, no teeth (one 5 px white mark under the hook at ~(843,798) may be the 'white fang').
- **Black cheek mass** (region 20, bbox 1030-1169 x 711-789 + continuation 32): sits BELOW the red plate, between the throat apex and the red neck column; it is the dark side of the neck, not a separate object. Bluegray patches 31/39/15 (x 841-951, y 597-700) sit BEHIND the muzzle plates, in front of horn B's root.
- **Crown**: the cranium top is a dark flat run y~544 from x=1026 to 1131 (regions 14/34). On it: **spike C** (x1005-1030, y488-544, dark-capped, 0.084 L tall), **blade D** (temple appendage, base (1131,543) apex (1241,429), length 0.25 L at 46 deg, ~55 px wide, tan/olive with darker inner leaf lines) and **stub E** (cream-tan bone, root (1255,480) to rounded tip (1319,480), 0.10 L long x 28 px thick, near-horizontal, ends in a blunt round knob).
- **Olive blade F**: drooping appendage below horn B, pointing left and ~9 deg down, tip (773,704), length 0.149 L, ~22 px thick, with a split/forked root at (840-880, 650-700).
- **Fringe** (the only 'skull rear' you can see): dark brown strands streaming right: short upper strand tip (1301,594); a **long streak** from notch (1262,609) to tip (1444,626), 0.289 L, drooping 5 deg, beaded with small light dots; a bluegray lock (regions 44/40) with ragged lower edge, tips (1410,686) and (1295,745); and **cream strands** (regions 82/98/105/106/113/99/112) that sweep from behind the eye (1120,640) down-right at ~51 deg and hang onto the neck to y~766.
- **Neck**: red column (88/74, highlight stripe 114) with dark left side; width 0.348 L (220 px) at y=850; front edge x 1036-1048, back edge x 1242-1260; it is vertical/near-parallel, slightly widening downward. The neck attaches to the head UNDER the fringe/cream strands at y~745-766 and in front by the throat apex.
- **Horn A** (main, right in image, 'near'): base knob at (885,533) [knob 48 px wide]; shaft rises almost vertically 0.50 L (318 px) to the elbow (870,215) with CONSTANT width 0.137 L (87 px; left edge leans 4 deg, right edge vertical x=945); hard outer corner at the elbow (846,235) with a dark cap; then an arm bending ~66 deg to the right: chord elbow->top knob (1138,96) = 0.463 L at +23.9 deg; the upper edge is a gentle arc (fitted circle r=238 px = 0.375 L, centre (1136,344)); the underside edge is tighter (r=92 px = 0.145 L), so the arm TAPERS from ~87 px to ~30 px; top joint knob (1138,96); distal segment 0.431 L at -20.4 deg, ~30 px thick, ending in a **black curved claw** pointing down-right, tip (1394,191). A black **spur** springs from the underside of the elbow region, 95 px long, pointing right and -31.7 deg (tip (1081,300)). Total: horn A rises 0.708 L above the crown line (y544) and spans 0.866 L horizontally.
- **Horn B** (far, left): thinner (0.066 L, 42 px), C-shaped: leaves the head behind horn A's base, passes left and down (outer arc r~162 px = 0.256 L, centre (800,473)), makes an elbow knob at the left extreme (626,493) with a small dark side-tab at (742,472), then rises up-and-slightly-right (74 deg) 0.60 L to a flat top knob (766,259) with a pale cut face. B's top is 163 px (0.26 L) lower than A's.

## 4. NEGATIVE SPACE (R-HEAD)

Polygons walk the silhouette and are closed by a chord across the open side (vertices in `head_negative_space.json`; overlay `head_negative_space.png`). Areas normalised by L^2 (L=633). 'mean width' = area / chord, the typical gap width in L (not meaningful for N1, whose chord is short).

| id | gap | area px | area / L^2 | bbox w x h (L) | mean width (L) |
|---|---|---|---|---|---|
| N1 | N1 gap between horn B and horn A (horn-pair gap) | 41529 | 0.1036 | 0.292 x 0.585 | 1.055 |
| N2 | N2 horn-A inner window (C of the horn arc, open right) | 110583 | 0.2760 | 0.711 x 0.621 | 0.617 |
| N3 | N3 bay under blade D / stub E (chord to fringe tip) | 8814 | 0.0220 | 0.202 x 0.163 | 0.141 |
| N4 | N4 fringe pocket between upper strand and long streak | 3104 | 0.0077 | 0.267 x 0.057 | 0.034 |
| N5 | N5 fringe pocket between long streak and bluegray lock | 1802 | 0.0045 | 0.120 x 0.087 | 0.043 |
| N6 | N6 nape gap (behind neck under fringe, to x=1340) | 11852 | 0.0296 | 0.147 x 0.245 | 0.417 |
| N7 | N7 under-jaw / throat gap (between snout and neck, to y=879) | 19176 | 0.0479 | 0.305 x 0.208 | 0.531 |
| N8 | N8 snout-dorsal hollow (between olive blade F and mandible hook) | 5659 | 0.0141 | 0.164 x 0.122 | 0.113 |
| N9 | N9 pocket between horn B arm and blade F | 3783 | 0.0094 | 0.202 x 0.168 | 0.047 |

What matters for the modeler:
- **N1 horn-pair gap**: a tall teardrop 0.29 L wide x 0.58 L high, open at the top; bounded by horn B's inner edge (convex toward the gap, i.e. it follows a circular arc) on the left and horn A's straight left edge (x 846-866) on the right; the floor is horn B's arm meeting horn A's base at y~590-606. The horns do NOT touch except at the base.
- **N2 horn-A window**: the big C interior, 0.71 x 0.62 L; its left wall is the straight vertical shaft (x=945), its top is the arm underside, the black spur projects INTO it from the upper left, the floor is the crown line (y~544) with spike C poking up into it and blade D forming the lower-right wall. The distal tine/claw points toward blade D's apex without touching (gap chord ~0.35 L).
- **N7 throat gap**: the large open notch under the jaw (between hook and neck), apex (1009,746); its walls are the rising ventral jaw edge and the near-vertical neck front edge; the opening between hook bottom (854,822) and the neck (1048,879) is ~0.31 L wide.
- **N8 snout hollow**: a 0.16 x 0.12 L pocket between olive blade F (roof) and the hook (floor), closed on the right by the vertical edge x=878. This is what makes the snout read as 'wedge under a blade'.
- **N3** bay between blade D / stub E and the fringe: apex at (1186,568), 0.20 x 0.16 L.
- **N4/N5**: slim wedge pockets between fringe streaks (0.27 x 0.057 L and 0.12 x 0.087 L): fringe strands are SEPARATE thin shapes, not a solid mass.
- **N6** nape gap: open space behind the neck below the fringe (x>1256), neck back edge is clean and vertical.
- N9: slender pocket between horn B's under-arm and blade F.

## 5. LINE CLASSIFICATION (R-HEAD)

Overlay `head_line_classification.png` (legend inside): red A form change, blue B overlapping geometry, green C colour boundary, magenta D linework, orange = silhouette. Region ids from `atlas_regions_x3.png`.
- **A (needs geometry)**: horn A/B joints (knob at base (885,533), elbow cap (880,208), top knob (1138,100), arm->claw joint (~1290,150), horn B elbow knob (650,470)); spur; spike C; blade D; stub E; blade F; mandible hook (9); neck column (88/74); fringe/hair strands where they form the silhouette (35/25/38/57/44/40); cranium top (14/34).
- **B (overlapping shapes: model as stacked/shell geometry, not as a cut)**: cream brow plate (96/101/104) over the dark cranium; horn A's root overlaps the brow plate; red muzzle plates 70/71/4/47 over the black cheek mass; cream jaw plate 103 over the red hook; cream cheek plate 97/102; olive collar 43/51 and bluegray patches 15/31/39 BEHIND the muzzle plates and in front of horn B's root; cream fringe strands 82/98/105/106/113/99/112 in front of the neck; horn B passes BEHIND horn A's base.
- **C (colour only, no geometry)**: black cheek/neck mass 20/32/21/28; eye socket black/brown ring 3/17/26 (socket may be a shallow recess, but its black/brown banding is pigment); dark band over eye 36/30; red neck stripe 76; black gaps 6/7/8; tone steps on horns; iris yellow.
- **D (linework/highlights, no geometry)**: the ~3-4 px black ink outline around every plate; neck highlight stripe 114; orange/tan highlight stripes on horn A (x~888-900, y 330-440) and horn B; small light dots on the fringe ((1200,598), (1218,608), (1380-1440,630)); thin internal leaf lines on blade D.

## 6. SILHOUETTES

Black-on-flat: `head_silhouette_black.png` (ROI 900x800, source px), mask `head_silhouette_mask.png`, outline `head_silhouette.json` (`outline_eps1p5_src` / `_norm`, 358 points, closed, clockwise from the horn B knob). Full-body: `hero_silhouette_mask.png` (1891x4096), `hero_silhouette_black_half.png`, `hero_landmarks.json -> outline_eps3_*`. R-FACE/R-SIDE/R-BACK: `other_views_silhouettes.json` and `mask_*_half.png`. Halo handling: see section 1 (alpha<128 = outside; ~3-4 px black ink is INCLUDED in the shape, so a modeled silhouette should be compared against this mask, not against the fill colour only).

## 7. SHAPE LANGUAGE (measurable)

1. **Head is small, horns are huge**: the head core (crown y544 to throat apex y746 = 0.32 L; to hook bottom 0.44 L high) is dwarfed by horn A (0.708 L above the crown, 0.866 L across). Horn A's height is 1.7x the head's own height. Horn B top is at v=0.82, horn A top v=1.08.
2. **Horns = jointed beetle-leg tubes, not tapering cones**: constant width shaft (0.137 L), hard knuckles with knobs at base/elbow/top, abrupt direction changes (shaft 90 deg -> arm +24 deg -> distal -20 deg: a 'C' / 'hook' / 'shepherd's crook'), dark chitin claw ends. Curvature is concentrated in the elbow (r~0.07 L at the outer corner) and gentle along the arm (r 0.375 L); the distal segment is nearly straight.
3. **Asymmetry**: horn A (thick, 0.137 L, tall, straight shaft) vs horn B (thin 0.066 L, C-arc r 0.256 L, elbow at the extreme left). Blade D (up-right 46 deg, 0.25 L) vs blade F (left, 9 deg down, 0.15 L) are different shapes at opposite sides; stub E is blunt/round-ended, F is pointed/forked.
4. **Thin protrusions**: spur (95 px long, ~30 px wide, black, needle-like), spike C (25 px), stub E (28 px), blade F (22 px), claw, fringe streaks (~15-25 px thick x 0.29 L long). Thin means thin: these are 0.04 L or less.
5. **Snout**: not a long curved muzzle; a short drooped wedge (0.40 L tip-to-eye) whose front is a hooked heel pointing down-left; straight ventral edge at 26 deg; flat-then-vertical dorsal step. The mouth is a flat seam; the lower jaw is the cream plate that runs the full length under the red plate and ends in the hook.
6. **Rhythm**: sharp graphic angles (vertical edge x=878, elbow corner, spur) alternate with long sweeps (fringe streaks, ventral jaw edge, arm arc). Fringe elements all stream rearward (screen-right) at -5 deg to -51 deg; blades/horns point up and left; hook points down-left: the head is a radial burst of thin spikes around a small plate-faced skull.
7. **Overlap**: plates are stacked cut-out shapes with thick dark gaps (the dark outline is 8-14 px at plate edges, e.g. between red 71 and cheek mass 20): treat them as layered shells.
8. **Neck**: a long vertical column (width 0.348 L at y850) with straight edges; the head sits on it at the TOP-FRONT (throat apex at x=1009 is 0.31 L in front of the neck front edge? no: the neck front edge is x~1040, so the throat apex is just in front of it) - the head overhangs forward of the neck by ~0.32 L (snout tip is 230 px / 0.36 L in front of the neck front edge).
9. **Eye**: tiny round iris with a large dark swept socket; socket tilts up toward the back at ~12 deg and is overhung by the cream brow band whose underside is the 'upper eyelid' (rising from (990,628) to (1073,632) ... eyelid line is nearly level with a 12 deg tilt).

## 8. AMBIGUITIES (ranked by importance for the modeler)

1. **Snout dorsal line / forehead-to-snout transition**: not visible as a curve. The art shows plates stepping down-left (cream 96 -> red 70 -> vertical edge x=878 -> hook). Whether the real skull is continuous is not determinable. Only the plates and silhouette steps are known.
2. **Skull rear (occiput) and its volume**: hidden under fringe strands and the dark crown; only the fringe silhouette and the crown top y~544 are visible. Head depth (thickness toward the viewer) is NOT shown in the profile.
3. **Horn A/B roots**: both horn roots disappear under the brow plate/olive collar (horn A base ~ (950,585), horn B root ~ (900,625)); how they attach to the skull is hidden. Only the visible knobs are certain. Which horn is 'left' or 'right' of the character cannot be told from this single view (A is the near one, B the far one).
4. **Mouth**: only a seam is visible (no corners, no open jaw, no fang except a 5 px white fleck). Mouth corners are NOT in the art; the straight-on rage face shows an open mouth, but that is a different (generated) view.
5. **Nostril**: none visible in the profile (the profile red plate has a dark patch at (1010-1030,695-705), region 'dark plum', which may be a nostril/gill, uncertain); the straight-on faces show a black triangular nose.
6. **Cheek boundary / jaw hinge**: no mandible hinge visible; the lower-jaw plate (103) merges into the red cheek plate (71/4) with a black line. The black cheek mass boundary below the red plate is clear, but its depth is not.
7. **Hero camera**: head is drawn in pure profile (facing screen-left) on a 3/4 front body, torso twisted; the head's silhouette must be tested from a camera that sees it in profile, not the body's camera. The hero image is a low-angle perspective drawing: lengths are foreshortened (right foot is 127 px lower than left).
8. **Left foot** is cut flat at x=365 (vertical straight edge y~3750-3870): either cropped or drawn flat; toes beyond are unknown. The left arm/hand ends at the image edge (x=8) holding the (removed) mace; the mace head is not in the 4096 hero.
9. **Hero rear/hidden**: neck-shoulder junction behind the right pauldron and under the cream sash knot; left shoulder dark cape hides the shoulder/arm root.
10. **Dark-on-dark detail**: on the black cheek/neck mass and the hero's black cape/skirt, internal forms are nearly invisible (value 24,21,21 vs 11,8,7); anything in there is guesswork.
11. R-FACE views are generated/completed (up to 17 % inferred) - use for symmetry/width only, and not as a shape authority over the profile.

## 9. R-HERO (full body) - coordinates and landmarks

Coordinate system: section 1. Silhouette: single connected component, bbox x0-1890, y96-3999 (width includes the left hand/mace stub at x=8). Row spans for every 100 px are in `hero_landmarks.json -> row_runs_src`. Key proportions (all /H=3904): head length L = 0.162 H; horn A top at v=1.0; snout tip at v=0.825; throat apex v=0.832-0.0.. (y746: v=0.834); neck from throat (y746) to cape junction (y~1150) = 0.103 H, neck width 0.058 H; shoulders: cape extreme x=504 to pauldron extreme x=1712 = 1208 px = 0.309 H; right pauldron 620 px tall (0.159 H); belt at y~1880 (v=0.543); right fist bottom y 2510 (v=0.382); knees y~2730-2910 (v=0.30-0.32); skirt hem y~3314-3470; left foot bottom y~3873 (v=0.033), right foot y=4000 (v=0).

| # | landmark | src px | (u, v) | kind |
|---|---|---|---|---|
| 1 | extreme top (horn A knob) | (1138, 96) | (0.049, 1.000) | V |
| 2 | horn B top knob | (766, 259) | (-0.046, 0.958) | V |
| 3 | horn A claw tip | (1394, 191) | (0.115, 0.976) | V |
| 4 | horn B elbow (left extreme of head) | (626, 493) | (-0.082, 0.898) | V |
| 5 | snout / hook tip | (811, 780) | (-0.035, 0.825) | V |
| 6 | eye centre | (1022, 638) | (0.020, 0.861) | V |
| 7 | crown top | (1079, 544) | (0.034, 0.885) | V |
| 8 | throat gape apex | (1009, 746) | (0.016, 0.834) | V |
| 9 | fringe long streak tip | (1444, 626) | (0.128, 0.864) | V |
| 10 | neck front edge y=1000 | (1039, 1000) | (0.024, 0.768) | V |
| 11 | neck back edge y=1000 | (1266, 1000) | (0.082, 0.768) | V |
| 12 | neck front edge meets cape/shoulder | (1010, 1150) | (0.017, 0.730) | J |
| 13 | left cape/shoulder slope y=1300 | (832, 1300) | (-0.029, 0.692) | V |
| 14 | left cape extreme (leftmost shoulder) | (504, 1500) | (-0.113, 0.640) | V |
| 15 | left cape lower hem corner | (560, 1600) | (-0.099, 0.615) | V |
| 16 | right pauldron top | (1590, 1005) | (0.165, 0.767) | V |
| 17 | right pauldron right extreme | (1712, 1470) | (0.196, 0.648) | V |
| 18 | right pauldron bottom | (1650, 1625) | (0.180, 0.608) | V |
| 19 | neck back / right shoulder junction (hidden under pauldron) | (1300, 1130) | (0.091, 0.735) | H |
| 20 | left arm upper-outer edge | (365, 1900) | (-0.149, 0.538) | V |
| 21 | left forearm armour lower end | (130, 2260) | (-0.209, 0.446) | J |
| 22 | left hand extreme-left tip | (8, 2500) | (-0.240, 0.384) | V |
| 23 | left hand claws underside | (200, 2480) | (-0.191, 0.389) | V |
| 24 | right elbow plate top | (1520, 1830) | (0.147, 0.556) | V |
| 25 | right elbow plate right extreme | (1769, 1900) | (0.211, 0.538) | V |
| 26 | right fist bottom | (1640, 2510) | (0.178, 0.382) | V |
| 27 | belt left end | (700, 1880) | (-0.063, 0.543) | J |
| 28 | belt right end | (1215, 1880) | (0.069, 0.543) | J |
| 29 | hanging pendant (right of waist) bottom | (1330, 2170) | (0.099, 0.469) | V |
| 30 | chest bandolier left shoulder knot | (880, 1480) | (-0.017, 0.645) | J |
| 31 | skirt left edge top | (363, 2800) | (-0.149, 0.307) | V |
| 32 | skirt left hem strand tip | (540, 3470) | (-0.104, 0.136) | V |
| 33 | skirt right edge max | (1890, 3430) | (0.242, 0.146) | V |
| 34 | skirt hem between legs left | (900, 3314) | (-0.012, 0.176) | V |
| 35 | skirt hem between legs right | (1290, 3350) | (0.088, 0.167) | V |
| 36 | left knee wrap centre | (700, 2910) | (-0.063, 0.279) | J |
| 37 | right knee plate centre | (1260, 2730) | (0.081, 0.325) | J |
| 38 | left ankle | (720, 3560) | (-0.058, 0.113) | J |
| 39 | left foot toe (flat vertical cut at x=365) | (365, 3800) | (-0.149, 0.051) | V |
| 40 | left foot heel / right extent | (880, 3830) | (-0.017, 0.043) | V |
| 41 | left foot bottom | (620, 3873) | (-0.083, 0.033) | V |
| 42 | right ankle | (1600, 3500) | (0.168, 0.128) | J |
| 43 | right foot right extreme | (1888, 3830) | (0.241, 0.043) | V |
| 44 | right foot toe-left | (1487, 3850) | (0.139, 0.038) | V |
| 45 | right foot bottom (ground row) | (1700, 4000) | (0.193, 0.000) | V |

**Hero negative space** (convex hull minus silhouette; areas / H^2; overlay `hero_negative_space.png`):

| pocket | area px | area/H^2 | bbox |
|---|---|---|---|
| P1 | 568731 | 0.0373 | [0, 462, 1053, 2498] |
| P2 | 471586 | 0.0309 | [370, 3114, 1542, 4000] |
| P3 | 354890 | 0.0233 | [0, 2423, 648, 3878] |
| P4 | 324996 | 0.0213 | [943, 151, 1710, 1150] |
| P5 | 107048 | 0.0070 | [1647, 1817, 1887, 3321] |
| P6 | 62453 | 0.0041 | [1290, 1753, 1505, 2392] |
| P7 | 54188 | 0.0036 | [1655, 3271, 1891, 3897] |
| P8 | 45026 | 0.0029 | [714, 131, 1041, 606] |
| P9 | 34106 | 0.0022 | [1679, 1167, 1794, 1821] |
| P10 | 20455 | 0.0013 | [256, 2158, 464, 2411] |

Interior holes (enclosed background): between the right arm and torso (bbox 1290-1505 x 1753-2392, 62k px = 0.0041 H^2: the **arm-torso gap** under the right elbow), a smaller hole at 1146-1277 x 1769-2063 (waist-pendant gap) and one at 256-464 x 2158-2411 (left arm/torso gap). The big open spaces are the V-gap between legs (P2, 0.031 H^2: apex at skirt hem ~(900-1290, 3314-3350)), the left-arm sweep (P1/P3) and the head/neck cavity to the right of the neck (P4).
The legs: the left leg (screen-left) is planted with its foot at x 365-880 and the right leg's foot at x 1487-1890: a wide stance 0.36 H between foot centres; the skirt/loincloth strands hang to y~3470 and form ragged triangular tips.

## 10. THE 10 MOST IMPORTANT MEASUREMENTS FOR THE MODELER (R-HEAD, in L = 633 px)

1. Snout tip -> eye centre: **0.402 L at 33.9 deg below horizontal**; eye at (u,v) = (0.333, 0.224).
2. Eye iris 0.062 x 0.041 L (tilt +12.5 deg, rising to the back); socket 0.142 x 0.082 L.
3. Snout is a hooked wedge: hook height 0.074 L, underside radius 0.054 L; ventral edge 26 deg up to the throat apex at (u,v)=(0.313, 0.054); dorsal edge is a vertical step at u=0.106 (v 0.063-0.118).
4. Head overhangs the neck: snout tip is 0.36 L in front of the neck front edge (x=1040); neck width 0.348 L; neck back edge u=0.68-0.71.
5. Horn A: shaft width 0.137 L, shaft length 0.50 L (vertical), elbow at (u,v)=(0.055, 0.861), top knob (0.517, 1.081), claw tip (0.921, 0.931); total 0.708 L above the crown, span 0.866 L.
6. Horn A arm bends +24 deg then the distal segment drops -20 deg; arc radii 0.375 L (top) / 0.145 L (underside); spur 95 px / 0.15 L long at -32 deg.
7. Horn B: width 0.066 L, outer arc radius 0.256 L, left extreme at u=-0.292 (v=0.453), top knob (-0.071, 0.823); 0.26 L shorter than A.
8. Crown line at v=0.373 (flat from u=0.34 to 0.51); blade D base (0.51,0.373) apex (0.679, 0.554) (0.25 L at 46 deg); stub E tip (0.80, 0.474); spike C top (0.338, 0.461).
9. Blade F: tip (-0.060, 0.120) from the snout tip... length 0.149 L, pointing left and 9 deg down, below horn B and above the hook (gap N8 = 0.014 L^2).
10. Fringe/occiput: crown to rear tip u=1.0; long streak 0.289 L at -5 deg; cream strands at -51 deg; rear skull itself is hidden (ambiguity #2); negative spaces N1 (0.104 L^2) and N2 (0.276 L^2) must stay open: horns do not touch.
