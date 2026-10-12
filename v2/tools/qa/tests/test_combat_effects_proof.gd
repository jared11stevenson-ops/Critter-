extends RefCounted
## MOVE EFFECT GATE (production/PRODUCTION.md section 10): every move of every critter declares `effect_kind` and an
## `expected` block in its JSON; this test runs a scripted scenario per move, compares it with a baseline run of the same
## scenario WITHOUT the move, asserts the measured change and writes v2/tools/out/move_audit.md. A no-op move fails.
const U = preload("res://src/combat/sim_test_util.gd")
const KINDS := ["physical", "special", "status", "terrain", "displacement", "control", "defense", "resource", "summon"]
const AUDIT_PATH := "res://tools/out/move_audit.md"

var _rows: Array = []

func run() -> Array:
	var fails: Array = []
	for cid in CombatData.critter_ids():
		var c := CombatData.critter(cid)
		var mids: Array = c.moves.keys()
		mids.sort()
		for mid in mids:
			var m: MoveDef = c.moves[mid]
			_check_move(fails, c, m)
	_selfcheck(fails)
	_write_audit()
	return fails

## The gate must reject a move that changes nothing: a scenario identical to its baseline fails every measure.
func _selfcheck(fails: Array) -> void:
	var c := CombatData.critter("aruun")
	var m: MoveDef = c.moves["aruun_combo1"]
	var exp: Dictionary = {"dist": 1.8, "ticks": 40}
	var a := _scenario(c, m, "light0", exp, false, {})
	var b := _scenario(c, m, "light0", exp, false, {})
	for ms in [{"m": "enemy_vit_drop", "min": 0.5}, {"m": "hit", "min": 0.5}, {"m": "self_moved", "min": 1.0}, {"m": "enemy_status", "name": "rooted", "min_ticks": 1}, {"m": "event", "type": "hit"}]:
		if _measure(ms, a, b, m.id)[0]:
			fails.append("effects: gate self-check - a no-op passed measure %s" % str(ms))

func _slot_of(c: CritterDef, mid: String) -> String:
	var ids: Dictionary = c.move_ids
	for i in ids["light"].size():
		if ids["light"][i] == mid:
			return "light%d" % i
	for k in ["heavy", "grab", "dodge", "guard", "ability1", "ability2", "ability3", "laststand"]:
		if str(ids.get(k, "")) == mid:
			return k
	return "passive"

func _check_move(fails: Array, c: CritterDef, m: MoveDef) -> void:
	var raw: Dictionary = m.raw
	var label := "%s/%s" % [c.id, m.id]
	var kind := str(raw.get("effect_kind", ""))
	var exp: Dictionary = raw.get("expected", {})
	if not kind in KINDS or exp.is_empty() or not exp.has("measure"):
		fails.append("effects: %s lacks effect_kind/expected (a move must declare a measurable effect)" % label)
		_rows.append([c.id, m.id, kind, "-", "FAIL (undeclared)"])
		return
	var slot := _slot_of(c, m.id)
	var with_r := _scenario(c, m, slot, exp, true, {})
	var base_r := _scenario(c, m, slot, exp, false, {"zone_pos": with_r.get("zone_pos", Vector2.ZERO)})
	var notes: Array = []
	var ok := true
	for ms in exp["measure"]:
		var res := _measure(ms, with_r, base_r, m.id)
		notes.append(res[1])
		if not res[0]:
			ok = false
			fails.append("effects: %s FAILED measure %s -> %s" % [label, str(ms), res[1]])
	_rows.append([c.id, m.id, kind, "; ".join(notes), "PASS" if ok else "FAIL"])

