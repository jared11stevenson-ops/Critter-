class_name CombatAI extends RefCounted
## AI opponent. Reads the sim like a player would: it sees the opponent's tells after a reaction delay,
## learns their habits, mixes up attacks, baits and feints. Skill profiles: novice / standard / expert.
## Usage: var ai := CombatAI.new(1, "standard", seed); input_b = ai.decide(sim)
const Habits = preload("res://src/combat/ai/ai_habits.gd")
const PROFILES_PATH := "res://src/combat/ai/profiles.json"
static var _profiles: Dictionary = {}

var idx := 1
var profile_name := "standard"
var P: Dictionary = {}
var rng := RandomNumberGenerator.new()
var habits = Habits.new()
var allow_yield := true
var hist: Array = []              # delayed view of the opponent
var sched: Array = []             # [[frame, key], ...] timed presses
var guard_from := -1
var guard_to := -1
var think_cd := 0
var strafe := 1.0
var strafe_cd := 0
var my_last := "idle"
var my_last_frame := -999
var last_opp_sig := ""
var handled_sig := ""
var chain_done := ""
var feint_done := ""
var hold_guard_until := -1
var _last_guard := false
var _danger_cache := -1.0

static func profile_names() -> Array:
	return ["novice", "standard", "expert"]

static func load_profiles() -> Dictionary:
	if _profiles.is_empty():
		_profiles = CombatData.read_json(PROFILES_PATH)
	return _profiles

func _init(my_index: int, profile: String, seed_value: int, allow_yielding: bool = true) -> void:
	idx = my_index
	profile_name = profile
	P = load_profiles()[profile]
	rng.seed = seed_value
	allow_yield = allow_yielding
	strafe = 1.0 if rng.randf() < 0.5 else -1.0

# ---------------------------------------------------------------- helpers
func _hit0(m: MoveDef) -> Dictionary:
	return m.hits[0] if m != null and m.hits.size() > 0 else {"reach": 1.0, "at": 0, "len": 1, "grab": false}

func _reach(me, kind: String) -> float:
	var m: MoveDef = _move_of(me, kind)
	if m == null or m.hits.is_empty():
		return 0.0
	return float(m.hits[0]["reach"]) + me.radius

func _move_of(me, kind: String) -> MoveDef:
	var ids: Dictionary = me.def.move_ids
	match kind:
		"light": return me.def.move(ids["light"][0])
		"heavy": return me.def.move(ids["heavy"])
		"grab": return me.def.move(ids["grab"])
		"a1": return me.def.move(ids["ability1"])
		"a2": return me.def.move(ids["ability2"])
		"ls": return me.def.move(ids["laststand"])
	return null

func _kind_of(m: MoveDef) -> String:
	if m == null:
		return "wait"
	if m.kind == "light":
		return "light"
	if m.kind == "heavy":
		return "heavy"
	if m.kind == "grab":
		return "grab"
	if m.kind == "dodge":
		return "dodge"
	return "ability"

func _band(gap: float) -> String:
	return "close" if gap < 1.0 else ("mid" if gap < 2.6 else "far")

func _ready_for(me, kind: String) -> bool:
	var m := _move_of(me, kind)
	if m == null or me.cooldowns.get(m.id, 0) > 0:
		return false
	if m.stamina_cost > 0.0 and me.sta < m.stamina_cost:
		return false
	if me.winded and (m.kind == "heavy" or m.kind == "ability"):
		return false
	if (m.pressure_cost != 0.0 or m.require_pressure > 0.0) and me.pressure < maxf(maxf(m.pressure_cost, 0.0), m.require_pressure):
		return false
	return true

func _press(inp: CombatInput, key: String, away: Vector2 = Vector2.ZERO) -> void:
	match key:
		"light": inp.strike_tap = true
		"heavy": inp.strike_hold = true
		"grab": inp.grab = true
		"dodge":
			inp.dodge = true
			if away != Vector2.ZERO:
				inp.move = away
		"a1": inp.ability1 = true
		"a2": inp.ability2 = true
		"ls":
			inp.ability1 = true
			inp.ability2 = true

