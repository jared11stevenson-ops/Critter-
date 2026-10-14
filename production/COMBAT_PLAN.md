# Combat Perfection Plan (Priority 1 until the creator says otherwise)

Creator brief (2026-10-14): combat is the core. Fix animations, study each critter's anatomy and rig it correctly for fluid dynamic movement; every ability works, looks good, matches character and lore, feels fun, rewards skill, and gives each critter its own personality; balance within 5%; bigger ring; less *For Honor*, more *Elden Ring PvP / Marvel Rivals 1v1*. Order after this: 2 Jars, 3 Expeditions (may be cut), 4 everything else.
`BETA_ROADMAP.md` is superseded in order, not in content: M3 (balance) and M5.1-5.2 (animation, faces) are pulled forward and expanded here.

## 1. Where combat stands today (facts from the repo)
- Deterministic fixed-tick sim, data-driven moves (8 critters x 11 moves), 3 AI levels, parry/riposte, poise, stamina, grabs, Last Stand, rule modifiers. 30 test files green.
- Animation is **procedural on rigid cut parts** (`pose_lib.gd`, `rig_events.gd`, spring secondaries). Parts are cut from the Tripo meshes; no skin, so joints show seams, bodies can't bend, and there is no weight shift or secondary deformation. This is the main reason motion feels stiff.
- Abilities: all 88 pass the Move Effect Gate (they *do* something measurable). That is not the same as *feeling* right: VFX are generic per kit, never reviewed on device.
- Balance (seed 51, 30 bouts/pair): overall 43.8-54.0% (spread 10 points). Open pairs: Cigarra v Mollusk ~23%, Scarlith v Bramvex ~25%, Mollusk v Pharilux timeouts ~45%.
- Ring: small (duel-sized); camera fixed over-the-shoulder; spacing designed around lock-on tracking.

## 2. Target definition ("done" for combat)
| # | Gate | Measure |
|---|---|---|
| C-A | Every critter animates from a skinned skeleton fitted to its own anatomy: idle, walk/run, backpedal, strafe, dodge, guard, light x3, heavy, grab, each ability, hurt (light/heavy), stagger, knockdown/get-up, win, lose, KO | pose-sheet + video review per critter |
| C-B | No visible seam/tearing at any joint in any clip; details (faces, armour) survive | contact sheets at 4 angles |
| C-C | Every ability: readable windup (tell), distinct VFX/SFX in the critter's palette and lore, a skill answer, and a "fun" check by the creator | per-ability checklist (section 5) |
| C-D | Win-rate spread between best and worst critter <= **5 points** at expert, <= 7 at standard/novice; no matchup outside 38/62 | 1,000+ bouts per critter (about +-1.5 points noise) |
| C-E | Bigger arena, Elden-Ring/Rivals pacing: free movement, sprint, dodge-roll i-frames, stamina-based aggression, long-range tools, mix-ups; lock-on optional | creator feel pass on device |
| C-F | 60 fps p95 mid-range with skinned rigs | perf report |

"5% difference" is interpreted as: top-to-bottom overall win rate spread of at most 5 points (for example 47.5-52.5%) when skilled humans/expert AI play, because the creator wants skill to close the remaining gap. Tell me if you meant pairwise instead.

## 3. Pillar A - Animation and rigging (the biggest lever)

### 3.1 Tooling findings (researched 2026-10-14)
- **Tripo auto-rig (rig-v2.0 API):** skeleton plus skin weights for biped, quadruped, hexapod, octopod, avian, serpentine and aquatic rigs; Tripo or Mixamo bone naming; GLB/FBX out; 25 credits per rig, free pre-check. **Retarget API:** 100+ preset animations, up to 5 per request, 10 credits each, in-place option. Good for a *first* idle/walk/attack base, but presets are generic and weights are automatic. Risk: a re-exported mesh may change topology/textures and lose the detail the creator guards. Not verified for our models.
- **Godot 4.6 IK modifier family** (TwoBoneIK3D, ChainIK3D, SplineIK3D, FABRIK3D, CCDIK3D, JacobianIK3D), **SpringBoneSimulator3D** (4.5), **RetargetModifier3D** (4.4), **LookAtModifier3D**, BoneConstraint3D. Modifiers run after AnimationMixer, so IK/springs layer on top of clips. This fits us exactly: authored clips for intent, IK for foot planting / hand-to-target / head tracking, spring bones for tails, antennae, wings, cloth.
- 4.7 specifics were not found; check the 4.7 release notes before depending on a new node.
- I do **not** have Mixamo-style humanoid retargeting for our non-humanoid roster: critters are insectoid, mollusc, avian etc. Each needs a bespoke skeleton. Auto-rig types (hexapod, avian, serpentine, aquatic, quadruped) cover most body plans and are worth testing.