# ---------------------------------------------------------------- scenario
func _scenario(c: CritterDef, m: MoveDef, slot: String, exp: Dictionary, with_move: bool, extra: Dictionary) -> Dictionary:
	var enemy := str(exp.get("enemy_critter", "mollusk"))
	if str(exp.get("enemy", "idle")) == "attacker":
		enemy = str(exp.get("enemy_critter", "zephyr"))
	var sim := CombatSim.new(c, CombatData.critter(enemy), _arena(exp), 2, 7)
	var me = sim.fighters[0]
	var foe = sim.fighters[1]
	var dist := float(exp.get("dist", 2.0))
	U.face_off(sim, dist)
	_apply_pre(sim, exp.get("pre", {}))
	if with_move:
		_apply_pre(sim, exp.get("pre_with", {}))
	else:
		for k in exp.get("base_off", {}).keys():
			me.T[k] = exp["base_off"][k]
	var ticks := int(exp.get("ticks", 100))
	var r := {"hits": {}, "dmg": {}, "events": {}, "peak_status_self": {}, "peak_status_foe": {}, "ent_max": {}, "field_max": {}, "field_min": {},
		"vit_start": [me.vit, foe.vit], "plate_start": me.plate_pool, "start_pos": [me.pos, foe.pos], "max_move": [0.0, 0.0], "zone_pos": Vector2.ZERO, "foe_stun_kinds": {}, "foe_dots_max": 0}
	var field_names := ["pressure", "rage", "reserve", "plate_pool", "debt", "stored", "intel"]
	for fn in field_names:
		r["field_max"][fn] = me.get(fn)
		r["field_min"][fn] = me.get(fn)
	var press_tick := int(exp.get("press_tick", 2))
	var foe_attack := str(exp.get("enemy", "idle")) == "attacker"
	var zone_after := int(exp.get("zone_after", 0))
	for t in range(1, ticks + 1):
		var ia := CombatInput.new()
		var ib := CombatInput.new()
		if with_move:
			_drive(ia, slot, t, press_tick, exp)
		if exp.has("damage_self_at") and t == 2:
			sim.damage(me, null, float(exp["damage_self_at"]), "test")
		if foe_attack and t == int(exp.get("enemy_tick", 1)):
			ib.strike_hold = str(exp.get("enemy_move", "light")) == "heavy"
			ib.strike_tap = not ib.strike_hold
		if zone_after > 0 and t == zone_after + 1:
			var zp: Vector2 = extra.get("zone_pos", Vector2.ZERO)
			if with_move:
				zp = _find_zone(sim, str(exp.get("zone_tag", "")), me.pos)
				r["zone_pos"] = zp
			if zp != Vector2.ZERO:
				if str(exp.get("zone_target", "enemy")) == "self":
					me.pos = zp
				else:
					foe.pos = zp
		sim.step(ia, ib)
		for e in sim.take_events():
			r["events"][e["type"]] = int(r["events"].get(e["type"], 0)) + 1
			if e["type"] == "hit" and e["fighter"] == 1 and e.get("attacker", 0) == 0:
				r["hits"][e["move_id"]] = int(r["hits"].get(e["move_id"], 0)) + 1
				r["dmg"][e["move_id"]] = float(r["dmg"].get(e["move_id"], 0.0)) + float(e["damage"])
			if e["type"] == "grab" and e["fighter"] == 1:
				r["hits"][e["move_id"]] = int(r["hits"].get(e["move_id"], 0)) + 1
				r["dmg"][e["move_id"]] = float(r["dmg"].get(e["move_id"], 0.0)) + float(e["damage"])
		for k in me.st.keys():
			r["peak_status_self"][k] = maxi(int(r["peak_status_self"].get(k, 0)), int(me.st[k]))
		for k in foe.st.keys():
			r["peak_status_foe"][k] = maxi(int(r["peak_status_foe"].get(k, 0)), int(foe.st[k]))
		if me.raging:
			r["peak_status_self"]["raging"] = 1
		var cnt := {}
		for en in sim.ents:
			cnt[en.kind] = int(cnt.get(en.kind, 0)) + 1
			if en.tag != "":
				cnt["tag:" + en.tag] = int(cnt.get("tag:" + en.tag, 0)) + 1
		for k in cnt.keys():
			r["ent_max"][k] = maxi(int(r["ent_max"].get(k, 0)), int(cnt[k]))
		for fn in field_names:
			r["field_max"][fn] = maxf(float(r["field_max"][fn]), float(me.get(fn)))
			r["field_min"][fn] = minf(float(r["field_min"][fn]), float(me.get(fn)))
		r["max_move"][0] = maxf(float(r["max_move"][0]), me.pos.distance_to(r["start_pos"][0]))
		r["max_move"][1] = maxf(float(r["max_move"][1]), foe.pos.distance_to(r["start_pos"][1]))
		r["foe_stun_kinds"][foe.stun_kind] = true
		r["foe_dots_max"] = maxi(int(r["foe_dots_max"]), foe.dots.size())
		if sim.is_over():
			break
	r["vit_end"] = [me.vit, foe.vit]
	r["plate_end"] = me.plate_pool
	r["cooldowns"] = me.cooldowns.duplicate()
	r["me_over"] = not me.alive
	return r

func _arena(exp: Dictionary) -> ArenaDef:
	var a := ArenaDef.make_circle(11.2, "drop")
	if exp.get("pre", {}).has("cracks"):
		a.cracks = [[3.0, 0.0, 0.8]]
	return a

