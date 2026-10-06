# ARUUN - authoritative design brief for the modelers (design-brief artist, 2026-10-06)

Status: DRAFT for the creator. Source of truth = the original sheet `tools/source_art/aruun_nerit_sheet.jpg` as cleaned in `design/reference_packs/aruun/`
(ortho views 4096 px tall, same scale, landmark rows shared; `metadata.json`). Height 2.40 m horn tip to sole; head 0.157 m crown-to-chin; 13.5 heads incl. horns.
Numbered images: `design/reference_packs/aruun/review/aruun_parts_{front,side,back}.jpg` (numbers below match). Machine-readable: `design/reference_packs/aruun/parts.json`.
Left/right below always means the CHARACTER's left/right. In the back view the character's LEFT is image-RIGHT; in the side view (faces screen-right) we see his RIGHT side.

## 0. How to read this
- Positions of every part are in parts.json (x,y as fractions of the aligned view image). Colours: "canonical" = my judgement of the flat paint colour of that part;
  "sampled" = most common non-outline colour in a 44-px box at the marker in each view (evidence, noisy where the box straddles two plates).
- Roughness/metalness are SUGGESTIONS (art has no PBR). Nothing in the art glows except the painted highlights; emissive is open (Q6).
- 3/4 FRONT is not orthographic (camera low, torso turned, head in profile): never take widths/depths from it.

## 1. Part list (numbered on the clean ortho views)
| # | part | material | layer | canonical base colour | rough | metal | sampled f / s / b (evidence) | seen in |
|---|---|---|---|---|---|---|---|---|
| 1 | Horn A (thick, hooked, jointed; char-left in back view) | chitin satin | 9 | `#8d332d` | 0.4 | 0 | - / #4b1b15 / #8d332d | fsb |
| 2 | Horn B (thinner, longer arch; cream shaft in back view) | chitin satin | 9 | `#a54533` | 0.4 | 0 | #a54533 / #b1875d / #d5a557 | fsb |
| 3 | Horn knob rings / side tines (cream-tan) | chitin satin | 9 | `#b1875d` | 0.4 | 0 | - / #4b1b15 / #8d332d | fsb |
| 4 | Red crown plates / horn cups | chitin gloss | 8 | `#933327` | 0.3 | 0 | #33211b / #933327 / #2d2727 | fsb |
| 5 | Cream temple tines + brow ridge | bone | 8 | `#b18769` | 0.45 | 0 | #937551 / #933327 / #6f4b33 | fsb |
| 6 | Eye (yellow, dark pupil ring, white glint) | glass | 8 | `#e0a030` | 0.05 | 0 | #c98739 / #ab7b57 / - | fs |
| 7 | Snout / nose pad / mandible hook (cream-tan face plate) | bone + chitin | 8 | `#b18769` | 0.45 | 0 | #b18769 / #c98757 / - | fs |
| 8 | Fang (white) at mouth corner | bone | 8 | `#efe6d0` | 0.45 | 0 | - / #c97b57 / - | s |
| 9 | Pale-yellow nape fringe + dark navy lower head | fibre / hair | 8 | `#d8c58a` | 0.45 | 0 | #6f5739 / #2d2727 / #2d2727 | fsb |
| 10 | Neck (long, orange-red, cream gloss streaks) | soft chitin / skin | 3 | `#ab5633` | 0.45 | 0 | #ab5733 / #93452d / #a5452d | fsb |
| 11 | Pauldron red ladybug disc (yellow spot, black holes), tan underplate | chitin gloss | 7 | `#a5382b` | 0.3 | 0 | #edb775 / #a5392d / #511b15 | fsb |
| 12 | Hooded mantle / cloak (dark brown-aubergine, cream fringe edge) | cloth | 10 | `#3a2d2a` | 0.9 | 0 | #2d2727 / - / #4b3933 | fb |
| 13 | Chest wrap + cream straps + knot | cloth | 6 | `#c8a982` | 0.9 | 0 | #cfa575 / #2d2727 / #b18769 | fsb |
| 14 | Tan back/chest plates (carapace) | bone / dry chitin | 5 | `#b08867` | 0.3 | 0 | #b18769 / #b1875d / #b18769 | fsb |
| 15 | Red waist sash + belt | cloth | 7 | `#8b352a` | 0.9 | 0 | #2d2727 / #933327 / #8d332d | fsb |
| 16 | Brass ring + boss belt ornament | aged brass | 8 | `#a98a4a` | 0.35 | 0.85 | #2d2727 / - / - | f |
| 17 | Cream tassels / hanging strips (belt) | cloth | 8 | `#d8bd96` | 0.9 | 0 | #271b15 / #2d2727 / #dbc3ab | fsb |
| 18 | Leaf pendant (olive) hanging at hip | leaf / fibre | 8 | `#6b6a3a` | 0.9 | 0 | #937551 / - / - | f |
| 19 | Elbow disc pad (red, yellow spot) | chitin gloss | 7 | `#a5382b` | 0.3 | 0 | #e1ab5d / #c38769 / #8d332d | fsb |
| 20 | Forearm guard (red + tan) | chitin / bone | 6 | `#92362b` | 0.3 | 0 | #93392d / #933327 / #6f2727 | fsb |
| 21 | Hand L (viewer-left in front): three long pointed claws | chitin | 4 | `#2e2729` | 0.45 | 0 | #271b15 / - / - | f |
| 22 | Hand R: gloved fist gripping Morrow haft | chitin + wrap | 4 | `#2e2729` | 0.45 | 0 | #b18769 / - / #2d2727 | fb |
| 23 | Dark under-armour (aubergine suit with cream star specks) | matte chitin / suit | 2 | `#2e2729` | 0.45 | 0 | #2d2727 / #e7c9ab / #393333 | fsb |
| 24 | Thigh plate (tan) with red patch | bone | 5 | `#b4886a` | 0.3 | 0 | #8d5739 / #bd9375 / #b18769 | fsb |
| 25 | Olive leaf skirt strips (front, hanging from waist) | leaf / fibre | 8 | `#6e6a3e` | 0.9 | 0 | #b7936f / - / - | f |
| 26 | Dark ragged skirt/cloak strips (outer, both sides) | cloth | 9 | `#4a3226` | 0.9 | 0 | #6f5739 / - / #ab7557 | fb |
| 27 | Tan/olive skirt strips (back view, right side) | leaf / fibre | 8 | `#997555` | 0.9 | 0 | - / - / #2d2727 | b |
| 28 | Knee guard (dark) | matte chitin | 6 | `#2e2729` | 0.3 | 0 | #ab7b51 / #b78769 / #8d4533 | fsb |
| 29 | Shin plate (orange-red) / red calf plate | chitin gloss | 6 | `#b26336` | 0.3 | 0 | #2d2727 / #b16339 / #8d4533 | fsb |
| 30 | Ankle wrap / bone plates | bone | 6 | `#b18769` | 0.3 | 0 | #6f5745 / #933327 / #b18769 | fsb |
| 31 | Foot with large claws / blunt toe | chitin | 4 | `#2e2729` | 0.5 | 0 | #2d2727 / #2d1b15 / #2d2727 | fsb |
| 32 | Second foot | chitin | 4 | `#2e2729` | 0.5 | 0 | #2d2727 / - / #2d2727 | fb |
| 33 | Red hanging fringe tail (shoulder tassel, side view) | cloth | 9 | `#913528` | 0.9 | 0 | - / #752d21 / - | s |