# ---------------------------------------------------------------- main
func decide(sim: CombatSim) -> CombatInput:
	var inp := CombatInput.new()
	var me = sim.fighters[idx]
	var op = sim.fighters[1 - idx]
	if sim.is_over() or not me.alive:
		return inp
	if sim.hitstop > 0:
		inp.guard = _last_guard
		return inp
	var ft: int = sim.frame + 1
	_observe(sim, me, op)
	var gap: float = me.pos.distance_to(op.pos) - me.radius - op.radius
	# --- yield / last stand ----------------------------------------------
	if allow_yield and P["yield_ratio"] > 0.0 and me.ratio() < P["yield_ratio"] and op.ratio() > 0.3 \
			and (me.last_stand_used or not me.def.move_ids.has("laststand")) and rng.randf() < 0.05:
		inp.yield_pressed = true
		return inp
	if (not me.last_stand_used) and me.ratio() < sim.R["last_stand_ratio"] and me.alive:
		var lsm := _move_of(me, "ls")
		var lsr := _reach(me, "ls") + (0.3 if lsm.hits.size() > 0 else 0.0)
		if (gap + me.radius <= lsr or me.ratio() < 0.12) and rng.randf() < float(P["last_stand"]) * 0.35:
			_press(inp, "ls")
			sched.clear()
			guard_from = -1
			return _finish(inp, me)
	# --- scheduled presses --------------------------------------------------
	var pending_press := false
	for i in range(sched.size() - 1, -1, -1):
		if sched[i][0] <= ft:
			if me.actionable() or me.stun > 0 or me.move != null:
				_press(inp, sched[i][1], sched[i][2] if sched[i].size() > 2 else Vector2.ZERO)
			sched.remove_at(i)
			pending_press = true
	var want_guard := ft >= guard_from and ft <= guard_to
	if me.stun > 0 and me.action != "guard":
		sched.clear()
		guard_from = -1
	# --- react to threats ------------------------------------------------------
	_react(sim, me, op, inp, ft, gap)
	want_guard = want_guard or (ft >= guard_from and ft <= guard_to) or ft <= hold_guard_until
	if want_guard and me.guard_lag > 0 and not me.want_guard:
		want_guard = false
	# --- offense / movement -------------------------------------------------
	if not pending_press and not inp.dodge and not inp.strike_tap and not inp.strike_hold:
		if me.stun == 0:
			_neutral(sim, me, op, inp, ft, gap, want_guard)
	inp.guard = want_guard or inp.guard
	return _finish(inp, me)

func _finish(inp: CombatInput, _me) -> CombatInput:
	_last_guard = inp.guard
	return inp

# ---------------------------------------------------------------- perception
func _observe(sim: CombatSim, me, op) -> void:
	hist.append({"a": op.action, "mid": op.move.id if op.move != null else "", "af": op.af, "stun": op.stun, "pos": op.pos})
	if hist.size() > 40:
		hist.pop_front()
	# habit learning: record the first committed action of each new opponent move
	var sig: String = (op.move.id + ":" + str(sim.frame - op.af)) if op.move != null else ""
	if sig != "" and sig != last_opp_sig:
		var gap: float = me.pos.distance_to(op.pos) - me.radius - op.radius
		var ctx := _band(gap) + ":" + (my_last if sim.frame - my_last_frame < 60 else "idle")
		habits.record(ctx, _kind_of(op.move))
	if sig != "":
		last_opp_sig = sig
	elif op.action == "guard" and not op.move:
		pass

func _seen() -> Dictionary:
	var k := clampi(hist.size() - 1 - int(P["reaction"]), 0, hist.size() - 1)
	return hist[k]

func _habit_ctx(gap: float) -> String:
	return _band(gap) + ":" + my_last

