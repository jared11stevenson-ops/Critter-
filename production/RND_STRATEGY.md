# CRITTER R&D strategy: how a fighting game with a living cast could do what nobody else does

Written 2026-10-18. Creator brief: real-developer pace (months, not sessions); highly experimental, but every experiment must WORK; think outside the box; use what 2026 offers; keep up with AI game-dev news. This is the plan behind `COMBAT_PLAN.md` and `AUTONOMY.md`. Findings marked [verified here] were measured in this container; [research] came from web searches (links at the end) and must be re-checked before relying on them.

## 1. The question: what is the one thing we do that others don't?
Everybody else uses AI as a *production* tool (faster art, faster code) and ships the same kind of game. The genuinely new thing a fighting game with **permadeath, a Habitat Jar and individual critters** can do is use AI *inside the game's identity*:

> **Every critter is an individual who learns, remembers and leaves a ghost behind.** Your champion fights the way YOU taught it. When it dies, its style survives in the Hall as a ghost anyone can challenge. Rivals remember how you fight and adapt. Tournaments are filled with believable, personality-driven fighters that were *trained*, not scripted.

That ties the three things the creator already loves (permadeath, identity, skilled play) to technology that is cheap enough to ship on a phone: tiny neural policies (kilobytes), deterministic inference, no server. The second differentiator is *feel*: Elden-Ring-level weight from **animation by intent** (paths and mechanics, solved by IK and physics) instead of hand-keyed angles, so eight very different bodies can share one motion engine and still feel individual.

## 2. Hard constraints (what keeps experiments honest)
- **Compute here:** 4 CPU cores, 15 GB RAM, NO GPU, about 3.7 GB free disk (91% used; clean /tmp, never download big models without checking) [verified]. PyTorch 2.14 (CPU) and onnxruntime 1.30 are installed [verified]. So: small networks, evolution strategies, imitation learning, offline simulation. No big diffusion models in the loop.
- **The sim is fast enough to train on:** about 8,600 sim ticks per second per core (18 bouts of ~3,600 ticks in about 7.5 s) [verified]. One bout is about 0.4 s; four cores give roughly 10 bouts/s, about 36,000 bouts per hour. An evolution-strategy generation of 64 candidates x 20 bouts takes about 2 minutes. 100 generations is a night.
- **Determinism:** the combat sim must stay deterministic across phones. Learned policies run in the sim's own thread using **integer-quantised MLPs** (int8 weights, int32 accumulate, ReLU only, no transcendental functions) so the same inputs always give the same outputs on any device.
- **Mobile budget:** Galaxy S25 class: <= 150 draw calls, 60 fps p95; skinned critters 55k tris each; policy inference < 0.2 ms per decision.
- **Creator laws:** two fight kinds only; skill answers not hidden multipliers; learned fighters get **exactly the inputs a human has** (`CombatInput`): no reading hidden state, no frame-perfect cheating beyond declared "AI skill levels".
- **Usage:** the creator has very little weekly usage. Autonomous routines do the long work (budget-capped, see `AUTONOMY.md`); chat sessions are for decisions and reviews.
- **Experiment discipline:** every experiment has a hypothesis, a time box, a measurable success bar, a kill criterion and an integration path. A spike that "works in a notebook" does not count; it counts when a headless test proves it and it runs inside the game loop.

