# Character Artist handoff (v2/src/critters)

Status: Haldor + Sessa polished (milestone 1). Weft, Cinder, Marro, Zell, Kragg follow (milestone 2). See bottom for the latest state.

## How to use the rig (Arena/Scene Engineer)
```gdscript
var rig := CritterRig.new()          # class_name CritterRig  (run `godot --import` once so the class cache exists, or preload critter_rig.gd)
add_child(rig); rig.setup("haldor")  # ids: haldor sessa weft cinder marro zell kragg
rig.position = Vector3(sim_x, 0, 0)  # origin = ground between the feet, +X = forward, +Y up, +Z = camera side
rig.three_quarter = 38.0             # deg turn toward the camera so faces read in a side-on bout (0 = pure profile)
# every render frame (dt = 0 during hit-stop is fine; shake/FX are driven per call):
rig.apply_fighter_state({"action": "strike_heavy", "action_frame": 22, "move_id": "haldor_heavy", "vitality_ratio": 0.8, "facing": 1}, dt)
rig.play_event({"type": "hit", "heavy": true})   # forward events to the rig they are ABOUT
rig.socket("weapon_tip").global_position         # also weapon_base, hand, head, ground (+ critter extras)
```
- `fs.action` in: idle walk strike_light strike_heavy guard parry grab dodge ability1 ability2 laststand hit stagger ko.
- Phase timing (startup/active/recovery) is resolved in `timing.gd`: `fs.phase` (Vector3i or {startup,active,recovery}) > `res://data/moves/<move_id>.json`
  (fields startup/active/recovery) > a clearly marked STUB table (presentation placeholders, NOT gameplay numbers). **Combat Engineer: once data/moves lands, nothing else needs to change; or put `phase` in the fighter snapshot.**
- Events: `hit` (victim), `block` (defender), `parry`/`clash`/`grab`/`dodge`/`tell`/`laststand` (actor), `stagger`/`ko`/`ringout`/`yield` (that fighter). Optional keys: `heavy` (bool, triggers 2-frame impact inversion on the character), `world_pos` (Vector3 impact point).
- Full-screen impact frame helper: `FxCtl.make_invert_overlay()` (CanvasLayer, show 2 frames; one screen read only while visible).
- Expressions: `set_expression("grin")` is a manual override (`"auto"` releases). Auto mode follows state + vitality_ratio.
- Perf per critter (static, worst case, outline hull + smear + spark included): see the table in the final report / `tools/qa/tests/test_art_build.gd` output. Budget 20 draws / 6000 tris.

## Files
| File | Purpose |
|---|---|
| `critter_rig.gd` | The CritterRig node: state to pose, procedural layers (breath, walk, fidget, squash spring, lag springs, shake), events |
| `pose_lib.gd` | Swing-style table + generic action keys; every critter maps actions to styles in its design cfg |
| `timing.gd` | Frame-data resolver (fs > data/moves json > STUB) |
| `rig_build.gd`, `prim.gd` | RigBuilder + MeshBuilder (superellipsoid blobs, swept tubes, rings, face patch merged into 1 mesh per part) |
| `designs/<id>.gd` | One file per critter: geometry, sockets, face params, cfg (styles, overrides, fidget) |
| `face_ctl.gd` + `shaders/face.gdshader` | 6 expressions, blink, glance (procedural face, 1 draw call) |
| `fx_ctrl.gd` + `shaders/fx.gdshader` | smear ribbon from weapon sockets, star-burst spark, white flash, impact inversion, glow boost |
| `shaders/toon.gdshader`, `outline.gdshader` | 2-band cel + rim + inverted-hull outline (screen-space width, no post-process) |
| `stage.gd`, `turnaround.tscn/.gd` | Lookdev stage (golden sun / teal shade) and the interactive Seven scene |
| `tools/shoot.gd`, `tools/make_sheets.py`, `tools/run_art_tests.gd` | Screenshot sheets (xvfb) and the art-gate runner |

## Art gates (in v2/tools/qa/tests/)
`test_art_palette.gd`, `test_art_build.gd`, `test_art_silhouette.gd` (needs a renderer; skipped under `--headless`).
Run: `godot --headless --path v2 --script res://src/critters/tools/run_art_tests.gd` or with `xvfb-run -a ... --rendering-driver opengl3` for the silhouette gate.

## Rendering notes
- Palette values are authored for display space (no sRGB conversion in the shader); the shadow band is the cool floor `shade_amb` + 0 sun, the lit band adds the sun, so any DirectionalLight works. Characters ignore environment ambient on purpose.
- Outline: `px_width` 3.2 px at any distance (clamped 0.004-0.06 m). Raise `Toon.OUTLINE_PX` for phones.
- `set_silhouette(true)` renders flat black (used by the silhouette gate).
- Software GL (xvfb llvmpipe) renders fine; ~2 s per run.
- Godot rewrites `v2/project.godot` when it opens the project; revert that file before committing (not ours).
