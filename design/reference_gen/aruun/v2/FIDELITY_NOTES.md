# Aruun v2 reference views - what could differ from the true design (ranked by risk)
Status: GENERATED, UNAPPROVED. Only the creator approves. Method: projection + completion only (no diffusion). Every pixel is a sheet pixel (resampled/warped), a 3-4 px ink outline, or a nearest-neighbour copy.
Legend in every `*_derivation.png`: GREEN original sheet pixels, YELLOW inferred/completed/warped from other views, RED unknown (nearest-neighbour fill). Percentages = share of painted pixels.
Reproduce: `python3 tools/refgen/v2_complete.py; v2_build_front.py; v2_view3q.py; v2_face.py; v2_overview.py` (tools/refgen/).

| file | green / yellow / red % |
|---|---|
| aruun_v2_side_completed_4096 | 99.9 / 0.1 / 0 |
| aruun_v2_back_completed_4096 | 100 / 0.04 / 0 |
| aruun_v2_front_ortho_4096 | 9.6 / 87.5 / 3.0 |
| aruun_v2_34_front_left_4096 (yaw +35, sees his LEFT) | 6.8 / 80.5 / 12.6 |
| aruun_v2_34_front_right_4096 (yaw -35, sees his RIGHT) | 12.0 / 81.6 / 6.4 |
| aruun_v2_34_back_left_4096 (yaw 145) | 34.3 / 56.2 / 9.5 |
| aruun_v2_34_back_right_4096 (yaw -145) | 34.1 / 61.8 / 4.1 |
| aruun_v2_face_calm_4096 (+ _zoom) | 82.8 / 16.5 / 0.7 |
| aruun_v2_face_rage_4096 (+ _zoom) | 98.8 / 0 / 1.2 |

All PNGs: transparent, 4096 px tall, 1626.67 px/m, ground row 4000 (compare.py conventions). Width differs; `x_offset_px` / `axis_x_px` in each json says where world x=0 is (side/back: original axis + 100 px left pad; front/face: axis 900/700; 3/4: 1100). Camera yaw convention in json: 0=front, -90 sees his right (side), 180=back.

## Ranked risks (highest first)
1. **FRONT body paint is a warped 3/4 pose, not a true front (87% yellow).** The sheet's front is a low-camera perspective contrapposto with the torso turned and the right arm out; no true front exists. Each part group (torso, mantle, arms, legs, feet, strips) is re-mapped by hand-registered row warps (`v2_front.py GROUPS`, keyframes = sheet landmarks). Proportions inside each part (chest wrap, belt ring, tassel spacing, knee plate, foot claws) can be off by tens of percent; seams between groups (hips, shoulders) are visible; vertical smears appear where the warp stretches a thin sheet detail. Use as a LAYOUT/colour-blocking reference, not for measuring.
2. **Front pauldron / shoulder.** The sheet shows a large round red disc facing the viewer on his LEFT shoulder; the proxy+back silhouette only gives a narrow outer slice, so in the front ortho the disc is cut to a sliver and its true front size is unknown. Creator question still OPEN: pauldrons on both shoulders? His RIGHT shoulder is the mantle in front+back, the side view shows a red pauldron on the right: region left as drawn (mantle) and marked unknown, nothing invented.
3. **Front silhouette = back cut mirrored below the neck.** Exact for any solid in orthographic projection only up to occlusion: concavities that the back hides (chest depth, the gap between arm and torso, strips that hang in front on the sheet's front but not in the back) are not represented; the olive front leaf-skirt between the legs (sheet front, parts 25) is NOT in this silhouette (no sheet-independent evidence for its outline in a true front). Open: does the leaf skirt show in a true front, and where does it end?
4. **Horns in the front/face views.** Long lyre horns = the BACK cut mirrored (real paint, opposite face), bases nudged by 0 / 4 cm to the CALM tile stub tops, nudge fading to 0 by 2.34 m. The tile's own stubs are short, cut flat by the tile top, and wider (~0.1 m) than the back horns (~0.05 m) so the join has a width step; a small stray fragment of the back head's side tine can appear left of horn A. Whether the calm straight-on horns are the long lyre horns or the short notched stubs is the old open question (PIPELINE.md Q1).
5. **Face views.** CALM/RAGE tiles are original pixels (x4 Real-ESRGAN, 60 px source faces; no extra detail added), but are slightly down-looking busts with a foreshortened snout, so snout length/nostril position are not ortho-true; the calm mouth/fang is not visible (fang only in the RAGE tile: expression, not calm design). The CALM tile's right fringe is clipped by a hard vertical edge (crop, not design) and the tile's bottom edge is a crop (red rows). Black clip line of the CALM tile top was removed (cut rows < 696).
6. **3/4 pairs.** Silhouette = the proxy (1-3 cm vs side/back cuts) so fringe, strips, tines, claws, horn tips and the arm shapes are proxy-smooth; paint is chosen per pixel from front/side/back by normal.view dot product, so seams follow tube geometry rather than the art. Surfaces nobody sees (his LEFT flank/hip, inner arms; ~10% of the front-left view) are RED nearest-neighbour fill. Treat the right-side pair (front_right / back_right) as better supported than the left ones; the left ones are included because the request named front-LEFT, but his left flank has almost no source.
7. **Side/back completions are tiny (<=0.1% of pixels).** Side: forearm cuff clipped at the left cut edge (+14 px rounded continuation on opaque rows only) and horn B tip (28 px taper). Back: two edge clips (+12 px / small tip). Real extents may be larger (they are lower bounds, RULINGS 2). I did not extend further to avoid inventing shapes.
8. **Palette snap / outline.** Pixels within dE 14 of palette.json colours are snapped (front only: 99.6% of pixels were already within dE 14 of a palette colour and got snapped, so the effect is mild flattening, no hue change beyond tolerance); 3-4 px ink outline on silhouettes is the sheet's ink colour but heavier than the original 0.2% line.
9. **Proxy registration.** Proxy-to-cut registration uses the best-IoU shift (side -10 px, back 0); head x is placed at world x 0.08 (cranium centre 0.09, neck 0.07). A few-cm error moves paint by a few cm in 3/4 views.

## Self-critique summary (see rejected/REASONS.md)
- No feature was added that is absent from every source; additions are limited to ink outline, edge continuations (side/back) and nearest-neighbour fills (RED).
- Known visual defects kept visible rather than hidden: group seams in the front, smear streaks near the feet/hips, horn-to-stub width step, stray horn fragment, proxy-smooth 3/4 silhouettes.
- Not 'approved': creator decision needed on the questions below.

## Questions for the creator
1. Pauldrons on both shoulders (side view shows one on his right; front/back show the mantle there)?
2. True-front skirt: do the olive leaf strips fall in front of the thighs/between the legs in a straight front view, and how long are they?
3. Straight-on face: long lyre horns (as drawn in turnaround/back) or the short notched stubs of the expression tiles?
4. Is a higher-resolution/uncropped original of the sheet available (faces are ~60 px at source)?
5. Which 3/4 side matters for modelers (the right-side pair is better supported)?
