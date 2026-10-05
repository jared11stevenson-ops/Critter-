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
