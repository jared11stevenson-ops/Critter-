extends RefCounted
## Core combat tests: determinism, triangle, parry window edges, i-frames, stamina, poise, buffer.
const U = preload("res://src/combat/sim_test_util.gd")

func run() -> Array:
	var fails: Array = []
	_determinism(fails)
	_triangle(fails)
	_parry_edges(fails)
	_iframes(fails)
	_stamina(fails)
	_poise(fails)
	_buffer(fails)
	return fails

func _tap(i: CombatInput) -> void:
	i.strike_tap = true

func _grab(i: CombatInput) -> void:
	i.grab = true

func _dodge(i: CombatInput) -> void:
	i.dodge = true

func _guard_hold(i: CombatInput, _t: int) -> void:
	i.guard = true

func _fuzz_inputs(rng: RandomNumberGenerator, i: CombatInput) -> void:
	i.move = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	var r := rng.randf()
	i.strike_tap = r < 0.06
	i.strike_hold = r > 0.06 and r < 0.075
	i.grab = r > 0.1 and r < 0.12
	i.dodge = r > 0.15 and r < 0.17
	i.guard = r > 0.5 and r < 0.65
	i.ability1 = r > 0.8 and r < 0.83
	i.ability2 = r > 0.9 and r < 0.93

func _determinism(fails: Array) -> void:
	for pair in [["aruun", "zephyr"], ["bramvex", "scarlith"], ["mollusk", "zephyr"], ["nyxaris", "aruun"]]:
		var hashes: Array = []
		for run_i in 2:
			var sim := U.make(pair[0], pair[1], "ring", 1, 1234)
			var rng := RandomNumberGenerator.new()
			rng.seed = 99
			for t in 2000:
				var ia := CombatInput.new()
				var ib := CombatInput.new()
				_fuzz_inputs(rng, ia)
				_fuzz_inputs(rng, ib)
				sim.step(ia, ib)
				if sim.is_over():
					break
			hashes.append([sim.state_hash(), sim.tick])
		if hashes[0] != hashes[1]:
			fails.append("determinism: %s vs %s diverged: %s" % [pair[0], pair[1], str(hashes)])

func _triangle(fails: Array) -> void:
	# Strike beats Grab (faster startup): Cigarra light (10f) vs Aruun grab (18f) started together.
	var sim := U.make("zephyr", "aruun")
	U.face_off(sim, 1.8)
	var evs := U.run(sim, 40, {1: _tap}, {1: _grab})
	if U.count(evs, "hit", 1) < 1 or U.count(evs, "grab", 0) > 0:
		fails.append("triangle: strike should beat slower grab (hit_on_aruun=%d grab_on_cigarra=%d)" % [U.count(evs, "hit", 1), U.count(evs, "grab", 0)])
	# Strike beats Grab on the same active tick: Aruun grab starts 8 ticks earlier (active at af 18 == tick 19; light active tick 19).
	sim = U.make("zephyr", "aruun")
	U.face_off(sim, 1.8)
	evs = U.run(sim, 40, {11: _tap}, {1: _grab})
	if U.count(evs, "hit", 1) < 1 or U.count(evs, "grab", 0) > 0:
		fails.append("triangle: same-tick strike must beat grab")
	# Guard beats Strike
	sim = U.make("zephyr", "aruun")
	U.face_off(sim, 1.8)
	var hold_guard := func(i: CombatInput, t: int) -> void: i.guard = true
	evs = U.run(sim, 14, {20: _tap}, {}, Callable(), hold_guard)
	sim = U.make("zephyr", "aruun")
	U.face_off(sim, 1.8)
	evs = U.run(sim, 50, {30: _tap}, {}, Callable(), hold_guard)
	if U.count(evs, "block", 1) < 1 or U.count(evs, "hit", 1) > 0 or U.count(evs, "parry", 1) > 0:
		fails.append("triangle: held guard should block strike (block=%d hit=%d parry=%d)" % [U.count(evs, "block", 1), U.count(evs, "hit", 1), U.count(evs, "parry", 1)])
	# Grab beats Guard
	sim = U.make("zephyr", "aruun")
	U.face_off(sim, 1.8)
	evs = U.run(sim, 60, {30: _grab}, {}, Callable(), hold_guard)
	if U.count(evs, "grab", 1) < 1:
		fails.append("triangle: grab should beat guard")