## 3. What 2026 offers (and what it doesn't) [research]
- **Engine:** Godot 4.6 made Jolt the default 3D physics and added the **IK modifier family** (TwoBoneIK3D, ChainIK3D, FABRIK3D, CCDIK3D, JacobianIK3D), SpringBoneSimulator3D (4.5) and RetargetModifier3D (4.4). Godot 4.7 (our version) adds Jolt/soft-body fixes and small animation-editor features; I did not find 4.7 features that change this plan. Modifiers run after the AnimationMixer, which fits "authored/generated base + IK + springs" layering.
- **Motion generation:** NVIDIA **Kimodo** (March 2026, v1.1 April) is an open text-to-motion diffusion model, but for human/humanoid skeletons only; hosted services (Uthana) retarget to humanoid rigs. No verified open model for *creature* motion exists, so non-humanoid critters need our own motion engine (this strategy) or humanoid-retargeted references.
- **Physics-based characters:** DeepMimic-style imitation RL is mature, 2026 work extends it to interacting characters (AssistMimic), but policies are brittle and need clean mocap; training needs GPUs. For us the useful part is the *idea* (physics-plausible motion), implemented cheaply by baking simulated reactions offline.
- **Auto-rigging:** **UniRig** (SIGGRAPH 2025, Tsinghua/VAST) predicts skeleton and skinning weights for arbitrary models; release status of the skinning part was unclear in sources. It is the one open tool that might remove the need for a T-pose model per critter.
- **Industry:** DeepMind is partnering with game developers on world-model prototypes; KRAFTON and others describe in-game AI agents that compete with players; 90% of developers use AI in production, mostly for repetitive work and playtesting; the big worries are IP/data ownership and measuring ROI. I found no verified shipped game built around learned fighting opponents that mirror the *player's* style, so this niche looks open (to be re-verified).

## 4. The experiments (each must end in a test that passes and a feature that runs)
### Pillar A: Living fighters
**E0 Bout logger and throughput harness** (foundation). Record deterministic bouts as (seed, tick, observation vector, input) and measure ticks/s. *Success:* 100k decisions logged per minute, replay reproduces the exact result. *Why first:* it feeds E1, E2, E3 and every regression test.

**E1 Ghosts: behaviour-cloned player style.** Train a small MLP (2 x 64) with PyTorch on logged bouts of a player; export int8 weights as JSON (a few KB); run it in GDScript as an `AiProvider`. Uses: (a) your retired champion defends the tournament ladder; (b) your critter's ghost lives in the Hall and can be challenged; (c) export/import a ghost as a short text/QR so players can swap ghosts on Discord: **asynchronous PvP with no server**. *Bootstrap without human data:* clone the expert AI profile to prove the pipeline, then add the creator's real bouts. *Success:* ghost reproduces the source's action statistics within 15% (guard rate, dodge timing, engagement distance, ability mix) AND wins 40-60% against its source over 200 bouts; weights < 20 KB; identical result on two machines. *Kill:* cannot beat the novice AI after tuning, or results differ between runs. *Risk:* human data is scarce: mitigate with data augmentation (mirror, speed) and DAgger-style correction runs.

**E2 Self-play gym with evolution strategies.** Population training inside the sim (ES or PPO via a bridge) produces skilled, personality-regularised policies per critter (Bramvex keeps range; Mollusk turtles; Zephyr evades). Observation: relative position and velocity, stamina, poise, vitality, opponent action id and frame, cooldown flags, arena edge distance. Action: 9-way move + {none, strike, heavy, guard, dodge, ability1-3, grab}. Reward: win/loss plus shaped damage differential, with style regularisers so training does not collapse every critter into the same strategy. *Success:* a learned policy beats the hand-written "expert" AI >= 60% for at least 4 critters within 24 CPU-hours; behaviour is visibly in character. *Kill:* no gain over the expert AI after 48 CPU-hours, then fall back to imitation of the expert plus search. These policies become "Elite" opponents and the tournament boss tier.

**E3 Balance oracle.** Run E2 policies across the 8 x 8 matrix at the *skill ceiling* to find degenerate strategies (stalling, ring-out loops) and measure the creator's target (<= 5-point spread, no matchup beyond 38/62) where it matters: against strong play, not against scripted AI. Output: ranked list of tuning levers with predicted win-rate change; applied by an automatic hill-climb with human-readable diffs. *Success:* spread <= 5 points at expert and at learned-elite level, stable across 3 seeds. *Risk:* balance chased by a learner can overfit; mitigation: hold-out opponents and human sanity checks.

**E4 Rival memory.** Opponents keep a compact model of your habits (bandit over your opening, guard timing, ability use) and counter it within fairness rules (adaptation is telegraphed in the intro: "he watched you"). Reuses E1's feature extractor. *Success:* adaptive rival beats a fixed-habit player 65% after 5 bouts but not a varied player; players report it as fair.

