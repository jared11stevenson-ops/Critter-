# CIGARRA ARTLOG (Agent 4)  - v2 face-first rebuild, 2026-10-05

## Baseline critique (the Lead's words, confirmed by qa/compare_cycles.png)
v1 was chunky/plastic: box sleeves, capsule legs, 7-colour palette atlas, a tiny cartoon face (two dots) under a white helmet of hair. Estimated sheet match ~45 %.

## Reference study (hires/head_x4.png, side_x4.png, crown_x4.png, turnaround.png)
Face: tan-brown skin, GOLD almond eyes with very heavy black liner + wing flick, thin dark brows, black third-eye dot (forehead, high), small nose, soft lips, black chin line,
brown slash marks on the cheeks, pale scar line on the brow, pointed elf ears through shaggy white hair with lime streaks. Crown: dark branching stalks with olive patches,
big glossy black spheres with a yellow crescent glint. Outfit: cream/olive crop top with black hem, bare midriff, violet hooded jacket (open), puffy sleeves, bandaged wrists/shins,
brown belt with gold ring, orange cords, two pale skull-gourds + orange egg-pod charms, baggy violet harem pants with brown knee patches, leaf-trimmed dark boots,
four lime wing panels with violet cells + gold-lime veins, gold sigil tab on the back.

## Build
Head (SDF, 3k tris, head 6.1 heads tall body incl. 1.12x head scale) + body shell (SDF 4.7k) + hands with real fingers (2x420) + cards (hair 70 clumps, crown 7 spheres + 9 branches,
cape with sigil, hood roll/bag, collar, jacket panels, belt, buckle, cords, charms, leaf trims, 4 wing panels) = 14.4k tris. Same bone names as the stand-in rig; arms abducted 11 deg so the puffy sleeves clear the trousers.
Two materials: body 2048 (albedo/ORM/normal/emissive) and wings 512x1024 alpha (leaf-cut ragged hem, two-sided). Shape keys angry / calm / open on the head.

## Face iterations
1. `qa/v2_face_iter1_textured_preview.png` first textured head: reads as a face (eyes, third eye, nose, lips, markings, ears) but: hair is a white helmet with a hard line over the forehead,
   brow bars float at the third-eye height (wrong z), lower face is long/blocky, jaw heavy.
2. `qa/v2_engine_face_iter2_black_hair.png` IN ENGINE: face is good, but the whole hair is BLACK. Cause: my tube() winding was inside-out (numeric check: 0 % outward) so cull_back showed the dark inner wall
   + the 1.1 cm outline hull swamped 2 cm hair tubes. Fix: winding flipped, per-vertex outline scale (hair 0.10, branches 0.22, face 0.30).
3. `qa/v2_engine_face_iter3.png` hair white and shaggy, jacket panels added; face still too long/alien: shortened lower face and chin, raised mouth/nose/lips by ~5 mm (all paint positions moved with them), brows thinned and lowered, boots darkened.
4. `qa/v2_engine_face_iter4.png` eyes: the emissive was 0.7 x accent 1.6 = over-exposed pale peach, pupil lost its contrast; emissive cut to 0.28, saturated gold. See the final images for the state at hand-off.

## Honest status
Face reads as a face at close/medium range (eyes+liner, third eye, nose, lips, ears, hair). At the real game camera (14 m, -40 deg) the face is ~10 px: you read white hair, tan face, gold crown spheres, violet jacket, lime wings.
Remaining: wings are flat panels (no translucency; opaque painted), hair is low-poly blades (no alpha strands), pants are a smooth baggy sack (no cloth folds in geometry), face skin has no subsurface/blush gradient beyond painted,
no eyelid geometry (blink / half-lid is only a squash on the `calm` key).