# ---------------------------------------------------------------- reactions
func _react(sim: CombatSim, me, op, inp: CombatInput, ft: int, gap: float) -> void:
	var ob := _seen()
	var react: int = int(P["reaction"])
	if ob["mid"] == "" or me.stun > 0 or not alive_ok(me):
		return
	var m: MoveDef = op.def.move(ob["mid"])
	if m == null or m.hits.is_empty():
		return
	var sig: String = ob["mid"] + ":" + str(sim.frame - op.af)
	if sig == handled_sig:
		return
	handled_sig = sig
	var h: Dictionary = _first_threat(m)
	if h.is_empty():
		return
	var est_af: int = int(ob["af"]) + react + 1
	var rem: int = int(h["at"]) - est_af
	if rem < -1 and not (m.kind == "ability" and m.hits.size() > 1):
		return
	rem = maxi(rem, 0)
	# threatened? use the geometry we can see now
	var reach_to_me: float = float(h["reach"]) + op.radius + me.radius + 0.35
	var dist: float = me.pos.distance_to(op.pos)
	if dist > reach_to_me and not (m.motion.size() > 0):
		return
	if rng.randf() > float(P["react_prob"]):
		return
	var impact: int = ft + rem
	var is_grab: bool = h["grab"]
	var heavy: bool = m.kind == "heavy" or m.kind == "ability" or m.kind == "laststand"
	var w := {"parry": 0.0, "block": 0.0, "dodge": 0.0, "interrupt": 0.0, "ability": 0.0}
	if is_grab:
		w["dodge"] = float(P["dodge_prob"]) * 1.4
		w["interrupt"] = float(P["interrupt_prob"]) * 1.5
		w["block"] = 0.05
	elif heavy:
		w["dodge"] = float(P["dodge_prob"]) * 1.2
		w["parry"] = float(P["parry_prob"]) * 0.8
		w["block"] = float(P["block_prob"]) * 0.4
		w["interrupt"] = float(P["interrupt_prob"]) * 0.3
	else:
		w["parry"] = float(P["parry_prob"])
		w["block"] = float(P["block_prob"])
		w["dodge"] = float(P["dodge_prob"]) * 0.3
		w["interrupt"] = float(P["interrupt_prob"]) * (1.0 if rem > 12 else 0.2)
	if me.winded:
		w["dodge"] = 0.0
		w["parry"] *= 0.5
	if me.sta < 12.0:
		w["dodge"] = 0.0
	# defensive ability hint (stances)
	for slot in ["a1", "a2"]:
		var hint: Dictionary = me.def.ai_hints.get("ability1" if slot == "a1" else "ability2", {})
		if hint.get("when", "") == "defensive" and _ready_for(me, slot):
			var am := _move_of(me, slot)
			var lead := int(am.stance.get("from", am.startup)) + 3 if not am.stance.is_empty() else am.startup
			if rem >= lead - 2:
				w["ability"] = float(P["ability"]) * 0.9
	# habit-informed anticipation raises parry/dodge for experts
	var pick := _weighted(w)
	if pick == "":
		return
	match pick:
		"parry":
			var win: int = int(me.T["parry_window"])
			var k: int = clampi(int(win * 0.5) + rng.randi_range(-int(P["parry_jitter"]), int(P["parry_jitter"])), -2, win + 4)
			if me.action == "guard" or me.guard_lag > 0:
				guard_from = ft
				guard_to = impact + 8
			else:
				var press_at: int = impact - k
				if press_at <= ft:
					guard_from = ft
				else:
					guard_from = press_at
				guard_to = impact + 10
		"block":
			guard_from = ft
			guard_to = impact + 10
		"dodge":
			var s: int = impact - 2 + rng.randi_range(-int(P["parry_jitter"]) / 2, int(P["parry_jitter"]) / 2)
			var side := Vector2(-(op.pos - me.pos).y, (op.pos - me.pos).x).normalized() * strafe
			sched.append([maxi(s, ft), "dodge", side])
		"interrupt":
			var mine := _move_of(me, "light")
			if mine != null and mine.startup + 1 < rem and gap_ok(me, op, "light"):
				sched.append([ft, "light"])
		"ability":
			for slot in ["a1", "a2"]:
				var hint2: Dictionary = me.def.ai_hints.get("ability1" if slot == "a1" else "ability2", {})
				if hint2.get("when", "") == "defensive" and _ready_for(me, slot):
					var am2 := _move_of(me, slot)
					var lead2 := int(am2.stance.get("from", am2.startup)) + 3 if not am2.stance.is_empty() else am2.startup
					sched.append([maxi(impact - lead2, ft), slot])
					break

func alive_ok(me) -> bool:
	return me.alive

func _first_threat(m: MoveDef) -> Dictionary:
	for h in m.hits:
		return h
	return {}

func gap_ok(me, op, kind: String) -> bool:
	var r := _reach(me, kind)
	return me.pos.distance_to(op.pos) <= r + op.radius + 0.05

