extends RefCounted
## AI opponent tests: plays full bouts, deterministic, reads/parries, habits, yield and Last Stand decisions.
const U = preload("res://src/combat/sim_test_util.gd")
const Habits = preload("res://src/combat/ai/ai_habits.gd")

func run() -> Array:
	var fails: Array = []
	_full_bouts(fails)
	_determinism(fails)
	_habits(fails)
	_profiles(fails)
	_parry(fails)
	_yield_and_last_stand(fails)
	_abilities_used(fails)
	return fails

func _play(a: String, b: String, pa: String, pb: String, seed_value: int, max_ticks: int = 20000, stakes: int = 1) -> CombatSim:
	var sim := U.make(a, b, "ring", stakes, seed_value)
	var ai_a := CombatAI.new(0, pa, seed_value + 1, false)
	var ai_b := CombatAI.new(1, pb, seed_value + 2, false)
	while not sim.is_over() and sim.tick < max_ticks:
		sim.step(ai_a.decide(sim), ai_b.decide(sim))
		sim.take_events()
	return sim

func _full_bouts(fails: Array) -> void:
	var pairs := [["haldor", "sessa"], ["weft", "cinder"], ["marro", "zell"], ["kragg", "haldor"], ["sessa", "kragg"]]
	var i := 0
	for p in pairs:
		for prof in CombatAI.profile_names():
			i += 1
			var sim := _play(p[0], p[1], prof, prof, 40 + i)
			if not sim.is_over():
				fails.append("ai: %s vs %s (%s) did not finish" % [p[0], p[1], prof])
				continue
			var r := sim.result()
			if not r.has("reason") or not r.has("winner"):
				fails.append("ai: bad result for %s vs %s" % [p[0], p[1]])

func _determinism(fails: Array) -> void:
	var h: Array = []
	for k in 2:
		var sim := _play("cinder", "zell", "expert", "standard", 77, 1500)
		h.append(sim.state_hash())
	if h[0] != h[1]:
		fails.append("ai: AI vs AI not deterministic for the same seeds")

func _habits(fails: Array) -> void:
	var hb = Habits.new()
	for i in 12:
		hb.record("close:light", "guard")
	hb.record("close:light", "grab")
	var p: Dictionary = hb.predict("close:light")
	if p["guard"] < 0.5:
		fails.append("ai habits: should learn that the opponent guards")
	var w: Dictionary = Habits.counter_weights(p)
	if w["grab"] <= w["light"]:
		fails.append("ai habits: a guard-happy opponent should be answered with grabs")
	if hb.confidence("close:light") < 0.9 or hb.confidence("nothing") > 0.01:
		fails.append("ai habits: confidence should grow with samples")

func _profiles(fails: Array) -> void:
	var pr := CombatAI.load_profiles()
	for n in ["novice", "standard", "expert"]:
		if not pr.has(n):
			fails.append("ai: missing profile " + n)
	if not (pr["novice"]["reaction"] > pr["standard"]["reaction"] and pr["standard"]["reaction"] > pr["expert"]["reaction"]):
		fails.append("ai: reaction frames should shrink with skill")
	if not (pr["novice"]["parry_prob"] < pr["expert"]["parry_prob"]):
		fails.append("ai: expert should parry more")

func _parry(fails: Array) -> void:
	# A scripted attacker taps every 70 ticks; the expert AI should parry some of them and take little damage.
	var parries := 0
	var hits := 0
	for s in 6:
		var sim := U.make("sessa", "haldor", "ring", 1, 300 + s)
		U.face_off(sim, 1.8)
		var ai := CombatAI.new(1, "expert", 900 + s, false)
		for t in 700:
			var ia := CombatInput.new()
			ia.strike_tap = t % 70 == 1
			sim.step(ia, ai.decide(sim))
			for e in sim.take_events():
				if e["type"] == "parry" and e["fighter"] == 1:
					parries += 1
				if e["type"] == "hit" and e["fighter"] == 1:
					hits += 1
			if sim.is_over():
				break
	if parries < 3:
		fails.append("ai: expert should parry repeated lights (parries=%d hits=%d)" % [parries, hits])
	# novice parries far less
	var novice_parries := 0
	for s in 6:
		var sim2 := U.make("sessa", "haldor", "ring", 1, 300 + s)
		U.face_off(sim2, 1.8)
		var ai2 := CombatAI.new(1, "novice", 900 + s, false)
		for t in 700:
			var ia2 := CombatInput.new()
			ia2.strike_tap = t % 70 == 1
			sim2.step(ia2, ai2.decide(sim2))
			for e in sim2.take_events():
				if e["type"] == "parry" and e["fighter"] == 1:
					novice_parries += 1
			if sim2.is_over():
				break
	if novice_parries > parries:
		fails.append("ai: novice parried more than expert (%d vs %d)" % [novice_parries, parries])

func _yield_and_last_stand(fails: Array) -> void:
	var yielded := false
	for s in 5:
		var sim := U.make("sessa", "haldor", "ring", 2, 50 + s)
		U.face_off(sim, 4.0)
		sim.fighters[1].vit = sim.fighters[1].max_vit * 0.05
		sim.fighters[1].last_stand_used = true
		var ai := CombatAI.new(1, "expert", 5 + s, true)
		for t in 900:
			sim.step(CombatInput.new(), ai.decide(sim))
			sim.take_events()
			if sim.is_over():
				break
		if sim.is_over() and sim.result()["reason"] == "yield" and not sim.result()["killed"]:
			yielded = true
	if not yielded:
		fails.append("ai: a beaten expert should yield (loser lives)")
	var used := false
	for s in 5:
		var sim2 := U.make("kragg", "marro", "ring", 1, 60 + s)
		U.face_off(sim2, 2.2)
		sim2.fighters[0].vit = sim2.fighters[0].max_vit * 0.15
		var ai2 := CombatAI.new(0, "expert", 8 + s, false)
		for t in 900:
			sim2.step(ai2.decide(sim2), CombatInput.new())
			sim2.take_events()
			if sim2.fighters[0].last_stand_used or sim2.is_over():
				break
		used = used or sim2.fighters[0].last_stand_used
	if not used:
		fails.append("ai: AI should use Last Stand when low and in range")

func _abilities_used(fails: Array) -> void:
	for id in CombatData.critter_ids():
		var used := 0
		for s in 3:
			var sim := _play(id, "marro" if id != "marro" else "haldor", "standard", "standard", 200 + s, 6000)
			for k in sim.fighters[0].cooldowns.keys():
				used += 1
			if sim.fighters[0].last_stand_used:
				used += 1
		if used == 0:
			fails.append("ai: %s never used abilities in 3 bouts" % id)
