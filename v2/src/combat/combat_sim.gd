class_name CombatSim extends RefCounted
## Deterministic 60 Hz 1v1 duel simulation (pure logic, no Nodes). See SCHEMA.md and
## design/v2/INTERFACES.md. All gameplay numbers come from data (rules.json, critters, moves).
const FighterT = preload("res://src/combat/fighter.gd")
const Fighter = FighterT
const Actions = preload("res://src/combat/sim_actions.gd")
const Hits = preload("res://src/combat/sim_hits.gd")
const Fx = preload("res://src/combat/sim_effects.gd")
const Mind = preload("res://src/combat/sim_mind.gd")
const Res = preload("res://src/combat/sim_res.gd")

var R: Dictionary
var arena: ArenaDef
var stakes := 1
var rng := RandomNumberGenerator.new()
var fighters: Array = []
var ents: Array = []
var tick := 0              # real ticks (including hit-stop)
var frame := 0             # simulation frames (hit-stop frames excluded)
var hitstop := 0
var cracks: Array = []     # remaining cracked Thoughtstone (copied from the arena)
var dt := 1.0 / 60.0       # seconds per tick (rules.tick_rate)
var fx = Fx
var mind = Mind
var res = Res
var _events: Array[Dictionary] = []
var _over := false
var _result: Dictionary = {}
var _pending: Array = []   # fighter indices whose vitality reached 0 this tick
var _finisher := ""
var _dealt := [0.0, 0.0]

func _init(a: CritterDef, b: CritterDef, arena_def: ArenaDef, stakes_tier: int, seed_value: int) -> void:
	R = CombatData.rules()
	dt = 1.0 / float(R["tick_rate"])
	arena = arena_def
	cracks = arena_def.cracks.duplicate(true)
	stakes = stakes_tier
	rng.seed = seed_value
	var defs := [a, b]
	for i in 2:
		var f = FighterT.new()
		_setup_fighter(f, i, defs[i])
		fighters.append(f)
	var sp: Array = arena.spawns
	fighters[0].pos = sp[0]
	fighters[1].pos = sp[1]
	fighters[0].facing = (sp[1] - sp[0]).normalized()
	fighters[1].facing = -fighters[0].facing

func _setup_fighter(f: Fighter, i: int, d: CritterDef) -> void:
	f.idx = i
	f.def = d
	var defaults: Dictionary = R["tuning_defaults"]
	for k in defaults.keys():
		f.T[k] = d.tuning.get(k, defaults[k])
	for k in R["stat_formulas"].keys():
		f.T[k] = d.derived(k, R)
	f.radius = float(f.T["body_radius"])
	f.max_vit = float(f.T["max_vit"])
	f.vit = f.max_vit
	f.max_sta = float(f.T["max_sta"])
	f.sta = f.max_sta
	f.max_poise = float(f.T["max_poise"])
	f.poise = f.max_poise
	Res.setup(self, f)

## Mollusk's Shell Memory: each bout survived carves a mark (permanent small armor).
func set_shell_marks(idx: int, marks: int) -> void:
	fighters[idx].marks = marks

## Team bouts: a critter keeps the vitality it had (ratio 0..1).
func set_vitality_ratio(idx: int, ratio: float) -> void:
	fighters[idx].vit = maxf(1.0, fighters[idx].max_vit * clampf(ratio, 0.0, 1.0))

## "Shatters cracked Thoughtstone": removes arena cracks inside the radius.
func shatter(p: Vector2, radius: float) -> void:
	for c in cracks.duplicate():
		if p.distance_to(Vector2(float(c[0]), float(c[1]))) <= radius + float(c[2]):
			cracks.erase(c)
			emit("shatter", 0, "", Vector2(float(c[0]), float(c[1])), 0.0)

