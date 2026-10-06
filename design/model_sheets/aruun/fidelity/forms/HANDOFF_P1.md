# HANDOFF P1 (Gate 2, pass 1: head, horns, pauldron/shoulder blades). Primary Modeler. No self-grade; numbers are compare.py output.
Base = the Gate-1 proxy after correction round 3 (tools/modeling/aruun/v4_proxy/build_proxy.py = LOCKED_BASELINE_03, IoU side 0.876 / back 0.884). Note: LOCKED_BASELINE_02 on disk predates round 3; I built on the later proxy because it is the one the Gate 1 decision measured (0.876/0.884). Both are saved.

## Files (design/model_sheets/aruun/fidelity/forms/)
- `LOCKED_P1/`: `forms.blend`, `forms.glb` (clay grey, 42 named objects), `build_forms_P1.py`, `closeups/` (head and shoulder, front/side/3-4/back, clay + 'parts' colour-coded debug), `compare_orig_ref/` and `compare_v2_ref/` (REPORT.md, metrics, overlays, side-by-sides, renders/ at the reference cameras incl. sil_ and clay_ side/back/front).
- `stage1_head/`, `stage2_horns/`, `stage3_shoulders/`: the cumulative snapshot after each form (same layout). One commit per form. stage1/stage2 were built before the final SKULL_L_SCALE tweak (see below).
- Code: `tools/modeling/aruun/v5_forms/build_forms.py` (FORMS_STAGE=0..3), `run_stage.sh` (build + render + compare against BOTH references), `render_closeups.py` (Cycles CPU, orthographic).
- Reference config: `tools/fidelity/fid_common.py` honours `FID_REF=v2` (v2 completed side/back masks, axis 536/759, width 1147/1659) and defaults to the original cuts. Both are reported; run render_model_views.py and compare.py with the same FID_REF value.
Reproduce: `tools/modeling/aruun/v5_forms/run_stage.sh 3 <outdir>`.

## IoU (aligned), proxy -> after each form
| stage | side orig | back orig | side v2 | back v2 |
|---|---|---|---|---|
| proxy (stage 0) | 0.876 | 0.884 | 0.876 | 0.884 |
| + head | 0.875 | 0.884 | | |
| + horns | 0.876 | 0.883 | | |
| + pauldron/blades (final) | 0.874 | 0.882 | 0.873 | 0.881 |
No form lowered side or back IoU by more than 0.005 (largest cumulative: side -0.002, back -0.002).

## What was built
1. HEAD (separate objects): `skull` (the measured proxy cranium, narrowed 15% in L below the crown plates because the face features carry width now), `muzzle_upper` (thick root, long taper, droop), `nose_pad`, `nostril_L/R`, `mandible` (separate lower jaw with the hooked chin; its object origin is the JAW PIVOT at F -0.02, U 2.02, L 0.09 so it can rotate to open), `eyeball_L/R` (on the SIDES of the skull, ready for a material), `brow_L/R`, `cheek_plate_L/R`, `crown_plate`, `horn_cup_A/B`. Snout tip, head length and skull top unchanged: head length 0.302 vs ref 0.307 (proxy 0.304); snout tip height 2.011 vs 2.008.
2. HORNS: `hornA_knob1/2`, `hornB_knob1/2` (knobbed joints), cream tines at the temple: `temple_tine_L` (long, to L 0.245) and `temple_tine_R` (short, to L -0.08), as in the back head crop. horns.solid_width side 0.122 / back 0.113 (ref 0.119 / 0.113-0.119); spans unchanged: back B 0.284 (ref 0.290), back A 0.112 (0.103), side A 0.217 (0.217), side B 0.202 (0.183, lower bound).
3. PAULDRON: `pauldron_disc` (red ladybug disc, same measured envelope as the proxy ellipsoid) + `pauldron_underplate` (tan plate under it) on his LEFT only; `shoulder_blade_L/R` (tan carapace plates on the back, 1 cm proud). No second pauldron (question still open).

## Measured regions, proxy -> final (orig reference; v2 reference gives the same within 0.001)
| region | ref | proxy | final |
|---|---|---|---|
| side head.outer_width | 0.226 | 0.228 | 0.233 |
| side snout.outer_width | 0.236 | 0.241 | 0.248 |
| back head.outer_width | 0.210 | 0.214 | 0.218 |
| back head.extent (tines) | 0.331 | 0.275 | 0.326 |
| back shoulders.outer_width | 0.625 | 0.617 | 0.629 |
| side shoulders.outer_width | 0.402 | 0.417 | 0.418 |
Regions that got slightly worse (+0.005 to +0.012 m, inside the +-0.015 tolerance of the head metrics): side head/snout outer width, back head outer width. Cause: eyes, cheek plates and brows protrude from the skull. I reduced this by narrowing the skull (0.92 -> 0.85 scale) and lowering the muzzle top; further reduction would flatten the face features.
Improved: back head.extent 0.275 -> 0.326 (temple tines), back shoulders -0.008 -> +0.004.

## Known wrong / not matched
- The face reads as a face (muzzle, nostrils, eyes on the sides, brows, cheeks, jaw) but proportions of sockets, brow shape, mandible hook curve and cheek plate shapes are approximations of the 60 px source faces; the straight-on face width at the cheeks was not measured (generated, low confidence).
- The crown/skull still has the flat-topped proxy cranium; the red crown plates are one flat ellipsoid, not the separate plate pieces of the reference.
- Horn bone tines on the shafts were dropped (they widened the back horn A span by 0.04 m); knobs are small rings, not the jointed segments of the reference.
- Side view: occiput overhang (about 0.025 m at 2.08-2.13 m) and snout-root front depth (+0.015 at 2.04) from the proxy are unchanged.
- Pauldron has no yellow spot, black pits or tan rim (material/detail stage); shoulder blades are plain ellipsoid plates, not the carapace shapes of the parts images.
- Mantle, hands, feet, chest wrap/belt, thigh/knee plates, skirt strips, fringe: untouched (later passes).
- `snout.extent` (back) is -0.029 vs ref (mandible/muzzle narrower in the back view than the reference snout, which includes cheek flare).
