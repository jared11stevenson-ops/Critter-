# INSPECTOR REPORT (blind, proxy stage) - inspection_01

Method: reference alpha masks and current clay masks aligned at the same pixel scale (1626.667 px/m, ground row 4000) with horizontal best-fit IoU search (side shift 1205 px, back 1201 px). Overlays: red = reference only, blue = current only, grey = both. Overall silhouette IoU: side 0.872, back 0.881 (XOR = 14.1% side / 12.9% back of reference area); front is a 3/4 pose, qualitative only. Reference halo/jagged edges mean sub-2% width differences are ignored. Armor, fringe, tassels, materials are NOT criticised.

Evidence images (evidence/): overlay_side.png, overlay_back.png, overlay_front.png, side_head_horns.png, back_head_horns.png, side_torso_arms.png, back_torso_arms.png, side_legs_feet.png, back_legs_feet.png, front_qualitative_ref_vs_current.png. Crops are 3 panels: reference | current | overlay, green ticks = height in m.

## Ranked correction tickets

### T1 Horns (A and B), overall layout
- REGION: horns (both views). SEVERITY 9. ERROR TYPE: shape / placement / thickness
- REFERENCE: back view: the two horns form a connected antler frame (a closed loop at ~2.15-2.34 m between the horn roots and a joined crown at 2.40 m); horn limbs are thin (~35-60 px, 2-4 cm) with knobbed joints and spurs. Side view: both horns sweep up and forward, thin and bone-segmented, tips at 2.40 m (B tip x~2141 px) with an open C-hook.
- CURRENT MODEL: horns are two unrelated tubes. A is a straight fat vertical stub (back view: ~110 px/6.8 cm wide, ends in a blunt point at ~2.37 m, right of the head), B a long thick diagonal sweep that crosses the head and ends in a loose curl; no loop/negative space between them. Side view B ends in a closed loop/hook reaching x=2181 vs ref 2151 (+30 px, +1.8 cm in extent, top 6 px higher) and the horn limbs are ~2x as thick (e.g. row 300 side: cur width 247 px vs ref 163, +52%; back row 400: +58%).
- REQUIRED CORRECTION: thin both horns to ~40-60 px; re-route A and B so they join into the reference's antler loop in back view (red-only region ~90x180 px between horns, back crop) and sweep forward in side view; shorten B's curl.
- MAGNITUDE: horn-region XOR ~45% of horn area (back); tip positions off by 30-60 px (1.8-3.7 cm); thickness +50-100%. Crops: back_head_horns.png, side_head_horns.png.

### T2 Head: flat brim disc and head mass
- REGION: head/skull/snout. SEVERITY 8. ERROR TYPE: invented shape / wrong shape
- REFERENCE: back view head is a narrow tapered wedge (~1.97-2.15 m) with small ear/antler spurs; side view head is a compact skull with a hooked, downward-drooping muzzle.
- CURRENT MODEL: a flat elliptical brim (hat-like disc) at 2.09-2.13 m, ~470 px wide in back view (reference widest point at that height ~ +-200 px, spurs only); the disc overhangs on both sides (blue at both ends of the brim). In side view the same disc becomes a pointed flat wedge snout sticking out horizontally at 2.03-2.11 m and ending at x=2150 with a flat vertical cut, vs the reference's drooping curved muzzle that ends lower (~2.0 m). Skull is a rounded blob (blue lobe at back of head ~60 px beyond reference).
- REQUIRED CORRECTION: delete the brim disc; model snout as a downward-curving tapered form; reduce occiput bulge; head width in back view per reference wedge.
- MAGNITUDE: brim ~+120 px (7 cm) each side in back view; snout tip height ~+6 cm too high; XOR on head region ~35%. Crops: back_head_horns.png, side_head_horns.png.

### T3 Neck
- REGION: neck. SEVERITY 6. ERROR TYPE: proportion/shape
- REFERENCE: back view neck is a near-vertical column x 1645-1830 (width 185 px at 1.91 m, 11.4 cm), straight into the shoulders. Side view neck width ~175-200 px.
- CURRENT MODEL: back neck tapers outward and leans (width 206 px at 1.91 m, +11%, and tilts ~12 deg so the base is shifted right ~25 px). Side view neck at 1.84 m is 263 px vs 202 px (+30%, row 1000) because the neck-chest transition starts too high. Neck-head notch in side view (ref concave notch behind skull at 2.0 m) is almost absent.
- REQUIRED CORRECTION: straighten neck axis; reduce root flare 20-30 px per side; restore the neck-head notch.
- MAGNITUDE: +11% width (back), +30% (side at 1.84 m). Crop: back_head_horns.png (bottom), overlay_side.png.