### Pillar B: Animation by intent (the Elden Ring feel)
**E9 Animation lint (do this first).** Automatic metrics so autonomous workers can iterate without a human eye: foot sliding, joint-limit violations (per-bone anatomical limits), limb-through-body proxy, silhouette readability (anticipation vs impact pixel difference from a side camera), momentum curve (a velocity peak must land on the impact frame; anticipation must move the centre of mass AWAY from the target), timing equals the sim's startup/active/recovery frames. *Success:* every clip of Bramvex passes; deliberately broken clips fail. *Why:* it is the multiplier for everything else.

**E5 Effector-path animation.** Describe each move as paths of the weapon tip, hands and feet in body-relative space plus body mechanics (weight shift, lean, hip lead), and let Godot's IK modifiers solve the limbs. Retargets automatically to other body plans (claws, tentacles, extra legs) by naming effectors instead of angles. *Success:* Bramvex light, heavy, guard and grab produced from <= 12 paths each; creator prefers them over the current hand-keyed poses in a blind A/B; passes E9. *Kill:* IK solutions jitter or break on the stick limbs and cannot be damped.

**E6 Baked physics reactions.** Offline, simulate hit reactions with an articulated rigid-body model of each critter's real mass distribution (CPU physics library): 8 impact directions x 3 strengths + fall/KO + get-up per critter, stored as compressed bone curves (about 2 MB for all eight), blended at runtime. Physical weight with zero runtime cost. *Success:* reactions differ visibly by direction and by critter mass; pass E9. *Kill:* the offline sim cannot reproduce a believable stick-body reaction. *Check first:* a physics package that fits the disk budget.

**E7 Generated motion as reference (humanoid critters only).** Use Kimodo-class text-to-motion on CPU to produce blocking references for Aruun, Bramvex, Cigarra and Scarlith, retargeted by bone mapping, then convert to effector paths (E5) instead of shipping raw. *Gate:* CPU time per clip < 10 min, licence allows commercial use, quality beats my hand blocking. Otherwise drop.

**E8 Personality grammar.** One motion engine, eight bodies: a style vector (weight, snap, hold time, overshoot, tremor, economy) drives timing and easing; anatomy files define joint limits and effectors; creators' personality notes become numbers. *Success:* a blind test where the creator matches each clip to the right critter 7 of 8 times.

**E10 Auto-rig benchmark.** Run UniRig (or its skeleton stage) on the squatting Bramvex and on each critter; score skinning with E9's test poses against my region-weight pipeline. *Success:* error below my pipeline on 5 of 8 critters would let us skip standing re-generations. *Check first:* disk space (model weights), CPU run time.

### Pillar C: Production AI
**E11 Content foundry.** Offline LLM generation (by me) of lore-consistent rival names, grudges, jar events, move text, tips; a validator checks each line against the lore bible and critter data; shipped as JSON, no runtime LLM and no runtime cost. *Success:* 5,000 lines pass validation; the creator rejects < 10% in review.

**E12 Playtest swarm.** Headless bots (E2 policies for combat, scripted UI flows for the career loop, economy simulators for Jar and scrap) run nightly: crashes, softlocks, hitches, economy dead ends, exploits. *Success:* zero softlocks in 10,000 simulated career hours.

**E13 Weekly research digest.** A scheduled routine searches for Godot, Tripo, rigging, motion, physics-character and game-AI news and appends verdicts (adopt / watch / ignore) to `production/RND_LOG.md`. *Success:* one actionable item per month that we adopt or consciously reject.

### Pillar D: Radical bets (small, cheap, may change the product)
- **Ghost exchange:** a critter's ghost as a pasteable string; "challenge a friend's champion" with no backend.
- **Legacy mode:** when a critter dies, the ghost can be adopted by the Jar as its "elder"; descendants inherit a blend of ancestor styles (generations on hold, design now).
- **Style fingerprints:** a radar chart of how each of your critters fights (aggression, patience, parry rate), shown on the Hall page; nothing else shows players how *they* play.
- **Adaptive tutorial:** the cloned-AI-of-the-tutorial adapts to teach the skill you are weakest in.

