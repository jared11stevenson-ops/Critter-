# INSPECTOR REPORT, inspection_05 (blind, adversarial)

Method: reference masks = alpha>128. Clay masks = any channel differing from the flat 214 background by >3, opened 2 px. The clay canvas is padded, so the clay was x-shifted onto the reference by an IoU search over the 0.05-1.75 m body (side shift 288 px, back 300 px). Scale was not touched (1626.667 px/m, ground row 4000). Heights: ref 2.400 m, clay 2.396 m. Band IoUs use the global x alignment, with no per-band cheating. In the overlays, red = reference only, blue = clay only, grey = both.

Evidence: evidence/overlay_side_full.png, overlay_back_full.png, overlay_side_head.png, overlay_back_head.png, front_face_vs_clay.png, side_head_vs_clay.png, back_head_vs_clay.png, _full.png (side by side, whole body).

## Band IoU table (global alignment)
| band | side | back |
|---|---|---|
| horn 2.0-2.4 m | 0.832 | 0.825 |
| head 1.75-2.0 m | 0.819 | 0.868 |
| neck 1.5-1.75 m | 0.933 | 0.955 |
| torso 0.9-1.5 m | 0.938 | 0.955 |
| legs 0.05-0.9 m | 0.872 | 0.839 |
| whole body | 0.897 | 0.897 |

Bbox widths, ref vs clay (m):
- Side: head 0.404 vs 0.396, neck 0.486 vs 0.452, torso 0.545 vs 0.478 (torso 12% too shallow).
- Back: head 0.478 vs 0.433 (9% narrow), torso 0.816 vs 0.791, legs 0.913 vs 0.868.

Silhouette is close and outline-driven. The real failures are internal form, horn construction and head read.

## RANKED CORRECTION TICKETS

### T1. HEAD, skull reads as a boxy block with a lid and floating shards
- SEVERITY 9. ERROR TYPE: form / skull curvature.
- REFERENCE: in the front face and the side crop, an organic wedge skull. Brow ridge wraps over large side-set eyes, the cranium flows into the snout and cheek plates, and the nape is a dark rounded cap.
- CURRENT: head_clay_front and head_clay_q34 show a rectangular slab with a flat top and vertical sides, sitting on a second slab (the snout). A visible horizontal seam and dark gap runs between them. Temple tines and cheek spikes are free cones stuck on the corners. The back view is a cube with a flat rim and a ledge plate. It reads as a boxy block with floating shards.
- REQUIRED: rebuild the cranium as a single domed volume with a curved occiput and a brow-ridge overhang. Blend or fuse the snout to it with no gap. Cheek plates must be surfaces on the skull, not spikes.
- MAGNITUDE: whole head replace, about 0.4 m wide by 0.45 m tall. Back-view head width is short by 45 mm (0.433 vs 0.478 m).
- Evidence: front_face_vs_clay.png, back_head_vs_clay.png.

### T2. HEAD, eyes and brow ridges absent
- SEVERITY 9. ERROR TYPE: missing feature.
- REFERENCE: two large almond eyes under heavy brow ridges, set on the sides of the face. Calm and rage faces show black eye-rings and cheek plates below them. The side crop shows a big eye socket mid-skull.
- CURRENT: the only features are two small bumps (nostrils or pads) on the top slab in front view. The side view has a lens-shaped bulge, with no socket and no brow.
- REQUIRED: carve eye sockets about 0.06-0.07 m wide, laterally placed, with a thick overhanging brow ridge. Add a tear or cheek plate below each.
- MAGNITUDE: 2 features, about 60 mm each, plus a brow volume of about 15 mm projection.
- Evidence: front_face_vs_clay.png, side_head_vs_clay.png.

### T3. SNOUT, wrong profile (blob and flat tongue instead of drooping spike with hook)
- SEVERITY 8. ERROR TYPE: silhouette / proportion of the head.
- REFERENCE: in the side overlay the snout is a long slim spike that tapers and droops, with a hooked mandible tip (the red area under the muzzle).
- CURRENT: the head is a blunt, rounded muzzle with a bulge at the nose, and a separate flat lower-jaw blade that sticks out horizontally. The jaw hook is missing, and the red-only crescent under the mandible in the overlay confirms it. The nose pad and mandible hook are not distinguishable.
- REQUIRED: taper the snout to a downturned spike. Curve the mandible down to a hook about 80 mm below the muzzle line. Add a nose pad bump.
- MAGNITUDE: about 40-80 mm at the snout tip and mandible.
- Evidence: overlay_side_head.png (red crescent at the lower right of the head), side_head_vs_clay.png.

### T4. HORNS, tube-and-sphere construction instead of faceted bone and plate segments
- SEVERITY 8. ERROR TYPE: form language.
- REFERENCE: each horn is a flattened, faceted bone blade with ridge and plate steps. It tapers, with a flared fork or notch at the tip. Horn A (the near one in the side view) is wider, with an angular saddle and a spurred, notched tip. Horn B is slimmer and longer.
- CURRENT: both horns are round tubes joined by ball knobs. The tips are thin cones, and a small spike pokes from the tine joint. They are visibly the same part twice. The extracted centrelines are good (horn IoU 0.83) but the cross-section and the tips are wrong: the round section is uniform, with no flattening or ridge.
- REQUIRED:
  - Give the cross-section an oval, flattened blade shape with a front ridge and 3-4 plate steps, wider at the base and tapering.
  - Replace ball joints with angular knobs and tine joints.
  - Make A and B differ: A wider with a saddle and a notched fork tip, B slimmer with a plain curved tip.