Not numbered because they are details of numbered parts: cream star-speck dots on dark plates (paint, not geometry); gloss ovals on red discs (paint);
small round holes on the pauldron/elbow/hip discs (black recesses - modelled as shallow pits, see 11, 19); bandage/wrap knots on the chest (13).
Morrow (the bonded mace) is its own part group, section 2.

### Layer order (inner -> outer), the sequence a modeler/rigger should build
1 body bones/skin -> 2 dark under-armour suit (23) -> 3 neck skin (10) -> 4 hands + feet (21,22,31,32) -> 5 tan plates (14, 24) -> 6 chest wrap, forearm guards, knee guard,
shin/ankle plates (13,20,28,29,30) -> 7 red discs and sash (11,15,19) -> 8 belt ornament, tassels, leaf pendant, skirt strips, head plates (16,17,18,25,27,4-9) ->
9 horns, outer ragged strips, shoulder tassel (1-3, 26, 33) -> 10 mantle/cloak (12). Skirt strips hang from the waist OVER the thighs; the mantle is the outermost layer.

## 2. Morrow (psionic-link mace) - from the MACE panel (`details/aruun_panel_mace_states.png`)
- Head: spiked sphere, near-black chitin with small cream rings/holes and 8-10 conical spikes; a large glossy RED core (oval, painted highlight) set in a cream-tan boss/collar; red psionic glow wisps are FX.
- Haft: thin dark jointed shaft with knuckle rings and a bound-leather grip near the butt; the butt has a frayed tassel.
- States on the sheet: RETRACTED (short haft, head hanging at the bottom), EXTENDED (long haft, red ring wisps), UPRIGHT full length (head on top, haft ~3x head height), FLOATING under psionic control (detached, red glow).
- Rig: spec.md says `weapon` bone with scale-Y telescoping. Head diameter is NOT dimensioned on the sheet (see Q4).