func _impact_tick_light1() -> int:
	return 1 + 10   # Cigarra light1: input at tick 1, startup 10 -> first active tick 11

func _parry_case(press_tick: int) -> Dictionary:
	var sim := U.make("zephyr", "mollusk")
	U.face_off(sim, 1.8)
	var press := func(i: CombatInput, t: int) -> void: i.guard = t >= press_tick
	var evs := U.run(sim, 16, {1: _tap}, {}, Callable(), press)
	return {"parry": U.count(evs, "parry", 1), "block": U.count(evs, "block", 1), "hit": U.count(evs, "hit", 1), "sim": sim}

func _parry_edges(fails: Array) -> void:
	var imp := _impact_tick_light1()
	# guard pressed k frames before impact: k=7 and 8 parry, 9 only blocks (8-frame window)
	var expect := {7: "parry", 8: "parry", 9: "block"}
	for k in expect.keys():
		var r := _parry_case(imp - k)
		if expect[k] == "parry" and r["parry"] != 1:
			fails.append("parry edge: guard %d frames before impact should parry (got %s)" % [k, str({"p": r["parry"], "b": r["block"], "h": r["hit"]})])
		if expect[k] == "block" and (r["parry"] != 0 or r["block"] != 1):
			fails.append("parry edge: guard %d frames before impact should only block (got %s)" % [k, str({"p": r["parry"], "b": r["block"], "h": r["hit"]})])
	# Parry negates damage, stuns attacker and opens a riposte
	var r2 := _parry_case(imp - 4)
	var sim: CombatSim = r2["sim"]
	if sim.fighters[1].vit < sim.fighters[1].max_vit - 0.001:
		fails.append("parry: defender took damage")
	if sim.fighters[0].stun <= 0 and sim.fighters[0].action != "stagger":
		fails.append("parry: attacker not stunned")
	if not sim.fighters[1].has("riposte"):
		fails.append("parry: no riposte status")
	# Cigarra's longer window (12f): Aruun light1 (startup 16) impacts on tick 17
	var sim2 := U.make("aruun", "cigarra")
	U.face_off(sim2, 2.0)
	var press2 := func(i: CombatInput, t: int) -> void: i.guard = t >= 5
	var evs2 := U.run(sim2, 20, {1: _tap}, {}, Callable(), press2)
	if U.count(evs2, "parry", 1) != 1:
		fails.append("parry: Cigarra 12-frame window should parry at k=12")
	var sim3 := U.make("aruun", "cigarra")
	U.face_off(sim3, 2.0)
	var press3 := func(i: CombatInput, t: int) -> void: i.guard = t >= 4
	var evs3 := U.run(sim3, 20, {1: _tap}, {}, Callable(), press3)
	if U.count(evs3, "parry", 1) != 0:
		fails.append("parry: Cigarra k=13 must not parry")

func _iframes(fails: Array) -> void:
	# exactly 6 invulnerable ticks from the start of a dodge
	var sim := U.make("zephyr", "aruun")
	U.face_off(sim, 6.0)
	var n := 0
	for t in 40:
		var ib := CombatInput.new()
		ib.dodge = t == 2
		sim.step(CombatInput.new(), ib)
		if sim.fighters[1].invulnerable():
			n += 1
	if n != 6:
		fails.append("iframes: dodge should give exactly 6 i-frames, got %d" % n)
	# Cigarra light active from tick 11 (3 active frames). Early dodge: i-frames expire, hit lands.
	var side := func(i: CombatInput) -> void:
		i.dodge = true
		i.move = Vector2(0, 1)
	var toward := func(i: CombatInput) -> void:
		i.dodge = true
		i.move = Vector2(-1, 0)
	sim = U.make("zephyr", "aruun")
	U.face_off(sim, 1.8)
	var evs := U.run(sim, 16, {1: _tap}, {1: toward})
	if U.count(evs, "hit", 1) != 1:
		fails.append("iframes: dodge too early must be hit after i-frames end")
	# Well-timed dodge: no damage, dodge event
	sim = U.make("zephyr", "aruun")
	U.face_off(sim, 1.8)
	evs = U.run(sim, 16, {1: _tap}, {8: toward})
	if U.count(evs, "hit", 1) != 0 or U.count(evs, "dodge", 1) < 1:
		fails.append("iframes: well timed dodge should evade (hit=%d dodge=%d)" % [U.count(evs, "hit", 1), U.count(evs, "dodge", 1)])

