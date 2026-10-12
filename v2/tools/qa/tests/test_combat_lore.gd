extends RefCounted
## Lore kits of Bramvex, Scarlith, Mollusk, Zephyr, Nyxaris (design/v2/LORE_MOVES.md): one block per critter.
const U = preload("res://src/combat/sim_test_util.gd")

func run() -> Array:
	var fails: Array = []
	_bramvex(fails)
	_scarlith(fails)
	_mollusk(fails)
	_zephyr(fails)
	_nyxaris(fails)
	return fails

func _tap(i: CombatInput) -> void:
	i.strike_tap = true

func _grab(i: CombatInput) -> void:
	i.grab = true

func _press(slot: String) -> Callable:
	return func(i: CombatInput) -> void:
		match slot:
			"ability1": i.ability1 = true
			"ability2": i.ability2 = true
			"ability3": i.ability3 = true
			"laststand": i.last_stand = true

func _hits_by(evs: Array, move_id: String, type: String = "hit") -> Array:
	var out: Array = []
	for e in evs:
		if e["type"] == type and e["move_id"] == move_id:
			out.append(e)
	return out

func _guard(i: CombatInput, _t: int) -> void:
	i.guard = true

func _bramvex(fails: Array) -> void:
	# Diplomacy swings bleed
	var sim := U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.6)
	var evs := U.run(sim, 40, {1: _tap})
	if _hits_by(evs, "bramvex_diplomacy1").is_empty() or sim.fighters[1].dots.is_empty():
		fails.append("bramvex diplomacy: thorn hits should make the target bleed")
	var v0: float = sim.fighters[1].vit
	U.run(sim, 90)
	if sim.fighters[1].vit >= v0:
		fails.append("bramvex diplomacy: bleed should tick")
	# Ghost: camouflage, next hit is an ambush crit and the tell is hidden
	sim = U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.6)
	var plain := U.run(sim, 40, {1: _tap})
	var base_hit := U.first(plain, "hit", 1)
	sim = U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.6)
	U.run(sim, 20, {2: _press("ability1")})
	if not sim.fighters[0].has("camo"):
		fails.append("bramvex ghost: camouflage expected")
	evs = U.run(sim, 40, {sim.tick + 1: _tap})
	var crit := U.first(evs, "hit", 1)
	if crit.is_empty() or base_hit.is_empty() or float(crit["damage"]) < float(base_hit["damage"]) * 1.35:
		fails.append("bramvex ghost: next hit should be an ambush crit (%s vs %s)" % [str(crit.get("damage")), str(base_hit.get("damage"))])
	var tell := U.first(evs, "tell", 0)
	if not tell.get("hidden", false):
		fails.append("bramvex ghost: tells should be flagged hidden")
	# Ground Prep
	sim = U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 7.0)
	U.run(sim, 80, {2: _press("ability2")})
	var zones := 0
	for e in sim.ents:
		if e.kind == "zone":
			zones += 1
	if zones != 3:
		fails.append("bramvex ground prep: 3 thorn traps expected (%d)" % zones)
	sim.fighters[1].pos = sim.ents[1].pos
	evs = U.run(sim, 5)
	if U.count(evs, "trap") < 1 or not sim.fighters[1].has("rooted"):
		fails.append("bramvex ground prep: stepping on a thorn should trigger and root")
	# Intel: observation and perfect guards sharpen his reads
	sim = U.make("mollusk", "bramvex", "ring", 1, 2)
	U.face_off(sim, 2.2)
	U.run(sim, 30, {1: _tap})
	if sim.fighters[1].intel <= 0.0:
		fails.append("bramvex intel: every enemy move he sees should add Intel")
	sim = U.make("mollusk", "bramvex", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var i0: float = sim.fighters[1].intel
	var pr := func(i: CombatInput, t: int) -> void: i.guard = t >= 11
	evs = U.run(sim, 24, {1: _tap}, {}, Callable(), pr)
	if U.count(evs, "parry", 1) < 1 or sim.fighters[1].intel < i0 + 0.14:
		fails.append("bramvex intel: a perfect guard should grant Intel")
	# Cigarra Hole: unpredictable chained evade
	sim = U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	evs = U.run(sim, 30, {2: func(i: CombatInput) -> void: i.dodge = true, 10: func(i: CombatInput) -> void: i.dodge = true})
	var n := 0
	for e in evs:
		if e["type"] == "tell" and e["move_id"] == "bramvex_cigarra_hole":
			n += 1
	if n != 2:
		fails.append("bramvex cigarra hole: should chain out of itself (%d)" % n)
	# Day 20: breaks holds, clears debuffs, counter-assault
	sim = U.make("bramvex", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.4)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	sim.fighters[0].add_status("rooted", 200)
	sim.fighters[0].add_status("slowed", 200)
	Res_add_dot(sim.fighters[0])
	evs = U.run(sim, 120, {2: _press("laststand")})
	if sim.fighters[0].has("slowed") or not sim.fighters[0].dots.is_empty():
		fails.append("bramvex day 20: should clear debuffs")
	if _hits_by(evs, "bramvex_day_20").size() < 4:
		fails.append("bramvex day 20: counter-assault expected")

func Res_add_dot(f) -> void:
	f.dots.append({"name": "venom", "age": 0, "life": 300, "dps": 1.0, "grow": 0.0, "burst": 0.0, "ripe": 0})

func _scarlith(fails: Array) -> void:
	var sim := U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var evs := U.run(sim, 40, {1: _tap})
	if sim.fighters[1].dots.is_empty():
		fails.append("scarlith culture jab: should apply a Culture stack")
	evs = U.run(sim, 340)
	if U.count(evs, "ripe", 1) < 1:
		fails.append("scarlith culture: stacks should ripen and burst")
	# Aged Smash scales with Cultures
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var plain := U.run(sim, 60, {1: func(i: CombatInput) -> void: i.strike_hold = true})
	var d0 := U.first(plain, "hit", 1)
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.2)
	for k in 3:
		sim.fighters[1].dots.append({"name": "culture", "age": 0, "life": 400, "dps": 0.0, "grow": 0.0, "burst": 5.0, "ripe": 0})
	var scaled := U.run(sim, 60, {1: func(i: CombatInput) -> void: i.strike_hold = true})
	var d1 := U.first(scaled, "hit", 1)
	if d0.is_empty() or d1.is_empty() or float(d1["damage"]) < float(d0["damage"]) * 1.4:
		fails.append("scarlith aged smash: damage should scale with Cultures (%s vs %s)" % [str(d1.get("damage")), str(d0.get("damage"))])
	# Ferment ripens, Aged to Perfection ripens everything now
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 3.0)
	sim.fighters[1].dots.append({"name": "culture", "age": 0, "life": 400, "dps": 0.0, "grow": 0.0, "burst": 9.0, "ripe": 0})
	evs = U.run(sim, 40, {2: _press("ability1")})
	if int(sim.fighters[1].dots[0].get("ripe", 0)) <= 0:
		fails.append("scarlith ferment: Cultures should be set to ripen")
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 3.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	for k in 3:
		sim.fighters[1].dots.append({"name": "culture", "age": 0, "life": 400, "dps": 0.0, "grow": 0.0, "burst": 9.0, "ripe": 0})
	var v0: float = sim.fighters[1].vit
	evs = U.run(sim, 60, {2: _press("laststand")})
	if sim.fighters[1].vit > v0 - 20.0 or not sim.fighters[1].dots.is_empty():
		fails.append("scarlith aged to perfection: every Culture should ripen at once")
	# Decompose rots guard
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.4)
	U.run(sim, 40, {2: _press("ability2")})
	if not sim.fighters[1].has("rotted"):
		fails.append("scarlith decompose: should rot the target")
	# Barter steals a buff and leaves a penalty
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 1.8)
	sim.fighters[1].add_status("haste", 400)
	U.run(sim, 50, {1: _grab})
	if not sim.fighters[0].has("haste") or sim.fighters[1].has("haste") or not sim.fighters[1].has("slowed"):
		fails.append("scarlith barter: should steal a buff and penalise the enemy")
	# Cultivate (ability 3): plants fungus that feeds and heals him; the enemy tramples it
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	U.face_off(sim, 6.0)
	U.run(sim, 40, {2: _press("ability3")})
	var fungus := 0
	for e in sim.ents:
		if e.tag == "fungus":
			fungus += 1
	if fungus < 1:
		fails.append("scarlith cultivate: fungus patches should grow")
	else:
		sim.fighters[0].vit = sim.fighters[0].max_vit * 0.5
		sim.fighters[0].pos = sim.ents[0].pos
		var vv: float = sim.fighters[0].vit
		U.run(sim, 30)
		if sim.fighters[0].vit <= vv or sim.fighters[0].pressure <= 0.0:
			fails.append("scarlith cultivate: standing on fungus should heal and feed Brew")
		sim.fighters[1].pos = sim.ents[0].pos
		var evs2 := U.run(sim, 3)
		if U.count(evs2, "trample") < 1:
			fails.append("scarlith cultivate: the enemy can trample patches")
	# Waste Not: damage taken becomes Brew
	sim = U.make("scarlith", "mollusk", "ring", 1, 2)
	sim.damage(sim.fighters[0], null, 20.0, "test")
	if sim.fighters[0].pressure < 5.0:
		fails.append("scarlith waste not: damage should turn into Brew")
	# Rind guard: a parry spoils the attacker's next move
	sim = U.make("mollusk", "scarlith", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var pr := func(i: CombatInput, t: int) -> void: i.guard = t >= 11
	U.run(sim, 24, {1: _tap}, {}, Callable(), pr)
	if not sim.fighters[0].has("spoiled"):
		fails.append("scarlith rind guard: a parry should spoil the attacker's next move")

func _mollusk(fails: Array) -> void:
	# Hold: blocked force is delayed, then lands later; Borrowed Seconds postpones it
	var sim := U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var evs := U.run(sim, 60, {1: func(i: CombatInput) -> void: i.strike_hold = true}, {}, Callable(), _guard)
	if sim.fighters[1].debt <= 0.0 and sim.fighters[1].vit >= sim.fighters[1].max_vit:
		fails.append("mollusk hold: blocked damage should be delayed (debt)")
	var v1: float = sim.fighters[1].vit
	var d1: float = sim.fighters[1].debt
	U.run(sim, 150)
	if d1 > 0.0 and sim.fighters[1].vit >= v1:
		fails.append("mollusk hold: delayed damage must land later")
	# Gathering blow grows while held
	var dmg: Array = []
	for hold in [0, 30]:
		var s2 := U.make("mollusk", "aruun", "ring", 1, 2)
		U.face_off(s2, 2.0)
		var h: int = hold
		var e2 := U.run(s2, 150, {}, {}, func(i: CombatInput, t: int) -> void: i.strike_hold = t == 1 or (t > 1 and t < 1 + h + 24))
		var hit := U.first(e2, "hit", 1)
		dmg.append(float(hit.get("damage", 0.0)))
	if not (dmg[1] > dmg[0] * 1.3):
		fails.append("mollusk gathering blow: holding should grow the hit (%s)" % str(dmg))
	# Inertia Field slows the enemy's actions
	var t_free := _light_hit_tick(false)
	var t_field := _light_hit_tick(true)
	if t_free <= 0 or t_field < t_free + 5:
		fails.append("mollusk inertia field: the enemy's strike should arrive later (%d vs %d)" % [t_field, t_free])
	# Borrowed Seconds: bonus now, debt later
	sim = U.make("mollusk", "aruun", "ring", 1, 2)
	U.face_off(sim, 5.0)
	U.run(sim, 20, {2: _press("ability2")})
	if not sim.fighters[0].has("borrowed"):
		fails.append("mollusk borrowed seconds: should be active")
	U.run(sim, 260)
	if not sim.fighters[0].has("owed"):
		fails.append("mollusk borrowed seconds: the debt must come due (owed)")
	# Shell Memory
	sim = U.make("aruun", "mollusk", "ring", 1, 2)
	sim.set_shell_marks(1, 5)
	U.face_off(sim, 2.0)
	var evs3 := U.run(sim, 30, {1: _tap})
	var h0 := U.first(evs3, "hit", 1)
	var sim4 := U.make("aruun", "mollusk", "ring", 1, 2)
	U.face_off(sim4, 2.0)
	var h1 := U.first(U.run(sim4, 30, {1: _tap}), "hit", 1)
	if h0.is_empty() or h1.is_empty() or float(h0["damage"]) >= float(h1["damage"]):
		fails.append("mollusk shell memory: marks should add armor")

func _light_hit_tick(field: bool) -> int:
	var sim := U.make("mollusk", "aruun", "ring", 1, 2)
	U.face_off(sim, 2.2)
	if field:
		sim.fighters[1].add_status("inertia", 400)
	for t in 80:
		var ib := CombatInput.new()
		ib.strike_tap = t == 1
		sim.step(CombatInput.new(), ib)
		if field:
			sim.fighters[1].add_status("inertia", 400)
		for e in sim.take_events():
			if e["type"] == "hit" and e["fighter"] == 0:
				return sim.tick
	return 0

func _zephyr(fails: Array) -> void:
	# Flutter chain
	var sim := U.make("zephyr", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var evs := U.run(sim, 70, {1: _tap, 7: _tap, 14: _tap, 21: _tap, 28: _tap, 35: _tap})
	var n: int = _hits_by(evs, "zephyr_flutter1").size() + _hits_by(evs, "zephyr_flutter2").size() + _hits_by(evs, "zephyr_flutter3").size()
	if n < 3:
		fails.append("zephyr flutter: three fast chained strikes expected (%d)" % n)
	# Promise (ability 3): a declared rush; keeping it pays, breaking it costs stamina
	sim = U.make("zephyr", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	evs = U.run(sim, 80, {1: _press("ability3")})
	if U.count(evs, "promise", 0) < 1:
		fails.append("zephyr promise: the Promise is declared at the tell")
	if _hits_by(evs, "zephyr_promise_attack").is_empty():
		fails.append("zephyr promise: the rushing attack should connect across the gap")
	sim = U.make("zephyr", "mollusk", "ring", 1, 2)
	sim.fighters[0].pos = Vector2(-9.0, 0.0)
	sim.fighters[1].pos = Vector2(9.0, 3.0)
	var sta_a: float = sim.fighters[0].sta
	U.run(sim, 70, {1: _press("ability3")})
	if sim.fighters[0].sta > sta_a - 20.0:
		fails.append("zephyr promise: a broken Promise should cost stamina (%f -> %f)" % [sta_a, sim.fighters[0].sta])
	# Loophole: a freshly raised guard slips through a light strike, not a heavy
	sim = U.make("aruun", "zephyr", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var lp := func(i: CombatInput, t: int) -> void: i.guard = t >= 15
	evs = U.run(sim, 24, {1: _tap}, {}, Callable(), lp)
	var slipped := false
	for e in evs:
		if e["type"] == "dodge" and e.get("loophole", false):
			slipped = true
	if not slipped or sim.fighters[1].vit < sim.fighters[1].max_vit:
		fails.append("zephyr loophole: should slip through a light strike")
	# Gust: knock-back and reflected projectiles
	sim = U.make("zephyr", "cigarra", "ring", 1, 2)
	U.face_off(sim, 2.4)
	U.run(sim, 40, {2: _press("ability1")})
	if sim.fighters[1].pos.x - 1.2 < 1.5:
		fails.append("zephyr gust: should knock the enemy back")
	sim = U.make("zephyr", "cigarra", "ring", 1, 2)
	U.face_off(sim, 4.0)
	evs = U.run(sim, 60, {22: _press("ability1")}, {1: func(i: CombatInput) -> void: i.strike_hold = true})
	var gust := U.first(evs, "gust", 0)
	if gust.is_empty() or int(gust.get("reflected", 0)) < 1:
		fails.append("zephyr gust: should reflect incoming projectiles (%s)" % str(gust))
	# Pollen: marks the enemy; marked enemies take bonus damage from Zephyr
	sim = U.make("zephyr", "mollusk", "ring", 1, 2)
	U.face_off(sim, 5.0)
	U.run(sim, 30, {2: _press("ability2")})
	sim.fighters[1].pos = sim.ents[0].pos
	U.run(sim, 4)
	if not sim.fighters[1].has("marked") or not sim.fighters[1].has("slowed"):
		fails.append("zephyr pollen: slows and marks the enemy")
	# A Promise Kept cannot be dodged
	sim = U.make("zephyr", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 120, {2: _press("laststand")}, {20: func(i: CombatInput) -> void: i.dodge = true})
	if _hits_by(evs, "zephyr_a_promise_kept").size() < 3:
		fails.append("zephyr a promise kept: the declared flurry cannot be dodged (%d)" % _hits_by(evs, "zephyr_a_promise_kept").size())

func _nyxaris(fails: Array) -> void:
	# Cocoon: command grab that costs silk and drags the target toward the edge
	var sim := U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.0)
	var r0: float = sim.fighters[0].reserve
	var evs := U.run(sim, 50, {1: _grab})
	if U.count(evs, "grab", 1) < 1 or sim.fighters[0].reserve >= r0:
		fails.append("nyxaris cocoon: command grab should land and spend silk")
	# the reserve regenerates
	var rr: float = sim.fighters[0].reserve
	U.run(sim, 300)
	if sim.fighters[0].reserve <= rr:
		fails.append("nyxaris silk reserve: should regenerate")
	# Boundary
	sim = U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 7.0)
	U.run(sim, 70, {2: _press("ability1")})
	var zones := 0
	for e in sim.ents:
		if e.tag == "boundary":
			zones += 1
	if zones != 5:
		fails.append("nyxaris boundary: a five-knot silk border expected (%d)" % zones)
	sim.fighters[1].pos = sim.ents[2].pos
	evs = U.run(sim, 4)
	if U.count(evs, "trap") < 1 or not sim.fighters[1].has("rooted"):
		fails.append("nyxaris boundary: crossing it freezes the intruder")
	# Silk is limited: low reserve blocks the web
	sim = U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 7.0)
	sim.fighters[0].reserve = 5.0
	evs = U.run(sim, 40, {2: _press("ability1")})
	if U.count(evs, "tell", 0) != 0:
		fails.append("nyxaris silk reserve: without silk the Boundary cannot be cast")
	# Venom stacks
	sim = U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 1.8)
	sim.fighters[0].reserve = 100.0
	var presses := {}
	for k in 8:
		presses[1 + k * 40] = _press("ability2")
	U.run(sim, 340, presses)
	var venom := 0
	for d in sim.fighters[1].dots:
		if d["name"] == "venom":
			venom += 1
	if venom < 2 or venom > 5:
		fails.append("nyxaris venom fang: ticking stacks up to five (%d)" % venom)
	# "Who gave you permission?": her perfect guard punishes the attacker (stun + root)
	sim = U.make("zephyr", "nyxaris", "ring", 1, 2)
	U.face_off(sim, 2.0)
	var pg := func(i: CombatInput, t: int) -> void: i.guard = t >= 5
	evs = U.run(sim, 24, {1: _tap}, {}, Callable(), pg)
	if U.count(evs, "parry", 1) < 1 or not sim.fighters[0].has("rooted"):
		fails.append("nyxaris permission: a perfect guard should punish the attacker")
	# Cold Archive: slowed enemy, silk is free
	sim = U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 3.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	U.run(sim, 60, {2: _press("laststand")})
	if not sim.fighters[1].has("slowed") or not sim.fighters[0].has("archive"):
		fails.append("nyxaris cold archive: enemy slowed and silk free")
	# Frost lance chills
	sim = U.make("nyxaris", "mollusk", "ring", 1, 2)
	U.face_off(sim, 2.4)
	U.run(sim, 60, {1: func(i: CombatInput) -> void: i.strike_hold = true})
	if not sim.fighters[1].has("slowed"):
		fails.append("nyxaris frost lance: should chill on hit")