## 3. Contradictions across views, with PROPOSED resolutions
Each item: evidence -> proposal. Reply "OK" or the change. IDs C1.. are mine; Q1-Q6 are the six questions in QUESTIONS.md (merged here).

**C1 / Q2 - Mantle (hood+cloak) side.** Evidence: BACK view image-right (= his LEFT shoulder) carries a huge dark-brown mantle, its hem at y=0.37 and cream-edged fringe to y=0.47 (part 12); BACK image-left shows the red pauldron (11) uncovered.
SIDE view (we see his RIGHT) shows the red pauldron and NO mantle. FRONT 3/4 shows the hood/mantle behind the viewer-LEFT shoulder (= his RIGHT) and the red pauldron on viewer-right (= his LEFT).
Two views (back, side) agree: red pauldron on his RIGHT, mantle on his LEFT; the front is the odd one out (it is also a flipped, camera-low 3/4). The old spec.md ruling says "mantle over his RIGHT shoulder" but described the BACK view's image-right shoulder - that is his LEFT.
PROPOSAL: mantle over his LEFT shoulder with red pauldron uncovered on his RIGHT (side+back). Keep the front's hood bulge as a small hood behind the neck on the left. Alternative if the creator prefers the front: mirror both.

**C2 / Q1 - True front head.** Evidence: front head is a profile (snout points viewer-left); no straight-on view of the face exists (eye spacing, snout width, horn spread). Side + back + the 5 expression heads (RAGE is the only near-frontal: two yellow eyes at the sides of a long snout, upper lip with two nostrils, open jaw with fangs) give enough for a MODEL (long horse/dragon snout, eyes on the sides) but not for a design-approved front.
PROPOSAL: build the head from side + back + RAGE; treat the front head as RED until the generated true-front (design/reference_gen/aruun) is approved by the creator.

**C3 / Q3 - Horn tips.** Evidence: at 2400/6x the original side panel the tips end INSIDE the panel (pixel check at original sheet x 600-632, y 100-125: tips terminate in a dark knob with a downward hook; the panel frame is at x~638). The earlier worry that they touch the page edge was an artefact of my crop.
Heights: tips reach 2.40 m, cranium top 2.127 m => 0.27 m of horn above the skull. Horn A (thick, red, jointed) rises vertically then hooks FORWARD (side) / arches over the top (back). Horn B (thinner, longer, cream shaft in back view) leans outward-back then arches over.
PROPOSAL: tips intact as drawn (answers Q3: yes, the length shown IS the intended length). Horns are ASYMMETRIC (A thick/short, B thin/long); do not symmetrise.

**C4 / Q4 - Morrow size and states.** Evidence: the front 3/4 draws Morrow from a low camera; the panel shows the head ~1.6x the width of the haft knuckles, haft ~3x the head height when upright. Head diameter is unmeasured.
PROPOSAL: head diameter 0.45 m (about 3x the head-crown-to-chin 0.157 m... i.e. fist-sized x3), haft 1.5 m extended; build all 4 states as one mesh with telescoping + a detached floating pose handled in animation (no extra mesh). Needs the creator's number.

**C5 / Q5 - Hands and feet symmetry.** Evidence: front: viewer-left hand (his RIGHT) = three long pointed claw fingers (part 21), viewer-right (his LEFT) = gloved fist gripping the mace (22); back view shows his right hand as a wrapped fist too, with the thumb side cream. Feet: front viewer-left foot has big forward claws, viewer-right foot is seen toe-on with 3 claws; side foot has a blunt long toe + heel spur.
PROPOSAL: both hands same anatomy (3 long claw fingers + thumb) - the left one is wrapped/gripping; both feet identical (3 forward claws + heel spur), mirrored. The 'blunt' side toe is the claw seen edge-on.

**C6 / Q6 - Emissive.** Evidence: no glow halo in any view except the Morrow psionic wisps (FX) and painted gloss ovals on red discs.
PROPOSAL: emissive 0 on the body; Morrow core emissive 0.4 only while linked; eyes: tiny emissive 0.2 so they read at phone distance.

**C7 - Skirt.** Evidence: FRONT shows a full olive leaf skirt (strips from y=0.60 to 0.80, both legs, part 25) plus dark outer strips on the far right (26). SIDE shows NO skirt at all (bare thigh plate 24, dark suit down to the knee). BACK shows strips only along the character's LEFT leg (image-right, parts 26/27, from y=0.5 to 0.83) and a bare tan thigh plate on the right leg.
Interpretation: it is NOT a full skirt but a ragged strip panel hanging from the belt over the front and his LEFT hip/thigh (front-left drape), open on his right.
PROPOSAL: strips hang from the belt across the front and the character's left side; none on the right thigh; none at the centre back.

