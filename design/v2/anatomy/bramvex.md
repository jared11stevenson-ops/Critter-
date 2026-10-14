# Bramvex - anatomy and motion study (Thornmarch sergeant, "The Quiet Command")

Sources: `tools/source_art/bramvex_sheet.png` (turnaround, movement strip: idle, walk, stalk-low, sprint, wing flare, vault, wall cling, ambush drop, thorn guard), lore bible entry 31, the Tripo model (4 views), `data/critters/bramvex.json` (zoner / terrain tactician, reach 9, speed 5, vitality 5).

## 1. What he is physically
A **phasmid (stick insect) soldier** with a humanoid sergeant's gear, **bat-style membrane wings**, a **cloak/banner rig** and a huge thorned club ("Diplomacy"). Four things that confuse auto-riggers and one that breaks them:
1. **Stick limbs**: every limb is a long thin segmented rod (femur/tibia/tarsus proportions, not a humanoid muscle taper). Joints are knobby thorn-studded knuckles. Upper and lower segments are about equal length and thin, so skin weights must be sharp at joints (little blend), or the limb "noodles".
2. **Hunched, near-seated field stance** in the model: knees high and forward, torso leaned forward, arms hanging long with the club resting diagonally across the body. An auto-rig assumes a T/A-pose and finds the "spine" wrongly.
3. **Cloak and banner tatters** hang over hips and legs and fuse to them in the mesh, so heat-map weights bleed the legs into the cloak.
4. **Wing** is a bat wing: a long arm-like spar plus finger spars and a membrane, rooted on the shoulder blade, plus a **lantern pole** rising from the same area. Auto-rig reads these as extra arms.
5. **Prop**: the club is longer than the body; it must be a separate weapon bone (hand-attached or free), never skinned to the arm.

## 2. Skeleton (proposed, 58 bones, game-ready)
```
root (ground, centre)
 hips (pelvis, slightly below belt line)
  spine_1 - spine_2 - spine_3 (long, flexible: stick-insect thorax leans, bends forward 35 deg at rest)
   chest (thorax, shoulder girdle)
    neck_1 - neck_2 - head (cap + antennae)
      antenna_L/R x3 (spring chain, 3 bones each)
    shoulder_L/R - upperarm - forearm - hand (3 finger bones as one curl bone each: thumb, grip, off)
    wing_root_L/R - wing_arm - wing_fore - wing_finger_1..3 (membrane skinned across)  [wing_R opens, L tucked as in the sheet]
    lantern_pole (4-bone spring chain from back) + lantern (pendulum)
  thigh_L/R - shin_L/R - foot_L/R - toe_L/R (digitigrade-ish: ankle high, long metatarsus)
  cloak_back_1..4 (spring chain, 3 columns), cloak_front_L/R_1..3 (spring), belt_pouch_L/R (pendulum)
weapon (free bone, constrained to hand_R grip; second grip hand_L optional)
```
Rules: leg and arm chains use TwoBoneIK3D (feet planted, hands onto the weapon); spine and head use LookAtModifier3D toward the opponent; antennae, cloak, wing finger tips, lantern use SpringBoneSimulator3D. Wing and cloak weights are painted separately from leg weights (cloak vertices above the belt follow the spine, below it follow the cloak chain only, never the legs).

