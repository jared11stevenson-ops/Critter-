extends RefCounted
## Combat rules tests: data sanity, ring-out, stakes tiers, yield, Last Stand, clash, chain, hazards, timeout.
const U = preload("res://src/combat/sim_test_util.gd")
const STAT_KEYS := ["vit", "sta", "poi", "spd", "rch", "dmg"]

func run() -> Array:
	var fails: Array = []
	_data(fails)
	_ringout_and_stakes(fails)
	_ko_stakes(fails)
	_yield(fails)
	_last_stand(fails)
	_clash(fails)
	_chain_and_hitstop(fails)
	_hazard(fails)
	_timeout(fails)
	_team_vitality(fails)
	return fails

func _tap(i: CombatInput) -> void:
	i.strike_tap = true

func _grab(i: CombatInput) -> void:
	i.grab = true

func _data(fails: Array) -> void:
	var ids: Array = CombatData.critter_ids()
	if ids.size() != 8:
		fails.append("data: roster must have 8 critters")
	for id in ids:
		var c := CombatData.critter(id)
		if c == null:
			fails.append("data: missing critter " + id)
			continue
		if c.stat_total() != 36:
			fails.append("data: %s stat total %d != 36" % [id, c.stat_total()])
		for k in STAT_KEYS:
			var v := int(c.stats.get(k, 0))
			if v < 1 or v > 10:
				fails.append("data: %s stat %s out of range" % [id, k])
		var ids_used: Array = []
		for l in c.move_ids["light"]:
			ids_used.append(l)
		for k in ["heavy", "grab", "dodge", "ability1", "ability2", "laststand"]:
			ids_used.append(c.move_ids[k])
		if c.move_ids.has("ability1_counter"):
			ids_used.append(c.move_ids["ability1_counter"])
		for mid in ids_used:
			var m := c.move(mid)
			if m == null:
				fails.append("data: %s missing move %s" % [id, mid])
				continue
			if m.tell_anim == "":
				fails.append("data: move %s lacks tell_anim" % mid)
			if m.startup < 0 or m.active < 1 or m.recovery < 0:
				fails.append("data: move %s bad frames" % mid)
			if m.kind == "heavy" and m.startup < 24:
				fails.append("data: heavy %s startup %d < 24" % [mid, m.startup])
			if m.kind == "light" and mid in c.move_ids["light"]:
				var last: bool = mid == c.move_ids["light"][c.move_ids["light"].size() - 1] and c.move_ids["light"].size() > 1
				if m.startup < 10 or m.startup > (18 if last else 16):
					fails.append("data: light %s startup %d outside 10-16 (finisher 18)" % [mid, m.startup])
		if c.moves.size() == 0:
			fails.append("data: no moves for " + id)
		for mid in c.moves.keys():
			if c.moves[mid].lore_source.strip_edges() == "":
				fails.append("data: move %s has no lore_source (every move must cite LORE_MOVES.md)" % mid)

func _nyxaris_throw_sim(stakes: int) -> CombatSim:
	var sim := U.make("nyxaris", "cigarra", "ring", stakes, 3)
	sim.fighters[0].pos = Vector2(8.4, 0.0)
	sim.fighters[1].pos = Vector2(9.5, 0.0)
	U.run(sim, 90, {1: _grab})
	return sim

func _ringout_and_stakes(fails: Array) -> void:
	for stakes: int in [0, 1, 2]:
		var sim := _nyxaris_throw_sim(stakes)
		if not sim.is_over():
			fails.append("ringout(stakes %d): bout should end" % stakes)
			continue
		var r := sim.result()
		if r["reason"] != "ringout" or r["winner"] != 0:
			fails.append("ringout(stakes %d): expected ringout win for 0, got %s" % [stakes, str(r)])
		var want_killed := stakes == 2
		if r["killed"] != want_killed:
			fails.append("stakes %d: killed should be %s" % [stakes, want_killed])
		if stakes == 1 and r["injury"].is_empty():
			fails.append("stakes 1: injury must be recorded")
		if stakes != 1 and not r["injury"].is_empty():
			fails.append("stakes %d: no injury expected" % stakes)
	# wall edge: no ring-out
	var sim := U.make("nyxaris", "cigarra", "pit", 2, 3)
	sim.fighters[0].pos = Vector2(6.2, 0.0)
	sim.fighters[1].pos = Vector2(7.3, 0.0)
	U.run(sim, 90, {1: _grab})
	if sim.is_over() and sim.result()["reason"] == "ringout":
		fails.append("ringout: wall edge must not ring out")

