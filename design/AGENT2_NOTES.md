# Agent 2 — Gameplay / UI / UX notes

## Status (this branch)
- **UI**: title (Continue / New Game / Settings / Credits), two-column Settings (fits 720p), Credits card
  (World & characters, **Music: Youngyumeprophecy**, Godot MIT, fonts from CREDITS.md), dialogue box (word-wrap,
  portraits, comms/narration styles, choices), pause, Field Codex (5 tabs), HUD (boss bar top-centre under the
  objective; ability arc + captions on plates; scan labels screen-space), Habitat builder, end card.
- **Hub**: hub_visual.tscn if present, else `hub_fallback_room.gd`; hotspots + NPC labels with overlap avoidance;
  toasts bottom-centre. **Habitat**: `habitat_visual.tscn` if present, else `habitat_fallback.gd`.
- **Flow**: Title → New Game → hub_intro → Gate → Red Reaches beats → boss → choice (repair/extract) → exfil →
  debrief → habitat → hub_hook → end card → free roam. Continue resumes hub or RR checkpoint.
- **Balance**: every tunable number in `game/combat/balance.json` (hit-stop, shake, cooldowns, enemy stats).

## QA commands (from the worktree root)
Run `/opt/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --quit --path .` after `tools/validate.sh`
(the 4.3 pass leaves a class cache 4.7.2 can't read → "UiKit not declared"); then `git checkout -- '*.import'`.
- UI tour: `tools/shot.sh res://game/ui/title/title.tscn /tmp/s/tour 1.5,3.2,5.0,8.5,16.5,18.5 21 res://tools/qa/scripts/ui_tour.json`
- Hub late game: `tools/shot.sh res://game/world/hub/hub.tscn /tmp/s/hub 5,8.5,15.5,19 20 res://tools/qa/scripts/ui_tour_hub.json qa_flags=briefed,rr_complete,debriefed`
- Full flow (repair): `tools/shot.sh res://game/ui/title/title.tscn /tmp/s/ffr 10,46,70,96,105 108 res://tools/qa/scripts/full_flow.json`
- Full flow (extract): same with `full_flow_extract.json`
- Mid-level Continue: `... title.tscn /tmp/s/mid 28.5,38.5 40 res://tools/qa/scripts/continue_midlevel.json`
- Boss phases 2/3 + beam: `tools/shot.sh res://game/world/red_reaches/red_reaches.tscn /tmp/s/b 8,11.5,20.5 27 res://tools/qa/scripts/rr_boss_phases.json`
- Draw-call breakdown: `... red_reaches.tscn /tmp/s/p 3.4 25 res://tools/qa/scripts/rr_perf.json` (prints `PERF BREAKDOWN`)
- Other resolutions: same args to Godot with `--resolution 1600x720` / `2400x1080` and a matching Xvfb screen.

## Perf notes
- Peak level draw calls 238 → ~125 (rr_perf) / 154 peak across the whole full flow. Biggest remaining chunk is the
  HUD (~65): TouchButtons draw shapes first then text, no outline passes; further gains need one canvas item for
  the whole button cluster.
- Fallback creature meshes are merged per material; small creatures rely on blob shadows.

## Fixed this session
- Knockback fed back into velocity every frame (6 m/s → 80 m/s launches): `Actor.body_move` now removes last
  frame's knock before steering.
- Full-rect Controls created in-tree used `set_anchors_preset` (keeps zero offsets) → codex/dialogue collapsed.
  Use `set_anchors_and_offsets_preset`.

## Known issues
- Agent 1 `character_billboard.gd:423` freed-instance spam in hub (REQUESTS.md).
- QA `choice_point` teleport lands beside the dead rig; party sometimes hidden by the rig's occlusion fade.