## 3. How he naturally moves (personality: disciplined, quiet, economical)
- **Idle:** weight on the back foot, club tip grounded, slow breathing in the thorax; antennae tick toward sound every 2-4 s; wing partly folded, one finger twitches; lantern sways. Never fidgets with flourish.
- **Walk:** deliberate, stalk-like: long stride from the hips with the knees lifted high (stick-insect "sway"), torso almost still, club carried low across the body. Footfalls soft. Whole body bobs only slightly; cloak drags.
- **Stalk (low, guard-free):** drops the thorax to a crouch, legs spread wide, moves with a "freeze and creep" rhythm (two steps, hold). Camouflage ability uses this as its base pose.
- **Sprint / vault / wall cling (sheet):** four-limbed scramble: arms plant on the ground, legs drive, wings flare for balance; vault = plant club, swing over; cling = hooks hand and thorn-foot into a post.
- **Dodge:** a *fold*: collapses into a thin rod (stick posture), slides sideways, wings snap closed; he reads as a branch moving. Short, low, quiet.
- **Guard (Thorn Guard):** plants club upright in front, wings spread behind like a shield, head tucked. Slow hold, small recoil flinch.
- **Light strike:** a short jab with the club butt from the hip (reach 9: long thrusting spear-like pokes), thorns first; body leans only slightly; recovers by pulling the weapon straight back.
- **Heavy strike:** one-handed overhead club slam; the free hand and the wings swing back as counterweight; long wind-up (Elden-Ring-style commitment), a visible thorn flash on impact.
- **Grab:** hooks with the thorned forearm and drags (insect raptorial grab), not a human clinch.
- **Hurt:** quick stiff whip-back (thin body, little mass), thorns shudder; stagger = knees buckle, club drops to the ground; knockdown = folds like a dropped stick bundle; get-up uses the club as a crutch.
- **Win / lose:** wins by planting the club and giving a quiet two-finger salute; loses by sitting down against the club with the lantern dimming.
- **Ability poses:** Branchline (becomes a branch: freeze with limbs crossed, thorns erect), Thorn Salvo (pivots, club braced across the shoulder, thorn burst), Bat Sweep (wings spread, charges low, wing edges lead), Sergeant's Mark (raises the lantern pole, sigil above), Impale the Ground (one-handed overhead drive, free palm slaps the ground as the thorns erupt).

## 4. Why Tripo auto-rig fails on him (and the answer)
Auto-rig assumes a standing humanoid/quadruped body plan with limbs attached to a single torso, and clean silhouettes. Bramvex has a crouched stance, cloak fused to legs, wing/pole as extra limb-like spars, and a weapon taller than himself. Answer: skeleton above, **built by hand to the anatomy**, weights from **part ownership** (limb segments rigid-ish, cloak by height gradient), props on separate bones. Do not feed the whole mesh to an auto weighter.

## 5. Rigging plan for the prototype (next session, ~1-2 sessions of work)
1. Reuse the detail pipeline's source (`/tmp/cu/br/plain.glb`, or rebuild from `tools/source_art/bramvex_tripo.glb`), same rot_z/scale as `tripo_build.py`.
2. Decimate the **whole** body once to about 45k triangles, bake the 4096 normal map from the original (detail preserved), keep the club, wing and lantern pole as separate objects.
3. Place the armature by landmarks measured from the mesh (feet, knees, hips, belt, shoulder blades, head), then **weight by region** (my own script: vertex-to-bone-segment distance with sharp falloff, cloak gradient rule, wing spars by distance to spar bones) instead of bone-heat on the cloak.
4. Test poses: T-pose, A-pose, walk contact, deep crouch, club overhead, wings flared, dodge-fold. Accept only if no tearing, no cloak-through-legs, and face/thorn detail unchanged.
5. Export GLB with skin; load in Godot with an AnimationPlayer and the layered modifiers (TwoBoneIK3D feet/hands, LookAtModifier3D head, SpringBoneSimulator3D cloak/wing/antennae/lantern).
6. Author 6 clips (idle, walk, stalk, light, guard, hurt) pinned to the move frames, review as a contact sheet.

## 6. Open questions for the creator
1. DECIDED (creator): slightly taller, still hunched; the seated crouch is kept only for stalk / Branchline.
2. DECIDED (creator): the club is always ONE-handed (right hand). The left hand is the Command Hand, see section 7.
3. DECIDED (creator): wings are functional: flare for dodge, charge (Bat Sweep), heavy counterweight and guard shield. Any gameplay effect (e.g. dodge distance) must be a skill-based, costed choice, not a hidden multiplier.

## 7. The Command Hand (left hand, decided 2026-10-14: club stays one-handed)
Lore anchors: he is a *sergeant*; "They don't shout. They set the line."; "Silence sets the standard."; his powers are camouflage, terrain and marking targets; the sheet shows hand-over-chest, thorn bandolier, wall cling and a thorned forearm. So the free hand is **the hand of orders and terrain**, never a second weapon. Every use is a visible, readable gesture that also helps the player read his intent.