func _ko_stakes(fails: Array) -> void:
	for stakes: int in [0, 1, 2]:
		var sim := U.make("aruun", "cigarra", "ring", stakes, 5)
		U.face_off(sim, 1.8)
		sim.fighters[1].vit = 1.0
		U.run(sim, 60, {1: _tap})
		if not sim.is_over():
			fails.append("ko(stakes %d): fatal blow should end bout" % stakes)
			continue
		var r := sim.result()
		if r["reason"] != "ko" or r["winner"] != 0:
			fails.append("ko(stakes %d): bad result %s" % [stakes, str(r)])
		if r["killed"] != (stakes == 2):
			fails.append("ko(stakes %d): killed flag wrong (%s)" % [stakes, r["killed"]])
		if stakes == 1 and r["injury"].is_empty():
			fails.append("ko(stakes 1): injury missing")

func _yield(fails: Array) -> void:
	var sim := U.make("aruun", "cigarra", "ring", 2, 5)
	U.run(sim, 10, {5: func(i: CombatInput) -> void: i.yield_pressed = true})
	var r := sim.result()
	if not sim.is_over() or r["reason"] != "yield" or r["winner"] != 1 or r["killed"]:
		fails.append("yield: expected loser lives, winner 1: %s" % str(r))

func _last_stand(fails: Array) -> void:
	var both := func(i: CombatInput) -> void:
		i.last_stand = true
	var sim := U.make("zephyr", "aruun", "ring", 1, 5)
	U.face_off(sim, 3.0)
	var evs := U.run(sim, 20, {2: both})
	if U.count(evs, "laststand") != 0:
		fails.append("laststand: must be locked above 25% vitality")
	U.run(sim, 100)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 30, {sim.tick + 2: both})
	if U.count(evs, "laststand", 0) != 1:
		fails.append("laststand: should trigger below 25%% (got %d)" % U.count(evs, "laststand", 0))
	# once per bout: let it finish, then try again
	U.run(sim, 200)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 30, {sim.tick + 2: both})
	if U.count(evs, "laststand", 0) != 0:
		fails.append("laststand: only once per bout")
	if not sim.fighters[0].last_stand_used:
		fails.append("laststand: used flag not set")

func _clash(fails: Array) -> void:
	var sim := U.make("zephyr", "zephyr", "ring", 1, 5)
	U.face_off(sim, 1.5)
	var evs := U.run(sim, 20, {1: _tap}, {1: _tap})
	if U.count(evs, "clash") < 2 or U.count(evs, "hit") != 0:
		fails.append("clash: same-tick strikes should clash with no damage (clash=%d hit=%d)" % [U.count(evs, "clash"), U.count(evs, "hit")])

func _chain_and_hitstop(fails: Array) -> void:
	var sim := U.make("zephyr", "aruun", "ring", 1, 5)
	U.face_off(sim, 1.8)
	var evs := U.run(sim, 40, {1: _tap, 12: _tap, 25: _tap})
	var h := U.first(evs, "hit", 1)
	if h.is_empty() or int(h.get("hitstop", 0)) <= 0:
		fails.append("hitstop: hit event must carry hitstop frames")
	var tells := 0
	for e in evs:
		if e["type"] == "tell" and str(e["move_id"]).begins_with("zephyr_flutter"):
			tells += 1
	if tells < 2:
		fails.append("chain: tapping again after a hit should chain the next light (tells=%d)" % tells)
	# hit-stop freezes the simulation: frame counter pauses while tick advances
	var sim2 := U.make("zephyr", "aruun", "ring", 1, 5)
	U.face_off(sim2, 1.8)
	U.run(sim2, 11, {1: _tap})
	var f0 := sim2.frame
	U.run(sim2, 2)
	if sim2.hitstop <= 0 and sim2.frame - f0 >= 2:
		fails.append("hitstop: sim should freeze after a hit")

func _hazard(fails: Array) -> void:
	var sim := U.make("mollusk", "mollusk", "pit", 1, 5)
	sim.apply_modifiers(["hazard"])
	sim.fighters[0].pos = Vector2(0.0, 0.0)
	sim.fighters[1].pos = Vector2(4.0, 0.0)
	U.run(sim, 120)
	if sim.fighters[0].vit >= sim.fighters[0].max_vit:
		fails.append("hazard: standing in a dps zone should hurt")

func _timeout(fails: Array) -> void:
	var sim := U.make("mollusk", "mollusk", "ring", 1, 5)
	U.run(sim, int(CombatData.rules()["timeout_ticks"]) + 600)
	if not sim.is_over() or sim.result()["reason"] != "timeout":
		fails.append("timeout: idle bout should time out")

func _team_vitality(fails: Array) -> void:
	var sim := U.make("mollusk", "zephyr")
	sim.set_vitality_ratio(0, 0.5)
	if absf(sim.fighters[0].ratio() - 0.5) > 0.001:
		fails.append("set_vitality_ratio failed")