func _weighted(w: Dictionary) -> String:
	var tot := 0.0
	for k in w.keys():
		tot += w[k]
	if tot <= 0.0001:
		return ""
	# probability of acting at all scales with the strongest option (so weak profiles often do nothing)
	var best := 0.0
	for k in w.keys():
		best = maxf(best, w[k])
	if rng.randf() > minf(1.0, best * 1.4 + tot * 0.25):
		return ""
	var r := rng.randf() * tot
	for k in w.keys():
		r -= w[k]
		if r <= 0.0:
			return k
	return ""

# ---------------------------------------------------------------- neutral / offense
func _neutral(sim: CombatSim, me, op, inp: CombatInput, ft: int, gap: float, guarding: bool) -> void:
	var dist: float = me.pos.distance_to(op.pos)
	var to: Vector2 = (op.pos - me.pos).normalized()
	var perp := Vector2(-to.y, to.x)
	# chain / feint management while in a move
	if me.move != null:
		_manage_move(sim, me, op, inp, ft, gap)
		return
	if me.action != "idle" and me.action != "guard":
		return
	if strafe_cd <= 0:
		strafe = 1.0 if rng.randf() < 0.5 else -1.0
		strafe_cd = rng.randi_range(30, 90)
	strafe_cd -= 1
	if think_cd > 0:
		think_cd -= 1
	var my_l: float = _cd(me, op, "light")
	var threat: float = maxf(_cd(op, me, "light"), maxf(_cd(op, me, "heavy"), _cd(op, me, "grab")))
	var rmin: float
	var rmax: float
	if my_l >= threat + 0.3:
		rmin = threat + 0.2          # outrange: hold just outside their reach
		rmax = my_l - 0.15
	else:
		rmin = maxf(me.radius + op.radius + 0.2, my_l - 0.8)
		rmax = my_l - 0.1
	var ob := _seen()
	# --- movement
	var dir := Vector2.ZERO
	var low_sta: bool = me.sta < me.max_sta * 0.2 and rng.randf() < float(P["stamina_care"])
	if low_sta or me.winded:
		dir = -to * 0.8 + perp * strafe * 0.3
	elif dist > rmax:
		dir = to + perp * strafe * 0.35
	elif dist < rmin:
		dir = -to * 0.6 + perp * strafe * 0.5
	else:
		dir = perp * strafe * 0.6
	# stay off drop edges, more so against opponents who can throw or knock us far
	var arena: ArenaDef = sim.arena
	var inside: float = -arena.depth(me.pos)
	var danger: float = _edge_danger(op) + float(P["edge_margin"])
	if inside < danger and arena.edge_type(me.pos) == "drop":
		var inward: Vector2 = -me.pos.normalized()
		var w: float = clampf(1.0 - inside / danger, 0.0, 1.0)
		if dir.dot(inward) < 0.0:
			dir -= inward * dir.dot(inward)
		dir += inward * (0.4 + 1.6 * w)
	if guarding:
		dir *= 0.5
	inp.move = dir.limit_length(1.0)
	# --- decisions
	if think_cd > 0 or guarding:
		return
	think_cd = rng.randi_range(int(P["think_min"]), int(P["think_max"]))
	if rng.randf() > float(P["aggression"]) + (0.25 if ob["a"] in ["stagger", "knockdown", "hit"] else 0.0):
		if rng.randf() < 0.25:
			guard_from = ft
			guard_to = ft + rng.randi_range(8, 24)
		return
	var opts := {}
	var vulnerable := _opp_vulnerable(op)
	var punish: bool = vulnerable > 0 and rng.randf() < float(P["punish"])
	var in_l := gap_ok(me, op, "light")
	var in_h := gap_ok(me, op, "heavy")
	var in_g := gap_ok(me, op, "grab")
	var opp_guarding: bool = ob["a"] == "guard"
	if in_l and _ready_for(me, "light"):
		opts["light"] = 1.0
	if in_h and _ready_for(me, "heavy") and me.sta > me.max_sta * 0.3:
		opts["heavy"] = 0.45 + (1.2 if punish and vulnerable >= _move_of(me, "heavy").startup else 0.0)
	if in_g and _ready_for(me, "grab"):
		opts["grab"] = 0.5 + (1.0 if opp_guarding else 0.0)
	if punish and opts.has("light") and vulnerable < 24:
		opts["light"] = 2.0
	# abilities
	for slot in ["a1", "a2"]:
		var hint: Dictionary = me.def.ai_hints.get("ability1" if slot == "a1" else "ability2", {})
		if hint.is_empty() or str(hint.get("when", "")) == "defensive" or not _ready_for(me, slot):
			continue
		var d: float = dist
		if d < float(hint["min"]) or d > float(hint["max"]):
			continue
		var wt := float(P["ability"]) * 0.8
		if hint["when"] == "pressure" and me.pressure < 45.0:
			continue
		if hint["when"] == "gap" and vulnerable > 0:
			wt *= 1.5
		opts[slot] = wt
	if opts.is_empty():
		if rng.randf() < 0.3 * float(P["feint"]) and _ready_for(me, "heavy") and gap > _reach(me, "heavy") - 0.3:
			opts["heavy"] = 1.0
		else:
			return
	# habit counters
	var conf: float = habits.confidence(_habit_ctx(gap))
	if float(P["habit"]) > 0.0 and conf > 0.0:
		var cw := Habits.counter_weights(habits.predict(_habit_ctx(gap)))
		for k in opts.keys():
			var key: String = k
			if cw.has(key):
				opts[key] = float(opts[key]) * (1.0 + float(P["habit"]) * conf * 3.0 * float(cw[key]))
	var choice := ""
	if rng.randf() < float(P["noise"]):
		choice = opts.keys()[rng.randi() % opts.size()]
	else:
		var tot := 0.0
		for k in opts.keys():
			tot += opts[k]
		var r := rng.randf() * tot
		for k in opts.keys():
			r -= opts[k]
			if r <= 0.0:
				choice = k
				break
	if choice == "":
		return
	_press(inp, choice)
	my_last = {"light": "light", "heavy": "heavy", "grab": "grab", "a1": "ability", "a2": "ability"}.get(choice, "light")
	my_last_frame = sim.frame
	chain_done = ""
	feint_done = ""

