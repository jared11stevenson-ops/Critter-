extends RefCounted
## Every ability (2 per critter + Last Stand) for all seven critters: triggers, finishes, and shows its effect.
const U = preload("res://src/combat/sim_test_util.gd")

func run() -> Array:
	var fails: Array = []
	for id in CombatData.critter_ids():
		for slot in ["ability1", "ability2", "laststand"]:
			_generic(fails, id, slot)
	_haldor(fails)
	_sessa(fails)
	_weft(fails)
	_cinder(fails)
	_marro(fails)
	_zell(fails)
	_kragg(fails)
	return fails

func _press(slot: String) -> Callable:
	return func(i: CombatInput) -> void:
		if slot == "ability1" or slot == "laststand":
			i.ability1 = true
		if slot == "ability2" or slot == "laststand":
			i.ability2 = true

func _generic(fails: Array, id: String, slot: String) -> void:
	var foe := "kragg" if id != "kragg" else "marro"
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

func _hits_by(evs: Array, move_id: String, type: String = "hit") -> Array:
	var out: Array = []
	for e in evs:
		if e["type"] == type and e["move_id"] == move_id:
			out.append(e)
	return out

func _haldor(fails: Array) -> void:
	var sim := U.make("haldor", "marro", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var evs := U.run(sim, 80, {2: _press("ability1")})
	var h := _hits_by(evs, "haldor_quake_slam")
	if h.is_empty() or sim.fighters[1].action != "knockdown" and sim.fighters[1].stun_kind != "knockdown":
		fails.append("haldor quake slam: should knock down")
	# Horn Charge: super-armor charge rings the target out
	sim = U.make("haldor", "sessa", "ring", 2, 2)
	sim.fighters[0].pos = Vector2(2.0, 0.0)
	sim.fighters[1].pos = Vector2(5.4, 0.0)
	U.run(sim, 120, {2: _press("ability2")})
	if not sim.is_over() or sim.result()["reason"] != "ringout" or sim.result()["winner"] != 0:
		fails.append("haldor horn charge: expected ring-out, got %s" % str(sim.result()))
	# Armor: Horn Charge startup ignores a light poke (no flinch)
	sim = U.make("haldor", "sessa", "ring", 1, 2)
	U.face_off(sim, 2.0)
	U.run(sim, 40, {2: _press("ability2"), 14: func(i: CombatInput) -> void: pass}, {15: func(i: CombatInput) -> void: i.strike_tap = true})
	# Landslide: three escalating slams
	sim = U.make("haldor", "marro", "ring", 1, 2)
	U.face_off(sim, 2.2)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 160, {2: _press("laststand")})
	var n := _hits_by(evs, "haldor_landslide").size() + _hits_by(evs, "haldor_landslide", "block").size()
	if n < 3:
		fails.append("haldor landslide: expected 3 slams, got %d" % n)

func _sessa(fails: Array) -> void:
	var sim := U.make("sessa", "haldor", "ring", 1, 2)
	U.face_off(sim, 2.4)
	var evs := U.run(sim, 120, {2: _press("ability1")}, {12: func(i: CombatInput) -> void: i.strike_tap = true})
	var parried := false
	for e in evs:
		if e["type"] == "parry" and e["fighter"] == 0 and e.get("auto", false):
			parried = true
	if not parried:
		fails.append("sessa riposte stance: strike should be auto-parried")
	if _hits_by(evs, "sessa_riposte_combo").size() < 2:
		fails.append("sessa riposte stance: should counter with a combo (%d hits)" % _hits_by(evs, "sessa_riposte_combo").size())
	sim = U.make("sessa", "haldor", "ring", 1, 2)
	U.face_off(sim, 2.4)
	evs = U.run(sim, 40, {2: _press("ability2")})
	if U.count(evs, "teleport", 0) != 1 or sim.fighters[0].pos.x <= sim.fighters[1].pos.x:
		fails.append("sessa blur step: should end behind the opponent")
	sim = U.make("sessa", "marro", "ring", 1, 2)
	U.face_off(sim, 1.6)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 160, {2: _press("laststand")})
	var n := _hits_by(evs, "sessa_thousand_cuts").size()
	if n < 6:
		fails.append("sessa thousand cuts: expected a flurry, got %d hits" % n)

