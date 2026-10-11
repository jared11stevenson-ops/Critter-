extends RefCounted
## Every ability (2 per critter + Last Stand) for all seven critters: triggers, finishes, and shows its effect.
const U = preload("res://src/combat/sim_test_util.gd")

func run() -> Array:
	var fails: Array = []
	for id in CombatData.critter_ids():
		for slot in ["ability1", "ability2", "laststand"]:
			_generic(fails, id, slot)
	_aruun(fails)
	_cigarra(fails)
	_bramvex(fails)
	_scarlith(fails)
	_mollusk(fails)
	_zephyr(fails)
	_nyxaris(fails)
	return fails

func _press(slot: String) -> Callable:
	return func(i: CombatInput) -> void:
		if slot == "ability1" or slot == "laststand":
			i.ability1 = true
		if slot == "ability2" or slot == "laststand":
			i.ability2 = true

func _generic(fails: Array, id: String, slot: String) -> void:
	var foe := "nyxaris" if id != "nyxaris" else "mollusk"
	var sim := U.make(id, foe, "ring", 1, 11)
	U.face_off(sim, 2.4)
	if slot == "laststand":
		sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	sim.fighters[0].pressure = 80.0
	var want: String = sim.fighters[0].def.move_ids[slot]
	var evs := U.run(sim, 260, {2: _press(slot)})
	var seen := false
	for e in evs:
		if e["type"] == "tell" and e["fighter"] == 0 and e["move_id"] == want:
			seen = true
	if not seen:
		fails.append("%s %s: did not trigger (%s)" % [id, slot, want])
	for f in sim.fighters:
		if not (f.pos.is_finite() and is_finite(f.vit) and is_finite(f.sta)):
			fails.append("%s %s: non-finite state" % [id, slot])
	if not sim.is_over() and sim.fighters[0].move != null and sim.fighters[0].move.id == want and sim.fighters[0].af > sim.fighters[0].move.total:
		fails.append("%s %s: action never ended" % [id, slot])
	if slot != "laststand" and not sim.fighters[0].cooldowns.has(want) and sim.fighters[0].def.move(want).cooldown > 0 and sim.tick < sim.fighters[0].def.move(want).cooldown:
		fails.append("%s %s: cooldown not applied" % [id, slot])

func _tap(i: CombatInput) -> void:
	i.strike_tap = true