## How far from a drop edge we want to stay: the longest throw / knockback the opponent has.
func _edge_danger(op) -> float:
	if _danger_cache >= 0.0:
		return _danger_cache
	var d := 0.0
	for mid in op.def.moves.keys():
		var m: MoveDef = op.def.moves[mid]
		for h in m.hits:
			d = maxf(d, maxf(float(h["throw_dist"]), float(h["knock"])))
		for seg in m.motion:
			if str(seg.get("dir", "")) == "fwd":
				d = maxf(d, float(seg.get("dist", 0.0)) * 0.5)
	_danger_cache = d
	return d

## Center distance at which `a`'s `kind` move reaches `b`.
func _cd(a, b, kind: String) -> float:
	return _reach(a, kind) + b.radius

func _opp_vulnerable(op) -> int:
	if op.stun > 0 and op.action in ["stagger", "hit"]:
		return op.stun
	if op.move != null and op.stun == 0 and op.af >= op.move.startup + op.move.active:
		return op.move.total - op.af
	return 0

func _manage_move(sim: CombatSim, me, op, inp: CombatInput, ft: int, gap: float) -> void:
	var m: MoveDef = me.move
	var sig: String = m.id + ":" + str(sim.frame - me.af)
	var ob := _seen()
	# chain lights while it keeps connecting
	if m.cancel_from >= 0 and me.af >= m.cancel_from and (me.contact or m.chain_on == "always") and chain_done != sig:
		chain_done = sig
		if m.chain != "" and rng.randf() < float(P["chain"]) and gap_ok(me, op, "light") and me.sta > 6.0:
			inp.strike_tap = true
		elif m.kind == "light" and me.contact and rng.randf() < 0.3 and _ready_for(me, "heavy"):
			pass
	# feint a heavy windup based on what the opponent shows
	if m.feint and me.af < m.startup - 3 and me.af >= int(m.startup * 0.4) and feint_done != sig:
		if rng.randf() < float(P["feint"]):
			if ob["a"] == "guard" and _ready_for(me, "grab"):
				feint_done = sig
				inp.grab = true
			elif ob["a"] == "dodge" or (ob["mid"] != "" and gap > _reach(me, "heavy")):
				feint_done = sig
				guard_from = ft
				guard_to = ft + 14
	inp.move = Vector2.ZERO
