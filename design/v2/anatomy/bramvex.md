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
- **Heavy strike:** two-handed overhead/club slam with the wings flared for counterweight; long wind-up (Elden-Ring-style commitment), a visible thorn flash on impact.
- **Grab:** hooks with the thorned forearm and drags (insect raptorial grab), not a human clinch.
- **Hurt:** quick stiff whip-back (thin body, little mass), thorns shudder; stagger = knees buckle, club drops to the ground; knockdown = folds like a dropped stick bundle; get-up uses the club as a crutch.
- **Win / lose:** wins by planting the club and giving a quiet two-finger salute; loses by sitting down against the club with the lantern dimming.
- **Ability poses:** Branchline (becomes a branch: freeze with limbs crossed, thorns erect), Thorn Salvo (pivots, club braced across the shoulder, thorn burst), Bat Sweep (wings spread, charges low, wing edges lead), Sergeant's Mark (raises the lantern pole, sigil above), Impale the Ground (two-hand overhead drive into the floor).

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
1. Keep the near-seated crouch as the base stance, or stand him a little taller for combat readability (recommended: slightly taller, still hunched)?
2. Is the club always two-handed, or can it rest one-handed in idle (sheet shows both)?
3. Wings: functional (flare for dodge/charge) or display only?
