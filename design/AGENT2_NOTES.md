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
- Per preset: append `qa_quality=low|medium|high` (default in QA = Auto → High on desktop).
- Frame-cost bench: `tools/shot.sh res://game/world/red_reaches/red_reaches.tscn /tmp/s/b 5.5 19.5 res://tools/qa/scripts/bench_rr.json qa_bench=3-6,9.5-12.5,16-19 qa_quality=medium`
- Mid-level Continue: `... title.tscn /tmp/s/mid 28.5,38.5 40 res://tools/qa/scripts/continue_midlevel.json`
- Boss phases 2/3 + beam: `tools/shot.sh res://game/world/red_reaches/red_reaches.tscn /tmp/s/b 8,11.5,20.5 27 res://tools/qa/scripts/rr_boss_phases.json`
- Draw-call breakdown: `... red_reaches.tscn /tmp/s/p 3.4 25 res://tools/qa/scripts/rr_perf.json` (prints `PERF BREAKDOWN`)
- Other resolutions: same args to Godot with `--resolution 1600x720` / `2400x1080` and a matching Xvfb screen.

## Graphics quality / mobile perf pass (v0.7.1)
- `Quality` autoload (`game/core/quality.gd`): Settings → Graphics cycles **Auto / Low / Medium / High**, Frame rate
  **30 / 60**. Persisted in `GameState.settings` (`gfx_quality`, `fps_cap`, `gfx_auto_level`). First launch = Auto:
  **Medium on phones/web, High on desktop**; after ~5 s of 3D gameplay Auto measures real frame time and steps down
  one level (toast) if it misses the FPS budget by >30 %. Auto never downgrades in QA runs (`qa_autoprobe` to test).
- Levels: LOW render scale 0.7 (capped to 620 px tall), no MSAA, no sun shadows (blob shadows only), no glow, no fog
  sun-scatter/aerial, no dust motes, no decorative omni lights, scatter 30 %, particles 50 %, aniso off, cheapest
  shader variants. MEDIUM scale 0.85 (≤ 860 px), no MSAA, 1024 single-split shadow ≤ 30 m (hard PCF), glow, scatter
  60 %, particles 75 %, reduced shaders. HIGH = the v0.7.0 look (MSAA 2x, 2048 2-split soft shadows, full shaders).
- Shader variants: `Quality.shader(key, code)` injects `#define QUALITY_LOW/MEDIUM` and recompiles in place when the
  level changes. terrain_pbr: 13 samples → 7 (Med) / 3 (Low, dominant-plane cliff, no normal maps, Lambert);
  toon_prop: 9–10 → 3 (Med, tri-planar albedo) / 1 (Low); sky clouds off on Low. ToonKit.occluding_shader routes
  through it automatically.
- Always on (all levels): sky shader no longer reads TIME (it forced a sky radiance rebuild every frame; clouds step
  every 4 s on High), mood blend 10 Hz + sky colours ≤ 2 Hz, scatter split into 48 m X-chunks (frustum + shadow
  culling; was one level-wide MultiMesh per kind), terrain chunks 64 → 48 m, billboard uniforms only re-uploaded when
  changed, off-screen creatures skip gait uniforms, CPUParticles share one quad mesh.
- Profiling: `qa_bench=a-b,...` prints `[QA] BENCH` with **process CPU ms/frame** (all threads incl. llvmpipe, from
  /proc — robust to other agents' Godot processes; wall time is not, and `delta` is capped at 8 physics ticks so
  never use it for timing). `qa_toggle=noshadow+nomsaa+...` switches features off; `qa_quality=low|medium|high`,
  `qa_fps=30`. Script: `tools/qa/scripts/bench_rr.json` (valley / drill / boss).
- v0.7.0 feature costs (CPU ms/frame valley/drill/boss, 1280x720 llvmpipe; base 855/704/1233): MSAA 2x −30/−23/−49 %,
  terrain PBR shader −31/−36/−34 %, render scale 0.5 −50 %, sun shadows −13 %, glow −5 %, sky TIME −4 %, fog / motes /
  structures / scatter ≈ 0 on llvmpipe (scatter halves primitives, matters more on phone GPUs).

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

## Ledger integration (Phase 1) — what exists now
- **Run flow**: level `_begin_ledger_run` (Ledger.begin_run once per descent, resume-safe), `_end_ledger_run` in `_exfil`
  (all_conscious = nobody downed), `party_wipe` recorded on wipe. Hub `_return_sequence`: LedgerCard (debrief_lines +
  opinion_shift_lines + rival outcomes) -> Reaction Matrix barks (`take_reaction(char,"return")`, count by Story tone) ->
  hub_debrief the first time. End card shows the same Ledger facts.
- **Rivals**: `game/enemies/rival_enemy.gd` (AI; tactic->behaviour map in its header), `game/world/red_reaches/rival_encounters.gd`
  (spawn from `Rivals.active_in` + released bondables, greeting, resolution panel, outcomes). Orrin at the Drill Site,
  Vesk (ambush) near the Waystation. Rivals never die: at flee_at they yield; 12 s to choose or they escape. Scanning
  the Survey Camp records `evidence` (unlocks "Expose them"). "Return Descent" (Gate Map, after rr_complete) drops you at the
  Waystation with every unresolved rival already out there, adapted.
- **Bond Contracts**: `BondScreen` (hub "Bonds" button + pause menu): stage track, contradiction, test hint, opinion, live promise.
- **Session Zero + Director**: `SessionZero` after New Game (pause menu to revisit); `Director` (static) scales enemy HP/damage,
  pickups, scan radius, burden hold time, return barks, and shows the ONE rule (advantage/disadvantage toast).
- **Gate Map**: `GateMap` replaces the Gate confirm dialogue: blank / rumored / charted homelands, Red Reaches route fills in.
- QA: `tools/qa/scripts/{rival_orrin,rival_return,hub_ledger,session_zero,gate_map}.json`. Title skips Session Zero in QA
  unless `qa_session_zero` is passed.
- Known: full flow peak draw calls 155 (hub/habitat, was 154 before); rival body is a primitive placeholder (FallbackVisual
  "rival_<faction>") until Agent 1/4 supply art.
