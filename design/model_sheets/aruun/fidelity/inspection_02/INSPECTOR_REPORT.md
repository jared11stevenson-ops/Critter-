# Inspector report, inspection_02 (blind, silhouette proxy)

Method: own overlays (ref alpha>128 opened 3 px; clay = pixels <200 grey; ground row 4000, 1626.667 px/m, no height rescale; horizontal best-fit IoU). Colours: red = model only, blue = reference only, grey = both.
Overall: height 2.399 m model vs 2.400 m ref (exact). IoU side 0.869, back 0.882 (front 0.58, non-ortho, qualitative only). The proxy is close; remaining errors are 2-10 cm local shape errors. Overlays: evidence/overlay_side.png, overlay_back.png, overlay_front.png (front misaligned by design).
Caveat checks: ref halo is ~3 px so any claim below is >= 15 px; no claimed ref part touches the canvas edge (side ref canvas right edge x=2153, hand at x~2075).

## Ranked correction tickets

### T1. REGION: Horn A (thick/short/red), side view
SEVERITY 6. ERROR TYPE: thickness + length/tip.
REFERENCE: horizontal run width of horn shaft 106 px (y=310) / 112 px (y=360) / 151 px (y=410) = 6.5-9 cm; shaft continues ~50 px farther forward and ~60 px higher at the tip than model (tip at crop (610,50)).
CURRENT MODEL: 72 / 70 / 72 px = 4.4 cm; tip ends ~50 px short in x and ~70 px (4 cm) lower. Blue rim on both sides of the shaft.
REQUIRED CORRECTION: thicken horn A shaft ~1.45x (about +2 cm across the mid shaft), lengthen/raise the tip by ~4 cm, keep base position.
MAGNITUDE: 30-45% width, ~4 cm tip (side). Evidence: evidence/crop_side_head.png.

### T2. REGION: Horn B (thin/long/cream) path and loop, back and side views
SEVERITY 6. ERROR TYPE: curve path / loop placement.
REFERENCE (back): horn sweeps out left and then curls into a lower closed loop; loop interior (negative space) sits ~60 px (3.7 cm) below the model's arc; the outer sweep ends at x=1268 (y=160). REFERENCE (side): mid-horn runs 20-50 px (1.2-3 cm) right of model for y=260-460, and the loop tip ends ~35 px right/up of the model loop.
CURRENT MODEL (back): horn B arcs over in a high rounded bridge (red arc, top at y~100) with its distal part hooked right; (side) mid shaft 36-49 px too far back (more upright), loop displaced.
REQUIRED CORRECTION: lower the distal loop ~3.5 cm, restore the ref curl direction (reference curls down/inward, model arches over), shift side-view mid-shaft forward 2-3 cm.
MAGNITUDE: 2-4 cm along path (both views). Evidence: crop_back_head.png, crop_side_head.png.

### T3. REGION: Crotch / leg gap and right inner thigh, back view
SEVERITY 5. ERROR TYPE: negative-space shape.
REFERENCE: gap apex (top) is at y~2454 (0.95 m) at x=1760, and the gap ceiling slopes diagonally down to the right (2562 at x=1800, 2715 at 1850, 2793 at 2000). Viewer-right thigh inner edge runs as a long diagonal to the knee: inner edge at 2076/2045/2008 px at 0.45/0.55/0.65 m vs 2210/2138/2056 for the model (133 px = 8 cm at 0.45 m). May partly be fringe, but it is a 9 cm x 0.5 m solid wedge.
CURRENT MODEL: flat horizontal gap ceiling at y=2592 (0.865 m), with a visible straight shelf 170 px wide; inner thigh nearly vertical.
REQUIRED CORRECTION: raise crotch apex ~8-9 cm, make ceiling an inverted V sloping toward the viewer-right leg, widen right thigh inner mass toward the gap (wedge up to ~8 cm at 0.45 m).
MAGNITUDE: apex 138 px (8.5 cm); wedge up to 133 px (8 cm). Evidence: crop_back_legs.png.

### T4. REGION: Viewer-right trapezius / neck base, back view; nape hump, side view
SEVERITY 4. ERROR TYPE: slope/volume.
REFERENCE (back): at 1.85 m the section spans x 1640-1849 (209 px); right shoulder slope starts lower. (side): upper back/nape hump is flatter; ref xmin at 1.55 m is 1285 vs 1248.
CURRENT MODEL (back): width 355 px (1664-2019) at 1.85 m, shoulder-neck junction ~60 px (3.7 cm) too high, red wedge up to 170 px (10 cm) wide; (side) back at 1.55 m is 37 px (2.3 cm) too far back, red hump ~50 px (3 cm) along the nape/upper back.
REQUIRED CORRECTION: lower right trapezius top ~3.5 cm and bring slope in toward the neck; trim upper back ~2.5 cm in side view.
MAGNITUDE: 3-4 cm height, 10 cm width of wedge (back); 2-3 cm (side). Evidence: crop_back_torso.png, crop_side_torso.png.

