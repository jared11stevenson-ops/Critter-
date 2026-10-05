# ARUUN ARTLOG (Agent 4)

## 2026-10-05 - Stage 0: honest baseline
- Legacy build (capsule/SDF parts + procedural paint) vs sheet: silhouette IoU side 0.51, back 0.67 (qa/v2_fit_overlay.png left tiles).
  In game (qa/before_pop_red_00.png): symmetric lyre horns, bulky symmetric torso, flat procedural plates = mannequin. Estimated sheet match ~65%.
- Reference study (landmarks.json + hires): 2.40 m, 8.3 heads of body incl horns; neck 0.45 m, orange-red, rises forward from a hunched trunk; asymmetric contrapposto
  (head/neck centred ~0.1 m to his left of the hips); big red ladybug pauldrons with yellow/black spots; dark aubergine chitin with tan plates; olive leaf skirt, cream tassels;
  dark hooded mantle over his RIGHT shoulder with cream fringe; horns: two thick jointed red/cream stag-beetle horns, asymmetric, hooked forward (side) and arching over the top (back);
  pale-yellow fringe at the nape, cream temple tines, red crest plates, yellow eyes on the sides of a long snouted skull.
- Must survive in 3D: asymmetric horns, long forward neck, pauldrons, hunch, long clawed feet, mantle+fringe, leaf skirt, Morrow.

## Stage 1 - silhouette fit (qa/v2_fit_overlay.png)  IoU side 0.90 / back 0.93.
## Stage 2 - first textured v2 (qa/v2_iter0_projection.png): torn card ribbons, hollow voxel shells, marbled projection. CRITIQUE (ranked): 1 front texture marbles, 2 cards torn, 3 head is a stump, 4 horns float.
## Iteration 1 (qa/v2_iter2_head.png): head hull + eyes/tines/crest/fringe + anchored thick horns. Fixed 3,4.
## Iteration 2: skirt ellipse rebuild (hula ring -> hugging), mantle Delaunay hem, front projection bug (stale confidence), grade, painted-class normal relief.
(continued below as iterations land)

---
# v3 - face-first rebuild (Agent 4, 2026-10-05)  [creator: "Aruun's face doesn't look like a face"]
Pipeline: `tools/modeling/aruun/v3/run_all.sh` (head.py SDF -> horns3.py -> build_mesh3.py -> unwrap3.py -> paint3.py -> finish3.py).
Everything below was OPENED and looked at; image paths are in `qa/`.

## Reference study (detail_head.png, spec)
Long dragon/horse snout (nose pad at the tip, nostrils on top), downward mandible hook, cream/tan face plate on snout+cheek, dark navy lower head/nape,
red crown plates over the brow, heavy bone brow ridge, big YELLOW eye with dark pupil ring + white glint on the SIDE of the head set into a dark socket,
white fang visible at the mouth corner even when calm, pale-yellow/olive fringe sweeping back, two big red jointed horns rooted in red crown cups, cream temple tines.

