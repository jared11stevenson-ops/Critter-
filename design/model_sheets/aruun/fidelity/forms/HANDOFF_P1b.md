# HANDOFF P1b (Gate 2 pass 1b): head and horns REBUILT by reference-driven construction. Primary Modeler; no self-grade, compare.py / band_iou.py numbers only.
Rollback: the hand-placed pass-1 head and horns were dropped (the pass-1 pauldron, underplate and shoulder blades are kept). Base = LOCKED_BASELINE_03 proxy + those shoulder forms (stage 0 below). Reference for all construction = v2 COMPLETED side/back masks. LOCKED_P1 (the failed pass) is untouched on disk; this pass is `LOCKED_P1b/`.

## Files (design/model_sheets/aruun/fidelity/forms/)
`LOCKED_P1b/`: forms.blend, forms.glb (clay grey, separate named objects), closeups/ (head: front/side/3-4/back, clay + colour-coded `parts`; shoulder), compare_orig_ref/ and compare_v2_ref/ (REPORT.md, overlays, side-by-sides, renders/ at the reference cameras, band_iou.json), horn_curves.json, and copies of the scripts.
Per-component snapshots (same layout, each with its own renders/compare): `p1b_horns/`, `p1b_hull/`, `p1b_features/`. One commit per component.
Code (tools/modeling/aruun/v5_forms/): `extract_horns.py` (medial axis + distance transform -> 3D curves), `head_hull.py` (visual hull), `head_features.py`, `build_forms2.py` (FORMS2_STAGE 0..3), `run_stage2.sh`, `band_iou.py` (new band IoU metric, same alignment as compare.py), `render_closeups.py`.
Reproduce: `python3 tools/modeling/aruun/v5_forms/extract_horns.py design/.../forms/horn_curves.json && tools/modeling/aruun/v5_forms/run_stage2.sh 3 <outdir>`.

## Method
1. HORNS: skeleton (skimage) of the horn zone (U >= 2.12) of the v2 side mask and of the v2 back mask, routed between measured endpoints per horn (A, B), per-point radius = distance transform (so knobs and tine bumps come from the reference), smoothed. Side path gives (F,U), back path gives (L,U); the ascending parts are matched by U, the descending hook tail by arclength fraction. A and B are separate curves (not mirrored). Swept as tapered tubes (radius x1.15 to cancel the smoothing loss), base continued 0.035 m into the head, plus the dark hooked needle at the tip of B (v2 side view).
2. HEAD HULL: voxel intersection (4 mm) of the extruded side mask and back mask over U 1.945-2.135; back mask clipped to the skull half-width (0.108 about the head line L=0.09, so tines/fringe do not become wings) and a lateral wedge taper along F beyond the skull (slim muzzle); each skull row is a super-ellipse with exactly the measured F and L extents; lowest 25 mm blended to the neck cross-section; Gaussian-smoothed marching cubes.
3. FEATURES (separate objects): `eye_socket_L/R`, `eyeball_L/R` (on the sides), `brow_L/R` (angled down toward the snout), `nose_pad`, `nostril_L/R`, `cheek_plate_L/R` + `cheek_plate2_L/R` (angular extruded polygons on the hull surface), `crown_plate1-3` (stepped slabs), `horn_cup_A/B`, `temple_tine_L` (long, to L 0.245) / `temple_tine_R` (short, to L -0.08, rising), `mandible` (the lower jaw is split from the hull below the mouth line, U < 2.045 for F > 0.05; object origin = jaw pivot at F 0.03, U 2.03, L 0.09, so it can rotate open).

## Numbers (orig reference; v2 reference within 0.001 everywhere)
| stage | IoU side | IoU back | horn zone 2.0-2.4 side/back | horns only >2.14 side/back | head 1.75-2.0 side/back |
|---|---|---|---|---|---|
| proxy + pauldron (rolled back, stage 0) | 0.874 | 0.883 | 0.629 / 0.619 | 0.475 / 0.449 | 0.829 / 0.846 |
| failed pass-1 head+horns (for reference) | 0.874 | 0.882 | 0.638 / 0.617 | 0.499 / 0.453 | 0.813 / 0.837 |
| + HORNS (component 1) | 0.896 | 0.896 | 0.812 / 0.819 | 0.804 / 0.799 | 0.835 / 0.848 |
| + HEAD HULL (component 2) | 0.904 | 0.899 | 0.879 / 0.852 | 0.805 / 0.792 | 0.861 / 0.866 |
| + FEATURES (component 3, final) | 0.903 | 0.898 | 0.870 / 0.838 | 0.803 / 0.788 | 0.850 / 0.862 |
Horn-zone band IoU is now above the 0.75 target in both views (was 0.63/0.62).
Horn measured regions (final, ref in brackets): horns.solid_width side 0.117 / back 0.119 (0.119); back horn B span 0.291 (0.290); back horn A span 0.109 (0.103); side horn A span 0.213 (0.217); side horn B span 0.204 (0.183, lower bound); tip heights A 2.381 / 2.363, B 2.394 / 2.394; total back spread within 0.01.
Head: head.outer_width side 0.229 (0.226) back 0.217 (0.210); back head.extent 0.326 (0.331); snout.outer_width 0.237 (0.236); head length 0.298 (0.307).

## Rule check
- Component 1 (horns) and 2 (hull) raised whole-silhouette IoU and the horn/head band IoU: kept.
- Component 3 (features) lowered the whole IoU by 0.001 (within 0.005) but LOWERED the horn-zone and head band IoU relative to the hull (horn zone -0.009 side / -0.014 back, head band -0.011 side / -0.004 back; tines, brow, crown plates and cheek plates add area outside the reference). I kept it because the features (eyes, brows, jaw, cheeks, crown plates, tines) are what the Lead and inspector asked for, but this is a flagged regression against the strict rule: the hull alone (`p1b_hull/`) is the higher-metric version. The features were individually sunk toward the hull surface and the skull narrowed slightly (SK_HALF 0.115 -> 0.108) to limit the loss; a feature ablation was started (temple tines worth about +0.003-0.01 horn-zone, brow/eyes about -0.012 in the back view) and not completed.

## Known wrong
- The head reads as a boxy block with a separate jaw: the visual hull of two orthographic silhouettes has flat vertical walls; the reference skull/face curvature is not recoverable from silhouettes. Eyes are on the lateral planes and are not visible from straight-on; the straight-on face aspect was not used for width except through the clip.
- Snout: from the side silhouette (droop and thin hooked beak are in the hull), but head length is 0.298 vs 0.307 (smoothing shrinks the tip) and back-view snout extent is 0.213 vs 0.258.
- Hull mouth line (U < 2.045) is a straight cut; the jaw is a thin slab, not a hooked mandible shape beyond what the side mask gives; no fangs.
- Cheek plates are flat polygons and look like shards in the close-ups; crown plates are three stacked ellipse slabs, not the reference's plates; horn cups are simple ellipsoid sleeves.
- Horns: knobs come from distance-transform bumps (smooth rings), not the sharp tine stubs of the reference; A's and B's junction near the arch top in the back view is not modeled as a join; side horn B span +0.022 (clipped reference); A tip height -0.019 side.
- Neck-skull junction is blended over 25 mm only; neck mid back width is +0.01 as in the proxy.
