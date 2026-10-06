# INSPECTOR REPORT, inspection_04 (Gate 2 primary forms, blind)

Method. Masks: reference = alpha > 128; model = pixel differs from the corner grey (214) by sum-abs RGB > 18. Scale 1626.667 px/m, ground row 4000. Reference was shifted horizontally for best IoU (side dx=1206 px, back dx=1200 px) and overlaid on the model canvas; vertical alignment is the shared ground row, no vertical shift.
Overlay evidence: evidence/overlay_side.png, overlay_back.png (grey = both, red = reference only, blue = model only), evidence/overlays_both.png.

Global result: total-silhouette IoU side 0.871, back 0.881. Body widths at 0.1/0.4/0.8/1.0/1.3/1.5/1.7/1.8/1.9 m heights agree to within about 0.01-0.04 m in both views (e.g. side torso depth at 1.0 m: ref 0.433 vs model 0.437; back chest width at 1.3 m: 0.725 vs 0.735). The proxy body is genuinely measured. Total height identical (top row 96). The failure is the HEAD and HORNS, where the model does not read as the reference character.

Band IoU (side / back): horns+head-top 2.0-2.4 m 0.64 / 0.61; head 1.75-2.0 m 0.82 / 0.85; neck 0.92 / 0.95; torso 0.94 / 0.96; legs 0.86 / 0.83.

## CORRECTION TICKETS (ranked)

### T1  REGION: Horns (both), overall form
SEVERITY: 9
ERROR TYPE: Wrong silhouette / wrong design (asymmetric, wrong curve, thin, hooked tips)
REFERENCE: Two thick, stout, tapered antler-beams of nearly the same shape and mirrored in the rear view, rising from heavy bases on the crown, sweeping forward-up in side view as two nearly parallel arcs (side crop), flaring apart in an inverted-U arch in the back view; tips are thin and taper straight, no curl. Beams are fat at the base (about 0.07-0.09 m) with several raised knob/tine joints along them. Straight-on, both are near-parallel columns with notched tips.
CURRENT MODEL: Horn A rises as a thin pipe, bends once and ends in a flat-cut blunt stub; horn B is a long thin pipe ending in an upward-curled hook (a cane/crook). They differ from each other in length and shape. In the front and back close-ups one horn is a vertical post and the other a long diagonal sweeping across over the head, so the pair is not mirrored. Beams are about half the reference thickness. Joint knobs are tiny beads, not the reference tine bumps.
REQUIRED CORRECTION: Rebuild both horns as a mirrored pair from the reference side/back/face views: thick base tapering to a thin straight pointed tip, forward-up arc in side view, symmetric diverging arch in back view. Remove the hook curl and the flat-cut end. Thicken to match the reference; enlarge the knob joints into the reference's tine bumps.
ESTIMATED MAGNITUDE: horn band IoU 0.64/0.61; model-only area (blue) 42,800 px side vs 31,800 px reference-only; beam thickness roughly 50% low; the horn tip hook is about 0.1 m of wrong geometry.
EVIDENCE: evidence/head_side_vs_ref.png, overlay_side.png, overlay_back.png, model_heads_front_q34_back.png, face_calm_rage_vs_model_front.png

### T2  REGION: Eyes and brow ridges
SEVERITY: 9
ERROR TYPE: Missing / illegible primary feature
REFERENCE: Large almond eyes with dark socket rings on the SIDES of the head, set under heavy angled brow ridges; they are the focal point of both the side view and the front face (calm and rage tiles).
CURRENT MODEL: In the front close-up no eyes or brows can be seen; the face is a flat-topped dome with a snout blob. In the side close-up there is one small ellipsoid near the brow and a large oval, neither reads as an eye in a socket under a brow. No lateral eye placement is legible from the front.
REQUIRED CORRECTION: Add sockets and eyeballs on the lateral skull planes (visible from straight-on at the sides), with a brow ridge that overhangs and angles down toward the snout; eye roughly 1/6 of head length per the side reference.
ESTIMATED MAGNITUDE: feature absent at readable scale; target eye about 0.04 m across.
EVIDENCE: face_calm_rage_vs_model_front.png, head_side_vs_ref.png, model_heads_front_q34_back.png

### T3  REGION: Snout, nose pad, mandible hook
SEVERITY: 8
ERROR TYPE: Wrong shape / wrong gesture
REFERENCE: Side view: snout narrows to a slim spike that curves DOWN, with a hooked mandible tip projecting below it; the muzzle reads as a drooping beak. Front: narrow, wedge-shaped muzzle with a V nose and a long dark jaw/throat below.
CURRENT MODEL: Snout is a short straight wedge held horizontal, ending in a blunt rounded tip with a small lip bulge; no downward droop, no hooked mandible, no fangs. From the front it is a wide rounded pad with two nostril dots (like a duck/pig bill), much wider than the reference muzzle. Length is about right (about 0.26 m both) but shape is wrong.
REQUIRED CORRECTION: Taper the snout to a narrow spike with downward curvature (tip about 25-30 deg below horizontal), add the lower mandible hook protruding below the tip, narrow the front width to a wedge.
ESTIMATED MAGNITUDE: tip height error about 0.04-0.06 m (droop missing); front muzzle width roughly 1.5-2x the reference.
EVIDENCE: head_side_vs_ref.png, face_calm_rage_vs_model_front.png

