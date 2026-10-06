# HEAD v6 handoff (head specialist)

Files: `head_v6.blend`, `head_v6.glb` (head objects only, clay). Code: `tools/modeling/aruun/v6_head/` (`run_step.sh N`, `measure.sh`, `export_head6.py`). Renders per step: `step1..4/` (P1b framing, 0.62 m ortho), `step4_tight/` (0.30 m), each with `compare.png` (top: reference crops front-calm-tile / v2 side / focused_34 / v2 back; bottom: model). `band_diff.png` = head-band silhouette diff (red ref-only, blue model-only). `depth/` = Depth Anything V2 small maps.
Objects: skull, mandible (origin = jaw pivot F 0.03, U 2.03, L 0.09), eye_L/R, brow_L/R, cheek_L/R (+cheek2_L/R snout plates), crown_plates (3 stepped plates joined), temple_tine_L/R, nose_pad, nostril_L/R, horn_cup_A/B, nape_fringe_L/C. Frame: blender (L, -F, U) like P1b; head line L = 0.09. Context body/neck/horns in the measuring scene are the untouched LOCKED_P1b objects.

## Method
1. Depth: DA-V2-Small on all head refs (profile, side, back, front, rage, 34s, v2 calm/rage faces; ~6 s each on CPU). Maps are blobs (flat painting): they find the brow band along eye -> muzzle, cranium dome, lower cheeks, but give no usable absolute shape. Used ONLY on the registered v2 side head crop (depth px map to F,U exactly): high-pass (gauss 9 - gauss 45), normalised, displaces skull vertices +-5 mm along the normal weighted by the lateral normal component (`head6.depth_relief`, env DEPTH_AMP=0 disables). A first try with a finer high-pass (3/30 px) looked like noise and was dropped.
2. Skull: ONE loft (cranium+muzzle, 31 super-ellipse rings, 28 verts each, subsurf 3) from hand profiles (top/bottom/half-width/exponent vs F) read off the v2 side crop and masks; skull core is deliberately smaller than the mask, plates/tines supply the rest of the silhouette. No seam.
3. Sockets = smooth dents + raised rim in the skull mesh; eyes oriented to the surface normal; brows = swept tubes whose centreline is ray-projected onto the skull around each eye.
4. Mandible = separate loft hooked at the tip, profile fitted to the side mask (top/bottom runs at F 0.045-0.196).
5. Plates (cheek, crown) = polygons subdivided, projected on the skull by BVH rays (radial from head axis for cheeks, vertical for crown), lifted 3-11 mm, solidified inward 7-11 mm, so they are rooted. Tines/cups/fringe = tubes that start inside the skull.

## Numbers (head band 1.75-2.0 m, v2 masks, whole scene incl. P1b neck/body)
side IoU 0.846 (gate 0.82 ok), back 0.835 (gate 0.85 NOT met). Skull-only band 1.96-2.14: side 0.864, back 0.836; 2.0-2.14: side 0.870, back 0.858. Most remaining back error in the 1.75-2.0 band is the P1b NECK/shoulder edge (red/blue on the neck sides in `band_diff.png`), not the head. Head length ~0.30 m (nape fringe to jaw hook), skull half-width 0.107 (spec 0.105).
Meshes: skull 54.6k polys, mandible 17k (needs decimate for production).

## Known wrong
- Still reads as a rounded, bulbous skull; the painted head is angular/faceted with a longer, slimmer, more strongly drooping snout and a hooked jaw that meets the upper jaw. Mouth gap follows the mask (open look from front/3-4).
- Eyes are plain ellipsoids (no slanted almond, no pupil ring); brows are simple tubes, no tan strip/angular plate look. Front view has no orange crown shield, no cream V nose plates, no dark jaw wedge.
- Cheek plates are soft raised pads rather than crisp angular plates; crown plates read as a helmet strip with a visible dark gap line.
- Horn cups are placeholder collars (horn A root sits ~2 cm outside the skull edge in P1b curves); olive/yellow nape fringe hair is only 2 tapered spikes.
- Depth prior contribution is small (mild brow/cheek undulation); side-only, no front/back depth fused. TripoSR volume prior not tried (time-box).
- Back band gate 0.85 not met in the 1.75-2.0 band (neck-dominated).
- Mandible not skinned/tested through a jaw rotation; plates are separate meshes (not welded).
