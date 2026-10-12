extends RefCounted
## Input ingestion, input buffer, action state machine and voluntary movement.
## Static helpers operating on a CombatSim; holds no state (avoids reference cycles).
const Res = preload("res://src/combat/sim_res.gd")
const KIND_PRIO := {"ls": 0, "dodge": 1, "grab": 2, "heavy": 3, "light": 4, "a1": 5, "a2": 6, "a3": 7}
const Fighter = preload("res://src/combat/fighter.gd")

static func ingest(sim: CombatSim, f: Fighter, inp: CombatInput) -> void:
	var p: Dictionary = f.prev
	var kind := ""
	var best := 99
	# universal Grab = Guard + Strike together (or the explicit grab flag)
	var tap_edge: bool = inp.strike_tap and not p.get("tap", false)
	var grab_in: bool = inp.grab or (inp.guard and inp.strike_tap)
	var pairs := [
		["light", inp.strike_tap and not inp.guard, "tap"], ["heavy", inp.strike_hold, "hold"], ["grab", grab_in, "grab"],
		["dodge", inp.dodge, "dodge"], ["a1", inp.ability1, "a1"], ["a2", inp.ability2, "a2"], ["a3", inp.ability3, "a3"]]
	if inp.guard and tap_edge:
		p["grab"] = false                 # the chord is a fresh grab press
	if inp.last_stand and not p.get("ls", false) and _ls_ready(sim, f):
		kind = "ls"
		best = 0
	elif inp.ability3 and not p.get("a3", false) and f.def.move_ids.has("ability3") and f.def.move(str(f.def.move_ids["ability3"])).kind == "toggle_rage":
		Res.toggle_rage(sim, f)           # Beetle Rage: an activatable overdrive (toggle, no animation)
		pairs[6][1] = false
	for pr in pairs:
		var edge: bool = pr[1] and not p.get(pr[2], false)
		if edge and KIND_PRIO[pr[0]] < best:
			kind = pr[0]
			best = KIND_PRIO[pr[0]]
	p["tap"] = inp.strike_tap
	p["hold"] = inp.strike_hold
	p["grab"] = grab_in
	p["dodge"] = inp.dodge
	p["a1"] = inp.ability1
	p["a2"] = inp.ability2
	p["a3"] = inp.ability3
	p["ls"] = inp.last_stand
	f.hold_level = inp.strike_hold
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
		"a3":
			return f.def.move(ids["ability3"]) if ids.has("ability3") else null
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
	if m.reserve_cost > 0.0 and not f.has("archive") and f.reserve < m.reserve_cost:
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
		"a3": return "ability3"
	return "strike_light"

static func start_move(sim: CombatSim, f: Fighter, o: Fighter, m: MoveDef, kind: String) -> void:
	var R: Dictionary = sim.R
	var cost: float = m.stamina_cost
	if m.kind == "dodge" and float(f.T["intel_gain"]) > 0.0:
		cost *= 1.0 - f.intel * float(R["intel_dodge_discount"])
	f.sta = maxf(0.0, f.sta - cost)
	if m.reserve_cost > 0.0 and not f.has("archive"):
		f.reserve = maxf(0.0, f.reserve - m.reserve_cost)
	if m.pressure_on_use > 0.0:
		f.pressure = minf(float(f.T["pressure_max"]), f.pressure + m.pressure_on_use)
	f.charge = 0
	if m.props.get("cleanse", false):
		Res.cleanse(sim, f)
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
	var aim: Vector2 = f.compel["pos"] if f.compel.get("mode", "") == "decoy" else o.pos
	var to_o: Vector2 = aim - f.pos
	if to_o.length_squared() > 0.0:
		f.facing = to_o.normalized()
	if not m.promise.is_empty():
		sim.emit("promise", f.idx, m.id, f.pos, 0.0)
	if float(o.T["intel_gain"]) > 0.0 and m.kind != "dodge":
		o.intel = minf(1.0, o.intel + float(R["intel_per_tell"]) * float(o.T["intel_gain"]))
	if o.has("premonition") or o.has("touched"):
		sim.mind.spawn_ghost(sim, o, f, m)
	if f.has("riposte") and (m.kind == "light" or m.kind == "heavy"):
		f.af = int(m.startup * (1.0 - float(R["riposte_startup_mult"])))
		f.dmg_mult = float(R["riposte_dmg_mult"])
		f.riposte_boost = true
		f.st.erase("riposte")
	if kind == "dodge":
		var dir: Vector2 = f.move_in
		if dir.length() < float(sim.R["input_deadzone"]):
			dir = -f.facing
		f.mvec = dir.normalized()
		f.dodge_chain_left = int(f.T["dodge_chain"]) + (1 if f.has("borrowed") else 0)
	if kind == "ls":
		f.last_stand_used = true
		f.last_stand_active = true
		f.iframes = 0
		sim.emit("laststand", f.idx, m.id, f.pos, 0.0)
	if m.kind == "light":
		f.chain_idx += 1
	else:
		f.chain_idx = 0
	sim.emit("tell", f.idx, m.id, f.pos, 0.0, {"startup": m.startup, "tell_anim": m.tell_anim, "kind": m.kind, "hidden": f.has("camo") or sim.fog})
	sim.fx.on_start(sim, f, o, m)

## A store move with props.release == "debt" turns what it absorbed into damage owed later.
static func release_store(f: Fighter, rules: Dictionary) -> void:
	if f.move != null and f.move.props.get("release", "") == "debt":
		f.debt += f.stored * float(rules["debt_factor"])
		f.stored = 0.0

