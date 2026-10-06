# Baseline v3 (current game/art/models/aruun/aruun.glb) vs reference. No opinion, numbers from tools/fidelity.

Reproduce (about 20 s CPU, deterministic):
```
python3 tools/fidelity/extract_ref_silhouettes.py
python3 tools/fidelity/render_model_views.py game/art/models/aruun/aruun.glb --out design/model_sheets/aruun/fidelity/baseline_v3/renders
python3 tools/fidelity/compare.py --render-dir design/model_sheets/aruun/fidelity/baseline_v3/renders --out design/model_sheets/aruun/fidelity/baseline_v3 --views side back front
python3 tools/fidelity/make_spec.py      # regenerates CHARACTER_SPEC.md / character_spec.json
```
Files: `REPORT.md` (all region tables), `metrics.json`, `width_error_{side,back,front}.csv` (100 slices, signed), `overlay_*.png` (RED = model only, BLUE = reference only), `sidebyside_*.png`, `renders/` (sil_/clay_ at the reference framing).
Model rendered at true scale (height 2.382 m, top 2.383 m, no rescale), Morrow mace islands dropped (reference has none), rest pose. Horizontal offset aligned by best silhouette IoU (the glTF origin is not the reference axis).

| view | IoU aligned | IoU at dx=0 | dx | model/ref area | mean abs rel width err |
|---|---|---|---|---|---|
| side | 0.697 | 0.535 | -0.076 m | 1.26 | 0.667 |
| back | 0.852 | 0.843 | +0.007 m | 1.02 | 0.139 |
| front (3/4 ref, qualitative) | 0.575 | 0.457 | +0.143 m | 0.85 | 0.301 |

(Earlier ARTLOG quotes IoU 0.90/0.93 for the v2 fit; the v3 face-first rebuild measures lower with this tool; edge error of the tool is +-0.004 m, so the gap is real.)

## Five largest measurable deviations (side+back, distinct regions, err = model - reference)
1. SIDE thigh depth (band 0.596-0.894 m): ref 0.192 m, model 0.586 m, +0.395 m (+206%). The model hangs a box-like skirt panel on his right side; the reference side view shows bare thigh plate, no skirt (pelvis band also +0.190 m). Back view thigh/pelvis widths are within 0.016 m, so this is depth only.
2. HEAD length nape-to-snout tip (side): ref 0.307 m, model 0.644 m, +0.336 m (+109%). Model brow/crest tines sweep far back and the muzzle is long; of this snout length from the eye is ref 0.130 m vs model 0.268 m (+0.138 m, 2x). Head width (back, mean) ref 0.210 vs model 0.311-0.332 (+0.12 m, +58%) with the nape fringe flaring wide.
3. HORN A depth span (side): ref 0.217 m, model 0.369 m, +0.152 m (+70%); back-view spreads: horns total 0.393 ref vs 0.444 m (+0.051 m), B span +0.034 m, A span +0.017 m; tip height model 2.383 vs ref 2.40 (-0.017 m); see overlay_back.png / overlay_side.png for where the horn curves leave the reference.
4. NECK top depth (side, rows 1.92-1.97 m): ref 0.108 m, model 0.256 m, +0.147 m (+136%); neck mid is close (+0.009 m), neck base -0.025 m: the model neck is not the thin forward-leaning column, the jaw/throat merges into it.
5. FOOT length heel-to-toe (side): ref 0.416 m, model 0.549 m, +0.133 m (+32%) (long claw spikes past the toe and a heel spike); foot width equal (+0.012 m).

Not ranked (not like-for-like): arm length: back-view hand bottom ref 0.772 m, model 0.629 m (-0.143 m; model arm in A-pose carries the hand 0.14 m higher/out); shoulders back width +0.011 m, waist +0.006 m, torso +0.017 m, pelvis +0.016 m: the trunk widths in the back view already match to within 2-3%. Side shoulder depth +0.064 m, waist depth +0.067 m, chest-to-back depth +0.057 m.