**C8 - Pauldron/elbow count.** Evidence: FRONT shows a red disc on the viewer-right shoulder and a second red disc on the viewer-right elbow (11, 19) - one arm. SIDE shows pauldron + elbow disc on the near (right) arm. BACK shows red pauldron (right) and a red elbow/forearm (22 region) on the right; the left shoulder is the mantle.
PROPOSAL: the left shoulder has a small tan plate under the mantle, no red disc; red discs on the right shoulder + right elbow only... EXCEPT the front's red discs are on his LEFT (viewer-right). This is the same handedness conflict as C1: follow C1 (all red armour on the RIGHT arm).

**C9 - Neck length/pose.** Evidence: neck 0.20 m chin-to-base in the front/back landmarks but the side view shows it leaning ~12 degrees forward and 0.45 m visible along its arc (spec: neck 0.45 m).
PROPOSAL: neck arc length 0.45 m, leaning forward, gloss streaks along the front. Head is carried FORWARD of the trunk in the side view (head centre ~0.10 m ahead of the shoulders) - keep.

**C10 - Torso hunch / stance.** Evidence: side view: spine curves forward (shoulders ahead of the hips by ~0.12 m), knees bent, heel raised ~0.02 m; back view: weight on his left leg (leg planted wider). FRONT is a contrapposto 3/4.
PROPOSAL: rest pose = side-view hunch, weight on the left leg, no heel-lift.

**C11 - Outline artefact (not design).** The side and back ortho cuts carry a thick jagged black halo (2-5 px at 4096) from the upscaler/rembg. It is NOT a design feature; the original outline is ~0.2 % of height. Do not model outline thickness from the ortho PNGs.

## 4. Design locks - what must NEVER change
1. Two asymmetric jointed stag-beetle horns (thick short A + thinner long B), tips reach 2.40 m, hooked forward / arching over; red-brown with cream knob rings and side tines.
2. Long snouted dragon/horse head, yellow side-set eyes with dark pupil ring + white glint, white fang visible at the mouth even when calm, cream/tan face plate, red crown plates over the brow, cream temple tines, pale-yellow nape fringe.
3. Very long orange-red neck leaning forward; hunched trunk; head ahead of the shoulders.
4. Big round red ladybug-style pauldron + elbow disc (yellow-cream spot, black pits) - round, glossy, not angular.
5. Dark aubergine under-armour with cream star specks + tan bone plates on thighs/arms/chest.
6. Hooded dark mantle with cream fringe over one shoulder; chest wrap with knot; red waist sash; brass ring boss ornament; cream tassels.
7. Ragged olive leaf-strip skirt hanging from the belt (not a full circle skirt).
8. Clawed hands (long pointed) and large clawed feet with armoured ankle wraps.
9. Morrow: spiked near-black sphere with a red glossy core on a jointed telescoping haft.
10. Palette: #9c2f22 / #c8462b / #d9803a / #6b6a3a / #4a3226 (canon.json) plus aubergine #2e2729 and tan #b18769; height 2.40 m.
11. Style: heavy black ink silhouette, flat cel blocks with one hard shadow tone, small painted gloss ovals - no photoreal PBR noise.

## 5. Modeling priority at the phone camera (impact / pixel share, highest first)
1. FACE + head (snout, eye, fang, crown plates) - the face is what the creator judged failed; reads at ~40 px.
2. HORNS (silhouette: 0.27 m above the skull, the signature outline).
3. PAULDRON + elbow disc (largest saturated red masses) and the long orange neck (second strongest colour mass).
4. MANTLE / cloak + fringe (largest dark mass, defines the left silhouette).
5. SKIRT strips + belt/sash/tassels (lower-body shape and motion).
6. HANDS (claws) - read as a gesture shape only.
7. FEET + ankle wraps - ground contact, readable in profile.
8. MORROW (carried prop; high impact when it is in frame, rank 3 in combat close-ups).
9. Under-armour, star specks, small ornaments, texture-only detail.

## 6. New generated references
`design/reference_gen/aruun/` did not exist when this brief was written. When images land they are reviewed in `design/reference_packs/aruun/REVIEW_GEN.md`
using `python3 tools/refsheets/review_gen.py` (alignment, silhouette IoU against the originals, edge/colour drift, difference overlays). Rejection criteria are in that file.