func _aruun(fails: Array) -> void:
	# Morrow combo: 3-hit chain, the finisher knocks back
	var sim := U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 1.8)
	var evs := U.run(sim, 90, {1: _tap, 7: _tap, 13: _tap, 19: _tap, 25: _tap, 31: _tap, 37: _tap, 43: _tap, 49: _tap, 55: _tap})
	var hits := _hits_by(evs, "aruun_combo1").size() + _hits_by(evs, "aruun_combo2").size() + _hits_by(evs, "aruun_combo3").size()
	if hits < 3:
		fails.append("aruun morrow combo: expected 3 chained hits, got %d" % hits)
	if sim.fighters[1].pos.x - 0.9 < 1.2:
		fails.append("aruun morrow combo: finisher should knock back (moved %f)" % (sim.fighters[1].pos.x - 0.9))
	# Reaching Strike: long-range heavy that shatters cracked Thoughtstone
	var arena := ArenaDef.make_circle(8.0, "drop")
	arena.cracks = [[2.5, 0.0, 0.6]]
	sim = CombatSim.new(CombatData.critter("aruun"), CombatData.critter("mollusk"), arena, 1, 2)
	U.face_off(sim, 4.6)
	evs = U.run(sim, 70, {2: _press("ability1")})
	if _hits_by(evs, "aruun_reaching_strike").is_empty():
		fails.append("aruun reaching strike: should hit at long range")
	if U.count(evs, "shatter") < 1 or not sim.cracks.is_empty():
		fails.append("aruun reaching strike: should shatter cracked Thoughtstone")
	# Gravity Pull: drags the target in, then slams down
	sim = U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 4.5)
	evs = U.run(sim, 90, {2: _press("ability2")})
	var pulls := _hits_by(evs, "aruun_gravity_pull")
	if pulls.size() < 2 or sim.fighters[1].stun_kind != "knockdown":
		fails.append("aruun gravity pull: pull then slam with knockdown (hits=%d)" % pulls.size())
	# Rage: bar builds from trading hits, Strain pays Vitality but never below 1, guard-crush, super-armor heavies, can end early
	sim = U.make("aruun", "nyxaris", "ring", 1, 2)
	U.face_off(sim, 1.8)
	U.run(sim, 60, {1: _tap}, {5: func(i: CombatInput) -> void: i.strike_tap = true})
	if sim.fighters[0].rage <= 0.0:
		fails.append("aruun rage: should build as he trades hits")
	var chord := func(i: CombatInput) -> void:
		i.ability1 = true
		i.ability2 = true
	sim = U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 6.0)
	sim.fighters[0].rage = 80.0
	sim.fighters[0].vit = 8.0
	sim.fighters[0].last_stand_used = true
	U.run(sim, 5, {2: chord})
	if not sim.fighters[0].raging:
		fails.append("aruun rage: chord should enter Rage")
	var haste_ok: bool = sim.fighters[0].haste_mult > 1.0
	U.run(sim, 300)
	if sim.fighters[0].vit < 1.0 or sim.is_over():
		fails.append("aruun rage: Strain must never kill him (vit %f)" % sim.fighters[0].vit)
	if sim.fighters[0].vit > 1.01:
		fails.append("aruun rage: Strain should have drained Vitality to 1 (vit %f)" % sim.fighters[0].vit)
	sim = U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 6.0)
	sim.fighters[0].rage = 80.0
	U.run(sim, 5, {2: chord})
	var v0: float = sim.fighters[0].vit
	U.run(sim, 60)
	if sim.fighters[0].vit >= v0:
		fails.append("aruun rage: Strain should drain Vitality every second")
	U.run(sim, 3, {sim.tick + 2: chord})
	if sim.fighters[0].raging:
		fails.append("aruun rage: can be ended early")
	sim = U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 1.8)
	sim.fighters[0].rage = 90.0
	var hg := func(i: CombatInput, t: int) -> void: i.guard = true
	U.run(sim, 5, {2: chord}, {}, Callable(), hg)
	evs = U.run(sim, 60, {sim.tick + 20: _tap}, {}, Callable(), hg)
	var b := U.first(evs, "block", 1)
	if b.is_empty() or not b.get("broke", false):
		fails.append("aruun rage: every swing should crush guard")
	sim = U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 6.0)
	sim.fighters[0].rage = 90.0
	U.run(sim, 5, {2: chord})
	U.run(sim, 20, {sim.tick + 1: func(i: CombatInput) -> void: i.strike_hold = true})
	if sim.fighters[0].armor_now() <= 0.0:
		fails.append("aruun rage: heavy should carry super-armor")
	# shell plates absorb damage before Vitality
	sim = U.make("aruun", "mollusk", "ring", 1, 2)
	var p0: int = ceili(sim.fighters[0].plate_pool / 30.0)
	sim.damage(sim.fighters[0], null, 40.0, "test")
	if sim.fighters[0].vit < sim.fighters[0].max_vit or ceili(sim.fighters[0].plate_pool / 30.0) >= p0:
		fails.append("aruun shell plates: should absorb damage and crack")
	# Morrow moves first: a perfect parry launches an automatic counter-strike
	sim = U.make("mollusk", "aruun", "ring", 1, 2)
	U.face_off(sim, 2.0)
	var press := func(i: CombatInput, t: int) -> void: i.guard = t >= 11
	evs = U.run(sim, 40, {1: _tap}, {}, Callable(), press)
	if U.count(evs, "parry", 1) < 1 or U.count(evs, "morrow_first", 1) < 1:
		fails.append("aruun morrow moves first: parry should trigger an automatic counter (parry=%d first=%d)" % [U.count(evs, "parry", 1), U.count(evs, "morrow_first", 1)])
	# Carry the Bridge: absorbs hits without flinching, then returns them in a huge counter
	sim = U.make("aruun", "nyxaris", "ring", 1, 2)
	U.face_off(sim, 2.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	var hp: float = sim.fighters[0].vit
	evs = U.run(sim, 70, {2: _press("laststand")}, {20: func(i: CombatInput) -> void: i.strike_hold = true})
	if sim.fighters[0].vit < hp - 0.5 or sim.fighters[0].stored <= 0.0:
		fails.append("aruun carry the bridge: should absorb the blow (vit %f -> %f, stored %f)" % [hp, sim.fighters[0].vit, sim.fighters[0].stored])
	evs = U.run(sim, 110)
	var c := _hits_by(evs, "aruun_carry_the_bridge")
	if c.is_empty() or float(c[0]["damage"]) < 40.0:
		fails.append("aruun carry the bridge: counter should be huge")

func _cigarra(fails: Array) -> void:
	# Bad Thought: fast ranged flick, chains
	var sim := U.make("cigarra", "mollusk", "ring", 1, 2)
	U.face_off(sim, 3.6)
	var evs := U.run(sim, 60, {1: _tap, 12: _tap})
	if _hits_by(evs, "cigarra_bad_thought1").is_empty():
		fails.append("cigarra bad thought: should hit at range")
	# Puppet Thought beats guard and compels (guarding target -> drops guard and staggers)
	sim = U.make("cigarra", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.4)
	var hg := func(i: CombatInput, t: int) -> void: i.guard = true
	evs = U.run(sim, 70, {2: func(i: CombatInput) -> void: i.grab = true}, {}, Callable(), hg)
	var comp := U.first(evs, "compel", 1)
	if comp.is_empty() or comp["mode"] != "drop_guard":
		fails.append("cigarra puppet thought: should beat guard and drop it (%s)" % str(comp.get("mode", "none")))
	# near the edge the target stumbles toward it: ring-out risk
	sim = U.make("cigarra", "cigarra", "ring", 2, 2)
	sim.fighters[0].pos = Vector2(5.4, 0.0)
	sim.fighters[1].pos = Vector2(7.0, 0.0)
	evs = U.run(sim, 160, {2: func(i: CombatInput) -> void: i.grab = true})
	if sim.is_over():
		if sim.result()["reason"] != "ringout":
			fails.append("cigarra puppet thought: stumble near the edge should end in ring-out")
	else:
		fails.append("cigarra puppet thought: edge stumble should be dangerous")
	# Poise shortens the compel
	var short_f := 0
	var long_f := 0
	for tid in ["cigarra", "aruun"]:
		var s2 := U.make("cigarra", tid, "ring", 1, 2)
		U.face_off(s2, 2.4)
		var e2 := U.run(s2, 70, {2: func(i: CombatInput) -> void: i.grab = true})
		var c2 := U.first(e2, "compel", 1)
		if tid == "cigarra":
			long_f = int(c2.get("frames", 0))
		else:
			short_f = int(c2.get("frames", 0))
	if not (short_f > 0 and short_f < long_f):
		fails.append("cigarra puppet thought: high Poise should shorten the compel (%d vs %d)" % [short_f, long_f])
	# readable tell and interruptible: a hit on her during the startup stops it
	sim = U.make("cigarra", "aruun", "ring", 1, 2)
	U.face_off(sim, 1.8)
	evs = U.run(sim, 60, {1: func(i: CombatInput) -> void: i.grab = true}, {1: _tap})
	if U.count(evs, "compel") != 0 or U.count(evs, "hit", 0) < 1:
		fails.append("cigarra puppet thought: hitting her during the flare must interrupt it")
	var tell := U.first(evs, "tell", 0)
	if int(tell.get("startup", 0)) < 24:
		fails.append("cigarra puppet thought: tell must be readable (startup %s)" % str(tell.get("startup")))
	# a well-timed dodge evades it
	sim = U.make("cigarra", "aruun", "ring", 1, 2)
	U.face_off(sim, 2.6)
	evs = U.run(sim, 60, {2: func(i: CombatInput) -> void: i.grab = true}, {16: func(i: CombatInput) -> void: i.dodge = true})
	if U.count(evs, "compel") != 0:
		fails.append("cigarra puppet thought: dodging should evade it")
	# Premonition ghosts + Brain Skip
	sim = U.make("cigarra", "aruun", "ring", 1, 2)
	U.face_off(sim, 2.0)
	sim.fighters[0].add_status("premonition", 300)
	evs = U.run(sim, 40, {}, {2: _tap}, Callable(), Callable())
	var ghost := U.count(evs, "ghost", 0)
	if ghost < 1:
		fails.append("cigarra premonition: enemy tells should spawn future ghosts")
	sim = U.make("cigarra", "aruun", "ring", 1, 2)
	U.face_off(sim, 1.6)
	sim.fighters[0].add_status("premonition", 300)
	var side := func(i: CombatInput) -> void:
		i.dodge = true
		i.move = Vector2(0, 1)
	evs = U.run(sim, 40, {13: side}, {2: _tap})
	if U.count(evs, "brain_skip", 0) != 1 or sim.fighters[1].stun_kind != "skipped" and U.count(evs, "hit", 1) == 0:
		fails.append("cigarra brain skip: dodging through a ghost should counter")
	# False Memory: the target chases the decoy and strikes the air; a hit breaks it
	sim = U.make("cigarra", "aruun", "ring", 1, 2)
	U.face_off(sim, 4.0)
	evs = U.run(sim, 40, {2: _press("ability2")})
	if not sim.fighters[1].has("compelled") or sim.fighters[1].compel.get("mode", "") != "decoy":
		fails.append("cigarra false memory: target should be fooled by the decoy")
	var dpos: Vector2 = sim.fighters[1].compel["pos"]
	evs = U.run(sim, 120)
	if U.count(evs, "tell", 1) < 1:
		fails.append("cigarra false memory: the fooled enemy should strike at the decoy")
	if sim.fighters[1].pos.distance_to(dpos) > 2.5 and sim.fighters[1].has("compelled"):
		fails.append("cigarra false memory: the enemy should chase the decoy")
	# Future-Noise builds with use; Future Touched auto-dodges and counters
	sim = U.make("cigarra", "aruun", "ring", 1, 2)
	U.face_off(sim, 4.0)
	U.run(sim, 40, {2: _press("ability1")})
	if sim.fighters[0].pressure < 10.0:
		fails.append("cigarra future-noise: Premonition should build noise")
	sim = U.make("cigarra", "aruun", "ring", 1, 2)
	U.face_off(sim, 2.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 120, {2: _press("laststand")}, {40: _tap, 80: _tap})
	if U.count(evs, "brain_skip", 0) < 1 or sim.fighters[0].vit < sim.fighters[0].max_vit * 0.2 - 0.1:
		fails.append("cigarra a future touched: attacks should be auto-dodged and countered")
	if sim.fighters[0].pressure < 60.0:
		fails.append("cigarra a future touched: should end in Future-Noise overload")

func _bramvex(fails: Array) -> void:
	var sim := U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.5)
	U.run(sim, 20, {2: _press("ability1")})
	if not sim.fighters[0].has("camo"):
		fails.append("bramvex ghost thorn: camouflage expected")
	var evs := U.run(sim, 60, {sim.tick + 1: func(i: CombatInput) -> void: i.strike_tap = true})
	var h := U.first(evs, "hit", 1)
	var base: float = sim.fighters[0].def.move("bramvex_light1").hits[0]["damage"]
	if h.is_empty() or float(h["damage"]) < base * 1.3:
		fails.append("bramvex ghost thorn: next hit should crit (%s vs %f)" % [str(h.get("damage", 0)), base])
	if sim.fighters[0].has("camo"):
		fails.append("bramvex ghost thorn: camo should be consumed by the hit")
	sim = U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 7.0)
	U.run(sim, 80, {2: _press("ability2")})
	var zones := 0
	for e in sim.ents:
		if e.kind == "zone":
			zones += 1
	if zones != 3:
		fails.append("bramvex thorn line: 3 thorn traps expected (%d)" % zones)
	sim.fighters[1].pos = sim.ents[1].pos
	evs = U.run(sim, 5)
	if U.count(evs, "trap") < 1 or not sim.fighters[1].has("rooted"):
		fails.append("bramvex thorn line: stepping on a thorn should trigger and root")
	sim = U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 3.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	U.run(sim, 40, {2: _press("laststand")})
	if not sim.fighters[1].has("slowed") or not sim.fighters[0].has("haste"):
		fails.append("bramvex hold the line: enemy slowed and bramvex hasted")
	sim = U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 1.8)
	evs = U.run(sim, 50, {2: func(i: CombatInput) -> void: i.grab = true})
	if U.count(evs, "grab", 1) < 1:
		fails.append("bramvex haft shove: should land at close range")