### T5. REGION: Forearm/hand projection, side view
SEVERITY 4. ERROR TYPE: missing silhouette feature.
REFERENCE: a forearm/hand curl leaves the torso forward at y~1330-1480 (1.55-1.62 to 1.55 m region ~0.9-1.0 m rows) reaching x=2075, ~85 px (5 cm) past the belly front line (1989); ~60 px thick.
CURRENT MODEL: arm is fully inside the torso silhouette; no forward protrusion.
REQUIRED CORRECTION: swing the forearm/hand forward ~5 cm beyond the torso front, or add elbow flexion (forearm slightly forward).
MAGNITUDE: 5 cm protrusion x ~8 cm tall (side). Evidence: crop_side_torso.png (blue curl, right side).

### T6. REGION: Snout and skull, side view
SEVERITY 4. ERROR TYPE: thickness / back-of-skull volume.
REFERENCE: snout upper plane and jaw underside ~25-30 px (1.7 cm) thinner than model near mid snout; occiput 30 px (2 cm) smaller.
CURRENT MODEL: skull back bulge 30 px too far back (crop (110-215, 480-700)); snout 40-50 px (2.5-3 cm) too deep, with red on both upper and lower edge. Tip position matches.
REQUIRED CORRECTION: reduce skull rear ~2 cm and snout depth ~2.5 cm total.
MAGNITUDE: 2-3 cm (side). Evidence: crop_side_head.png.

### T7. REGION: Lower leg calf and heel, side view; calf inner, back view
SEVERITY 3. ERROR TYPE: contour.
REFERENCE (side): heel/lower-shin back edge x=1260 at 0.15 m, 1300 at 0.25 m; shin front edge 20-40 px closer; foot sole has an arch and is flat to ground at 3999. (back): viewer-left calf inner edge 1699 at 0.35 m, 1746 at 0.45 m.
CURRENT MODEL: heel back 31/33 px (2 cm) too far back at 0.15/0.25 m; shin front 25-40 px (2 cm) too forward; arch filled (red ~25 px under mid-foot); sole at 4002 (3 px below ground); back-view left calf inner edge 71/56 px (4 cm) too far into the gap.
REQUIRED CORRECTION: pull heel/Achilles forward ~2 cm, slim shin front ~2 cm, carve a foot arch ~1.5 cm, slim viewer-left calf inner side ~3-4 cm.
MAGNITUDE: 2-4 cm. Evidence: crop_side_legs.png, crop_back_legs.png.

### T8. REGION: Left arm-to-torso gap, back view
SEVERITY 2. ERROR TYPE: negative-space width.
REFERENCE: slit between viewer-left arm and torso 54 px (0.95 m) / 48 px (1.05 m), ~3 cm.
CURRENT MODEL: 24 px / 12 px, ~1 cm.
REQUIRED CORRECTION: open the gap ~2 cm (arm out or torso narrower there).
MAGNITUDE: 1.5-2 cm. Evidence: overlay_back.png.

### T9. REGION: Front 3/4 (qualitative only)
SEVERITY 2. REFERENCE: head turned in profile, thick horn hooked crescent, viewer-left arm pointing out and back, and trailing skirt/fringe widening the lower silhouette; CURRENT: head, horn cone and arms straight under an orthographic front. Not scoreable (non-ortho); only note the model's horn A in the front render is a straight cone while ref horn A is a crescent that hooks. Evidence: evidence/front_sidebyside_qualitative.png, overlay_front.png.

## Scorecard (silhouette proxy)

| Category | Score | Evidence |
|---|---|---|
| Silhouette /25 | 20 | IoU side 0.869, back 0.882 despite unmodelled fringe/tassels; main losses T3 gap wedge, T1/T2 horns, T4 shoulder. |
| Proportions /20 | 17 | Height 2.3988 vs 2.4000 m; landmark rows (head top, shoulder, hip, knee, ground) agree within 2-5 cm; widths: side depth 0.586 vs 0.582 m, back span 0.868 vs 0.896 m (-3%, partly fringe); crotch 8.5 cm too low (T3). |
| Head-Neck-Horns /15 | 9 | Neck width (side 178 vs 183 px at 1.95 m) and snout tip good; horn A 30-45% thin (T1), horn B path/loop 2-4 cm off (T2), snout/skull 2-3 cm heavy (T6). |
| Anatomy-Limbs /10 | 7 | Limb widths within 2-4 cm except right inner thigh wedge, calf, forearm projection (T3, T5, T7). |
| Asymmetry /5 | 4 | Back-view asymmetries (horn pair, differing leg/arm outlines, shoulder bias) all reproduced in sign; magnitudes off per T3/T4. |
| Total (of 75) | 57 | |

Evidence folder: inspection_02/evidence/ (overlay_side/back/front, crop_side_head, crop_back_head, crop_side_torso, crop_back_torso, crop_side_legs, crop_back_legs, front_sidebyside_qualitative).
