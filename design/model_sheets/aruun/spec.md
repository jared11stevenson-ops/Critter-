# Aruun 3D model spec (Agent 3)
- Height 2.40 m horn tip to sole; landmarks from landmarks.json (side+back average).
- Cloak ruling (Lead): the views disagree. Model uses the BACK view's cloak draped over his RIGHT shoulder
  plus the FRONT view's hood. The side view's "no cloak" is not followed.
- Build: `python3 tools/modeling/aruun/build.py geo && python3 tools/modeling/aruun/finish.py` (Blender 5.0 bpy module).
- Output: game/art/models/aruun/aruun.glb (single mesh, single material, 2048 albedo/normal/ORM), aruun_anim.json.
- Rig: 36 bones (spine x4, neck x3, head, jaw, arms/legs per side, `weapon` (Morrow, scale-Y = telescoping reach), `cloak`).
- QA: qa/compare_cycles.png (sheet vs model), qa/anim_poses_cycles.png, qa/engine_*.png (gameplay cam yaw 0 / pitch -40 / dist 14 / FOV 42, close-ups, Red Reaches lighting).