func _scarlith(fails: Array) -> void:
	var sim := U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.4)
	sim.fighters[0].pressure = 80.0
	var evs := U.run(sim, 80, {2: _press("ability1")})
	var h := _hits_by(evs, "scarlith_rot_burst")
	if h.is_empty() or float(h[0]["damage"]) < 20.0 * sim.fighters[0].out_mult():
		fails.append("scarlith rot burst: damage should scale with Brew")
	if sim.fighters[0].pressure > 0.1:
		fails.append("scarlith rot burst: should spend Brew")
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.4)
	U.run(sim, 40, {2: func(i: CombatInput) -> void: i.strike_tap = true})
	if sim.fighters[0].pressure <= 0.0:
		fails.append("scarlith: strikes must build Brew")
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 3.0)
	U.run(sim, 20, {2: _press("ability2")})
	sim.fighters[1].pos = sim.ents[0].pos
	var v0: float = sim.fighters[1].vit
	U.run(sim, 90)
	if sim.fighters[1].vit >= v0 - 1.0:
		fails.append("scarlith spoil zone: should deal damage over time")
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.6)
	sim.fighters[0].vit = 3.0
	U.run(sim, 120, {2: _press("laststand")})
	if sim.fighters[0].vit < 1.0 or sim.is_over():
		fails.append("scarlith aged to perfection: must not kill the user")

