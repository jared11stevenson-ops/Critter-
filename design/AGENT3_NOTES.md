# Agent 3 notes
## Aruun 3D (status: in engine, animated; refinement pending)
- 13,579 tris (budget 25k). One 2048^2 texture set (albedo, normal, ORM) embedded in the glb.
- Known deviations from the sheet (honest list):
  - Albedo is procedural mottling in sheet palette colours, NOT projected from the sheet; the sheet's
    specific blotch layout (especially cream plates on thighs/shins/forearms) is not reproduced; limbs read darker.
  - Normal map is derived from the painted height (no high-poly bake).
  - Horns are near-straight paired horns; the sheet's horns arc back in a hook. Head reads more giraffe-like than the sheet.
  - Back cloak is a blocky slab, larger than the sheet's ragged drape; skirt panels are simpler.
  - Proportions: shoulders/pauldrons more symmetric and rounder than the sheet's hunched 3/4 pose.
  - Morrow's reach is a whole-weapon Y-scale (head stretches slightly) rather than segment telescoping.
  - Weights are procedural (distance to bone segments, part-restricted); skirt can intersect legs in run/downed.
- Cigarra: NOT started (no 3D reference pack yet).
## Integration
`res://game/art/models/aruun/aruun_model.tscn` (script `character_model.gd`, class `CharacterModel`) implements the
CharacterBillboard API (set_facing, set_move_amount, play_attack, flash_hit, set_downed, set_highlight, set_ghost,
get_height) plus play_anim(name) -> duration and get_impact_time(name). Swap it in wherever the player's
CharacterBillboard for "aruun" is instanced. play_attack: light cycles attack_1/2/3; heavy=attack_3; cast=gravity_pull;
leap=reaching_strike. Ability-specific clips (beetle_rage, burden_hold, talk_idle, dash) via play_anim.
