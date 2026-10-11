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

## Lore move rules (design/v2/LORE_MOVES.md is binding)
* Every move JSON carries `lore_source` (tag + quote key from LORE_MOVES.md). `test_combat_rules.gd` rejects moves without one.
* Passive / resource entries (Rage, Future-Noise, Observation, Cultivate, Hold, ...) are `kind: "resource"` moves that are never started; they exist so the rule is traceable.

## Effect vocabulary added for the lore kits
| Field / effect | Used by | Meaning |
|---|---|---|
| `on_hit.compel {mode: auto, frames}` on a grab | Cigarra Puppet Thought | **Compel**: no throw; the target is forced for ~1.2 s (shortened by max Poise: `compel_poise_ref`, `compel_max_resist`). Mode `auto`: near a drop edge -> `stumble` (forced walk, can ring out); guarding -> `drop_guard` (stagger); else `whiff` (forced swing at the empty air, facing locked) or `drop_guard`. Event `compel{mode, frames}`. Interruptible: a hit during the startup cancels the grab; a dodge evades it. |
| spawn `type: false_memory {frames}` | Cigarra False Memory | decoy entity; the target's inputs are replaced (chase the decoy, swing at it every `decoy_strike_interval`). A damaging hit on the target breaks it. |
| status `premonition` | Cigarra Premonition | every enemy tell spawns a `ghost` entity (event `ghost{lead}`); dodging with i-frames through an attack triggers **Brain Skip** (enemy stunned `brain_skip_stun`, Cigarra gets a riposte window, 9 s cooldown) |
| `pressure_on_use` | Cigarra | Future-Noise: at >= `noise_threshold` Brain Skip fails half the time until it decays (`tuning.pressure_decay`) |
| status `touched` (stance) | Cigarra A Future Touched | every incoming attack is ghosted and auto-dodged, each one triggers Brain Skip with no cooldown |
| Rage (`tuning.rage_max`, `rage_*`) | Aruun | bar fed by damage dealt/taken (`rage_per_dealt/taken`); **chord ability1+ability2** toggles Rage when Last Stand is not available and the bar >= `rage_enter`. In Rage: haste, damage x`rage_dmg`, every melee swing crushes guard, heavies get `rage_armor`, Strain drains `rage_strain` of max Vitality per second but never below 1 Vitality, bar drains `rage_drain`/s |
| `moves.auto_counter` | Aruun Morrow moves first | after a perfect parry (and at low odds `morrow_odds` per tick in Rage) the mace launches a free counter-strike (event `morrow_first`) |
| `tuning.plate_pool` | Aruun shell plates | damage is absorbed by plates (`plate_size` each) before Vitality; event `plate{plates_left}` |
| `spawns type: shatter` | Aruun Reaching Strike | removes `ArenaDef.cracks` ([x, y, radius]) inside the radius, event `shatter` |
| `props.store_ratio`, `props.stored_mult`, `props.release` ("debt"), `props.release_debt` | Aruun Carry the Bridge, Mollusk | armor frames convert absorbed damage into `stored`; a later hit adds `stored * stored_mult` (and the Borrowed debt if `release_debt`); `release: debt` turns it into damage owed later |
| `debt` / `tuning.guard_delay` | Mollusk Hold, Delay | blocked force is delayed into `debt`, paid at `debt_rate` per second; status `borrowed` pauses and widens parry window / adds a dodge, then `owed` slows |
| `charge_max`, `charge_at`, `props.charge_gain` | Mollusk Gathering Blow | while `strike_hold` stays true the heavy waits at frame `charge_at` and grows |
| zone buff `inertia` | Mollusk Inertia Field | victim's actions advance at `inertia_rate` of normal speed |
| `on_hit.dot {name, life, dps, grow, burst, ripe, max}` | Bramvex bleed, Scarlith Culture, Nyxaris venom | stacking damage-over-time; with `ripe` it bursts. `on_hit.ripen` (Ferment) makes cultures ripen soon, spawn `ripen_all` (Aged to Perfection) bursts them now, `props.culture_scale` scales a hit by Cultures |
| `on_hit.steal`, `on_hit.status {name: frames}` | Scarlith Barter, Decompose | steal one buff (`buff_list`) leaving a slow; apply statuses (`rotted`, `marked`) |
| `tuning.cultivate_interval`, `waste_not`, `brew_bonus`, `parry_spoil` | Scarlith | fungus patches (heal + Brew, enemy tramples), damage -> Brew, Brew raises damage, parry spoils the attacker's next move |
| `tuning.intel_gain`, `props.intel_scale`, `props.cleanse` | Bramvex | Intel grows with each enemy tell and perfect guard: wider parry window, cheaper dodges; Day 20 clears debuffs and scales with Intel; motion `dir: random` (Cigarra Hole) |
| `promise {bonus, refund, penalty}`, `props.ignore_iframes` | Zephyr | the move is a declared Promise (event `promise` at the tell): connecting pays bonus damage and refunds stamina, whiffing or being interrupted costs stamina. A Promise Kept ignores i-frames |
| `tuning.loophole_window` | Zephyr guard | a guard raised within N frames slips through a non-heavy strike |
| spawn `type: gust`, zone buff `mark`, `tuning.marks_bonus` | Zephyr | reflect projectiles; marked enemies take bonus damage from Zephyr |
| `tuning.reserve_max`, `reserve_cost`, status `archive` | Nyxaris silk reserve | web moves spend silk, it regenerates (`reserve_regen`); Cold Archive makes silk free |
| status `permission`, `moves.counter` (guard + grab chord) | Nyxaris | a melee strike entering her space is punished (stun, root, damage); event `parry{permission:true}` |
| `tuning.marks_armor` + `CombatSim.set_shell_marks(idx, n)` | Mollusk Shell Memory | each carved mark adds `mark_armor` damage reduction (cap `mark_cap`) |
