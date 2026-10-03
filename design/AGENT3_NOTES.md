# Agent 3 notes
## Aruun 3D (status: in engine, animated; refinement pending)
- 13,579 tris (budget 25k). One 2048^2 texture set (albedo, normal, ORM) embedded in the glb.
- Fidelity pass (lead review): albedo is now the sheet's own paint, orthographically projected from
  game/art/characters/aruun/{front,side,back}.png (facing^2 blend + per-view depth test, best-facing fallback for
  occluded texels, UV dilation for seams; procedural only where nothing projects, and on Morrow/eyes). Horns
  now hook back over the skull; snout shortened/skull widened; cape = 9 torn strips + 3 shoulder tongues;
  pauldrons asymmetric (L high/forward, R low/flat); Morrow reach = two haft segments sliding on bones
  weapon_ext1/2 (head unscaled); skirt panels progressively ride the same-side thigh.
- Remaining deviations (honest):
  - Sheet "front" is a 3/4 pose with Morrow in front of the legs: projected front colours on the lower legs/skirt
    partly carry Morrow/haft paint; sheet line-art + baked shading come along; texel density limited by the
    ~200 px/m sheet views (soft). In engine the albedo reads lighter/pinker than the sheet under Red Reaches light.
  - Front-view horn hook is in depth so orthographic front reads straight; head still longer than the sheet mask.
  - Body is not hunched (rig joints unchanged); only the pauldrons carry the asymmetry.
  - Skirt clipping reduced by weights, not verified frame-by-frame in all clips.
- Cigarra: NOT started (no 3D reference pack yet).
## Integration
`res://game/art/models/aruun/aruun_model.tscn` (script `character_model.gd`, class `CharacterModel`) implements the
CharacterBillboard API (set_facing, set_move_amount, play_attack, flash_hit, set_downed, set_highlight, set_ghost,
get_height) plus play_anim(name) -> duration and get_impact_time(name). Swap it in wherever the player's
CharacterBillboard for "aruun" is instanced. play_attack: light cycles attack_1/2/3; heavy=attack_3; cast=gravity_pull;
leap=reaching_strike. Ability-specific clips (beetle_rage, burden_hold, talk_idle, dash) via play_anim.
