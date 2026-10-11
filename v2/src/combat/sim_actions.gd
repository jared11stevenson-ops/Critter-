extends RefCounted
## Input ingestion, input buffer, action state machine and voluntary movement.
## Static helpers operating on a CombatSim; holds no state (avoids reference cycles).
const KIND_PRIO := {"ls": 0, "dodge": 1, "grab": 2, "heavy": 3, "light": 4, "a1": 5, "a2": 6}
const Fighter = preload("res://src/combat/fighter.gd")

static func ingest(sim: CombatSim, f: Fighter, inp: CombatInput) -> void:
	var p: Dictionary = f.prev
	var kind := ""
	var best := 99
	var pairs := [
		["light", inp.strike_tap, "tap"], ["heavy", inp.strike_hold, "hold"], ["grab", inp.grab, "grab"],
		["dodge", inp.dodge, "dodge"], ["a1", inp.ability1, "a1"], ["a2", inp.ability2, "a2"]]
	var ls_combo := inp.ability1 and inp.ability2
	if ls_combo and (not p.get("a1", false) or not p.get("a2", false)):
		if _ls_ready(sim, f):
			kind = "ls"
			best = 0
	for pr in pairs:
		var edge: bool = pr[1] and not p.get(pr[2], false)
		if edge and KIND_PRIO[pr[0]] < best and not (ls_combo and kind == "ls"):
			kind = pr[0]
			best = KIND_PRIO[pr[0]]
	p["tap"] = inp.strike_tap
	p["hold"] = inp.strike_hold
	p["grab"] = inp.grab
	p["dodge"] = inp.dodge
	p["a1"] = inp.ability1
	p["a2"] = inp.ability2
	f.guard_rise = inp.guard and not f.prev_guard
	if f.guard_rise:
		f.guard_press_frame = sim.frame + 1
	f.prev_guard = inp.guard
	f.want_guard = inp.guard
	f.move_in = inp.move.limit_length(1.0)
	if kind != "":
		f.buf_kind = kind
		f.buf_age = 0

static func _ls_ready(sim: CombatSim, f: Fighter) -> bool:
	return not f.last_stand_used and f.alive and f.ratio() < sim.R["last_stand_ratio"] and f.def.move_ids.has("laststand")

static func move_for(f: Fighter, kind: String) -> MoveDef:
	var ids: Dictionary = f.def.move_ids
	match kind:
		"light":
			return f.def.move(ids["light"][0])
		"heavy":
			return f.def.move(ids["heavy"])
		"grab":
			return f.def.move(ids["grab"])
		"dodge":
			return f.def.move(ids["dodge"])
		"a1":
			return f.def.move(ids["ability1"])
		"a2":
			return f.def.move(ids["ability2"])
		"ls":
			return f.def.move(ids["laststand"])
	return null

static func can_start(sim: CombatSim, f: Fighter, m: MoveDef) -> bool:
	if f.cooldowns.get(m.id, 0) > 0:
		return false
	if m.kind == "dodge":
		if f.winded or f.sta < m.stamina_cost:
			return false
	elif m.stamina_cost > 0.0 and f.sta <= 0.0:
		return false
	if f.winded and (m.kind == "heavy" or m.kind == "ability"):
		return false
	if (m.pressure_cost != 0.0 or m.require_pressure > 0.0) and f.pressure < maxf(maxf(m.pressure_cost, 0.0), m.require_pressure):
		return false
	return true

static func action_name(f: Fighter, m: MoveDef, kind: String) -> String:
	match kind:
		"light": return "strike_light"
		"heavy": return "strike_heavy"
		"grab": return "grab"
		"dodge": return "dodge"
		"a1": return "ability1"
		"a2": return "ability2"
		"ls": return "laststand"
	return "strike_light"

