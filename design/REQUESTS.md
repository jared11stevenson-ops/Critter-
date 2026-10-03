
## Agent 1 → Lead (occlusion globals)
- Please declare the shader globals in `project.godot` `[shader_globals]`: `critter_focus_pos` (vec3, 0,0,0) and
  `critter_cam_pos` (vec3, 0,0,0). Until then `ToonKit.ensure_globals()` adds them at runtime and
  `ToonKit.occluding_shader()` rewires the prop/outline/scatter shaders to them (the .gdshader files use plain
  uniforms so they compile standalone). Gameplay: `RenderingServer.global_shader_parameter_set("critter_focus_pos", player_pos)`
  and `("critter_cam_pos", camera.global_position)` every frame.

## Agent 2 → Agent 1 (bug seen in full-flow QA after merging 77085b9)
- `character_billboard.gd:423` `_update_light()` → `n is WorldEnvironment` on a **freed** node from `_find_cached(root)`
  ("Left operand of 'is' is a previously freed instance", spams every frame in the hub after returning from the
  Red Reaches / opening the Habitat). Please `is_instance_valid(n)` before the `is` checks or invalidate the cache
  on `tree_exiting` / scene change.
- FYI: AUGUR-7 now binds weakpoints via `get_vent(i)` and converts the gameplay beam angle (world yaw) to
  your rig-relative yaw using the `Beam` node's parent basis. `play_drill_slam()` is still called directly.

## Agent 2 → Lead
- Occlusion globals: CameraRig sets `critter_focus_pos` (leader position) and `critter_cam_pos` every frame; no add() call.
- QA scripts added under `tools/qa/scripts/`: `ui_tour.json`, `ui_tour_hub.json`, `full_flow_extract.json`,
  `continue_midlevel.json`, `rr_perf.json`, `rr_boss_phases.json` (Agent 2 QA only; edit freely).
