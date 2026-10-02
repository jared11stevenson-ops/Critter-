# CRITTER — Production Contracts (Art ⇄ Gameplay)

Owner: **Lead**. Agents build against these interfaces in parallel. If you need a contract change,
implement the closest compliant version, then write the request in `design/REQUESTS.md` (append only).
Never silently change another owner's files.

## 0. Ground rules (both agents)
- **Godot 4.3+ compatible GDScript.** Must load cleanly on Godot **4.3** and **4.7.2**. No typed
  Dictionaries (`Dictionary[String, int]` is 4.4+), no `@export_tool_button`, no `.uid` dependence.
  Hand-written `.tscn` files: `format=3`, no `uid=` attributes needed.
- **Renderer: Compatibility (gl_compatibility).** Shaders must compile there. No compute, no
  `hint_depth_texture` reliance for core visuals (allowed for optional effects with fallbacks).
  No SSAO/SSR/SDFGI/volumetric fog. Glow OK. Fog OK.
- **Pure GDScript.** No C#, no GDExtension, no editor plugins required to run.
- **Mobile performance.** Target 60 fps on mid-range phones: ≤ 150 draw calls in the field
  (use MultiMeshInstance3D for scatter), ≤ 250k triangles on screen, textures ≤ 1024 px except
  character sheets (≤ 1024 tall), alpha-scissor over alpha-blend where possible.
- Lowercase snake_case filenames, no spaces.
- Indent with **tabs** in GDScript.
- Validate before you finish: `tools/validate.sh` must print `failed=0` on both engines.
- Screenshot QA: `tools/shot.sh <scene> <out_prefix> <shots> <quit> [qa_script]` renders through Xvfb
  with the exact renderer phones use. Look at your screenshots (Read the PNG) — judge them like a
  player would.
- Canon: `game/canon/canon.json` + `design/lore_bible_v12.txt`. Visual canon is **immutable**:
  never repaint, humanize or simplify characters. Characters are cut from the approved sheets.

## 1. Ownership
| Path | Owner |
|---|---|
| `game/core/*`, `project.godot`, `game/canon/*`, `design/*`, `tools/*`, `game/world/red_reaches/layout.json` | Lead |
| `game/narrative/dialogue/*.json` (story text) | Lead |
| `game/art/**`, `game/world/**/*_visual*`, `game/world/red_reaches/terrain*`, `game/world/hub/hub_visual*`, `game/world/common/*` | **Agent 1 (Art)** |
| `game/player/**`, `game/combat/**`, `game/enemies/**`, `game/ui/**`, `game/narrative/*.gd`, `game/world/red_reaches/red_reaches.tscn` + `level_*.gd`, `game/world/hub/hub.tscn` + `hub_*.gd` (except hub_visual), `game/world/habitat/*.gd` | **Agent 2 (Gameplay/UX)** |
| `game/audio/**` | Lead |

## 2. Autoloads (Lead, exist now)
- `Events` — global signals (`game/core/events.gd`). Add needed signals via REQUESTS.md, or add them
  yourself **at the end of the file** under a `# --- Agent N ---` comment.
- `Canon` — `Canon.character(id)`, `Canon.ability(id)`, `Canon.species(id)`, `Canon.display_name(id)`.
- `GameState` — flags, trust, items, specimens, codex, save/load, input map
  (actions: move_left/right/up/down, attack, ability_1..3, dash, swap, scan, interact, pause, capture).
- `Audio` — `Audio.sfx(name)`, `Audio.sfx_at(name, pos)`, `Audio.music(track)`. Call these with the
  names in §7 even before files exist (missing files are silent).
- `Router` — `Router.goto(path, "fade"|"gate")`.
- `QA` — test harness, inert in normal play.

## 3. Character billboards (Agent 1 builds, Agent 2 consumes)
Characters are **HD-2D billboards cut from the approved model sheets**.

Files per character id (`aruun`, `cigarra`, plus ambient hub cast `mollusk`, `bramvex`, `nerit`, `zephyr`,
`nyxaris`, `pharilux`, `solmara`, `scarlith`, and humans `mara`, `dexter`):
- `res://game/art/characters/<id>/front.png`, `side.png` (**facing screen-right**), `back.png`
  — transparent background, tightly trimmed, feet touching the bottom edge, horizontally centered on the
  body's center of mass. Missing views fall back: back→front, side→front.
- `res://game/art/characters/<id>/meta.json`: `{"height_m": 2.4, "feet_y_px": <optional>, "views": ["front","side","back"]}`