static func start_move(sim: CombatSim, f: Fighter, o: Fighter, m: MoveDef, kind: String) -> void:
	var R: Dictionary = sim.R
	f.sta = maxf(0.0, f.sta - m.stamina_cost)
	if m.stamina_cost > 0.0:
		f.sta_delay = int(R["sta_regen_delay"])
		if f.sta <= 0.0:
			f.winded = true
	f.burst = 0.0
	if m.pressure_cost < 0.0:
		f.burst = f.pressure
		f.pressure = 0.0
	else:
		f.pressure -= m.pressure_cost
	if m.cooldown > 0:
		f.cooldowns[m.id] = m.cooldown
	if m.self_damage_ratio > 0.0:
		f.vit = maxf(1.0, f.vit - f.vit * m.self_damage_ratio)
	f.move = m
	f.action = action_name(f, m, kind)
	f.stun = 0
	f.stun_kind = ""
	f.af = 0
	f.contact = false
	f.hits_done.resize(m.hits.size())
	f.hits_done.fill(0)
	f.dmg_mult = 1.0
	f.riposte_boost = false
	f.buf_kind = ""
	f.idle_frames = 0
	var to_o: Vector2 = o.pos - f.pos
	if to_o.length_squared() > 0.0001:
		f.facing = to_o.normalized()
	if f.has("riposte") and (m.kind == "light" or m.kind == "heavy"):
		f.af = int(m.startup * (1.0 - float(R["riposte_startup_mult"])))
		f.dmg_mult = float(R["riposte_dmg_mult"])
		f.riposte_boost = true
		f.st.erase("riposte")
	if kind == "dodge":
		var dir: Vector2 = f.move_in
		if dir.length() < 0.2:
			dir = -f.facing
		f.mvec = dir.normalized()
		f.dodge_chain_left = int(f.T["dodge_chain"])
	if kind == "ls":
		f.last_stand_used = true
		f.last_stand_active = true
		f.iframes = 0
		sim.emit("laststand", f.idx, m.id, f.pos, 0.0)
	if m.kind == "light":
		f.chain_idx += 1
	else:
		f.chain_idx = 0
	sim.emit("tell", f.idx, m.id, f.pos, 0.0, {"startup": m.startup, "tell_anim": m.tell_anim, "kind": m.kind})
	sim.fx.on_start(sim, f, o, m)

static func end_move(sim: CombatSim, f: Fighter) -> void:
	f.move = null
	f.action = "idle"
	f.af = 0
	f.chain_idx = 0
	f.contact = false
	f.last_stand_active = false
	f.mvec = Vector2.ZERO

static func try_buffered(sim: CombatSim, f: Fighter, o: Fighter) -> bool:
	if f.buf_kind == "":
		return false
	var m := move_for(f, f.buf_kind)
	if m == null:
		f.buf_kind = ""
		return false
	if f.buf_kind == "ls" and not _ls_ready(sim, f):
		f.buf_kind = ""
		return false
	if not can_start(sim, f, m):
		return false
	start_move(sim, f, o, m, f.buf_kind)
	return true

static func tick_fighter(sim: CombatSim, f: Fighter, o: Fighter) -> void:
	var R: Dictionary = sim.R
	if not f.alive:
		return
	# --- timers -----------------------------------------------------------
	if f.guard_lag > 0:
		f.guard_lag -= 1
	if f.iframes > 0:
		f.iframes -= 1
	if f.buf_kind != "":
		f.buf_age += 1
		if f.buf_age > int(R["input_buffer"]):
			f.buf_kind = ""
	for k in f.cooldowns.keys():
		f.cooldowns[k] -= 1
		if f.cooldowns[k] <= 0:
			f.cooldowns.erase(k)
	f.slow_mult = 1.0
	f.haste_mult = 1.0
	f.take_mult = 1.0
	for k in f.st.keys():
		f.st[k] -= 1
		if f.st[k] <= 0:
			f.st.erase(k)
	if f.has("slowed"):
		f.slow_mult = float(f.T["slow_value"])
	if f.has("haste"):
		f.haste_mult = float(f.T["haste_value"])
	if f.combo_timer > 0:
		f.combo_timer -= 1
		if f.combo_timer == 0:
			f.combo_hits = 0
	_regen(sim, f)
	# --- action advance ---------------------------------------------------
	if f.stun > 0:
		f.stun -= 1
		if f.stun == 0:
			_stun_end(sim, f)
	elif f.move != null:
		f.af += 1
		if f.af >= f.move.total:
			end_move(sim, f)
	# --- decisions ---------------------------------------------------------
	_decide(sim, f, o)
	# --- facing + movement -------------------------------------------------
	var to_o: Vector2 = o.pos - f.pos
	var can_turn: bool = f.stun == 0 and (f.move == null or f.af < f.move.track) and f.action != "dodge"
	if can_turn and to_o.length_squared() > 0.0001:
		f.facing = to_o.normalized()
	sim.fx.motion(sim, f, o)
	_walk(sim, f)
	if f.move == null and f.stun == 0 and f.action == "idle":
		f.idle_frames += 1
	else:
		f.idle_frames = 0