func _stamina(fails: Array) -> void:
	var sim := U.make("aruun", "zephyr")
	U.face_off(sim, 6.0)
	var f = sim.fighters[0]
	f.sta = 4.0
	U.run(sim, 3, {1: _tap})
	if not f.winded or f.sta > 0.0:
		fails.append("stamina: spending to zero should cause Winded")
	# winded cannot dodge or heavy
	var sim2 := U.make("aruun", "zephyr")
	var f2 = sim2.fighters[0]
	f2.sta = 0.0
	f2.winded = true
	var evs := U.run(sim2, 5, {1: _dodge})
	if U.count(evs, "tell", 0) > 0:
		fails.append("stamina: winded fighter must not dodge")
	# regen recovers and clears winded
	U.run(sim, 400)
	if f.winded or f.sta < 20.0:
		fails.append("stamina: should regenerate and recover from Winded (sta=%f)" % f.sta)
	# winded guard breaks hard: chip is larger
	var sim3 := U.make("zephyr", "aruun")
	U.face_off(sim3, 1.8)
	var hg := func(i: CombatInput, t: int) -> void: i.guard = true
	U.run(sim3, 20, {}, {}, Callable(), hg)
	sim3.fighters[1].sta = 0.0
	sim3.fighters[1].sta_delay = 200
	sim3.fighters[1].winded = true
	var evs3 := U.run(sim3, 40, {sim3.tick + 2: _tap}, {}, Callable(), hg)
	var b := U.first(evs3, "block", 1)
	if b.is_empty() or not b.get("broke", false):
		fails.append("stamina: guard with no stamina should break")

func _poise(fails: Array) -> void:
	var sim := U.make("aruun", "zephyr")
	U.face_off(sim, 1.8)
	sim.fighters[1].poise = 5.0
	var evs := U.run(sim, 60, {1: func(i: CombatInput) -> void: i.strike_hold = true})
	if U.count(evs, "stagger", 1) < 1:
		fails.append("poise: heavy against low poise should stagger")
	# Chip: hit lowers poise but regenerates after delay
	var sim2 := U.make("aruun", "zephyr")
	U.face_off(sim2, 1.8)
	U.run(sim2, 30, {1: _tap})
	var p: float = sim2.fighters[1].poise
	if p >= sim2.fighters[1].max_poise:
		fails.append("poise: light hit should chip poise")
	U.run(sim2, 400)
	if sim2.fighters[1].poise < sim2.fighters[1].max_poise - 0.01:
		fails.append("poise: should regenerate")

func _buffer(fails: Array) -> void:
	# Aruun heavy whiffs (no cancel windows): a dodge pressed a few frames before it ends is buffered and starts on the first free tick.
	var sim := U.make("aruun", "mollusk")
	U.face_off(sim, 9.0)
	var total: int = sim.fighters[0].def.move("aruun_overhead").total
	var hold := func(i: CombatInput) -> void: i.strike_hold = true
	var evs := U.run(sim, total + 10, {1: hold, total - 3: _dodge})
	var dodge_tell := false
	for e in evs:
		if e["type"] == "tell" and e["move_id"] == "aruun_dodge":
			dodge_tell = true
			if e["tick"] != total + 1:
				fails.append("buffer: buffered dodge should start on tick %d, got %d" % [total + 1, e["tick"]])
	if not dodge_tell:
		fails.append("buffer: input pressed 4 frames early should execute")
	sim = U.make("aruun", "mollusk")
	U.face_off(sim, 9.0)
	evs = U.run(sim, total + 10, {1: hold, total - 8: _dodge})
	for e in evs:
		if e["type"] == "tell" and e["move_id"] == "aruun_dodge":
			fails.append("buffer: input older than 6 frames must expire")