func _apply_pre(sim: CombatSim, pre: Dictionary) -> void:
	var me = sim.fighters[0]
	var foe = sim.fighters[1]
	for k in pre.keys():
		var v = pre[k]
		match k:
			"self_vit_ratio": me.vit = me.max_vit * float(v)
			"self_rage": me.rage = float(v)
			"self_pressure": me.pressure = float(v)
			"self_sta": me.sta = float(v)
			"self_status":
				for s in v.keys():
					me.add_status(s, int(v[s]))
			"enemy_status":
				for s in v.keys():
					foe.add_status(s, int(v[s]))
			"enemy_cultures":
				for i in int(v):
					foe.dots.append({"name": "culture", "age": 0, "life": 600, "dps": 0.0, "grow": 0.0, "burst": 9.0, "ripe": 0})
			"self_dots":
				for i in int(v):
					me.dots.append({"name": "venom", "age": 0, "life": 600, "dps": 0.5, "grow": 0.0, "burst": 0.0, "ripe": 0})
			"enemy_vit_ratio": foe.vit = foe.max_vit * float(v)
			"enemy_pos": foe.pos = Vector2(float(v[0]), float(v[1]))
			"self_pos": me.pos = Vector2(float(v[0]), float(v[1]))
			"marks": sim.set_shell_marks(0, int(v))
			"damage_self": sim.damage(me, null, float(v), "test")
			"self_reserve": me.reserve = float(v)
			"self_plates": me.plate_pool = float(v)

func _find_zone(sim: CombatSim, tag: String, near: Vector2) -> Vector2:
	for en in sim.ents:
		if en.kind == "zone" and en.owner == 0 and (tag == "" or en.tag == tag):
			return en.pos
	return Vector2.ZERO

func _drive(ia: CombatInput, slot: String, t: int, press_tick: int, exp: Dictionary) -> void:
	if slot.begins_with("light"):
		if (t - press_tick) % 7 == 0 and t >= press_tick:
			ia.strike_tap = true
	elif slot == "heavy":
		ia.strike_hold = t == press_tick or (t > press_tick and t < press_tick + int(exp.get("hold", 1)))
	elif slot == "grab":
		ia.grab = t == press_tick
	elif slot == "dodge":
		ia.dodge = t == int(exp.get("dodge_tick", press_tick))
		var dv: Array = exp.get("dodge_dir", [0, 1])
		ia.move = Vector2(float(dv[0]), float(dv[1]))
	elif slot == "guard":
		ia.guard = t >= int(exp.get("guard_from", 1))
	elif slot == "ability1":
		ia.ability1 = t == press_tick
	elif slot == "ability2":
		ia.ability2 = t == press_tick
	elif slot == "ability3":
		ia.ability3 = t == press_tick
	elif slot == "laststand":
		ia.last_stand = t == press_tick
	elif slot == "passive":
		match str(exp.get("via", "none")):
			"ability1": ia.ability1 = t == press_tick
			"ability2": ia.ability2 = t == press_tick
			"ability3": ia.ability3 = t == press_tick
			"guard": ia.guard = t >= int(exp.get("guard_from", 1))
			"dodge":
				ia.dodge = t == int(exp.get("dodge_tick", press_tick))
				var dv2: Array = exp.get("dodge_dir", [0, 1])
				ia.move = Vector2(float(dv2[0]), float(dv2[1]))
	if exp.has("move_dir") and slot != "dodge":
		var mv: Array = exp["move_dir"]
		ia.move = Vector2(float(mv[0]), float(mv[1]))
	# extra scripted presses (e.g. a second input to trigger a stored counter)
	for pr in exp.get("extra_press", []):
		if int(pr["t"]) == t:
			match str(pr["key"]):
				"strike_tap": ia.strike_tap = true
				"strike_hold": ia.strike_hold = true
				"dodge": ia.dodge = true