- MAGNITUDE: width about 20-30 mm at the base, and a 40-60 mm fork at the tips. In the side overlay the red-only slivers are on the inner edge of both horns, about 10-20 mm.
- Evidence: side_head_vs_clay.png, overlay_side_head.png.

### T5. HORNS, back and front view layout (rear arc and crown bridge)
- SEVERITY 7. ERROR TYPE: pose / curvature.
- REFERENCE: in the back view the horns arch up and inward. The left shaft is tan-yellow, the right red, and a dark crown bridge or tines span between them over the top of the head. The tips splay outward in forked claws.
- CURRENT: two separate outward arcs with no bridge. The tips are small cones. The horn zone back IoU is 0.825.
- REQUIRED: add the crown tines or bridge between horn bases. Reshape the tips (flared, forked).
- MAGNITUDE: about 50-100 mm at the tip splay.
- Evidence: back_head_vs_clay.png, overlay_back_head.png.

### T6. NECK-SKULL JUNCTION
- SEVERITY 6. ERROR TYPE: transition.
- REFERENCE: a slim neck flows up into the nape cap. The nape is wider than the neck, with a fringe (not built yet).
- CURRENT: the neck is a plain cylinder ending in a collar ring or ledge directly under the box. The side overlay shows a sharp step, and the neck rear is blue-only (extra) up to 0.4 m below the head, with the red front stripe missing, i.e. the neck leans or bulges the wrong way. Side neck width is 0.452 vs 0.486 m.
- REQUIRED: swell the neck into the occiput. Pull the throat line forward.
- MAGNITUDE: about 30 mm.
- Evidence: overlay_side_head.png.

### T7. TORSO, side depth short and chest and back contour wrong
- SEVERITY 6. ERROR TYPE: proportion.
- REFERENCE: side torso width 0.545 m, with a chest and pauldron mass forward.
- CURRENT: 0.478 m (-67 mm, 12%). The overlay shows blue-only on the back (x left) and red-only on the front chest and neck-front slope. The front line of the chest is not carried up toward the neck.
- REQUIRED: fatten the front of the chest and upper torso. Add the front-neck slope.
- MAGNITUDE: about 40-70 mm.
- Evidence: overlay_side_full.png.

### T8. LEGS, merged forms and width
- SEVERITY 5. ERROR TYPE: proportion / anatomy.
- REFERENCE: the back view shows two distinct legs, thigh to knee to shin, with a wide gap and the left leg in the clear.
- CURRENT: legs are 0.868 vs 0.913 m wide. The shapes are a straight tube with no knee, and the legs merge into a block pelvis. Leg band IoU is 0.839 on the back and 0.872 on the side.
- REQUIRED: separate the legs, add the knee and calf shape, and widen the stance by about 45 mm.
- MAGNITUDE: about 45 mm.
- Evidence: overlay_back_full.png.

### T9. PAULDRON and shoulder blades read as floating ovals
- SEVERITY 4. ERROR TYPE: placement.
- CURRENT: in the back view two ovals and a bar float on the flat back, with no relationship to the shoulder.
- REQUIRED: integrate them with the shoulder mass and the mantle slope.
- MAGNITUDE: not measured.
- Evidence: _full.png.

Not built yet (not criticised): mantle detail, hands and claws, feet detail, skirt strips, fringe, tassels, belt, bandages, materials.

## SCORECARD (built parts only, blind)
| category | score | evidence |
|---|---|---|
| Silhouette /25 | 21 | whole-body IoU 0.90 on both views. Band IoUs 0.82-0.95, weakest are horns (0.83), head (0.82) and legs (0.84-0.87). Outline is close, but the head and horn edges differ. |
| Proportions /20 | 16 | height within 4 mm. Head, neck and torso placement good. Torso depth is 12% short, back head width is 9% short, leg stance is 5% narrow. |
| Head-Neck-Horns /15 | 6 | horn curves are good, but the skull is a boxy block, with no eyes, no brows, a blunt snout and tube horns. The neck junction is a collar. |
| Armor-Clothing /15 (built parts only) | 7 | the pauldron and blades are basic masses, and their placement is wrong. |
| Anatomy-Limbs /10 | 6 | the arms and legs are simple tubes with no knee or elbow shape. The side leg is plausible. |
| Asymmetry /5 | 2 | horn A and B are the same part with a different curve. There is no side-to-side difference in the head. |

Total (built categories) 58 out of 90. As a rough percentage that is about 64%, far below the G2 90% bar. The Gate 1 head-neck-horns bar of 13.5 is not met either (6/15). Silhouette is 21/25 against the 22.5 bar and proportions are 16/20 against 18.
