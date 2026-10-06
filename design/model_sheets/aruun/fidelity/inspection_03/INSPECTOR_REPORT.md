# Inspector Report, round 03 (blind, silhouette/proportion only)

Method: masks thresholded at ref alpha>128 and clay |RGB-214| sum >6. Ref and current aligned on ground row (y=4000, same 1626.667 px/m) and best horizontal fit by IoU (side 0.875, back 0.885; front 0.58, qualitative only because the reference is 3/4 with head in profile). Red = reference only, blue = current only. Ref canvas clipping checked: side ref is clipped at the back edge for rows 2274-2493 (arm/forearm) and slightly at rows 216-225; back ref clipped at rows 2394-2427 and 2953-2976. No claim below relies on those rows. Overlays: evidence/overlay_{side,back,front}.png.

Overall: side/back silhouettes agree to within about 1-3 percent of height almost everywhere (overall height 2.40 m both, widths within about 1 percent). The remaining errors are concentrated in the head, the horn A/B differentiation, the shoulder-neck ramp, the foot and the front-view pose.

## Tickets (ranked)

### T1. REGION: Head (skull) in back/front views. SEVERITY 8
- ERROR TYPE: wrong primitive shape / silhouette
- REFERENCE: back view: compact rounded, egg-shaped skull narrowing into the neck, with small side spikes (ears) near the top; no flange.
- CURRENT MODEL: back/front: a straight-walled cylinder cup with a flared flat rim ("top hat"), hard step to the neck; in side view the skull is a blobby sphere about 50 px too deep at the back (blue at the back of the skull).
- REQUIRED CORRECTION: replace cup with an ovoid skull tapering into the neck, remove the rim flare, trim the occiput in side view, keep the ear spikes as small side tabs.
- ESTIMATED MAGNITUDE: skull width in back view approx 20-30 percent too large at the rim (about 330 px vs about 270 px at 0.65 scale crop); about 50 px (0.03 m) excess at the back of skull in side view.
- Evidence: evidence/back_head_neck.png, evidence/side_head_neck.png

### T2. REGION: Horn A (thick, red) shape and horn A/B thickness contrast. SEVERITY 7
- ERROR TYPE: wrong shape / proportion
- REFERENCE: A is a thick, slightly curved shaft, nearly vertical in back view, ending in a hook that curls toward B (arch). Side view horizontal shaft width median rows 300-450: A about 110-130 px, B about 55-75 px (ratio about 1.8 to 2).
- CURRENT MODEL: A is a straight leaf/spike tapering to a point with no hook; side-view widths A about 90-105 px, B about 80-95 px (ratio about 1.1). The thin horn is about 30 percent too thick and the thick one about 15 percent too thin, so the pair reads as same-weight.
- REQUIRED CORRECTION: thicken A (about +15-20 percent), thin B (about -30 percent, esp. mid-shaft), give A a curved top that hooks toward B instead of a straight pointed tip.
- ESTIMATED MAGNITUDE: B shaft about 20 px too wide in side view; A tip is displaced about 30-40 px above and right of the ref hook in back view.
- Evidence: evidence/back_head_neck.png, evidence/side_head_neck.png

### T3. REGION: Front-view pose: arms and head orientation. SEVERITY 6 (qualitative, ref is 3/4)
- ERROR TYPE: pose / asymmetry
- REFERENCE: arms splayed away from the body with bent elbows (one forearm well out to the side, hand near knee height outside the hip line), head turned to profile, wide stance, one leg forward.
- CURRENT MODEL: arms hang straight against the torso, head faces front with horns viewed from the side-on cup, stance narrow and nearly symmetric.
- REQUIRED CORRECTION: if the front reference pose is canonical, rotate the head to profile and abduct/bend the arms (about 25-35 degrees abduction at the viewer-left arm). If side/back are authoritative, document the front view as a different pose, since side and back already match.
- ESTIMATED MAGNITUDE: viewer-left hand about 350-400 px (0.22-0.25 m) further out than the current hand in the front overlay.
- Evidence: evidence/overlay_front.png, evidence/front_head_horns.png

### T4. REGION: Snout (side view). SEVERITY 5
- ERROR TYPE: wrong shape
- REFERENCE: slender spike curving down with a hooked tip, about 50-60 px thick near the base.
- CURRENT MODEL: thick cone pointing forward-down, about 1.5 times thicker, tip about 25 px (0.015 m) further forward and about 40 px lower than the ref tip.
- REQUIRED CORRECTION: slim the cone about 35 percent, curve it down, shorten slightly.
- ESTIMATED MAGNITUDE: about 35 percent thickness, about 25-40 px position.
- Evidence: evidence/side_head_neck.png

