# Autonomous rigging and animation queue

Read by the scheduled "CRITTER rig worker" routine (fresh session each run, no memory). Creator priority 1: combat. Goal: all 8 critters get a skinned skeleton and proper animation, ONE critter at a time, in the order below. Creator rule: use as little usage as possible, but use what is needed.

```
runs_left: 16
last_run: never
```

## Rules for every run (read first, obey strictly)
1. `cd /home/user/critter && git pull --ff-only`. Read this file. If `runs_left` is 0 or less: print "paused: budget used up" and STOP (no other tool calls).
2. Decrement `runs_left`, set `last_run` to the current UTC time, commit and push that single change immediately (`git commit -m "autonomy: run counter"`), so the budget is spent even if the run fails.
3. Pick the FIRST unchecked step below whose "needs" are all satisfied (files present in the repo). If the first unchecked step needs something only the creator can give, append a one-line "waiting for ..." to the log and STOP.
4. Do that ONE step only. Limits: at most about 25 tool calls, at most ONE image view (a contact sheet), no long polling (use one background run plus one wait), never leave processes running.
5. Verify: if game code changed, run `GODOT=/opt/godot/Godot_v4.7.2-stable_linux.x86_64 bash v2/tools/qa/run_tests.sh` (all test files must pass; the first time in a fresh container run `/opt/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path v2 --import` once). If anything fails and cannot be fixed within the step, revert your changes (`git checkout -- .`), log what failed, and STOP.
6. If it passes: tick the step, append a log line (date, step, result, one honest sentence), commit and push to master. Commit messages end with the standard attribution lines for the session.
7. NEVER: change combat balance or move data, touch the Jar / economy / career code, delete files, force-push, bump the version or publish a release (the creator asks for releases), ask for or print secrets, or spend money. Do not start the next step in the same run.
8. Blender needs `python3` with the `bpy` module (already installed). Run builds in the background and wait with one until-loop Monitor. Run at most one Blender job at a time (RAM 15 GB).
9. Keep the creator's notes honest: say what was NOT verified.

## Critter order
1 Bramvex, 2 Aruun, 3 Cigarra, 4 Scarlith, 5 Zephyr, 6 Pharilux, 7 Nyxaris, 8 Mollusk.
Each critter needs a creator-supplied STANDING T-pose Tripo GLB (arms out, legs apart, no weapon, cloak open) saved by the Lead session at `tools/source_art/<id>_standing.glb`. Bramvex's is already done (`/tmp` source is gone in fresh containers: see step B0).

## Steps
### Bramvex (needs: v2/art/models/bramvex_skin.glb and tools/source_art/bramvex_standing.glb)
- [x] B0 (done by Lead 2026-10-18, standing source is in the repo) Make the build reproducible: the standing source GLB must live in the repo as `tools/source_art/bramvex_standing.glb` (the Lead session copies it; if missing, STOP and log "waiting for bramvex_standing.glb"). Update `bramvex_skin.py` to read it (decode with `npx @gltf-transform/cli copy` to /tmp first).
- [x] B2 (done by Lead 2026-10-18: `v2/src/critters/skinned_rig.gd` + `skin_poses.gd`, contact sheet `--screen=skinsheet`, test `test_skinned_rig.gd`) Godot `SkinnedRig` node (`v2/src/critters/skinned_rig.gd`): loads `res://art/models/<id>_skin.glb`, finds the Skeleton3D, exposes `play(state)` and a procedural idle + walk driven by code (bone pose rotations). Test `test_skinned_rig.gd`: loads, bones present, idle runs 120 frames without errors. One screenshot via `v2/tools/shoot_flow.sh`.
- [ ] B3 Club prop on bone `grip_R` (BoneAttachment3D, mesh from `v2/art/models/bramvex.glb` node `weapon`), SpringBoneSimulator3D on `cf1..3` and `cb1..3` (cloth). Add Blender antenna bones (3 per side) to `bramvex_skin.py`, rebuild, spring them too.
- [ ] B4 Animation set generated in code from move frame data (`v2/src/critters/skin_anims.gd`): idle, walk, run, backpedal, dodge (fold), guard, light x3, heavy, grab, ability1-3, last stand, hurt light/heavy, stagger, knockdown, get-up, win, lose, KO. Left hand = Command Hand per `design/v2/anatomy/bramvex.md` section 7. Test: each clip's key frames line up with the move's startup/active/recovery frames.
- [x] B5 (done by Lead 2026-10-18 in bout_scene.gd: SkinnedRig is used whenever `<id>_skin.glb` exists; smoke bout bramvex vs aruun ends in KO, 31 test files pass; STILL TO CHECK: perf (smoke reported tris_max 518k, draws_max 214, check against other critters), look at a side-view bout screenshot) Bout integration behind a per-critter flag in `rig_build.gd` / `critter_rig.gd` (use SkinnedRig when `<id>_skin.glb` exists and `skinned: true` in `<id>.json`; fall back to the old part rig otherwise). Tests + smoke bout + perf (draw calls, tris) must pass.
- [ ] B6 Review sheet for the creator: one contact sheet of all clips, note known issues. STOP and wait for the creator's OK before the next critter.
### Bramvex remaining work (do these before B6, in this order, one per run)
- [ ] B3a Club prop: attach the mesh of node `weapon` from `v2/art/models/bramvex.glb` to a BoneAttachment3D on `grip_R` (so he actually holds Diplomacy), orient it down-forward in the idle stance, and make `socket("weapon_tip")` the club head. Verify with `--screen=skinsheet` (one image).
- [ ] B3b Cloth/antennae springs: SpringBoneSimulator3D on `cf1..3`, `cb1..3` (banner and back shreds). Add antenna bones (3 per side) in `bramvex_skin.py` (rebuild the GLB with the `final` stage, ~12 min in the background) and spring them too.
- [ ] B4a Animation polish against the ELDEN RING STANDARD below, judged from a SIDE view contact sheet (add `--side` to `skin_sheet.gd`): fix anything that reads wrong (arms crossing the body, T-pose-like stubs, feet sliding).
- [ ] B4b Missing clips: run (faster, leaning forward), backpedal, strafe, dodge in 4 directions, parry flick, win and lose poses, get-up from knockdown, last-stand roar, ability poses specific to Branchline / Thorn Salvo / Bat Sweep / Sergeant's Mark / Impale the Ground (design/v2/anatomy/bramvex.md sections 3 and 7).
- [ ] B4c Feet planting: simple foot-lock so feet do not slide during walk (TwoBoneIK3D on legs) and head LookAt toward the opponent.
- [ ] B5b Perf check: compare draw calls and triangles of a bout with the skinned Bramvex against another critter on `tools/shoot_bout.sh`; if skinned Bramvex costs much more, reduce (outline pass, normal map on Low quality).