func _weft(fails: Array) -> void:
	var sim := U.make("weft", "marro", "ring", 1, 2)
	U.face_off(sim, 4.5)
	U.run(sim, 40, {2: _press("ability1")})
	if not sim.fighters[1].has("rooted"):
		fails.append("weft thread snare: should root the target")
	sim = U.make("weft", "marro", "ring", 1, 2)
	U.face_off(sim, 6.0)
	U.run(sim, 80, {2: _press("ability2")})
	var zones := 0
	for e in sim.ents:
		if e.kind == "zone":
			zones += 1
	if zones != 1:
		fails.append("weft web mine: trap should exist (%d)" % zones)
	var ents0: Array = sim.ents
	sim.fighters[1].pos = ents0[0].pos
	var evs := U.run(sim, 5)
	if U.count(evs, "trap") != 1 or not sim.fighters[1].has("rooted"):
		fails.append("weft web mine: stepping on it should trigger and root")
	sim = U.make("weft", "marro", "ring", 1, 2)
	U.face_off(sim, 3.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	U.run(sim, 40, {2: _press("laststand")})
	if not sim.fighters[1].has("slowed") or not sim.fighters[0].has("haste"):
		fails.append("weft silk cathedral: enemy slowed and weft hasted")
	# Tether Pull (grab) drags the target in
	sim = U.make("weft", "marro", "ring", 1, 2)
	U.face_off(sim, 4.0)
	U.run(sim, 70, {2: func(i: CombatInput) -> void: i.grab = true})
	if sim.fighters[0].pos.distance_to(sim.fighters[1].pos) > 2.6:
		fails.append("weft tether pull: should drag target close")

func _cinder(fails: Array) -> void:
	var sim := U.make("cinder", "marro", "ring", 1, 2)
	U.face_off(sim, 2.4)
	sim.fighters[0].pressure = 80.0
	var evs := U.run(sim, 80, {2: _press("ability1")})
	var h := _hits_by(evs, "cinder_pressure_burst")
	if h.is_empty() or float(h[0]["damage"]) < 20.0 * sim.fighters[0].out_mult():
		fails.append("cinder pressure burst: damage should scale with pressure")
	if sim.fighters[0].pressure > 0.1:
		fails.append("cinder pressure burst: should spend pressure")
	# Pressure builds on hit
	sim = U.make("cinder", "marro", "ring", 1, 2)
	U.face_off(sim, 2.4)
	U.run(sim, 40, {2: func(i: CombatInput) -> void: i.strike_tap = true})
	if sim.fighters[0].pressure <= 0.0:
		fails.append("cinder: strikes must build Pressure")
	# Scorch Spray: damage-over-time zone
	sim = U.make("cinder", "marro", "ring", 1, 2)
	U.face_off(sim, 3.0)
	U.run(sim, 20, {2: _press("ability2")})
	sim.fighters[1].pos = sim.ents[0].pos
	var v0: float = sim.fighters[1].vit
	U.run(sim, 90)
	if sim.fighters[1].vit >= v0 - 1.0:
		fails.append("cinder scorch spray: should deal damage over time")
	# Overpressure never kills the user
	sim = U.make("cinder", "marro", "ring", 1, 2)
	U.face_off(sim, 2.6)
	sim.fighters[0].vit = 3.0
	U.run(sim, 120, {2: _press("laststand")})
	if sim.fighters[0].vit < 1.0 or sim.is_over():
		fails.append("cinder overpressure: must not kill the user")
	var ev2 := U.make("cinder", "marro", "ring", 1, 2)
	U.face_off(ev2, 2.6)
	ev2.fighters[0].vit = ev2.fighters[0].max_vit * 0.2
	var before: float = ev2.fighters[0].vit
	U.run(ev2, 120, {2: _press("laststand")})
	if ev2.fighters[0].vit > before * 0.75:
		fails.append("cinder overpressure: should cost 30%% current vitality")

func _marro(fails: Array) -> void:
	var sim := U.make("marro", "haldor", "ring", 1, 2)
	U.face_off(sim, 2.2)
	var evs := U.run(sim, 70, {2: _press("ability1")}, {14: func(i: CombatInput) -> void: i.strike_tap = true})
	var walled := false
	for e in evs:
		if e["type"] == "block" and e.get("wall", false):
			walled = true
	if not walled or sim.fighters[0].vit < sim.fighters[0].max_vit:
		fails.append("marro shield wall: frontal hits should be negated")
	# Shield wall does not stop a command grab
	sim = U.make("marro", "kragg", "ring", 1, 2)
	U.face_off(sim, 1.8)
	evs = U.run(sim, 70, {2: _press("ability1")}, {10: _press("ability1")})
	if U.count(evs, "grab", 0) < 1:
		fails.append("marro shield wall: Pincer Hold (command grab) should bypass it")
	# Pike lunge crushes guard
	sim = U.make("marro", "haldor", "ring", 1, 2)
	U.face_off(sim, 3.6)
	var hg := func(i: CombatInput, t: int) -> void: i.guard = true
	evs = U.run(sim, 100, {2: _press("ability2")}, {}, Callable(), hg)
	var blk := _hits_by(evs, "marro_pike_lunge", "block")
	if blk.is_empty() or not blk[0].get("broke", false):
		fails.append("marro pike lunge: should crush a guard")
	# Colony Call phantoms
	sim = U.make("marro", "kragg", "ring", 1, 2)
	U.face_off(sim, 3.0)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	var v0: float = sim.fighters[1].vit
	U.run(sim, 40, {2: _press("laststand")})
	var ph := 0
	for e in sim.ents:
		if e.kind == "phantom":
			ph += 1
	if ph != 3:
		fails.append("marro colony call: 3 phantoms expected (%d)" % ph)
	U.run(sim, 240)
	if sim.fighters[1].vit >= v0:
		fails.append("marro colony call: phantoms should damage the target")

func _zell(fails: Array) -> void:
	var sim := U.make("zell", "marro", "ring", 1, 2)
	U.face_off(sim, 5.0)
	var evs := U.run(sim, 90, {2: _press("ability1")})
	if _hits_by(evs, "zell_skybound").is_empty():
		fails.append("zell skybound: leap and dive should land")
	sim = U.make("zell", "marro", "ring", 1, 2)
	U.face_off(sim, 5.0)
	evs = U.run(sim, 90, {2: _press("ability2")})
	if U.count(evs, "projectile", 0) != 1 or _hits_by(evs, "zell_glass_gale").is_empty():
		fails.append("zell glass gale: projectile should fly and hit")
	sim = U.make("zell", "marro", "ring", 1, 2)
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
	if inv < 60 or _hits_by(evs, "zell_final_flight").size() < 3:
		fails.append("zell final flight: invulnerable flurry expected (inv=%d hits=%d)" % [inv, _hits_by(evs, "zell_final_flight").size()])
	# Air dodge: a second dodge may chain out of the first
	sim = U.make("zell", "marro", "ring", 1, 2)
	U.face_off(sim, 5.0)
	evs = U.run(sim, 30, {2: func(i: CombatInput) -> void: i.dodge = true, 9: func(i: CombatInput) -> void: i.dodge = true})
	var dodges := 0
	for e in evs:
		if e["type"] == "tell" and e["move_id"] == "zell_dodge":
			dodges += 1
	if dodges != 2:
		fails.append("zell air dodge: expected chained second dodge (%d)" % dodges)

func _kragg(fails: Array) -> void:
	var sim := U.make("kragg", "marro", "ring", 1, 2)
	U.face_off(sim, 2.6)
	var evs := U.run(sim, 70, {2: _press("ability1")})
	var g := _hits_by(evs, "kragg_pincer_hold", "grab")
	if g.is_empty() or float(g[0]["damage"]) < 20.0 * sim.fighters[0].out_mult():
		fails.append("kragg pincer hold: command grab should land hard")
	sim = U.make("kragg", "marro", "ring", 1, 2)
	U.face_off(sim, 5.0)
	U.run(sim, 60, {2: _press("ability2")})
	if sim.fighters[0].pos.distance_to(sim.fighters[1].pos) > 2.6:
		fails.append("kragg chain pull: should drag the target in (%f)" % sim.fighters[0].pos.distance_to(sim.fighters[1].pos))
	sim = U.make("kragg", "marro", "ring", 1, 2)
	U.face_off(sim, 2.6)
	sim.fighters[0].vit = sim.fighters[0].max_vit * 0.2
	evs = U.run(sim, 120, {2: _press("laststand")})
	var m := _hits_by(evs, "kragg_main_event", "grab")
	if m.is_empty() or float(m[0]["damage"]) < 50.0 * sim.fighters[0].out_mult():
		fails.append("kragg main event: huge command throw expected")