# ---------------------------------------------------------------- measures: [ok, note]
func _measure(ms: Dictionary, r: Dictionary, b: Dictionary, mid: String) -> Array:
	var k := str(ms["m"])
	var mn := float(ms.get("min", 0.0))
	match k:
		"hit":
			var mv := str(ms.get("move", mid))
			var n := int(r["hits"].get(mv, 0))
			var dmg := float(r["dmg"].get(mv, 0.0))
			return [n >= int(ms.get("count", 1)) and dmg >= mn, "%d hit(s) of %s, %.1f dmg" % [n, mv, dmg]]
		"enemy_vit_drop":
			var d: float = (float(r["vit_start"][1]) - float(r["vit_end"][1])) - (float(b["vit_start"][1]) - float(b["vit_end"][1]))
			return [d >= mn, "enemy Vitality -%.1f vs baseline" % d]
		"self_vit_gain":
			var g: float = (float(r["vit_end"][0]) - float(r["vit_start"][0])) - (float(b["vit_end"][0]) - float(b["vit_start"][0]))
			return [g >= mn, "self Vitality +%.1f" % g]
		"self_vit_loss":
			var l: float = (float(r["vit_start"][0]) - float(r["vit_end"][0])) - (float(b["vit_start"][0]) - float(b["vit_end"][0]))
			return [l >= mn, "self Vitality -%.1f (cost)" % l]
		"damage_prevented":
			var lb: float = float(b["vit_start"][0]) - float(b["vit_end"][0]) + float(b["plate_start"]) - float(b["plate_end"])
			var lr: float = float(r["vit_start"][0]) - float(r["vit_end"][0]) + float(r["plate_start"]) - float(r["plate_end"])
			return [lb - lr >= mn, "damage taken %.1f vs %.1f baseline" % [lr, lb]]
		"enemy_status":
			var n2 := int(r["peak_status_foe"].get(str(ms["name"]), 0))
			return [n2 >= int(ms.get("min_ticks", 1)) and int(b["peak_status_foe"].get(str(ms["name"]), 0)) < n2, "enemy %s up to %d ticks" % [ms["name"], n2]]
		"self_status":
			var n3 := int(r["peak_status_self"].get(str(ms["name"]), 0))
			return [n3 >= int(ms.get("min_ticks", 1)) and int(b["peak_status_self"].get(str(ms["name"]), 0)) < n3, "self %s up to %d ticks" % [ms["name"], n3]]
		"enemy_moved":
			var d2: float = float(r["max_move"][1]) - float(b["max_move"][1])
			return [d2 >= mn, "enemy displaced %.1f m" % d2]
		"self_moved":
			var d3: float = float(r["max_move"][0]) - float(b["max_move"][0])
			return [d3 >= mn, "self moved %.1f m" % d3]
		"entity":
			var key := str(ms["kind"])
			var n4 := int(r["ent_max"].get(key, 0))
			return [n4 >= int(ms.get("count", 1)) and int(b["ent_max"].get(key, 0)) < n4, "%d x %s" % [n4, key]]
		"event":
			var n5 := int(r["events"].get(str(ms["type"]), 0))
			return [n5 >= int(ms.get("count", 1)) and int(b["events"].get(str(ms["type"]), 0)) < n5, "%d x event %s" % [n5, ms["type"]]]
		"field_up":
			var nm := str(ms["name"])
			var up: float = float(r["field_max"][nm]) - float(b["field_max"][nm])
			return [up >= mn, "self %s +%.1f" % [nm, up]]
		"field_down":
			var nm2 := str(ms["name"])
			var dn: float = float(b["field_min"][nm2]) - float(r["field_min"][nm2])
			return [dn >= mn, "self %s -%.1f" % [nm2, dn]]
		"enemy_dots":
			var n6 := int(r["foe_dots_max"])
			return [n6 >= int(ms.get("count", 1)) and n6 > int(b["foe_dots_max"]), "%d DOT stack(s)" % n6]
		"enemy_stun":
			var has: bool = r["foe_stun_kinds"].has(str(ms["kind"])) and not b["foe_stun_kinds"].has(str(ms["kind"]))
			return [has, "enemy stun kind %s" % ms["kind"]]
		"cooldown":
			var cd := int(r["cooldowns"].get(mid, 0))
			return [cd >= int(ms.get("min", 1)) and not b["cooldowns"].has(mid), "cooldown %d" % cd]
		"self_survives":
			return [not r["me_over"], "self alive"]
	return [false, "unknown measure " + k]

func _write_audit() -> void:
	var out := PackedStringArray()
	out.append("# Move audit (Move Effect Gate)")
	out.append("")
	out.append("Generated by `test_combat_effects_proof.gd`: each move is run in a scripted scenario and compared with a baseline run of the same scenario without the move.")
	out.append("")
	out.append("| critter | move | effect kind | measured effect | result |")
	out.append("|---|---|---|---|---|")
	var passed := 0
	for row in _rows:
		out.append("| %s | %s | %s | %s | %s |" % row)
		if str(row[4]) == "PASS":
			passed += 1
	out.append("")
	out.append("%d / %d moves PASS." % [passed, _rows.size()])
	var f := FileAccess.open(AUDIT_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(out) + "\n")
		f.close()