### T4  REGION: Crown plates, horn cups, temple tines, cheek plates
SEVERITY: 7
ERROR TYPE: Wrong shapes / misplaced secondary forms
REFERENCE: Red crown plates stepping up into horn cups; bone/tan tines at the temples curve outward and down (antler-like); cheek plates are angular plates flanking the face under the eyes.
CURRENT MODEL: Crown is a flat disc-like shelf with a straight conical spike on each side (spikes are horizontal needles, symmetric, ruler-straight, like a hat brim). Cheek plates are smooth round discs hanging like earrings at jaw height, at the head's side. Horn cups are plain collars.
REQUIRED CORRECTION: Replace brim and straight needles with curved temple tines; make the crown a stepped plate mass; reshape cheek plates as angular overlapping plates under the eye.
ESTIMATED MAGNITUDE: temple tine curvature and drop about 30-40 deg missing; cheek plate about 0.05 m too round and too low.
EVIDENCE: model_heads_front_q34_back.png, face_calm_rage_vs_model_front.png

### T5  REGION: Skull mass and neck-to-head junction
SEVERITY: 6
ERROR TYPE: Proportion
REFERENCE: Head skull compact, slightly narrow at the back; head band (1.75-2.0 m) in the back view is wider than the model (reference-only 15,057 px vs 7,493 px model-only), i.e. reference has fringe/nape volume, in the side view the skull is smaller.
CURRENT MODEL: Side view: skull is a bulbous ball bigger than the reference (model-only 14,813 px vs ref-only 7,701 px; IoU 0.82). Neck meets the skull in a hard horizontal seam from underneath; in the back view the head is a rounded block narrower than reference.
REQUIRED CORRECTION: Reduce skull volume in side view about 10-15%; widen the nape and rear in the back view (fringe volume placeholder); blend neck into the skull base along the reference angle.
ESTIMATED MAGNITUDE: about 0.03 m too deep in side view, about 0.03-0.04 m too narrow in back view.
EVIDENCE: overlay_side.png, overlay_back.png, head_side_vs_ref.png

### T6  REGION: Neck thickness (side)
SEVERITY: 3
ERROR TYPE: Proportion, small
REFERENCE / CURRENT: neck band IoU 0.92 side; model-only 19,497 px vs ref-only 7,865 px, the model neck is a straight tube slightly thicker toward the throat; reference has a throat taper and forward lean.
REQUIRED CORRECTION: Slim the front of the neck 0.01-0.02 m and add the reference's forward lean.
ESTIMATED MAGNITUDE: about 0.015 m.
EVIDENCE: overlay_side.png

### T7  REGION: Legs and feet silhouette
SEVERITY: 4
ERROR TYPE: Proportion / stance
REFERENCE: Digitigrade-looking lower leg with distinct ankle and hoof-like foot angled down; back view stance with wider feet spacing.
CURRENT MODEL: Straight tube shin and a flat slab foot (side); back-view feet are round pads. Side legs band IoU 0.86 (model-only 48,328 vs ref-only 15,539), back 0.83. Part of the back-view difference is the unbuilt skirt strips.
REQUIRED CORRECTION: Reprofile shin and ankle to the reference line; tilt the foot; this may be deferred as feet detail is not built yet.
ESTIMATED MAGNITUDE: up to about 0.04 m at the calf/ankle.
EVIDENCE: overlay_side.png, overlay_back.png

### T8  REGION: Shoulder line (back view)
SEVERITY: 3
ERROR TYPE: Shape
REFERENCE: Shoulders slope down from the neck base (width at 1.8 m is 0.337 m).
CURRENT MODEL: Torso is a straight block with abrupt shoulder corners; width at 1.8 m is 0.293 m (0.044 m narrow), so the trapezius slope is under-built. The two oval discs on the back are not reference shapes (reference has cape/mantle there; mantle is not built yet).
REQUIRED CORRECTION: Add the trapezius slope; remove or demote the blade ovals until the mantle exists.
ESTIMATED MAGNITUDE: 0.04 m at 1.8 m height.
EVIDENCE: overlay_back.png

## Not built yet (not ticketed)
Mantle/cape detail, hands and claws, feet detail, skirt strips, fringe, tassels, belt, bandages, fangs/teeth detail, materials and texture.

## Scorecard (inspector)
- Silhouette /25: 16. Total IoU 0.87 side / 0.88 back with the body band at 0.94-0.96; deductions for horn band 0.61-0.64 and legs 0.83-0.86 (some skirt-related).
- Proportions /20: 17. Heights and widths measured within about 0.01-0.04 m; head scale slightly large.
- Head-Neck-Horns /15: 4. Does not read as the reference face: no legible eyes or brows, wrong snout shape, mismatched hooked horns, hat-brim crown with needle spikes, earring cheek discs.
- Armor-Clothing /15 (built parts only): 8. The red pauldron mass holds the reference volume (side torso IoU 0.94) but shoulder slope and blades are off; nothing else built.
- Anatomy-Limbs /10: 6. Proxy limbs match widths; straight tube shin and slab foot.
- Asymmetry /5: 1. The horn pair is wrongly asymmetric (vertical post vs sweeping crook), while the reference horns are a near-mirrored pair.
- Total: 52/100.