## Iteration 1 - first dedicated head (qa/v3_face_iter1_cycles.png)
Built as a separate SDF sculpt (skull + 3-ellipsoid taper snout + nose pad + brow bars + cheek plates + horn cups + crest + separate mandible with chin hook,
fangs, tongue), 2.5k+0.65k tris, painted by position (cream plate / red crown / dark socket / nostrils / mouth line / palate).
CRITIQUE: reads as a face immediately (two eyes, snout, nostrils, fangs) BUT: (1) neck stub bulges into a collar ring where it meets the trunk; (2) horns are candy-cane
striped, 8-sided and faceted; (3) no fringe - head is bald; (4) nose-bridge ridge is bone-white so from the front it reads like a skull; (5) chin hook reads as a tongue.
## Iteration 2 (qa/v3_face_iter2_cycles.png)
Fixes: stub shrunk (smooth-union bulge compensated), horn bands narrowed, fringe cards + temple tines added, ridge toned to cream, chin plate recoloured dark red.
CRITIQUE: fringe cards are needle-thin and stick out like spikes; tines point sideways; open-jaw test (iter3 image) shows the mandible hinge works, tongue/fangs/palate read.
## Iteration 3 - in the ENGINE (qa/v3_engine_face_iter3_profile.png)  <- the honest test
Found by looking at the real game render: (a) the inverted-hull outline (0.022 m) and the teal rim swamped the head: it read as a black blob with a dot;
(b) the idle mocap pitches/yaws the head so the face is in profile or looking at the sky; (c) the eye pupil vanished (tiny fragmented UV charts + overexposed emissive);
(d) the head is too small to read at game distance.
FIXES: per-vertex shader control through glb COLOR_0 (r = outline width, g = rim, b = shade-floor boost: head r=0.22 g=0.30 b=1.0) in character_pop.*;
head scaled x1.18 over the sheet; eyes get a clean planar-disc UV in a reserved 128px square (pupil, amber ring, glint); emissive cut to 0.8; idle clip turns the head
back to the viewer (+22 deg yaw, +30 deg pitch correction measured in Blender: head-forward z 0.66 -> 0.27).
## Iteration 4 (qa/v3_engine_face_iter4_front.png)
Face now reads in-engine at close/medium range: yellow eye with dark pupil ring + glint, cream snout with dark nostril, fangs along the lip, mandible hook, red crown, fringe.
STILL WEAK: at the real gameplay camera (14 m, pitch -40) the head is ~12 px: you get the horns, the orange neck and ONE yellow dot - a stranger would not say "face" there;
it is a silhouette problem (horns+snout) not a texture one. See "what remains".

## Body paint (qa/v3_body_textured_preview.png)
Blotchy projection replaced by object-space plates: elongated Worley cells = plates, coloured by anatomical zone (red/bone/chitin probabilities), ink outlines, cream rim lights,
big ochre spots in red plates; hand-placed ladybug pauldrons (ochre spot, cream rim, teal emissive ring), cream sternum plate with rib lines, spine plates, belt, orange neck with cream dashes.
Horns restored to sheet scale (tips 2.36 m, hooked), 10 -> 8 sided, jointed knobs with cream bands + teal emissive bands, side tines, forked tips.

## Hand-off state (qa/v3_compare_cycles.png = sheet | model, side/back/front-3/4; qa/v3_game_camera_crop_both_heroes.png)
Gates: 14,675 tris (<=15k), 2048 WebP maps, 1 body material (+1 outline pass), tools/validate.sh 0 failures / 84 system tests pass, full_flow.json 0 SCRIPT ERRORs (peak draw calls
in that run 186 for the whole scene incl. world - heroes contribute ~6; world side is the Lead's). Face iterations: 4 (iter1-iter4 above), all opened and critiqued.
Jaw opens in attacks/hits/rage (checked numerically: jaw-vs-head angle 29 -> 61 deg in beetle_rage). Expressions: shape keys angry/calm on the skull, driven by CharacterModel.set_expression().
CRITIQUE vs the sheet (board):
- Silhouette: horns now hooked lyre antlers at sheet height (2.36 vs 2.40 m), snout + hook read in profile. Head is still a little small for the 2.4 m body (x1.18 already).
- Paint is now clean plates, but coverage is too red/cream: the sheet is dominated by near-black plum chitin with red/cream accents (about 60/25/15). Mine is closer to 40/30/30.
- Hands, feet and the mantle card are crude (flat cloak card, no fingers); Morrow is the legacy mesh.
- Face: lacks the sheet's expressive eye socket drama, the white fang is small, the pale-yellow fringe is a few paper-flat strands instead of a flowing mane.
HONEST MATCH: face ~60 % (structure + palette right, line quality / fringe / expression range not), body ~65 %.
WHAT REMAINS: darker chitin balance, real fringe strands with alpha, hands with fingers, mantle thickness/hood, per-expression texture swaps, a gameplay-distance silhouette pass (bigger snout contrast), contact-sheet review of every clip at close camera.