static func end_move(sim: CombatSim, f: Fighter) -> void:
	release_store(f, sim.R)
	Res.move_over(f, sim.R)
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
	if int(f.T["marks_armor"]) > 0:
		f.take_mult = 1.0 - minf(float(R["mark_cap"]), float(f.marks) * float(R["mark_armor"]))
	if f.facing_lock > 0:
		f.facing_lock -= 1
	for k in f.st.keys():
		f.st[k] -= 1
		if f.st[k] <= 0:
			f.st.erase(k)
	if f.has("slowed"):
		f.slow_mult = float(f.T["slow_value"])
	if f.has("haste"):
		f.haste_mult = float(f.T["haste_value"])
	if f.raging:
		f.haste_mult *= float(f.T["rage_haste"])
	if f.has("owed"):
		f.slow_mult *= float(R["owed_speed"])
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
		var advance := true
		if f.has("inertia"):                  # Inertia Field: the victim's actions run in slow motion
			f.slow_acc += float(R["inertia_rate"])
			if f.slow_acc < 1.0:
				advance = false
			else:
				f.slow_acc -= 1.0
		if advance and f.move.charge_max > 0 and f.af + 1 == f.move.charge_at and f.hold_level and f.charge < f.move.charge_max:
			f.charge += 1                     # Gathering blow: keeps growing while the button is held
			advance = false
		if advance:
			f.af += 1
			if f.af >= f.move.total:
				end_move(sim, f)
	# --- decisions ---------------------------------------------------------
	_decide(sim, f, o)
	sim.res.tick(sim, f)
	sim.mind.tick(sim, f)
	_morrow(sim, f, o)
	# --- facing + movement -------------------------------------------------
	var look: Vector2 = f.compel["pos"] if f.compel.get("mode", "") == "decoy" else o.pos
	var to_o: Vector2 = look - f.pos
	var can_turn: bool = f.stun == 0 and f.facing_lock == 0 and (f.move == null or f.af < f.move.track) and f.action != "dodge"
	if can_turn and to_o.length_squared() > 0.0:
		f.facing = to_o.normalized()
	sim.fx.motion(sim, f, o)
	_walk(sim, f)
	if f.move == null and f.stun == 0 and f.action == "idle":
		f.idle_frames += 1
	else:
		f.idle_frames = 0

## "Morrow moves first": in Rage the mace sometimes strikes before it is commanded.
static func _morrow(sim: CombatSim, f: Fighter, o: Fighter) -> void:
	if not f.raging or f.move != null or not f.actionable() or not f.def.move_ids.has("auto_counter"):
		return
	if f.cooldowns.get("morrow_first", 0) > 0 or f.pos.distance_to(o.pos) > float(sim.R["morrow_range"]):
		return
	if sim.rng.randf() < float(sim.R["morrow_odds"]):
		f.cooldowns["morrow_first"] = int(sim.R["morrow_counter_cd"])
		start_move(sim, f, o, f.def.move(str(f.def.move_ids["auto_counter"])), "light")
		sim.emit("morrow_first", f.idx, f.move.id, f.pos, 0.0)

static func _regen(sim: CombatSim, f: Fighter) -> void:
	var R: Dictionary = sim.R
	if f.sta_delay > 0:
		f.sta_delay -= 1
	elif f.sta < f.max_sta and not (f.move != null and f.stun == 0):
		var rate: float = float(f.T["sta_regen"]) * sim.dt
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
		f.poise = minf(f.max_poise, f.poise + float(f.T["poise_regen"]) * sim.dt)
	if f.pressure > 0.0 and f.T["pressure_decay"] > 0.0:
		f.pressure = maxf(0.0, f.pressure - float(f.T["pressure_decay"]) * sim.dt)

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
	# Cancel windows: lights cancel into dodge / guard late in recovery (whiff) or right after the hit (hit-confirm)
	if f.move != null and f.move.kind == "light" and f.stun == 0:
		var open_from: int = f.move.total - int(R["cancel_window"])
		if f.contact:
			open_from = mini(open_from, f.move.startup + f.move.active + int(R["confirm_cancel_delay"]))
		if f.af >= open_from:
			if f.buf_kind == "dodge":
				var dm: MoveDef = move_for(f, "dodge")
				if can_start(sim, f, dm):
					start_move(sim, f, o, dm, "dodge")
					return
			elif f.guard_rise and f.guard_lag == 0:
				end_move(sim, f)
				f.action = "guard"
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
	var R: Dictionary = sim.R
	var target := Vector2.ZERO
	var mult := 0.0
	if f.alive and f.stun == 0 and not f.has("rooted"):
		if f.move == null:
			mult = 1.0
			if f.action == "guard":
				mult = float(f.T["guard_move_mult"])
		else:
			var m: MoveDef = f.move
			if m.move_mult > 0.0 and (f.af < m.startup or f.af >= m.startup + m.active):
				mult = m.move_mult
	if mult > 0.0:
		var dir: Vector2 = -f.move_in if f.has("confused") else f.move_in
		var dz: float = float(R["walk_deadzone"])
		if dir.length_squared() >= dz * dz:
			var sp: float = float(f.T["walk_speed"]) * mult * f.slow_mult * f.haste_mult
			if f.winded:
				sp *= float(R["winded_move_mult"])
			if dir.dot(f.facing) < float(R["retreat_dot"]):
				sp *= float(R["retreat_mult"])
			target = dir * sp
	# acceleration / deceleration curve
	var rate: float = float(R["walk_accel"]) if target != Vector2.ZERO else float(R["walk_decel"])
	f.wvel = f.wvel.move_toward(target, rate * sim.dt)
	f.moving = f.wvel.length() > float(R["moving_epsilon"])
	if f.wvel != Vector2.ZERO:
		f.pos = sim.arena.clamp_inside(f.pos + f.wvel * sim.dt, float(R["lip_margin"]))
