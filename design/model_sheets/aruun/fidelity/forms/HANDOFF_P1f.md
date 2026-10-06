# HANDOFF P1f (Gate 2 pass 1f: mantle/hood, chest wrap/belt, arm + thigh plates). Primary Modeler; no self-grading, compare.py numbers only.
Base = LOCKED_P1f0 (= LOCKED_P1e). Head not touched. Env switches in build_forms2.py: MANTLE_F, CHEST_F, PLATES_F (default 1). One commit per ticket; snapshots `p1f_mantle/`, `p1f_chest/`, `p1f_plates/`; final `LOCKED_P1f/` (forms.blend/glb, closeups (shoulder), compare_orig_ref, compare_v2_ref, scripts). Clay grey only.

## Whole IoU (orig reference; v2 within 0.001). Rule: roll back if whole IoU falls > 0.005 per ticket
| state | side | back |
|---|---|---|
| LOCKED_P1f0 (= P1e) | 0.903 | 0.893 |
| + mantle/hood | 0.902 | 0.894 |
| + chest wrap/belt | 0.898 | 0.894 |
| + arm/thigh plates (final) | 0.898 | 0.893 |
No ticket rolled back. Largest drop: chest/belt side -0.004 after trimming (the first version dropped side to 0.894, -0.008, and was reduced).

## Ticket 1: MANTLE / HOOD (cloth_f.mantle)
The proxy mantle volume is cut at 1.46 m and capped; below it 7 flat ragged TAILS (lengths 0.09-0.20 m) hang from the rim around the back-to-right side (reference: dark ragged cloak tails; fringe is Gate 3). `hood_pad` (rolled hood behind the neck base, moved toward his right: L -0.075) and `hood_rim` (drooping onto the right shoulder). Everything stays inside the side silhouette (side IoU unchanged 0.903 -> 0.902; side xmin error at 1.84 m -0.023 as before).
Back-view numbers: solid width at 1.84 m: model 0.207 vs ref 0.185 (before 0.195-0.246 depending on the neck blend); at 1.82/1.80/1.77 m model 0.299/0.352/0.408 vs ref 0.306/0.365/0.418; right-edge error at 1.80 m -0.034 -> +0.001. The mantle tails are barely visible in clay close-ups (small slivers): the reference cloak is a large draped sheet, not tails only.

## Ticket 2: CHEST WRAP, STRAPS, BELT (cloth_f.chest_belt)
Thin bands conforming to the proxy trunk surface (analytic ellipse rings read from the proxy source): `chest_wrap_band1/2` (cream bandage wraps, 4 mm proud), `chest_strap_A` (L shoulder -> R hip), `chest_strap_B`, `chest_knot` + two tails, `gold_ring_pendant`; `belt_sash` (red sash ring at 1.165-1.255 m, +3..5 mm), `sash_knot` at the right hip, `belt_ring_buckle` (bone ring), `belt_medallion`, 4 `belt_bead_string*` with 3 beads each, `belt_stud*` along the belt. The hanging fringe tail from pass 1d stays.
Numbers: waist depth (side) 0.473 vs ref 0.460 (+0.013; before 0.448, -0.013); waist width back 0.746 vs 0.743; IoU side 0.902 -> 0.898 (the first version with 10-24 mm protrusions: 0.894, rolled down to 3-6 mm).

## Ticket 3: ARM + THIGH PLATES (plates_f.arms)
Red forearm bracers `bracer_L/R` with raised rims, `elbow_disc_L/R` (flat discs, outward), tan `upper_arm_plate_L/R`; tan `thigh_plate_L/R` with a red `thigh_mark_L/R`, `hamstring_plate_L/R` on the back; `shin_cuff_L/R` at the shin-to-sabaton join. All flush (4-10 mm).
Widths vs the current compare numbers: arm outer back 0.723 (ref 0.712; was 0.722), side 0.407 (0.399); thigh outer side 0.208 (ref 0.192; was 0.206), back 0.757 (0.755); shin outer side 0.129 (0.117; 0.129), back 0.621 (0.606; 0.617). IoU 0.898 / 0.893 (unchanged from ticket 2).

## Known wrong
- The mantle is a draped upper mass plus thin tails, not the large draped cloth sheet with a hood opening; hood shape is two ellipsoids.
- Straps/wrap bands are simple extruded ribbons (no cloth folds); gold ring, buckle ring and beads are small tubes/ellipsoids.
- Arm plates are 8-sided shells; no segmented plate layers. Part 23-24 thigh plates are flat ellipsoids, no tan plate edges.
- Thigh outer side width is +0.016 over the reference (it was +0.014 before the plates); shin +0.012.
- Skirt strips and fringe masses not built (Gate 3).