Scene: `res://game/art/characters/character_billboard.tscn` (root `Node3D`, script `character_billboard.gd`,
`class_name CharacterBillboard`). API (all must exist; no-ops are fine where noted):
```gdscript
@export var character_id: String          # loads textures + meta on _ready / when set
func set_facing(dir: Vector3) -> void     # world-space XZ direction the character faces; picks front/side/back
                                          # relative to the active camera, flips side for left
func set_move_amount(v: float) -> void    # 0..1 → procedural walk bob/sway/lean
func play_attack(kind: String = "light") -> void   # "light" | "heavy" | "cast" | "leap": squash/lunge anim
func flash_hit() -> void                  # white/red hit flash + small knock wobble
func set_downed(downed: bool) -> void     # slumped / desaturated
func set_highlight(color: Color, on: bool) -> void # scan/selection rim
func set_ghost(alpha: float) -> void      # for False Memory decoys / future ghosts (tinted translucent)
func get_height() -> float                # meters
```
Rendering: `Sprite3D`-based (or quad + shader), Y-axis billboard, alpha scissor, ink outline, soft blob
shadow on the ground, subtle rim light. Pixel size computed so the texture height == `height_m`.

## 4. Portraits & icons (Agent 1)
- Dialogue portraits: `res://game/art/portraits/<id>/<expression>.png` (square-ish crops of the head
  studies / expressions on the sheet, ≥ 160 px). Expression names from `canon.json`. Also
  `res://game/art/portraits/<id>/default.png` for every character.
