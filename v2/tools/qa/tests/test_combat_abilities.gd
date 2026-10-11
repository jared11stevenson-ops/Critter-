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

func _aruun(fails: Array) -> void:
	# Burden Slam (Rage): knocks down, costs self-damage, empowers
	var sim := U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var v0: float = sim.fighters[0].vit
	var evs := U.run(sim, 80, {2: _press("ability2")})
	if _hits_by(evs, "aruun_burden_slam").is_empty() or sim.fighters[1].stun_kind != "knockdown":
		fails.append("aruun burden slam: should knock down")
	if sim.fighters[0].vit >= v0 or not sim.fighters[0].has("empower"):
		fails.append("aruun rage: should cost vitality and empower")
	# Morrow Throw / Recall: thrown mace hits and returns to the owner
	sim = U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	evs = U.run(sim, 60, {2: _press("ability1")})
	if _hits_by(evs, "aruun_morrow_throw").is_empty():
		fails.append("aruun morrow throw: should hit")
	U.run(sim, 120)
	var n := 0
	for e in sim.ents:
		if e.kind == "proj":
			n += 1
	if n != 0:
		fails.append("aruun morrow throw: mace should be recalled (%d left)" % n)
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
	# Premonition widens the parry window (base 10 + bonus)
	var bonus := int(CombatData.rules()["premonition_bonus"])
	var sim := U.make("aruun", "cigarra", "ring", 1, 2)
	U.face_off(sim, 2.0)
	var press := func(i: CombatInput, t: int) -> void: i.guard = t >= 17 - (10 + bonus - 1)
	# aruun light1: startup 16 -> impact tick 17; premonition must already be up
	sim.fighters[1].add_status("premonition", 200)
	var evs := U.run(sim, 20, {1: func(i: CombatInput) -> void: i.strike_tap = true}, {}, Callable(), press)
	if U.count(evs, "parry", 1) != 1:
		fails.append("cigarra premonition: widened parry window should parry")
	sim = U.make("cigarra", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.0)
	evs = U.run(sim, 20, {2: _press("ability1")})
	if not sim.fighters[0].has("premonition"):
		fails.append("cigarra premonition: status should be active")
	# Branching Sphere: delayed probes on three paths
	sim = U.make("cigarra", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	evs = U.run(sim, 24, {2: _press("ability2")})
	if U.count(evs, "projectile", 0) != 3:
		fails.append("cigarra branching sphere: 3 probes expected (%d)" % U.count(evs, "projectile", 0))
	evs = U.run(sim, 120)
	if _hits_by(evs, "cigarra_branching_sphere").is_empty():
		fails.append("cigarra branching sphere: at least one probe should land")
	sim = U.make("cigarra", "mollusk", "ring", 1, 2)
	U.face_off(sim, 1.6)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 160, {2: _press("laststand")})
	if _hits_by(evs, "cigarra_future_touched").size() < 6:
		fails.append("cigarra future touched: expected a flurry")

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