| Situation | Left-hand action | Why it fits |
|---|---|---|
| Idle | Rests on the belt pouch, two fingers tap the strap; sometimes holds up a flat hand ("hold") when the opponent moves | disciplined, always counting supplies |
| Walk / stalk | Fingers spread low, feeling the air and ground; in stalk the hand touches the floor every other step (third point of contact, insect creep) | camouflage, terrain sense |
| Guard (Thorn Guard) | Flat palm raised: the "halt" signal; wings spread as shield | "Hold the Line" |
| Light strike | Free hand pulls back as a counterweight while the club jabs, then points along the line of the thrust (aiming like a spear fighter) | reach/zoner reads |
| Heavy strike | Free hand and wings swing back, then snap forward as the club comes down | counterbalance for a one-handed slam |
| Grab | The hand is the grab: the thorned forearm hooks (raptorial) and drags | insect anatomy, short fast grab, club stays ready |
| Dodge | Hand trails the cloak and flicks it across as a screen, body folds to a rod | camouflage |
| Thorn Salvo (ability) | Draws thorns from the bandolier / forearm and flicks a fan of them while the club braces on the shoulder | ranged pressure, thorns embed in the terrain |
| Sergeant's Mark (ability) | Raised closed fist, then points: command sigil appears over the target (lantern pole flares behind him) | the order, given silently |
| Branchline (ability) | Hand grips the nearest branch/wall and he merges into it (thorns erect) | terrain tactician |
| Bat Sweep (ability) | Hand braces on the floor as he charges low with wings leading | four-point scramble |
| Impale the Ground (ultimate) | One-handed club drive; palm slaps the ground as the thorn forest erupts | zone control |
| Hurt / stagger | Hand clutches the ribs; on knockdown it catches the ground | a thin body that takes hits |
| Win / lose | Win: a two-finger salute with the free hand. Lose: the hand covers the lantern | quiet, restrained |

Rig consequences: the club bone is parented to the right hand only (no left grip); the left arm gets its own TwoBoneIK3D target so it can reach the floor, wall, bandolier and target direction; finger bones on the left hand are individual (point, fist, flat palm, spread) rather than one curl bone; a bandolier of thorns (props) on the chest hides/reveals thorns during Thorn Salvo. Gameplay note (for the combat pass, nothing changed in data yet): the grab is a natural short-range off-hand move and Thorn Salvo is the ranged use; neither needs new balance levers unless the creator wants one.

## 8. Rig attempt 1 (2026-10-14): result and decision
Script: `tools/blender/rig/bramvex_rig_test.py` (14-bone armature placed from side/front measurements of the current model, automatic weights, then custom inverse-distance weights with a hands-rigid-with-club rule and a "loose cloak follows the pelvis" rule; renders rest / walk / strike / stand).
- **Worked:** the rest pose is identical to the current model (no loss of detail, no tearing), head, club and wing/lantern pole follow their bones, the arms bend as bodies, and the second weighting pass reduced cloak shards being dragged by arms.
- **Did not work (not smooth, not proper):** in the walk and stand poses the legs shear and stretch, the club separates from the hand, thin shreds float free, and cloth fused to the legs is torn between thigh and shin. Causes: (1) the model was generated in a **deep squat with the cloak, belt and thighs fused**, so there is no clean surface between leg and body to cut skin weights along; (2) the joint positions are my estimates from two orthographic views of an occluded pose, and each wrong joint shears a leg; (3) a 14-bone test rig with distance weights cannot fix (1).
- **Decision (per the creator's rule "fix it or give up"):** stop here. Nothing was added to the game; Bramvex keeps the current rigid-part rig (head, club, wing + lantern pole animate).
- **What would make a proper rig possible:** regenerate Bramvex in Tripo in a **neutral standing A-pose** (legs apart and straight, arms away from the torso, club held in the right hand pointing down-forward, cloak short or open so legs and arms are visible, wings folded or half open), keeping the same face/armour design. A standing pose gives clean joints, clean silhouettes and weights I can verify, and the hunched, crouching look can then come from the animation instead of the mesh. Alternatively accept a limited rig: skin only the arms and head, keep legs and cloak as one rigid body.
