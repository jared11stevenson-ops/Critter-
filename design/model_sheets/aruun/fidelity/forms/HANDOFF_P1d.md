# HANDOFF P1d (Gate 2 pass 1d: horns, neck, torso). Primary Modeler; no self-grading, compare.py / band_iou.py numbers only.
Base = LOCKED_P1b (saved as LOCKED_P1d0). The head was NOT touched (the neck is re-pathed; the head hull and features are unchanged). Defaults in build_forms2.py: P1C=0 (head = P1b hull+features), HORNS_D=1, NECK_D=1, CHEST_D=1; each ticket can be switched off by its env var. One commit per ticket. Final locked snapshot: `LOCKED_P1d/` (forms.blend/glb, closeups, compare_orig_ref, compare_v2_ref); per-ticket snapshots `p1d_horns/`, `p1d_neck/`, `p1d_torso/`.

## Numbers (orig reference; v2 within 0.001). Rule: roll back if whole IoU falls > 0.005
| state | IoU side/back | horn band side/back | head band side/back |
|---|---|---|---|
| LOCKED_P1d0 (= P1b) | 0.903 / 0.898 | 0.870 / 0.838 | 0.850 / 0.862 |
| + ticket 1 horns | 0.901 / 0.897 | 0.849 / 0.833 | 0.850 / 0.862 |
| + ticket 2 neck | 0.902 / 0.897 | 0.849 / 0.833 | 0.858 / 0.857 |
| + ticket 3 torso (final) | 0.903 / 0.897 | 0.849 / 0.833 | 0.859 / 0.857 |
Targets kept: horn band >= 0.83 / 0.83 (0.849 / 0.833), horns.solid_width 0.120 side / 0.121 back (target 0.119). No ticket rolled back.

## Ticket 1: HORNS (horns_blade.py; centerlines and measured radii unchanged)
Faceted 8-sided oval blades; flat 6-sided PLATE STEPS (collars, 1.10x) at 3 joints per horn instead of ball joints; sharp forked tines (a long prong + a short second prong, A at 0.35/0.62 rearward, B at 0.42/0.74/0.90 forward, i.e. away from the other horn so the side components do not merge); forked tips; A has a SADDLE ellipsoid at its base; B keeps its needle; inward CROWN TINES between the bases (A's points toward B and vice versa) for the back-view arch. A and B now differ in plate/tine counts, positions and A's saddle.
Before -> after: horn band 0.870/0.838 -> 0.849/0.833; solid_width 0.116/0.119 -> 0.120/0.121; back spans B 0.291 -> 0.304 (ref 0.290), A 0.109 -> 0.109 (0.103); side spans A 0.213 -> 0.237 (0.217), B 0.204 -> 0.203 (0.183, lower bound); whole IoU -0.002/-0.001.
Not done: the long BRIDGE bar between A's top and B's shaft. I built it and measured: it fused the two side-view components (side horn A span 0.355 vs ref 0.217) and added 3k px of model-only area, so it was replaced by the inward crown tines. The reference's crown-level loop floor is part of the head (untouched).

## Ticket 2: NECK
Neck tube re-pathed ~0.02 m forward at 1.84-1.92 m with the large (0.15 m) radii kept below 1.78 m and top radii (0.056/0.066) matched to the head hull's neck-blend cross-section (no collar ring). Finding: a first attempt moved the thin section too low; tilted large rings (radius 0.12 at a 30-40 degree tangent) bulged 0.05-0.085 m behind the neck at 1.87-1.89 m, which also explains part of the original -0.024 throat error. Side throat error at 1.89 m: xmin -0.017 -> -0.010; front xmax -0.006 -> +0.006; head band 0.850/0.862 -> 0.858/0.857 (side up, back -0.005).
Not matched: the inspector's "neck 34 mm too thin" is not reproduced by compare.py (side neck_mid run width is now 0.129 vs ref 0.115, i.e. +0.014 THICKER; before 0.119). Residual bulge at 1.87 m (xmin -0.035) comes from the trunk/neckbase, not the neck tube.

## Ticket 3: TORSO
Finding: the side reference's front extreme at 1.45 m (F 0.268, "torso depth 0.545 vs 0.478") is not chest mass but the red hanging FRINGE TAIL (part 33) hooking out of the strap; a chest ellipsoid pushing the front to F 0.265 made the side IoU drop 0.007 (rolled back). Built instead: `fringe_tail` (thin tube traced from the reference skeleton: (0.207,1.53) -> (0.243,1.495) -> (0.256,1.463) -> (0.257,1.445) -> (0.245,1.427), radius 0.006-0.011, placed on his right side at L -0.10, hidden in the back view) and `chest_plate` (ellipsoid flush with the trunk front, gives the front chest line without changing the silhouette). torso.extent 0.476 -> 0.523 (ref 0.537); chest_to_back_depth 0.460 -> 0.508 (ref 0.513); side IoU +0.001.

## Known wrong
- Horn tines/forks are small cone spurs, not the reference's blade-like tines; side horn A span +0.020; back horn B span +0.014; the arch bridge is not modeled as a bar.
- Collar ring: the head hull bottom (neck blend over 25 mm) and the neck tube now share a cross-section, but a faint step may remain in close-ups; not re-inspected visually at pixel level.
- Neck is 0.014 thicker than the reference in side (compare.py), contradicting the inspector's "too thin".
- Fringe tail is on his right side by assumption (the original side view only shows his right).