### R&D enablers (lane 2; do after the Bramvex steps above, see production/RND_STRATEGY.md)
- [ ] E9a Animation lint v0 (`v2/tools/qa/tests/test_anim_lint.gd`): for every action of every skinned critter check finite poses, per-bone joint limits (table in `skin_poses.gd`), the weight shifts BACK in anticipation and FORWARD at impact, impact frame equals the move's startup frame, clip never leaves the arena-scale root range. Deliberately broken clips must fail.
- [ ] E0a Bout logger: `v2/tools/sim/log_bouts.gd` records (seed, tick, compact observation vector, input) for AI-vs-AI bouts to `v2/tools/out/bouts/*.jsonl` (git-ignored) and replays them to verify determinism; report ticks/s.

- [ ] F2a Replay + fuzz harness (production/FRINGE_LAB.md F2): `v2/tools/lab/fuzz_sim.gd` runs random and grammar-based input streams through the sim with invariants (no NaN, no stuck action, no negative stamina, ring-out resolvable); prints failures with replay strings; 200k ticks per run.
- [ ] F1a Lint-as-loss spike (production/FRINGE_LAB.md F1), only after E9a exists: `v2/tools/lab/opt_pose.gd` optimises Bramvex's strike_light key poses against the lint score with a simple evolution strategy; output a before/after contact sheet for the creator. Time-box: one run to build it, one to run it.

## ELDEN RING STANDARD for every animation (creator's bar)
Weight and commitment, not floaty: (1) every attack has a readable anticipation that coils the body AWAY from the target and shifts weight back (startup frames), a short hold with a tremble, then a violent snap through the impact with overshoot (active frames), then a long settle with the weapon dragging (recovery frames); (2) heavy attacks are slower to wind up than they look and recover with the body low, hips lead, shoulders follow, weapon last; (3) the root moves: lunge forward on impact, step back on anticipation, never slide on the spot; (4) dodges commit (fold low, long recovery), guard plants the feet, hits knock the upper body away from the blow and let it spring back; (5) idle and walk are alive but economical (breathing, weight shift, cloth and antennae follow with a delay); (6) timing always comes from the sim frames (Timing.resolve), never invented; (7) personality: Bramvex is disciplined and economical (no flourish, short exact movements, the free hand gives the orders).

### Generic tooling (needs: B6 done)
- [ ] G1 Generalise `bramvex_skin.py` into `tools/blender/rig/skin_build.py` with a per-critter config (bone table, landmark auto-measurement, weight rules) so each new critter only needs a config. Document in `tools/blender/rig/README.md`.
### Next critters (each needs `tools/source_art/<id>_standing.glb` and G1 done)
- [ ] Aruun: measure -> config -> skin build -> pose sheet (X1), animations (X2), integrate (X3), review (X4)
- [ ] Cigarra (same four steps)
- [ ] Scarlith (same four steps)
- [ ] Zephyr (same four steps)
- [ ] Pharilux (same four steps)
- [ ] Nyxaris (same four steps)
- [ ] Mollusk (same four steps; snail body, hardest)

## Log (newest last; one line per run)
- 2026-10-18 Lead session: skinned Bramvex v4 built (31 bones incl. cloth chains cf1-3/cb1-3 and grip_L/R); legs/feet/arms/wings clean in walk/strike/crouch tests; known issue: central red banner and skirt streak in deep leg folds (fix with spring bones in B3). Not yet in the game. Schedule created: two hourly routines (:07 and :37 UTC) each doing one step; stops when runs_left hits 0.
- 2026-10-18 Lead session: SkinnedRig + skin_poses.gd written and tested (31 test files pass); Bramvex now uses the skinned rig in real bouts. Poses are first-pass: judged only from a front-facing sheet and one 3/4 bout shot; side-view review, club, springs, run/strafe/directional dodge, win/lose, foot planting still to do (see Bramvex remaining work). Routines A/B re-enabled.