### 3.2 Pipeline options for skinning (spike on ONE critter, Aruun, then decide)
| Option | How | Pros | Cons |
|---|---|---|---|
| S1 own skinning (recommended to try first) | Keep my existing partition + normal-bake detail pipeline; in Blender build an armature per critter from its anatomy sheet, weight by part ownership with smoothed joint blends (heat-map then clean-up), export skinned GLB | I control detail (4096 atlas and normals stay), joint blends tuned per body | I must author skeletons and weights; more per-critter work |
| S2 Tripo auto-rig | Upload original GLB to Tripo rig, get skeleton and weights back, bake our normal map onto it | Fastest to a moving skeleton | Weights generic, topology may change, textures may be re-baked (detail risk), credits |
| S3 hybrid | S2 for skeleton/weights, then my pipeline re-bakes details onto the skinned mesh and I hand-fix weights | Speed plus detail | Needs the auto-rig mesh to stay close to the original |

Spike acceptance (Aruun only): same face/armour detail as the current build at 4 angles, no stretching in 6 test poses, <= 50k triangles incl. outline, <= 60 bones, 60 fps on S25.

### 3.3 Animation authoring approach
1. **Per-critter anatomy sheet** (one page each): body plan, joint list with ranges, center of mass, gait pattern (Aruun bipedal giraffe-beetle, Cigarra, Mollusk, etc.), personality adjectives that drive timing (heavy/light, snappy/lingering, twitchy/deliberate). I draft from the lore and sheets; the creator corrects in one pass.
2. **Shared locomotion/action skeleton grammar** so the AnimationTree is the same shape for all critters: locomotion blend space (idle, walk, run, strafe L/R, backpedal), action layer (strikes, abilities, grabs), reaction layer (hurt, stagger, knockdown, get-up), emote layer (win, lose, taunt). Clip content is per critter.
3. **Authoring route:** procedural-keyframe generation in Blender Python (pose targets plus easing curves per move: anticipation -> strike -> follow-through -> recovery, with timing taken from the move's startup/active/recovery frames so animation always matches the sim), exported as clips. Creator-supplied Tripo/Mixamo base motions are optional starting points where body plan fits.
4. **Frame-data lock:** each clip's key poses are pinned to sim frames (tell on startup frame N, hit on active frame, recovery matches). A test compares clip length to move frames so animation can never drift from gameplay.
5. **Layered extras:** IK feet planting, head/eye LookAt toward the opponent, SpringBone tails/wings/antennae, hit-reaction additive layers (directional flinch), weight-shift on guard and dodge.
6. **Faces:** expression set (idle, hurt, angry, win, lose), blinks and eye-darts. Blend shapes if the skin route allows, else swapped face textures on the existing face quad.

### 3.4 Anatomy study list (first pass, to be checked against sheets and lore)
Done per critter as the 1-page sheet in 3.3.1. Deliverable folder: `design/v2/anatomy/<critter>.md` (body plan, joints, gait, silhouette keys, personality timing, ability poses).

## 4. Pillar B - Arena, camera and pacing (Elden Ring PvP / Marvel Rivals 1v1 feel)
Proposed changes, each behind a data flag so the creator can A/B on device:
- **Ring:** radius up from the current duel ring to roughly 1.6-2x area, with cover pillars/ledges and varied floor (slopes, low walls) per arena; ring-outs stay but are tied to optional edge hazards, not default.
- **Movement:** sprint with stamina cost, dodge-roll with commit and i-frames per critter weight class, jump/leap only for critters whose lore supports it, optional backstep; movement speed class per personality.
- **Camera:** soft lock-on (default) with free-camera toggle; camera distance scales with fighter gap; more cinematic framing at ability casts.
- **Pacing:** less For-Honor "guard-direction mind games", more Elden-Ring commitment (long windups on heavies, rolls to dodge, poise-break punish windows, stamina decisions) and Rivals ability rhythm (cooldown-driven kits, ultimates, mobility tools, zoning).
- **Ultimate/Last Stand** as a meter-driven signature per critter (replaces generic Last Stand look).
- **Input on touch:** keep six buttons; add contextual sprint on stick push, roll on double-tap/swipe.
- These shift all balance numbers, so they land **before** the final balance pass.

## 5. Pillar C - Abilities (per critter checklist, 3 abilities + signature)
For each ability the creator signs a card: lore fit, tell design (shape/colour/sound), VFX recipe in the critter palette, SFX, skill answer (what beats it), use case (when a skilled player reaches for it), counterplay, cooldown/cost, fun note. The card is stored in `design/v2/abilities/<critter>.md` and drives a test (every ability has a card, tell, answer).
Personality hooks to keep each kit distinct (from lore; to be refined): Aruun - patient reach and gravity, rage as payoff; Cigarra - foresight/misdirection; Bramvex - observation and traps; Scarlith - brew/decay over time; Mollusk - armour, borrowed time; Zephyr - slippery evasion and loopholes; Nyxaris - silk control and reserve; Pharilux - chains, hauling and pressure.

## 6. Pillar D - Balance to the 5-point spread
1. Instrument the sim: per-move damage share, uptime, first-hit rate, timeout cause, ring-out cause, resource usage.
2. **Tuning loop:** automatic hill-climb on a small set of safe levers per critter (damage_mult, move cooldowns/stamina, guard drain, move speed) against the 8x8 matrix at expert and standard, with human-readable diffs. Noise control: at least 1,000 bouts per critter per iteration (use sharding; roughly 8 min per full run today).
3. **Skill-gap check:** run the matrix with a "skilled" AI (expert + perfect-parry-rate option) vs "novice" so power does not hide behind skill; a critter that only wins at expert is flagged.
4. Human sanity: creator plays each critter once against standard AI and rates 1-5.
5. Re-run after every pillar-B change.

## 7. Milestones and what I will do with limited usage
Each step ends in a build and a one-paragraph test script.
| Step | Content | Effort | Creator input |
|---|---|---|---|
| C0 (now) | This plan; research done; commit | S | read and approve/adjust sections 2 and 4 |
| C1 | Aruun skinning spike (S1 vs S3), skeleton + 6 clips, side-by-side video/contact-sheet vs the current build | M | go/no-go on route |
| C2 | Shared AnimationTree + clip grammar, frame-lock test, IK/LookAt/Spring layers, Aruun fully animated | L | feel check on phone |
| C3 | Arena/camera/movement pass (pillar B) with flags; creator picks defaults | M | phone feel pass |
| C4 | Roll the pipeline to the other 7 critters, one per session (anatomy sheet -> skeleton -> clips -> faces) | L x 7 | one OK per critter |
| C5 | Ability cards + VFX/SFX redo, critter by critter, merged with C4 so each critter ships whole | L | card sign-off |
| C6 | Balance loop to the 5-point spread (needs C3-C5 stable) | M | human sanity ratings |
| C7 | Combat perf pass on device, tests, release | M | device report |

Suggested rule: **finish one critter completely (Aruun) before touching the second**, as in the earlier model work, so mistakes are caught once.

## 8. Decisions needed
1. Is "5%" a spread across all critters (my reading) or pairwise?
2. Skinning route: try S1 (own skinning, protects detail) first, with S3 as fallback? (recommended)
3. Willing to spend Tripo credits on a rig test (25 credits plus 10 per animation)? Only for the Aruun spike.
4. Ring: how much bigger (1.5x radius?), and are ring-outs still a win condition or hazard-only?
5. Dodge-roll and sprint for all critters, or per-critter mobility identities (Zephyr fast, Mollusk slow)? (recommended: per-critter)
6. Keep lock-on as default (recommended on touch) or free camera default?
7. Which critter after Aruun?

## 9. Risks
- Skinning loses detail or tears at joints -> acceptance test in 3.2 before any scale-up.
- Skinned meshes cost more per frame -> bone cap 60, LOD on Low quality, perf gate C-F.
- Bigger ring and rolls change the AI and every balance number -> pillar B before balance, AI retune included.
- Creator usage budget -> one critter per session, each step shippable, cut line after C2/C3 still yields a visibly better game.

Sources: Tripo developer docs (rig, animation/retarget), Godot 4.6 IK announcement and SkeletonModifier3D docs.
