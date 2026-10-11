# Combat Engineer handoff (live)

READY on branch `worktree-v2-combat`: CombatSim (2D plane, deterministic, 60 Hz), the seven LORE critters with LORE_MOVES.md kits, AI opponent, tournament bot,
tests `v2/tools/qa/tests/test_combat_*.gd`. Ids: aruun cigarra bramvex scarlith mollusk zephyr nyxaris (old slots haldor sessa weft cinder marro zell kragg).
Fresh checkout: run `godot --headless --path v2 --import` once (class_name cache).

## How BoutScene drives a bout (exact contract)
```gdscript
var sim := CombatSim.new(CombatData.critter("aruun"), CombatData.critter("cigarra"), CombatData.arena("ring"), stakes, seed)  # stakes 0 Sparring, 1 Contest, 2 Blood
var ai := CombatAI.new(1, "standard", seed + 1)          # profile novice|standard|expert; 2nd arg of decide() is not needed
# every physics tick (exactly 60 Hz, fixed step; never skip or double-step):
var in_a := player_input()                               # CombatInput, see below
var in_b := ai.decide(sim)                               # AI returns a CombatInput
sim.step(in_a, in_b)
for ev in sim.take_events(): rig[ev.fighter].play_event(ev); camera/hitstop/fx react   # events are per tick, take them every tick
var s := sim.state()                                     # snapshot for rigs + HUD
if sim.is_over(): outcome = sim.result()                 # {winner, reason ko|ringout|yield|timeout, killed, injury{}, loser, ticks, vitality_ratio[], damage_dealt[]}
```
**CombatInput (one per fighter per tick; create a new one or reuse + clear())**
* `move` Vector2 in WORLD plane axes (x = world x, y = world z), length <= 1. The sim does lock-on strafing itself; do not rotate by facing.
* `strike_tap` light (one-tick pulse on release before the hold threshold); `strike_hold` heavy: raise it when the hold threshold elapses and KEEP it true while the button is held (Mollusk's Gathering Blow charges while it stays true).
* `guard` LEVEL (true while held). `grab`, `dodge`, `ability1`, `ability2` are presses (the sim edge-detects; holding does not repeat).
* `ability1 + ability2` together: **Last Stand** (when `can_last_stand`: below 25% Vitality, once per bout); for Aruun otherwise it toggles **Rage** (needs bar >= `rage_enter`).
* `guard + grab` together: Nyxaris counter-stance (only critters with `moves.counter`).
* `yield_pressed` ends the bout now (loser lives, no kill).
* Inputs are buffered 6 frames inside the sim; hit-stop is inside the sim (do not freeze the clock yourself; keep stepping, the sim simply ignores most of the step during hit-stop and `state().hitstop > 0`).

**Reading state** `sim.state()`: `{tick, frame, hitstop, over, entities[], fighters[2]}` with per fighter
`pos(Vector2 x,z) facing vitality vitality_max stamina stamina_max poise poise_max pressure rage raging plates intel reserve dots compelled
action action_frame move_id tell_anim stun status[] cooldowns{} winded can_last_stand last_stand_used alive`.
* `action`: idle walk guard strike_light strike_heavy grab dodge ability1 ability2 laststand parry hit stagger knockdown clash ko. `move_id` + `action_frame` + `MoveDef` (data/moves) give startup/active/recovery phases.
* `tell_anim` is the PoseLib style key for the current move (see table). Use it as `fs.tell_anim` for `CritterRig.apply_fighter_state`.
* `entities[]`: `{kind: proj|zone|phantom|ghost|decoy, owner, pos, radius, life, tag}` (projectiles, traps, fungus, Premonition ghosts, False Memory decoy, hazard zones).
* `status[]` names worth drawing: winded, last_stand, premonition, touched, camo, rooted, slowed, haste, wall, borrowed, owed, rotted, marked, compelled, inertia, archive, permission, empower, riposte.

**Events** `{type, fighter, move_id, pos, damage, tick, ...}` (`fighter` = the one affected / acting):
tell hit block parry clash grab dodge stagger ringout ko laststand yield end (contract) plus: teleport projectile zone trap summon stance feint hazard compel ghost brain_skip
rage rage_end plate morrow_first ripe steal trample cleanse promise shatter gust. Extra keys: `hitstop` (frames) on hit/block/parry/clash, `counter`, `armor`, `broke` (guard break),
`mode`/`frames` on compel, `hidden:true` on a camouflaged `tell` (Bramvex Ghost: hide the tell telegraph), `startup` + `tell_anim` on tell.
Ring-out and KO: `result().killed` is true only in stakes 2; stakes 1 puts `injury{fighter, kind, move_id}` in the result.

## tell_anim keys (PoseLib style names, art agent: pose these)
Keys in use: charge, chop, grab, hook, leap, overhead, punch, roar, slash_back, slash_up, spin, stance, thrust.
| critter | move | kind | tell_anim | startup/active/recovery |
|---|---|---|---|---|
| aruun | aruun_combo1 | light | chop | 16/4/18 |
| aruun | aruun_combo2 | light | slash_back | 15/4/18 |
| aruun | aruun_combo3 | light | overhead | 18/4/30 |
| aruun | aruun_overhead | heavy | overhead | 36/5/32 |
| aruun | aruun_drag | grab | grab | 20/3/28 |
| aruun | aruun_dodge | dodge | leap | 0/6/16 |
| aruun | aruun_reaching_strike | ability | thrust | 30/4/34 |
| aruun | aruun_gravity_pull | ability | hook | 22/22/30 |
| aruun | aruun_morrow_first | light | slash_up | 8/3/18 |
| aruun | aruun_carry_the_bridge | laststand | stance | 100/3/36 |
| bramvex | bramvex_diplomacy1 | light | thrust | 14/3/16 |
| bramvex | bramvex_diplomacy2 | light | thrust | 13/3/20 |
| bramvex | bramvex_final_offer | heavy | overhead | 30/4/30 |
| bramvex | bramvex_detain | grab | grab | 18/3/30 |
| bramvex | bramvex_cigarra_hole | dodge | leap | 0/6/12 |
| bramvex | bramvex_ghost | ability | stance | 6/1/14 |
| bramvex | bramvex_ground_prep | ability | hook | 14/1/16 |
| bramvex | bramvex_day_20 | laststand | leap | 14/60/24 |
| cigarra | cigarra_bad_thought1 | light | punch | 10/3/10 |
| cigarra | cigarra_bad_thought2 | light | slash_back | 10/3/10 |
| cigarra | cigarra_bad_thought3 | light | slash_up | 12/3/18 |
| cigarra | cigarra_crown_barrage | heavy | spin | 28/1/30 |
| cigarra | cigarra_puppet_thought | grab | roar | 26/3/34 |
| cigarra | cigarra_grasshopper_thought | dodge | leap | 0/6/12 |
| cigarra | cigarra_brain_skip | counter | stance | 0/1/0 |
| cigarra | cigarra_premonition | ability | stance | 6/150/14 |
| cigarra | cigarra_false_memory | ability | roar | 20/1/22 |
| cigarra | cigarra_future_touched | laststand | stance | 24/240/14 |
| mollusk | mollusk_shell_shove1 | light | punch | 16/3/18 |
| mollusk | mollusk_shell_shove2 | light | slash_back | 15/3/22 |
| mollusk | mollusk_gathering_blow | heavy | charge | 36/4/32 |
| mollusk | mollusk_lift | grab | grab | 18/3/26 |
| mollusk | mollusk_shell_slide | dodge | leap | 0/6/16 |
| mollusk | mollusk_inertia_field | ability | stance | 14/1/20 |
| mollusk | mollusk_borrowed_seconds | ability | stance | 6/1/16 |
| mollusk | mollusk_everything_arrives | laststand | stance | 80/3/40 |
| nyxaris | nyxaris_silk_lash1 | light | punch | 15/3/18 |
| nyxaris | nyxaris_silk_lash2 | light | slash_back | 15/3/22 |
| nyxaris | nyxaris_frost_lance | heavy | thrust | 32/4/30 |
| nyxaris | nyxaris_cocoon | grab | grab | 14/4/26 |
| nyxaris | nyxaris_silk_hop | dodge | leap | 0/6/16 |
| nyxaris | nyxaris_boundary | ability | hook | 16/1/22 |
| nyxaris | nyxaris_venom_fang | ability | thrust | 14/3/22 |
| nyxaris | nyxaris_permission | ability | stance | 4/36/16 |
| nyxaris | nyxaris_cold_archive | laststand | roar | 30/1/20 |
| scarlith | scarlith_culture_jab1 | light | punch | 13/3/15 |
| scarlith | scarlith_culture_jab2 | light | slash_back | 12/3/20 |
| scarlith | scarlith_aged_smash | heavy | overhead | 26/4/30 |
| scarlith | scarlith_barter | grab | grab | 17/3/28 |
| scarlith | scarlith_hop_clear | dodge | leap | 0/6/14 |
| scarlith | scarlith_ferment | ability | hook | 20/3/26 |
| scarlith | scarlith_decompose | ability | roar | 22/3/26 |
| scarlith | scarlith_aged_to_perfection | laststand | roar | 30/1/30 |
| zephyr | zephyr_flutter1 | light | thrust | 10/3/11 |
| zephyr | zephyr_flutter2 | light | thrust | 10/3/11 |
| zephyr | zephyr_flutter3 | light | slash_back | 11/3/16 |
| zephyr | zephyr_delivery | heavy | charge | 26/8/26 |
| zephyr | zephyr_catch | grab | grab | 14/3/28 |
| zephyr | zephyr_air_dodge | dodge | leap | 0/6/10 |
| zephyr | zephyr_gust | ability | roar | 16/4/24 |
| zephyr | zephyr_pollen | ability | roar | 16/1/22 |
| zephyr | zephyr_a_promise_kept | laststand | leap | 14/70/24 |

## Other notes
* Mollusk's Shell Memory: call `sim.set_shell_marks(idx, survived_bouts)`; team bouts: `sim.set_vitality_ratio(idx, ratio)`.
* The AI never yields in the tournament; in-game create it with `CombatAI.new(idx, profile, seed, true)` to allow Yield / Last Stand decisions.
* Balance matrix: `bash v2/tools/sim/run_tournament.sh 200 1 4` (4 shards) writes `v2/tools/out/matrix.md`; see BALANCE.md.
