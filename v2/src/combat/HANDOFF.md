# Combat Engineer handoff (live)

READY (branch worktree-v2-combat): CombatSim (2D plane, deterministic, 60 Hz), CritterDef/MoveDef/ArenaDef/CombatInput, loader `CombatData`,
all seven critters with full move sets and abilities, rules/arenas JSON, tests in v2/tools/qa/tests/test_combat_*.gd.

How to use:
```gdscript
var sim := CombatSim.new(CombatData.critter("haldor"), CombatData.critter("sessa"), CombatData.arena("ring"), 1, seed)
sim.step(input_a, input_b)          # once per 1/60 s
for ev in sim.take_events(): ...    # tell hit block parry clash grab dodge stagger ringout ko laststand yield (+ teleport projectile zone trap summon stance feint hazard end)
var s := sim.state()                # fighters[i]{pos,facing,vitality,stamina,poise,action,action_frame,move_id,status[],cooldowns{}}
```
- Needs the class cache: run `godot --headless --import` once in a fresh checkout.
- `action` values: idle walk guard strike_light strike_heavy grab dodge ability1 ability2 laststand parry hit stagger knockdown clash ko.
  `move_id` + `action_frame` + MoveDef (startup/active/recovery, tell_anim) give the rig its phases.
- Hit-stop is applied inside the sim (frames freeze; `state().hitstop` > 0); events carry `hitstop` for shake/impact frames.
- Last Stand = ability1 + ability2 pressed together (UI: show when `fighters[i].can_last_stand`). Yield = `yield_pressed`.
- Event `pos` is arena plane (x, y=z). Result: `{winner, reason ko|ringout|yield|timeout, killed, injury{}, ...}`.
