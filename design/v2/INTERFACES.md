# CRITTER v2 — Interfaces between teams (contract; change only via Lead)

Project root: `v2/` (Godot 4.7, Compatibility). Folder ownership (one owner per folder; no one else edits it):
```
v2/project.godot                      Lead
v2/src/core/**      Platform Engineer (events, settings, perf, quality, save, input maps)
v2/src/combat/**    Combat Engineer   (CombatSim, moves, AI, tournament bot)
v2/src/critters/**  Character Artist  (rigs, shaders for characters, expressions, turnaround scene)
v2/src/arena/**     Arena/Scene Engineer (arenas, camera, hazards, wiring a bout together)
v2/src/ui/**        UI Engineer       (HUD, menus, Rack, jars, story panels, touch controls)
v2/data/critters/*.json, v2/data/moves/*.json   Combat Engineer owns the numbers; Lead owns identity (names, palettes)
v2/tools/** (qa runner, smoke, lint)   Platform Engineer; v2/tools/sim/** Combat Engineer; v2/tools/qa/tests/ shared (each agent owns its own test files)
v2/data/story/**    Platform Engineer (chapter rules; Lead owns story content)
Lead exemption: the Lead may edit any folder (integration, project.godot).
```
## 1. Combat simulation (pure logic, no Nodes; deterministic; 60 Hz)
```gdscript
class_name CombatSim extends RefCounted
func _init(a: CritterDef, b: CritterDef, arena: ArenaDef, stakes: int, seed: int) -> void
func step(input_a: CombatInput, input_b: CombatInput) -> void      # advances exactly one tick
func state() -> Dictionary                                          # snapshot: tick, fighters[2]{pos, facing, vitality, stamina, poise, action, action_frame, status[], cooldowns{}}
func take_events() -> Array[Dictionary]                             # presentation events since last call
func is_over() -> bool ; func result() -> Dictionary                # {winner, reason: ko|ringout|yield|timeout, killed: bool}
class_name CombatInput extends RefCounted   # one per fighter per tick
var move: Vector2 ; var strike_tap: bool ; var strike_hold: bool ; var guard: bool ; var grab: bool ; var dodge: bool ; var ability1: bool ; var ability2: bool ; var yield_pressed: bool
```
Events: `{type: "tell"|"hit"|"block"|"parry"|"clash"|"grab"|"dodge"|"stagger"|"ringout"|"ko"|"laststand"|"yield", fighter: 0|1, move_id, pos, damage, tick}`.
Data: `v2/data/critters/<id>.json` (stats, move ids, ability ids) and `v2/data/moves/<id>.json` (startup, active, recovery frames; hitbox; damage; poise damage; stamina cost; properties: unblockable, armor, guard_crush; tell_anim key).
## 2. Critter rig (visual)
```gdscript
class_name CritterRig extends Node3D
func setup(critter_id: String) -> void
func apply_fighter_state(fs: Dictionary, dt: float) -> void   # drives pose from {action, action_frame, move_id, vitality_ratio, facing}
func play_event(ev: Dictionary) -> void                       # hit reaction, expressions, smear
func set_expression(name: String) -> void                     # calm|grin|angry|hurt|scared|dying
func socket(name: String) -> Node3D                           # weapon_tip, hand, head, ground
```
Pose keys for each `tell_anim` and action (idle, walk, strike_light, strike_heavy, guard, parry, grab, dodge, ability1, ability2, laststand, hit, stagger, ko) are authored in the rig by the Character Artist from the frame data's phases (anticipation/active/recovery).
## 3. Presentation glue (Arena/Scene Engineer)
`BoutScene` owns a `CombatSim`, two `CritterRig`s, camera, arena meshes, hit-stop, shake, impact frames; reads inputs from `InputProvider` (touch/gamepad/AI).
## 4. Rules
- Gameplay numbers live in data files and are never hard-coded in rigs or UI.
- The sim never touches rendering; rigs never decide gameplay.
- Every public function used by another team has a test in `v2/tools/qa/`.
- A change to this file requires the Lead's approval and a version bump below.
Contract version: 1