static func _regen(sim: CombatSim, f: Fighter) -> void:
	var R: Dictionary = sim.R
	if f.sta_delay > 0:
		f.sta_delay -= 1
	elif f.sta < f.max_sta and not (f.move != null and f.stun == 0):
		var rate: float = float(f.T["sta_regen"]) / 60.0
		if f.action == "guard":
			rate *= float(R["guard_regen_mult"])
		if f.has("regen_block"):
			rate *= float(R["regen_block_mult"])
		f.sta = minf(f.max_sta, f.sta + rate)
	if f.winded and f.sta >= f.max_sta * float(R["winded_recover_ratio"]):
		f.winded = false
	if f.poise_delay > 0:
		f.poise_delay -= 1
	elif f.poise < f.max_poise and f.action != "stagger":
		f.poise = minf(f.max_poise, f.poise + float(f.T["poise_regen"]) / 60.0)
	if f.pressure > 0.0 and f.T["pressure_decay"] > 0.0:
		f.pressure = maxf(0.0, f.pressure - float(f.T["pressure_decay"]) / 60.0)

static func _stun_end(sim: CombatSim, f: Fighter) -> void:
	var kind: String = f.stun_kind
	f.stun_kind = ""
	if kind == "knockdown":
		f.iframes = int(sim.R["wakeup_invuln"])
	if kind == "stagger":
		f.poise = f.max_poise * float(sim.R["stagger_recover_ratio"])
	if kind == "block" and f.want_guard:
		f.action = "guard"
		return
	f.action = "idle"
	f.move = null
	f.af = 0
	f.contact = false

static func _decide(sim: CombatSim, f: Fighter, o: Fighter) -> void:
	var R: Dictionary = sim.R
	# Last Stand may break out of stun (once, below the threshold)
	if f.stun > 0:
		if f.buf_kind == "ls" and _ls_ready(sim, f) and f.action != "ko" and R["last_stand_breaks_stun"]:
			var m := move_for(f, "ls")
			start_move(sim, f, o, m, "ls")
		return
	# Feint: cancel a heavy windup into guard / grab
	if f.move != null and f.move.feint and f.af < f.move.startup:
		if f.guard_rise or f.buf_kind == "grab":
			var cost := float(R["feint_cost"])
			if f.sta >= cost:
				f.sta -= cost
				var want_grab: bool = f.buf_kind == "grab"
				end_move(sim, f)
				if want_grab and try_buffered(sim, f, o):
					return
				f.buf_kind = ""
				f.action = "guard"
				sim.emit("feint", f.idx, "", f.pos, 0.0)
				return
	# Chain / cancel window
	if f.move != null and f.move.cancel_from >= 0 and f.af >= f.move.cancel_from:
		if f.move.chain_on == "always" or f.contact:
			var nxt := ""
			var kind := ""
			if f.buf_kind == "light" and f.move.chain != "":
				nxt = f.move.chain
				kind = "light"
			elif f.buf_kind == "heavy" and f.move.props.has("chain_heavy"):
				nxt = str(f.move.props["chain_heavy"])
				kind = "heavy"
			elif f.buf_kind == "dodge" and f.move.kind == "dodge" and f.dodge_chain_left > 0:
				nxt = f.move.id
				kind = "dodge"
			if nxt != "":
				var m: MoveDef = f.def.move(nxt)
				if m != null and can_start(sim, f, m):
					var keep_chain: int = f.chain_idx
					var left: int = f.dodge_chain_left
					start_move(sim, f, o, m, kind)
					f.chain_idx = keep_chain + 1 if kind == "light" else 0
					if kind == "dodge":
						f.dodge_chain_left = left - 1
					return
	if not f.actionable():
		return
	if try_buffered(sim, f, o):
		return
	# Guard
	if f.want_guard and f.guard_lag == 0:
		if f.action != "guard":
			f.sta = maxf(0.0, f.sta - float(R["guard_raise_cost"]))
			f.action = "guard"
			f.sta_delay = maxi(f.sta_delay, int(R["guard_raise_delay"]))
	elif f.action == "guard":
		f.action = "idle"
		f.guard_lag = int(R["guard_lag"])

static func _walk(sim: CombatSim, f: Fighter) -> void:
	f.moving = false
	if f.has("rooted") or not f.alive:
		return
	var mult := 0.0
	if f.stun > 0:
		return
	if f.move == null:
		mult = 1.0
		if f.action == "guard":
			mult = float(f.T["guard_move_mult"])
	else:
		var m: MoveDef = f.move
		if m.move_mult > 0.0 and (f.af < m.startup or f.af >= m.startup + m.active):
			mult = m.move_mult
		else:
			return
	var dir: Vector2 = f.move_in
	if dir.length_squared() < 0.0025:
		return
	var sp: float = float(f.T["walk_speed"]) / 60.0 * mult * f.slow_mult * f.haste_mult
	if f.winded:
		sp *= float(sim.R["winded_move_mult"])
	if dir.dot(f.facing) < -0.3:
		sp *= float(sim.R["retreat_mult"])
	f.pos += dir * sp
	f.moving = true
	f.pos = sim.arena.clamp_inside(f.pos, float(sim.R["lip_margin"]))
