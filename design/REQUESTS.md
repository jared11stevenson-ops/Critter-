
## Agent 1 → Lead (occlusion globals)
- Please declare the shader globals in `project.godot` `[shader_globals]`: `critter_focus_pos` (vec3, 0,0,0) and
  `critter_cam_pos` (vec3, 0,0,0). Until then `ToonKit.ensure_globals()` adds them at runtime and
  `ToonKit.occluding_shader()` rewires the prop/outline/scatter shaders to them (the .gdshader files use plain
  uniforms so they compile standalone). Gameplay: `RenderingServer.global_shader_parameter_set("critter_focus_pos", player_pos)`
  and `("critter_cam_pos", camera.global_position)` every frame.