### T4 Shoulders / upper torso (side)
- REGION: shoulder, chest, back line. SEVERITY 6. ERROR TYPE: proportion
- REFERENCE: side shoulder crest peaks near x~1340 at 1.78 m; back line is nearly straight; chest front is flatter.
- CURRENT: rear shoulder/trapezius bulges ~40-45 px (2.6 cm) further back at 1.60-1.84 m (blue band on left of side_torso_arms.png) and the chest front bulges ~+50 px at 1.60-1.72 m (row 1300: width 682 vs 628, +9%). In the back view, the shoulder/arm at 1.84 m has a ~170 px wide extra block (row 1000: 385 vs 217 px, +77%) = shoulder starts ~7 cm too high.
- REQUIRED CORRECTION: drop/flatten shoulder line ~7 cm at the right shoulder in back view; trim posterior trapezius bulge 40 px; flatten chest.
- MAGNITUDE: +6-9% width (side), +77% at row 1000 (back). Crops: side_torso_arms.png, back_torso_arms.png.

### T5 Arms and hands (side + front)
- REGION: arms, forearm, hand. SEVERITY 7. ERROR TYPE: missing/invented shape, asymmetry
- REFERENCE: in side view the near forearm sweeps forward out of the torso at 1.54-1.41 m ending in a hooked hand x=2067 (red hook, ~100 px long, 6 cm). In the front, left arm hangs with a long forearm to ~0.85 m, with the hand held forward by the knee; right (far) arm swung wide and out to the viewer's left with the hand at ~0.7 m.
- CURRENT: that forearm/hand is absent in side view (red-only hook ~110 px, row 1600: ref 3 runs spanning 1292-2067 vs cur single run ending 1962, i.e. -105 px reach). In the front the arms are straight tubes hanging parallel to the torso with a heavy rectangular cuff/box on the left forearm (~200 px, 12 cm wide, ends abruptly at ~0.95 m) and a stub hand on the right (~0.93 m). Arm silhouette lacks the elbow bend and the lateral flare/asymmetry of the reference.
- REQUIRED CORRECTION: bend the near elbow forward ~35 deg and extend the forearm+hand to x ~ +105 px forward of the torso (side); remove box cuff; make arms asymmetric as in reference.
- MAGNITUDE: -105 px (6.5 cm) forward reach (side), arm lengths differ from reference by approx -15 to -20% in front. Crops: side_torso_arms.png, front_qualitative_ref_vs_current.png.

### T6 Rear leg silhouette in back view (thigh/knee/gaps)
- REGION: pelvis, thighs, knees, inter-leg gap. SEVERITY 6. ERROR TYPE: proportion / negative space
- REFERENCE: back view at 2.8-3.0 px rows (0.74-0.61 m) the gap between legs is 304 px at row 2800 and narrows to 159 px at row 3000 (crossing legs, calves close together near knees), then opens to 419 px at 3400.
- CURRENT: gap is 179 px at row 2800 (-41%), 256 px at row 3000 (+61%), 542 px at 3400 (+29%). The legs are tubes with no knee wedge; thighs/hips 8-10% too wide at rows 2800-2900 (+21%/+10%), then calves 13-16% too narrow at rows 3000-3200.
- REQUIRED CORRECTION: re-aim the knee line so the legs converge at row ~3000 (0.61 m); thicken calves by ~100 px at 0.5-0.6 m; slim pelvis/hip by ~100 px at 0.74 m.
- MAGNITUDE: gap errors -41%/+61%/+29% (back); width -16% calf, +21% thigh. Crop: back_legs_feet.png.