## 5. Roadmap at developer pace
Phase 0, weeks 1-2: foundations. E9 lint v0, E0 logger and throughput harness, per-bone joint limits, side-view contact sheets, Bramvex club and springs, disk hygiene, weekly digest routine, resume the thin engineering track for the APK (`BETA_ROADMAP` M1) because beta is blocked on it.
Phase 1, weeks 3-6: prove the two big bets on ONE critter. E5 effector paths for Bramvex (A/B with current), E2 gym v0 (Aruun vs Bramvex), E1 cloning of the expert AI, E10 benchmark.
Phase 2, weeks 7-12: Bramvex to the standard (full clip set, E6 reactions), generic rig tool (G1), Aruun through it, E2 across all critters, E3 oracle reports, E1 prototype in tournament defences.
Phase 3, months 4-6: one critter every 2-3 weeks (rig, animate, learned elite), ghost system in the Jar and Hall, adaptive rivals, balance to the 5-point target at skill ceiling, beta track resumes in parallel.
Review gates: end of weeks 2, 6, 12 and 24. At each gate we drop anything that missed its kill criterion and write down why.

## 6. How the autonomous workers use this
Lane 1 (now): Bramvex remaining steps in `AUTONOMY.md`. Lane 2 (queued after Bramvex steps): E9 lint and E0 logger. Lane 3 (weekly): research digest. Experiments E1/E2 are long-running: a worker starts a training run in the background, logs the generation scores, and stops; the next run reads the log and continues. Every run commits a note, never silently changes gameplay data; combat tuning from E3 needs the creator's OK.

## 7. Risks and honest unknowns
- Learned policies can be exploited by humans (ES opponents overfit). Mitigation: population of opponents, human playtests, hold-out.
- Behaviour cloning from one creator's play is a narrow sample: ghosts may feel samey. Mitigation: augmentation and a "style noise" parameter.
- IK on stick limbs and cloth springs may be unstable; E9 and conservative damping.
- Disk: 3.7 GB free means no large model downloads; each experiment states its footprint.
- IP: AI-generated 3D (Tripo) and any generated motion need provenance notes in `ASSET_LICENSES` before store submission.
- Everything here is slower than a normal feature: that is the point of the phases and kill criteria.

## 8. Decisions needed from the creator
1. Is "your critter learns your style and leaves a ghost" a direction you want (it touches permadeath identity and the Hall)?
2. Are learned "Elite" opponents and ghosts allowed to be harder than the scripted expert AI?
3. OK for ghosts to be shared as pasted strings (no accounts, no server)?
4. How much of your own play should be recorded (opt-in, local only) to train your ghost?
5. Is the research digest weekly, or monthly to save usage?
6. Priority order of pillars A (living fighters) and B (animation) when time is tight? Default: B for Bramvex first because it is already underway, A in parallel as autonomous background work.

## Sources
- [Godot 4.6: IK returns](https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/), [Godot 4.7 dev snapshots](https://godotengine.org/article/dev-snapshot-godot-4-7-beta-1/), [SkeletonModifier3D docs](https://docs.godotengine.org/de/4.x/classes/class_skeletonmodifier3d.html)
- [NVIDIA Kimodo (text-to-motion)](https://rits.shanghai.nyu.edu/ai/nvidia-releases-kimodo-controllable-text-to-motion-for-characters-and-humanoid-robots/), [Motion Diffusion Model](https://github.com/guytevet/motion-diffusion-model), [Uthana text-to-motion v2](https://replicate.com/uthana/text-to-motion-diffusion-v2)
- [DeepMimic](https://arxiv.org/pdf/1804.02717), [AssistMimic (2026)](https://arxiv.org/html/2603.11346v1)
- [UniRig](https://arxiv.org/html/2504.12451v1), [UniRig on GitHub](https://github.com/VAST-AI-Research/UniRig)
- [DeepMind and game developers (2026)](https://www.startuphub.ai/ai-news/ai-research/2026/deepmind-s-game-ai-evolves.md), [KRAFTON: AI for games](https://www.invenglobal.com/articles/23482/ai-for-games-krafton-highlights-three-fronts), [Google: AI meets the games industry](https://services.google.com/fh/files/misc/global_ai_meets_the_games_industry.pdf)
- [Tripo rig API](https://developers.tripo3d.com/en/models/rig), [Tripo animation API](https://developers.tripo3d.com/en/models/animation)