- Ability icons: `res://game/art/icons/<ability_id>.png` (crops from the sheet's ability panels, 256×256),
  ability ids from `canon.json` (`reaching_strike`, `gravity_pull`, `beetle_rage`, `aruun_combo`,
  `bad_thought`, `premonition`, `false_memory`, `brain_skip`, `grasshopper_thought`).
- Key art: `res://game/art/ui/key_art_*.png` for the title screen and loading cards.

## 5. Creatures (Agent 1 visuals, Agent 2 AI)
`res://game/art/creatures/<species_id>.tscn` — root `Node3D` with script exposing:
```gdscript
func set_facing(dir: Vector3) -> void
func set_move_amount(v: float) -> void
func play_attack(kind: String = "light") -> void     # windup+strike anim
func play_telegraph(duration: float) -> void          # windup pose / glow so the player can read it
func flash_hit() -> void
func play_die() -> float                              # returns seconds until visual is done
func set_highlight(color: Color, on: bool) -> void
func set_ghost(alpha: float) -> void                  # used by Premonition future ghosts (duplicate instance)
func get_radius() -> float                            # body radius in meters, for collision sizing
```
Species: `skitter_mite` (r≈0.5, swarm), `plate_beetle` (r≈1.4, heavy), `dust_grazer` (r≈0.9, passive,
long legs), `dominion_drone` (r≈0.6, hovering 1.6 m, red Dominion accent light), `augur_rig` (boss,
r≈6, drill arm with node `DrillTip` (Marker3D), three `Vent1..3` Marker3D nodes, `Core` Marker3D; extra API:
`set_phase(p:int)`, `open_vents(on: bool)`, `play_drill_slam()`, `set_beam(on: bool, angle: float)`).
Style: procedural low-poly insect anatomy (segments, legs, antennae) with the shared toon/ink shader so
they sit in the same illustrated world as the painted characters. Dominion tech: gunmetal + Dominion red.

## 6. World (Agent 1 visuals, Agent 2 gameplay)
### Red Reaches
- `res://game/world/red_reaches/terrain_builder.gd` (`class_name RedReachesTerrain`, extends Node3D):
  reads `layout.json`, builds terrain mesh + `StaticBody3D` collision, sky/environment/light, scatter
  props, structures. API:
  ```gdscript
  func build() -> void                         # idempotent; called in _ready
  func height_at(x: float, z: float) -> float  # terrain floor height
  func get_marker(name: String) -> Vector3     # from layout markers
  func get_structure(id: String) -> Node3D     # spawned structure nodes (rope_span, ochre_span, thought_boulder, augur_rig...)
  func set_rope_span_visible(on: bool) -> void # Cigarra drops the rope bridge (animated unroll)
  func break_boulder() -> void                 # shatter anim + remove collision
  func shake_span(intensity: float) -> void    # Burden moment visual
  func set_span_state(state: String) -> void   # "intact" | "braced" | "failing"
  ```
  Collision layers: **layer 1 = world/terrain**, **2 = player party**, **3 = enemies**, **4 = interactables /
  triggers**, **5 = projectiles**. Walkable floors must be smooth enough for CharacterBody3D (max slope 45°).
- Agent 2 owns `red_reaches.tscn` that instances the terrain builder and adds party, encounters,
  triggers, pickups from `layout.json`.

### Hub — Terrarium One / The Common
- `res://game/world/hub/hub_visual.tscn` (Agent 1): diorama scene with `Camera3D` NOT included (Agent 2
  owns camera), containing named `Marker3D`s: `Hotspot_Table`, `Hotspot_Gate`, `Hotspot_Habitat`,
  `Hotspot_Codex`, `Hotspot_Lab`, `CamFocus_Default`, and `NPC_<id>` stand points for the ambient cast,
  with billboards already placed and idling.
- `res://game/world/habitat/habitat_visual.tscn` (Agent 1): a Habitat enclosure with 4 slot markers
  `Slot_Substrate`, `Slot_Symbiont`, `Slot_Climate`, `Slot_Anchor`, + `SpecimenSpot`. Module visuals at
  `res://game/art/habitat/<module_id>.tscn` for modules: `reach_soil_bed`, `lichen_mat`, `heat_lamp`,
  `humidity_mister`, `lumen_lamp`, `moss_bed`, `scale_anchor`, `thoughtstone_pedestal`, `burden_bridge`.

## 7. VFX & audio names
VFX one-shots (Agent 1): `res://game/art/vfx/<name>.tscn`, root Node3D, script frees itself when done,
optional `func setup(params: Dictionary)`. Names: `hit_spark`, `heavy_impact`, `dust_puff`,
`mace_arc` (params: arc angle, radius), `reach_line` (params: length), `gravity_well` (params: radius,
duration), `rage_aura` (persistent while parented; `func stop()`), `psychic_bolt` (projectile visual, not
self-freeing), `psychic_burst`, `false_memory_echo`, `brain_skip_glitch`, `premonition_ghost_material`
(a `.tres` ShaderMaterial for ghost tint), `capture_beam` (params: from, to), `scan_ping`,
`pickup_glint`, `drill_sparks`, `coolant_vent`, `thoughtstone_shards`, `boss_explosion`, `leap_trail`,
`rope_unroll`, `heal_motes`, `thoughtstone_align` (the ending hook — fragment turning toward Morrow).

Screen shaders (Agent 1): `res://game/art/shaders/tilt_screen.gdshader` (canvas_item; `uniform float
strength` 0..1; reads screen texture; warps, chromatic split, depth-wobble; uses COLOR.a from the rect for
fade-to-dark), `future_noise.gdshader` (canvas_item; `uniform float noise` 0..1).

Audio names (Lead provides files later; call them now): sfx `ui_tap`, `ui_back`, `ui_confirm`,
`swing_light`, `swing_heavy`, `hit_flesh`, `hit_shell`, `hit_metal`, `mace_extend`, `gravity_hum`,
`slam`, `rage_roar`, `psychic_bolt`, `psychic_hit`, `premonition`, `false_memory`, `brain_skip`, `leap`,
`land`, `footstep_dirt`, `scan`, `codex`, `capture`, `pickup`, `drone_hum`, `drone_shot`, `drill`,
`vent`, `explosion`, `boulder_break`, `rope_unroll`, `span_creak`, `gate_whoosh`, `trust_up`,
`trust_down`, `noise_overload`, `downed`. Music: `title`, `hub`, `explore_reaches`, `combat`, `boss`,
`ending`.

## 8. Dialogue data (Lead writes, Agent 2 runs)
`res://game/narrative/dialogue/<dialogue_id>.json`:
```json
{"id":"briefing","lines":[
  {"who":"mara","expr":"focused","text":"Handler. ..."},
  {"who":"cigarra","expr":"curious","text":"...", "if":"flag_name"},
  {"label":"after_choice"},
  {"choice":[{"text":"...","goto":"label","set":{"flag":true},"trust":{"aruun":5}}, {"text":"..."}]},
  {"set":{"flag_x":true}}, {"trust":{"cigarra":3}}, {"item":{"thoughtstone_dust":-3}},
  {"event":"unlock_combo"}, {"goto":"label"}, {"end":true}
]}
```
`who` may be `"handler"` (player, no portrait), `"narration"`, `"comms:mara"` (radio-styled portrait).
`if` / `if_not` = flag gate; `event` = emitted via a dialogue runner signal for level scripts.

## 9. UI style (Agent 2, using Agent 1 art)
Parchment panels + dark ability cards, like the model sheets. Fonts in `res://game/art/fonts/`:
titles `permanent_marker.woff2`; dialogue `kalam_regular/bold.woff2`; UI labels
`barlow_condensed_medium/bold.woff2`; solemn titles `cinzel_bold.woff2`. Agent 1 delivers
`res://game/art/ui/` textures: `panel_parchment.png` (9-slice, 32 px margins), `panel_dark.png`,
`button_round.png`, `button_round_pressed.png`, `joystick_base.png`, `joystick_knob.png`,
`frame_portrait.png`, `divider_brush.png`, `cooldown_mask.png` — and a Theme
`res://game/art/ui/critter_theme.tres` using them.