### T5. REGION: Horn B tip and curl. SEVERITY 5
- ERROR TYPE: shape / placement
- REFERENCE: B ends in a small knob with short forks; the tip sits about 25 px lower and left of the current tip.
- CURRENT MODEL: B ends in an oversized hook/ring that reaches about 25 px past the ref (rightmost x 2178 vs 2153), blue mass at the tip top.
- REQUIRED CORRECTION: shrink the curl, thin the last third of the shaft.
- ESTIMATED MAGNITUDE: curl about 40 percent too large; tip about 0.015 m too far right.
- Evidence: evidence/side_head_neck.png

### T6. REGION: Neck base and trapezius ramp. SEVERITY 4
- ERROR TYPE: proportion / placement
- REFERENCE: neck width median (rows 800-1000) side 179 px, back 190 px; trapezius slope begins at about y=1150 in back view; at y=1000 side the back edge of the neck is at x=1562.
- CURRENT MODEL: neck width 184 px side (ok), 206 px back (about 8 percent wide); the shoulder ramp starts about 100 px (0.06 m) higher at the back of the neck in side view (x=1457 vs 1562 at y=1000) and about 150 px higher on the viewer-right in back view (width 385 vs 217 px at y=1000). Neck centre sits 11 px further back in side view.
- REQUIRED CORRECTION: lower the trapezius start about 0.06-0.09 m and narrow the back neck about 8 percent.
- Evidence: evidence/back_head_neck.png, evidence/side_head_neck.png

### T7. REGION: Foot (side and back). SEVERITY 4
- ERROR TYPE: wrong shape
- REFERENCE: pointed, slightly tapered boot/hoof with an ankle armor bulge; sole thin.
- CURRENT MODEL: wedge slab with a square heel block, sole slab dips about 3-5 px below the ground row, toe about 20 px longer than the ref (blue on the toe underside); in back view feet are round discs about 10-15 percent wider.
- REQUIRED CORRECTION: taper the toe, round the heel, lift the sole to the ground row, narrow the back-view foot about 10 percent.
- Evidence: evidence/side_legs_feet.png, evidence/back_legs.png

### T8. REGION: Asymmetry (back view torso mass). SEVERITY 4
- ERROR TYPE: asymmetry reversed
- REFERENCE: heavier on the viewer-right (right 790k vs left 763k px, +3.6 percent) due to the large cloak shoulder wedge, with the viewer-left shoulder round and smaller.
- CURRENT MODEL: heavier on the viewer-left (806k vs 768k, +5 percent), viewer-left shoulder blob bigger than the ref and the viewer-right shoulder smaller.
- REQUIRED CORRECTION: swap the bias: enlarge the viewer-right shoulder/upper back wedge about 0.04 m, reduce the viewer-left shoulder about 0.02 m.
- Evidence: evidence/back_torso_arms.png

### T9. REGION: Torso back (side) and arm. SEVERITY 3
- ERROR TYPE: proportion
- REFERENCE/CURRENT: current back of the chest/shoulder is about 20-30 px (0.015 m) deeper than the ref at rows 1000-1700; the torso waist taper is roughly equal. The ref arm/hand reaches further back than the current, but is clipped by the canvas edge so the size of the error is only a lower bound of at least 0.02 m.
- REQUIRED CORRECTION: trim the upper back by about 20 px.
- Evidence: evidence/side_torso_arms.png

### T10. REGION: Knees and calves (back view). SEVERITY 3
- ERROR TYPE: contour
- REFERENCE: viewer-left calf swells lower and the inner thigh/knee line is straighter; current calf bows about 15-20 px outward at mid-shin. Crotch gap wedge is partly cloth in the ref (not counted).
- REQUIRED CORRECTION: move the calf maximum about 0.04 m lower, tighten the shin by about 15 px.
- Evidence: evidence/back_legs.png

## Region notes without tickets
Overall silhouette height 2.40 m both; chest, waist, pelvis, thighs, lower legs and arms match in side/back to within about 1-3 percent (row widths in the tables measured at 150 px steps; the largest row deviations are 8-10 percent at the neck/shoulder ramp and the arm). Negative space between legs and between arm and torso is similar.

## Scorecard (from silhouette only)

| Category | Score | Evidence |
|---|---|---|
| Silhouette /25 | 19 | IoU side 0.875, back 0.885; overlays show only thin red/blue fringes except head/horns and front pose. Front view not comparable (pose). |
| Proportions /20 | 17 | Height identical, row widths within about 1-3 percent, neck 179 vs 184 px (side), 190 vs 206 px (back). |
| Head-Neck-Horns /15 | 8 | Cup-shaped head (T1), A/B thickness contrast lost (T2), snout and B tip curl off (T4, T5), shoulder ramp too high (T6). Horn placement and heights are good. |
| Anatomy-Limbs /10 | 7 | Limbs track the ref in side/back; calf and foot shapes off (T7, T10); the arms and the front pose are unverified or not matching (T3). |
| Asymmetry /5 | 2 | Back-view shoulder bias reversed (T8); the front pose asymmetry is not reproduced (T3). |
| Total | 53 / 75 | |
