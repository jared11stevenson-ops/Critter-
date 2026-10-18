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
- [ ] B2 Godot `SkinnedRig` node (`v2/src/critters/skinned_rig.gd`): loads `res://art/models/<id>_skin.glb`, finds the Skeleton3D, exposes `play(state)` and a procedural idle + walk driven by code (bone pose rotations). Test `test_skinned_rig.gd`: loads, bones present, idle runs 120 frames without errors. One screenshot via `v2/tools/shoot_flow.sh`.
- [ ] B3 Club prop on bone `grip_R` (BoneAttachment3D, mesh from `v2/art/models/bramvex.glb` node `weapon`), SpringBoneSimulator3D on `cf1..3` and `cb1..3` (cloth). Add Blender antenna bones (3 per side) to `bramvex_skin.py`, rebuild, spring them too.
- [ ] B4 Animation set generated in code from move frame data (`v2/src/critters/skin_anims.gd`): idle, walk, run, backpedal, dodge (fold), guard, light x3, heavy, grab, ability1-3, last stand, hurt light/heavy, stagger, knockdown, get-up, win, lose, KO. Left hand = Command Hand per `design/v2/anatomy/bramvex.md` section 7. Test: each clip's key frames line up with the move's startup/active/recovery frames.
- [ ] B5 Bout integration behind a per-critter flag in `rig_build.gd` / `critter_rig.gd` (use SkinnedRig when `<id>_skin.glb` exists and `skinned: true` in `<id>.json`; fall back to the old part rig otherwise). Tests + smoke bout + perf (draw calls, tris) must pass.
- [ ] B6 Review sheet for the creator: one contact sheet of all clips, note known issues. STOP and wait for the creator's OK before the next critter.
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
