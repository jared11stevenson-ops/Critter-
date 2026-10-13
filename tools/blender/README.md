# Blender model pipeline (authored by the lead agent, not outsourced)

All eight critters are modelled in Blender (the `bpy` pip module, headless) and exported to glTF:
`python3 tools/blender/build_<id>.py` -> `v2/art/models/<id>.glb` (+ `<id>.json` sidecar: face patch, sockets, swarm).

* `lib.py` is the kit: author in GAME coordinates (x forward, y up, z toward the viewer), `Part("torso", pivot, dy, sc)` = one rigid part whose
  node origin is the joint pivot; primitives `blob / tube / box / ring / cone`; `.hard()` marks geometry that must not be voxel-unioned or
  decimated (armour plates, horns, thorns, ribbons). `finish(voxel, smooth_passes, target_tris)` voxel-remeshes the organic geometry into one smooth surface,
  decimates it to the budget, joins the hard geometry, writes vertex colours (RGB = colour, A = emissive mask) and shades smooth.
* Godot side: `RigBuilder.use_glb(id)` swaps the procedural geometry of the parts found in the glb (names: torso head arm_f arm_b leg_f leg_b weapon extra),
  keeps the design's animation config, and merges the sidecar. Critters without a glb fall back to the procedural design.
* Budget: 16000 triangles incl. the outline pass (`test_art_build.gd`), roughly 8000 mesh triangles per critter.
* Portraits: `godot ... shoot.gd --mode=portrait` then `python3 v2/tools/gen/make_portraits.py <dir>` -> `v2/art/portraits/`.
* Gotchas learnt: Blender->glTF decodes vertex colours from sRGB (the kit pre-encodes); decimation eats thin geometry (hence `.hard()`); `ring()` axis is game Z.