func emit(type: String, fighter: int, move_id: String, pos: Vector2, damage: float, extra: Dictionary = {}) -> void:
	var e := {"type": type, "fighter": fighter, "move_id": move_id, "pos": pos, "damage": damage, "tick": tick}
	for k in extra.keys():
		e[k] = extra[k]
	_events.append(e)

func take_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out

func is_over() -> bool:
	return _over

func result() -> Dictionary:
	return _result

func damage(target: Fighter, source: Fighter, amount: float, move_id: String, chip: bool = false) -> void:
	if amount <= 0.0 or not target.alive:
		return
	if source != null:
		_dealt[source.idx] += amount
	amount = Res.on_damage(self, target, source, amount)
	if amount <= 0.0:
		return
	if chip and R["chip_cannot_kill"]:
		amount = minf(amount, maxf(0.0, target.vit - 1.0))
	target.vit -= amount
	if target.vit <= 0.0:
		target.vit = 0.0
		if not _pending.has(target.idx):
			_pending.append(target.idx)
			_finisher = move_id

func step(input_a: CombatInput, input_b: CombatInput) -> void:
	if _over:
		return
	tick += 1
	var inps := [input_a, input_b]
	for i in 2:
		inps[i] = Mind.compel_input(self, fighters[i], inps[i])
	for i in 2:
		Actions.ingest(self, fighters[i], inps[i])
	for i in 2:
		if inps[i].yield_pressed:
			_finish(1 - i, "yield", false, i)
			return
	if hitstop > 0:
		hitstop -= 1
		return
	frame += 1
	var first := frame & 1
	for k in 2:
		var i := first ^ k
		Actions.tick_fighter(self, fighters[i], fighters[1 - i])
	_physics()
	Hits.resolve_tick(self)
	Fx.tick_world(self)
	_check_end()

func _physics() -> void:
	var lip := float(R["lip_margin"])
	var decay := float(R["knock_decay"])
	for f in fighters:
		if not f.alive:
			continue
		if f.forced != Vector2.ZERO:
			var np: Vector2 = f.pos + f.forced
			f.forced *= decay
			if f.forced.length() < float(R["forced_epsilon"]):
				f.forced = Vector2.ZERO
			if arena.depth(np) > 0.0:
				if arena.edge_type(np) == "drop":
					f.pos = np
					_ringout(f)
					continue
				f.forced = Vector2.ZERO
			f.pos = arena.clamp_inside(np, lip) if (arena.depth(np) > -lip and arena.edge_type(np) != "drop") else np
	var a = fighters[0]
	var b = fighters[1]
	if a.alive and b.alive and not a.has("ghost") and not b.has("ghost"):
		var d: Vector2 = b.pos - a.pos
		var dist := d.length()
		var minimum: float = a.radius + b.radius
		if dist < minimum:
			var n: Vector2 = d / dist if dist > 0.0001 else Vector2.RIGHT
			var push: float = (minimum - dist) * 0.5
			a.pos = arena.clamp_inside(a.pos - n * push, lip)
			b.pos = arena.clamp_inside(b.pos + n * push, lip)

func _ringout(f: Fighter) -> void:
	f.alive = false
	f.action = "ko"
	f.move = null
	emit("ringout", f.idx, "", f.pos, 0.0)
	_pending.append(-1 - f.idx)

func _check_end() -> void:
	if not _pending.is_empty():
		var dead: Array = []
		var ring := false
		for p in _pending:
			if p < 0:
				dead.append(-1 - p)
				ring = true
			else:
				dead.append(p)
		_pending.clear()
		if dead.size() >= 2 and dead[0] != dead[1]:
			_finish(-1, "ringout" if ring else "ko", false, -1)
			_result["double_ko"] = true
			return
		var loser: int = dead[0]
		fighters[loser].alive = false
		fighters[loser].action = "ko"
		fighters[loser].move = null
		if not ring:
			emit("ko", loser, _finisher, fighters[loser].pos, 0.0)
		_finish(1 - loser, "ringout" if ring else "ko", stakes >= 2, loser)
		return
	if frame >= int(R["timeout_ticks"]):
		var ra: float = fighters[0].ratio()
		var rb: float = fighters[1].ratio()
		var w := -1
		if absf(ra - rb) > 0.0001:
			w = 0 if ra > rb else 1
		_finish(w, "timeout", false, -1)

