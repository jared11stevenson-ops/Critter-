# HEAD v7 handoff (landmark-driven faceted plate model)

Files: `head_v7.blend`, `head_v7.glb` (head objects only, flat shaded, material colours = painted colour blocks), `landmarks.json` (every landmark / plate polygon in reference px), `ITERATIONS.md`, `final/compare_{side,front,back}.png`, `band_diff.png`, `measure/*/band_iou.json`, crops with labelled grids (`crop_*_grid*.png`).
Code: `tools/modeling/aruun/v7_head/` : `crops.py` (grid crops), `build_head7.py` + `extras7.py` (model), `render7.py` + `post7.py` (verification renders + overlays), `iter.sh TAG`, `assemble7.py` + `measure7.sh` (swap into LOCKED_P1d + band IoU), `export7.py`.
Frame: blender (L, -F, U); head line L = 0.09; objects in world space. F_model = F_v2frame - 0.055 (frame offset measured by matching the neck to P1d).

## Method
1. Grid crops of v2 side tile (frame px, 1626.667 px/m) and calm face tile; landmarks read by eye and written to landmarks.json: side (silhouette stations, eye corners, brow strip, red cheek, crown steps, lip, jaw hook, tines) and front (shield polygon, eye sockets, nose pad, cheek plates, nostrils). Front rows shifted -25 px so front and side eye rows agree (U 2.083-2.087).
2. Skull cage: 11 ring stations x 8 flat-faced sides (separate upper/lower half widths), read from side silhouette + widths from front/back (skull 0.21 m). Mandible: separate 9-ring loft, pivot F 0.03 U 2.03 L 0.09.
3. Plates: side plates are ray-projected onto the cage along the lateral axis (vertices outside the silhouette are pulled in), front plates (shield, nose pad, cheek plate, nostrils) sit on an analytic surface F = F_front(U) - k s^2; every plate = low-poly patch + Solidify 8-10 mm (inward) + 1.2 mm bevel, flat shaded. Eyes: angular raised socket bowl (dark) + almond eye + pupil, axis 60 deg off forward. Tines = 5-sided cones, horn cups = 8-gon collars, fringe = flat strand cards.
4. Verification: same-camera Cycles clay + ID-pass overlay on each reference crop (see ITERATIONS.md, 5 shown iterations + final).

## Numbers
3692 tris (budget 8k), 42 objects. Head length F -0.109..0.199 = 0.308 m (spec 0.307). Head U 1.954-2.148.
Whole-scene band IoU, head 1.75-2.0 m, v2 masks: side 0.839 (gate 0.82 OK), back 0.848 (gate 0.85 MISSED by 0.002; the dominant back error is the untouched P1d neck/shoulder edge - red/blue on the neck sides in band_diff.png). Whole silhouette: side 0.897, back 0.896.
Object names: skull_cage, plate_* (_R/_L), nose_pad, nostril_L/R, socket_L/R, eye_L/R, pupil_L/R, mandible (+ plate_jaw_hook_*, plate_jaw_cream parented), tine_L/R, horn_cup_A/B, fringe_* , nape_mark.

## Known wrong (honest)
- Still not the reference's long slim drooping muzzle: the snout is a blunt wedge; the notch between the crown-shield knob and the jaw hook is only partly there; nose pad/V plates are simplified (one pad, no separate V plates).
- Mandible is a straight loft with a red hook plate; it does not tuck under the snout (visible mouth slit in front/side clay); never tested through a jaw rotation (meshes are not skinned).
- Many painted colour regions are missing or only approximate: side red cheek and tan brow strip positions are within ~10-20 px but their outlines are not the painted ones; the dark navy oval cranium cap, the yellow/cream inner-eye almond with dark ring, the olive/cream fringe strands (we have 4-5 flat cards, reference has many), brow ridge as a heavy angular plate above the eye.
- Sockets are raised bowls (read as recess by colour/shading), not a cut-in recess. Eyes are 6-gon almonds.
- Side plates are ray-projected on the 8-sided cage so some show sliver triangles at facet creases (e.g. around shield V-tip and nostrils in front); no manual cleanup.
- Tines/fringe wings approximate; bone tines are hidden behind horn cups in the side view. Back view: the cream tan nape mark exists but is a flat card; reference has bigger olive/tan fringe masses lower-left.
- Horn cups are placeholder collars (kept at P1d horn positions).
- Back-band gate 0.85 missed (0.848).