### T7 Foot and ankle (side + back)
- REGION: feet. SEVERITY 5. ERROR TYPE: shape
- REFERENCE: side: ankle bulge at 0.18 m then boot with instep step and rounded toe tapering at 0.04 m, heel round.
- CURRENT: block heel with a vertical cut at the back and a flat-sole wedge: sole extends below ref by ~15 px, toe is a straight pointed wedge (ends at x ~1896, ref 1888, but top profile 25-30 px too high over the instep); heel is a hard rectangle (blue at rear at 0.00-0.16 m, ~18 px). Ankle sits as an hourglass narrower by 40 px at 0.20 m. Back view: foot pads are round balls, ~35-60 px wider (row 3800: 734 vs 605, +21%) and flatter.
- REQUIRED CORRECTION: round heel, add instep step, rise toe taper, trim back-view foot width by 20%.
- MAGNITUDE: +21% foot width (back, 0.12 m), +/-25 px profile errors (side). Crops: side_legs_feet.png, back_legs_feet.png.

### T8 Shin/calf curvature (side)
- REGION: knee and lower leg. SEVERITY 4. ERROR TYPE: curvature
- REFERENCE: front shin edge has a knee notch at 0.74 m and a rear calf bulge at 0.5 m, thinning at 0.31 m (row 3500: 130 px).
- CURRENT: smooth S-curve; shin too thick at 0.25 m (row 3600: 218 vs 153, +42%) and the calf's rear line sits ~25-40 px too far right (blue stripe 0.25-0.70 m); knee front is ~45 px too far forward at 0.8-0.68 m (+17%).
- REQUIRED CORRECTION: shift calf rear edge forward ~30 px, thin ankle zone ~65 px, bring knee forward bulge in.
- MAGNITUDE: up to +42% width at 0.25 m, +17% at 0.7 m (side).

### T9 Waist / hip / seat (side)
- REGION: waist and buttock. SEVERITY 4. ERROR TYPE: contour
- REFERENCE: rear line straight with small break at 0.9 m; skirt-like front.
- CURRENT: buttock arc bulges ~15-45 px behind ref at 0.95-0.86 m and the front belly runs ~40 px too far (row 2500: front 1877 vs 1916 = -39 px, belly below 0.92 m too short). Global dW within +-3% at 1.0-1.3 m (good).
- REQUIRED CORRECTION: trim buttock bulge 20 px; extend front hip contour 40 px at 0.92 m.
- MAGNITUDE: 1-2.5 cm. Crop: side_torso_arms.png.

### T10 Front view (3/4) qualitative
- REGION: head pose, shoulders. SEVERITY 5. ERROR TYPE: pose / proportion
- REFERENCE: head in profile, snout pointing to viewer's left, neck long and leaning forward ~12 deg, wide pauldron shoulders (~1.3x torso waist width), tapering to a narrow waist.
- CURRENT: head faces the camera with a round muzzle, box-barrel torso with no shoulder/waist taper, torso width roughly constant (waist not narrower than the chest) and left arm shorter. Horns are mirrored in character (A a short upright stub vs ref's long arched red crescent in this view).
- REQUIRED CORRECTION: confirm A/B horn lengths against all three views (A reads ~ twice as tall in the front reference than modelled); add shoulder-to-waist taper (waist ~ -15% vs shoulders).
- MAGNITUDE: qualitative (non orthographic). Crop: front_qualitative_ref_vs_current.png.

## Scorecard (0-100, proxy-stage, from comparison renders only)

| Category | Score | Evidence |
|---|---|---|
| Silhouette /25 | 19.0 | IoU 0.87 side / 0.88 back; XOR 13-14% of reference area. Torso width (1.0-1.4 m rows) within +-3% (positive), but head, horns, arms, legs drag it down. G1 gate (22.5) NOT met. |
| Proportions /20 | 15.5 | Overall height matches within 6 px (top 90 vs 96; ground aligned); mid-torso, hips within 3%. Neck/shoulder height offset ~7 cm, arm length -15%, leg convergence errors up to 40-60%. G1 (18) NOT met. |
| Head-Neck-Horns /15 | 7.0 | Horn layout, thickness and brim disc are wrong (T1-T3). Horn extent roughly right in side view, but shapes fail. G1 (13.5) NOT met. |
| Anatomy-Limbs /10 (silhouette) | 6.0 | Limbs the right order of length; forearm/hand reach missing, knee/calf curvature and foot shape wrong (T5-T8). |
| Asymmetry /5 | 2.0 | Reference arms/legs strongly asymmetric; model arms near-mirrored, legs offset slightly (T5, T6, T10). |
| Armor-Clothing, Materials, Production, Microdetail | not applicable at proxy stage | - |

Proxy-applicable total: 49.5 / 75 (66%). Gate G1 fails in all three gated categories. Priority fix order: T1, T2, T5, T3/T4/T6.