func _mollusk(fails: Array) -> void:
	# Delay: incoming damage is stored, then paid later as debt
	var sim := U.make("mollusk", "aruun", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var evs := U.run(sim, 70, {2: _press("ability1")}, {8: func(i: CombatInput) -> void: i.strike_tap = true})
	if sim.fighters[0].debt <= 0.0 and sim.fighters[0].stored <= 0.0:
		fails.append("mollusk delay: damage should be stored and become debt")
	var debt0: float = sim.fighters[0].debt
	var v1: float = sim.fighters[0].vit
	U.run(sim, 120)
	if debt0 > 0.0 and sim.fighters[0].vit >= v1:
		fails.append("mollusk delay: debt must be paid later (Borrowed Seconds)")
	# Shell Brace negates frontal hits
	sim = U.make("mollusk", "aruun", "ring", 1, 2)
	U.face_off(sim, 2.2)
	evs = U.run(sim, 70, {2: _press("ability2")}, {14: func(i: CombatInput) -> void: i.strike_tap = true})
	var walled := false
	for e in evs:
		if e["type"] == "block" and e.get("wall", false):
			walled = true
	if not walled or sim.fighters[0].vit < sim.fighters[0].max_vit:
		fails.append("mollusk shell brace: frontal hits should be negated")
	# Everything Arrives At Once: absorbs, then releases it all
	sim = U.make("mollusk", "nyxaris", "ring", 1, 2)
	U.face_off(sim, 2.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 70, {2: _press("laststand")}, {20: func(i: CombatInput) -> void: i.strike_hold = true})
	var stored: float = sim.fighters[0].stored
	if stored <= 0.0:
		fails.append("mollusk everything arrives: should store incoming damage")
	evs = U.run(sim, 80)
	var r := _hits_by(evs, "mollusk_everything_arrives")
	if r.is_empty() or float(r[0]["damage"]) < stored:
		fails.append("mollusk everything arrives: should release what it stored")

func _zephyr(fails: Array) -> void:
	var sim := U.make("zephyr", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	var evs := U.run(sim, 60, {2: _press("ability1")})
	if _hits_by(evs, "zephyr_gust_step").is_empty():
		fails.append("zephyr gust step: air dash should close and strike")
	sim = U.make("zephyr", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	U.run(sim, 30, {2: _press("ability2")})
	var cloud: Vector2 = sim.ents[0].pos
	sim.fighters[1].pos = cloud
	U.run(sim, 4)
	if not sim.fighters[1].has("slowed") or not sim.fighters[1].has("confused"):
		fails.append("zephyr pollen cloud: slows and confuses")
	sim = U.make("zephyr", "mollusk", "ring", 1, 2)
	U.face_off(sim, 3.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	var inv := 0
	evs = []
	for t in 160:
		var ia := CombatInput.new()
		if t == 2:
			ia.ability1 = true
			ia.ability2 = true
		sim.step(ia, CombatInput.new())
		evs.append_array(sim.take_events())
		if sim.fighters[0].invulnerable():
			inv += 1
	if inv < 60 or _hits_by(evs, "zephyr_promise_kept").size() < 3:
		fails.append("zephyr a promise kept: invulnerable flurry expected (inv=%d hits=%d)" % [inv, _hits_by(evs, "zephyr_promise_kept").size()])
	sim = U.make("zephyr", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	evs = U.run(sim, 30, {2: func(i: CombatInput) -> void: i.dodge = true, 9: func(i: CombatInput) -> void: i.dodge = true})
	var dodges := 0
	for e in evs:
		if e["type"] == "tell" and e["move_id"] == "zephyr_dodge":
			dodges += 1
	if dodges != 2:
		fails.append("zephyr air dodge: expected chained second dodge (%d)" % dodges)

func _nyxaris(fails: Array) -> void:
	var sim := U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.6)
	var evs := U.run(sim, 70, {2: _press("ability1")})
	var g := _hits_by(evs, "nyxaris_frost_bind", "grab")
	if g.is_empty() or float(g[0]["damage"]) < 20.0 * sim.fighters[0].out_mult():
		fails.append("nyxaris frost bind: command grab should land hard")
	if not sim.fighters[1].has("rooted"):
		fails.append("nyxaris frost bind: target should be frozen in place")
	sim = U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	U.run(sim, 60, {2: _press("ability2")})
	if sim.fighters[0].pos.distance_to(sim.fighters[1].pos) > 2.6:
		fails.append("nyxaris silk pull: should drag the target in")
	sim = U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.6)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 120, {2: _press("laststand")})
	var m := _hits_by(evs, "nyxaris_cold_archive", "grab")
	if m.is_empty() or float(m[0]["damage"]) < 50.0 * sim.fighters[0].out_mult():
		fails.append("nyxaris cold archive: huge command throw expected")
	# silk-pull ring-out
	sim = U.make("nyxaris", "cigarra", "ring", 2, 3)
	sim.fighters[0].pos = Vector2(6.0, 0.0)
	sim.fighters[1].pos = Vector2(7.4, 0.0)
	U.run(sim, 90, {1: func(i: CombatInput) -> void: i.grab = true})
	if not sim.is_over() or sim.result()["reason"] != "ringout":
		fails.append("nyxaris cocoon throw: should ring out at the edge (%s)" % str(sim.result()))

func _hits_by(evs: Array, move_id: String, type: String = "hit") -> Array:
	var out: Array = []
	for e in evs:
		if e["type"] == type and e["move_id"] == move_id:
			out.append(e)
	return out
