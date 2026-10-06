# Aruun GATE 1 PROXY: Primary Modeler hand-off (no self-grading; numbers are compare.py output only)

## Files
- Build script (bpy headless, deterministic): `tools/modeling/aruun/v4_proxy/build_proxy.py`
  `python3 tools/modeling/aruun/v4_proxy/build_proxy.py` (needs the `bpy` module) writes `proxy.blend` + `proxy.glb` here.
  `ARUUN_PROXY_STRIPS=0` drops the single strip-mass volume (see "Open decision" below).
- Model: `proxy.glb`, `proxy.blend` (24 swept elliptical tubes/ellipsoids, one flat grey `clay` material, no rig, reference pose).
- Validation renders (exact reference cameras, `tools/fidelity/render_model_views.py proxy.glb --keep-mace`): `renders/sil_{side,back,front}.png`, `renders/clay_{side,back,front}.png`.
- Compare (`tools/fidelity/compare.py --views side back front`): `REPORT.md`, `metrics.json`, `width_error_{side,back,front}.csv`,
  `overlay_{side,back,front}[_large].png` (RED = model only, BLUE = reference only), `sidebyside_{side,back,front}.png`.

Reproduce:
```
python3 tools/modeling/aruun/v4_proxy/build_proxy.py
python3 tools/fidelity/render_model_views.py design/model_sheets/aruun/fidelity/proxy/proxy.glb --out design/model_sheets/aruun/fidelity/proxy/renders --keep-mace
python3 tools/fidelity/compare.py --render-dir design/model_sheets/aruun/fidelity/proxy/renders --out design/model_sheets/aruun/fidelity/proxy --views side back front
```

## What was built
Silhouette volumes only, in the reference pose (arms hanging as drawn), true scale (no height normalisation; top 2.402 m, sole 0.0 m):
- Head: cranium (narrow in depth at the chin row, 0.20 m wide in back), snout tube drooping to a tip at 2.00 m, one flat brow/temple-tine band (single volume, no tine geometry).
- Neck: thin forward-leaning tube (0.11 m deep / 0.12 m wide mid), plus a neck-base/hood hump ellipsoid.
- Horns: A (his RIGHT) thick, short, rising behind then hooking forward; B (his LEFT) thin, long, arching out to image-left in back and forward in side; B inner tooth bar that closes the horn loop seen in the back view.
- Trunk tube (pelvis to neck base, section-by-section from the side/back profiles), red pauldron mass on his LEFT, mantle mass on his RIGHT (kept thin in depth so the side silhouette stays inside the reference).
- Arms hanging: left forearm/fist come forward and hide inside the thigh depth in side (the side silhouette shows no fist below 0.86 m); right fist bottom at 0.86 m.
- Legs: thighs, knees, shins, ankles; wide-apart contrapposto stance from the back view; feet (heel-to-toe 0.41 m) with a flat sole volume.
- One flat "strip mass" volume inside his right thigh (back view only; thin and kept inside the leg depth so the side shows the bare thigh, per ruling 6).

## Compare numbers (final pass)
| view | IoU aligned | IoU dx=0 | model/ref area | mean abs rel width err |
|---|---|---|---|---|
| side | 0.874 | 0.873 | 1.05 | 0.081 |
| back | 0.881 | 0.881 | 1.02 | 0.077 |
| front (3/4, qualitative only) | 0.583 | 0.427 | 0.85 | 0.305 |

Without the strip mass (`ARUUN_PROXY_STRIPS=0`): side 0.873, back 0.864.
Baseline v3 for reference: side 0.697, back 0.852.

History (commits on worktree-agent4): v0 0.761/0.763, v1 0.81/0.835, v2 0.859/0.855, v3 0.862/0.855, v4 0.874/0.881, final 0.874/0.881 (horn spans and neck-mid width improved at the same IoU).

Spec measurements (ref -> model, m): total height 2.400 -> 2.402; head length nape..snout 0.307 -> 0.303; snout from eye 0.130 -> 0.127;
foot length 0.416 -> 0.410; side thigh depth 0.192 -> 0.200; side shin depth 0.117 -> 0.122; neck top depth 0.108 -> 0.111; neck mid depth 0.115 -> 0.123;
back shoulders 0.625 -> 0.617; back waist 0.743 -> 0.746; back pelvis 0.784 -> 0.772; back shin span 0.606 -> 0.603; back head width 0.210 -> 0.216;
back hand bottom 0.772 -> 0.750; horn A span back 0.103 -> 0.113, side 0.217 -> 0.198.

## Five largest remaining errors (compare.py ranking, side+back)
1. side horn_B span 0.183 ref -> 0.237 (+0.054). The reference value is a LOWER BOUND (horn B is clipped by the canvas edge; ruling 2), so part of this is expected.
2. side chest-to-back depth 0.513 -> 0.460 (-0.053). The reference front extreme (0.268 m at 1.45 m) is the hanging shoulder tassel (part 33, SECONDARY). The proxy has no tassel by brief. Torso front without the tassel is within about 0.01-0.03 m.
3. back horn_B span 0.290 -> 0.250 (-0.041), and back horns total spread 0.393 -> 0.363 (-0.031). The B arch tip does not reach far enough out to image-left at the top.
4. side neck-base depth 0.245 -> 0.280 (+0.034). The neck-base/hood hump is slightly too deep. Back neck-mid width is still +0.020.
5. Horn tip heights: A is 2.367 in side (ref 2.400) and 2.393 in back (ref 2.362). The reference views disagree by 0.04 m (spec section 7). The proxy is a compromise inside ruling 5's +-0.03 tolerance in both views.

Per-slice edge errors (width_error_*.csv) are within +-0.03 m almost everywhere. The exceptions:
- side 1.46 m front (-0.075): the tassel.
- side top slice 2.376-2.40 xmin (+0.146): only horn B reaches the top slice. Horn A was kept lower for the back view.
- back 1.39 m image-left (-0.034): the upper-arm / elbow-disc step.
- back 0.17 m (feet/ankle about 0.025).

## What is known to be wrong or unmatched, and why
- Horn topology is approximate. In the back view the reference horns form a closed loop. B's inner tooth bar crosses toward A and hooks down. The side view shows two separate forward arcs. One 3D path per horn cannot match both views exactly with these thin tubes: small offsets cost IoU, and the A/B tip heights conflict between views.
- Side view handedness (ruling 1): the side shows a red pauldron and no mantle. I followed front+back: mantle on his RIGHT, pauldron on his LEFT. The mantle is kept thin in depth so it does not break the side silhouette. If the creator says there are pauldrons on both shoulders, the right shoulder mass needs revisiting.
- Strip mass (open decision for the Lead): the back view has a large ragged-strip region inside his right thigh (about 0.02 m² of silhouette, worth +0.017 back IoU). The brief says no skirt strips. I represented it as ONE flat volume, not strips, with a toggle to remove it.
- Left fist position is inferred. Back shows the image-left fist bottom at 0.77 m. Side shows nothing behind the thigh below 0.86 m, so the left forearm comes forward and the fist hides in the thigh depth. The proxy's back hand bottom is 0.750 (-0.022).
- Not modeled by design (Gate 1): tassels, fringe, tines as separate pieces, nape fringe, elbow disc as its own piece, armour plates, claws, Morrow. The silhouette bumps these cause in the reference remain as blue areas in the overlays.
- Front 3/4 is not matched (IoU 0.58). It was used qualitatively only; it is a different pose (3/4, head in profile).
- Shapes are smooth tubes. Edge raggedness in the reference (fringe, strips, horn knobs) cannot be matched at proxy level, so it caps IoU at roughly this level without adding detail.
