# Agent 1 (Art) — notes

## Red Reaches world (`game/world/red_reaches/terrain_builder.gd`, class `RedReachesTerrain`)
- Instance with `RedReachesTerrain.new()` (or a Node3D with the script) at the world origin; `build()` runs in `_ready`.
  Structures and scatter use world coordinates, so keep the terrain node at the origin.
- Collision: HeightMapShape3D (layer 1) + structure bodies (layer 1). Rope span deck collision is disabled until
  `set_rope_span_visible(true)`; boulder collision is removed by `break_boulder()`.
- `height_at(x,z)` includes bridge decks (Ochre Span always; rope span only when unrolled).
- Exports: `with_lighting` (adds `CritterLighting` = WorldEnvironment + Sun, preset "reaches"), `with_scatter`,
  `with_structures`, `with_backdrop`, `with_collision`. Turn `with_lighting` off if the level provides its own.
- Structures (`get_structure(id)`): `gate_ring`, `rope_span` (`set_unrolled(on)`), `ochre_span`
  (`set_state("intact"|"braced"|"failing")`, `shake(i)`), `waystation_ruins`, `old_road_marker`,
  `thought_boulder` (`shatter()`), `drill_camp`, `augur_rig` (empty Node3D at boss_pos; boss visuals = creatures/augur_rig.tscn).
- Scatter: painted kit billboards in one MultiMesh (`reaches_scatter.gd`), 3D props (crates, flags, pillars) one
  MultiMesh per kind. Paths, markers, triggers, pickups and structures are kept clear.
- Visual "camera cut": cliffs on the camera side (+Z) of floors are lowered visually only (collision keeps full walls).
- QA: `tools/shot.sh res://game/world/red_reaches/terrain_qa.tscn <out> <shots> 16` (12 stops, 1.2 s apart from 1.4 s).

## Shared art code
- `game/art/world/toon_kit.gd` (`ToonKit`): SurfaceTool helpers + shared toon material (`toon_prop.gdshader` +
  `ink_outline.gdshader` next_pass). `game/world/common/world_lighting.gd` (`CritterLighting`) presets reaches/hub/dusk.
