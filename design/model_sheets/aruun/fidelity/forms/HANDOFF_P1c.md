# HANDOFF P1c (Gate 2 pass 1c, tickets: skull, eyes/brows, snout+mandible). Primary Modeler; no self-grade. VERDICT FOR THE LEAD: P1c is NOT locked. It fails the head-band rule (back 0.843 < 0.85) and the plates are visibly broken, so LOCKED_P1b (= LOCKED_P1c0) remains the current best. The P1c files are kept in `forms/p1c/` as an experiment.

## What was built (tools/modeling/aruun/v5_forms/)
- `head_loft.py` (ticket 1): ONE Catmull-Clark subdivision skull lofted from 5 mm stations; ring height from the v2 side mask run(s), ring width/centre from the v2 back mask row (clipped to the skull core), super-ellipse rings, apex end rings, lower rows blended toward the neck, slim muzzle taper; the lower jaw (`mandible`, origin = jaw pivot F 0.06 U 2.03 L 0.09) is a second loft from the lower run/beak (F >= 0.09). No voxel hull, no seam between skull and snout: the upper snout ends at F 0.158 and the beak continues as the jaw.
- `head_plates.py` (tickets 1-3): plates TRACED from the v2 side head crop by colour segmentation (red face/muzzle plates, tan brow/cheek plates), triangulated, conformed to the analytic skull surface and extruded with a bevel (`red_plate*_L/R`, `tan_plate*_L/R`, mirrored to the left side: symmetry assumption); rooted temple tines `temple_tine_L/R`; `eye_socket_L/R` + `eyeball_L/R` placed at the traced yellow eye; `nose_pad`, `nostril_L/R`; stepped `crown_plate1-3`; `horn_cup_A/B`. Cheek SPIKES were dropped: the reference back mask has no lateral spike below the tines (head width at U 1.99-2.0 is only L -0.007..0.20).
- Switch: `build_forms2.py` uses the loft + plates by default (env P1C=1); P1C=0 reproduces P1b.

## Numbers (orig reference; v2 within 0.001). Rule: head band >= 0.82 side / 0.85 back, whole IoU drop <= 0.005
| version | IoU side/back | horn zone side/back | head band side/back |
|---|---|---|---|
| P1b (LOCKED_P1c0) | 0.903 / 0.898 | 0.870 / 0.838 | 0.850 / 0.862 |
| P1c skull only (loft) | 0.902 / 0.897 | 0.864 / 0.834 | 0.860 / 0.845 |
| P1c final (loft + plates + eyes + tines) | 0.903 / 0.896 | 0.864 / 0.816 | 0.855 / 0.843 |
Head length 0.298 -> not restored to 0.307 by the loft either (see below).
FAILS: back head band 0.843 < 0.85 (the skull-only loft 0.845 already did; the lost width is the nape fringe/side lobes of the reference, which the clipped skull core does not reproduce), horn zone back -0.022 vs P1b.

## Known wrong
- Plates are visibly broken in the close-ups (shattered/jagged conformed patches near the eyes and brow); I could not debug them without an interactive viewer in the time available. They add 3-6k px of model-only area in the back view.
- The skull still reads as a wide flat shield from the front (the back mask head width at the crown is 0.24 m, and the top rows are shallow in F); eyes sit on the lateral planes and are hardly visible straight-on.
- The jaw/skull split line is still visible as a horizontal gap in the front view; snout length 0.298 vs 0.307 not restored (the upper snout is cut at F 0.158 and the beak tip radius is small).
- The reference has no spikes at the cheeks; the inspector's 'cheek spikes attach to the skull' was satisfied by removing them.

## Recommendation
Keep LOCKED_P1b as the baseline. If the Lead wants the loft skull (smoother, no hull ridges, same silhouette metrics), take `p1c/` with `P1C=1` and drop the traced plates (`PL_SKIP=red_plate,tan_plate`), then widen the skull core at the nape; the plate conforming (head_plates.patch) needs a rebuild (mesh generation bug, not method).