func _finish(winner: int, reason: String, killed: bool, loser: int) -> void:
	_over = true
	_result = {"winner": winner, "reason": reason, "killed": killed, "loser": loser, "ticks": tick,
		"vitality_ratio": [fighters[0].ratio(), fighters[1].ratio()], "damage_dealt": _dealt.duplicate(),
		"last_stand_used": [fighters[0].last_stand_used, fighters[1].last_stand_used], "finisher": _finisher, "injury": {}}
	if killed and loser >= 0:
		fighters[loser].action = "ko"
	if stakes == 1 and loser >= 0 and (reason == "ko" or reason == "ringout"):
		var kinds: Array = R["injury_kinds"]
		_result["injury"] = {"fighter": loser, "kind": kinds[rng.randi() % kinds.size()], "move_id": _finisher}
	emit("yield" if reason == "yield" else "end", maxi(loser, 0), _finisher, Vector2.ZERO, 0.0, {"reason": reason, "winner": winner, "killed": killed})

func state() -> Dictionary:
	var fs: Array = []
	for f in fighters:
		var act: String = f.action
		if act == "idle" and f.moving:
			act = "walk"
		var names: Array = f.st.keys()
		if f.winded:
			names.append("winded")
		if f.last_stand_active:
			names.append("last_stand")
		fs.append({"pos": f.pos, "facing": f.facing, "vitality": f.vit, "vitality_max": f.max_vit, "stamina": f.sta,
			"stamina_max": f.max_sta, "poise": f.poise, "poise_max": f.max_poise, "pressure": f.pressure, "rage": f.rage, "raging": f.raging, "plates": ceili(f.plate_pool / float(R["plate_size"])), "intel": f.intel, "reserve": f.reserve, "dots": f.dots.size(), "compelled": f.has("compelled"),
			"action": act, "action_frame": f.af, "move_id": f.move.id if f.move != null else "",
			"stun": f.stun, "tell_anim": f.move.tell_anim if f.move != null else "", "stored": f.stored, "debt": f.debt, "status": names, "cooldowns": f.cooldowns.duplicate(), "winded": f.winded,
			"can_last_stand": (not f.last_stand_used) and f.alive and f.ratio() < float(R["last_stand_ratio"]),
			"last_stand_used": f.last_stand_used, "alive": f.alive})
	var es: Array = []
	for e in ents:
		es.append({"kind": e.kind, "owner": e.owner, "pos": e.pos, "radius": e.radius, "life": e.life, "tag": e.tag})
	return {"tick": tick, "frame": frame, "hitstop": hitstop, "fighters": fs, "entities": es, "over": _over}

## Stable hash of the full simulation state (determinism tests).
func state_hash() -> int:
	var parts := PackedStringArray()
	parts.append("%d|%d|%d|%d" % [tick, frame, hitstop, rng.state])
	for f in fighters:
		parts.append("%d,%d,%d,%d,%d,%d,%d,%s,%d,%d,%d,%d" % [roundi(f.pos.x * 1000.0), roundi(f.pos.y * 1000.0),
			roundi(f.vit * 100.0), roundi(f.sta * 100.0), roundi(f.poise * 100.0), roundi(f.pressure * 100.0),
			roundi(f.facing.angle() * 1000.0), f.action, f.af, f.stun, f.st.size(), int(f.alive)])
	for e in ents:
		parts.append("%s%d,%d,%d" % [e.kind, roundi(e.pos.x * 1000.0), roundi(e.pos.y * 1000.0), e.life])
	return "|".join(parts).hash()
