# Combat data schemas (v2/src/combat)

All gameplay numbers live in data. Frames are 60 Hz ticks, distances meters, damage in vitality points.

## rules.json (global rules, `CombatData.rules()`)
Scalar tunables (parry window, stagger length, clash, knockdown, timeout, ...), `stat_formulas` (how the 1-10 stats map to
max_vit / max_sta / max_poise / walk_speed / regen) and `tuning_defaults` (per-critter overridable values, see below).

## data/critters/<id>.json
```
id, name, species, archetype, weapon, palette{main,accent,glow}      identity (from ROSTER.md)
stats{vit,sta,poi,spd,rch,dmg}   1..10, must sum to 36
moves{light:[ids], heavy, grab, dodge, ability1, ability2, laststand, ability1_counter?}
tuning{...}                      overrides of rules.tuning_defaults and of derived stats (max_vit, walk_speed, ...)
   body_radius parry_window block_chip guard_drain block_poise crush_resist guard_move_mult parry_blast
   dodge_chain pressure_decay pressure_max slow_value haste_value
ai{style, ability1{min,max,when}, ability2{...}}                     hints for the AI
```
## data/moves/<critter id>.json  ->  {"critter": id, "moves": {move_id: {...}}}
Move fields (all optional except frames):
```
name kind(light|heavy|grab|dodge|ability|laststand) tell_anim
startup active recovery            frames (total = sum unless rehit extends it)
stamina_cost cooldown pressure_cost(-1 = spend all) require_pressure pressure_gain self_damage_ratio
track            facing keeps tracking the target for N frames after the move starts
move_mult        walk speed multiplier during startup/recovery
iframes [from,count]   armor (0..1 damage cut, no flinch) armor_frames [from,to]
chain next_id, cancel_from frame, chain_on contact|always, feint (heavy startup may cancel into guard/grab)
damage poise_damage hitstun blockstun knockback hitstop      (single hit moves)
hitbox{reach arc offset}           reach is measured from the body edge; arc is the full cone in degrees
props{unblockable guard_crush knockdown unparryable no_clash chain_heavy pressure_damage}
grab: true, command: true, throw_dist, throw_stun, kd_frames
on_hit{root slow burn drain_sta self_heal pull_to throw_dir}
hits[ {at,len,damage,...overrides} ]    multi-hit      rehit{every,count,from,len,scale}   repeating hits
motion[ {at,len,dist,dir: fwd|back|input|side|to_target|behind, gap, nocollide} ]    dash / leap / teleport
spawns[ {at,type: projectile|zone|phantom, ...} ]   stance{status,from,frames}
```
Effect vocabulary: dash/leap/teleport (`motion`), projectile, stance (status), trap/zone (once, dps, buff slow/haste), tether (ranged hit + on_hit root/pull_to),
summon phantom, buff/debuff (zone buff, statuses), command grab, Pressure (resource, `pressure_gain`, `pressure_cost: -1`, `props.pressure_damage`).

## src/combat/arenas.json
`{id: {shape: circle|rect, radius | half[x,y], edge | sides{n,s,e,w}: wall|drop, walls[[deg,deg]], hazards[], spawns[[x,y],[x,y]]}}`
hazards: `{kind: dps|pulse|slow, shape, pos, radius|half, dps, period, knock, damage}`. Forced movement past a `drop` edge is a ring-out.

## Input mapping notes (CombatInput)
`move` is in world-plane axes; `strike_tap` light; `strike_hold` heavy (raise it when the hold threshold elapses); `guard` is a level;
`grab/dodge/ability1/ability2` are presses (edge-detected by the sim); ability1+ability2 together = Last Stand (below 25% Vitality, once).
