extends RefCounted
## Per-critter resources and long-running effects: Rage / Strain / plates (Aruun), damage-over-time stacks
## and Cultures (Bramvex bleed, Scarlith, Nyxaris venom), silk reserve, Intel, Promise, Borrowed Seconds, Cultivate.
const Fighter = preload("res://src/combat/fighter.gd")
const Ent = preload("res://src/combat/entity.gd")

static func setup(_sim: CombatSim, f: Fighter) -> void:
	f.plate_pool = float(f.T["plate_pool"])
	f.reserve = float(f.T["reserve_max"])
	f.plates_seen = ceili(f.plate_pool / maxf(1.0, float(CombatData.rules()["plate_size"])))

# --- Rage ---------------------------------------------------------------------
static func toggle_rage(sim: CombatSim, f: Fighter) -> void:
	if f.raging:
		f.raging = false
		sim.emit("rage_end", f.idx, "", f.pos, 0.0)
	elif f.rage >= float(sim.R["rage_enter"]) and f.alive:
		f.raging = true
		sim.emit("rage", f.idx, "", f.pos, 0.0)

## Called from CombatSim.damage(): feeds Rage, Brew (Waste Not) and consumes plates. Returns the damage left for Vitality.
static func on_damage(sim: CombatSim, target: Fighter, source: Fighter, amount: float) -> float:
	var R: Dictionary = sim.R
	if source != null and float(source.T["rage_max"]) > 0.0:
		source.rage = minf(float(source.T["rage_max"]), source.rage + amount * float(R["rage_per_dealt"]))
	if float(target.T["rage_max"]) > 0.0:
		target.rage = minf(float(target.T["rage_max"]), target.rage + amount * float(R["rage_per_taken"]))
	if float(target.T["waste_not"]) > 0.0:
		target.pressure = minf(float(target.T["pressure_max"]), target.pressure + amount * float(target.T["waste_not"]))
	if target.plate_pool > 0.0:
		var absorbed: float = minf(amount, target.plate_pool)
		target.plate_pool -= absorbed
		amount -= absorbed
		var left: int = ceili(target.plate_pool / float(R["plate_size"]))
		if left < target.plates_seen:
			target.plates_seen = left
			sim.emit("plate", target.idx, "", target.pos, absorbed, {"plates_left": left})
	return amount

# --- DOT stacks and Cultures ---------------------------------------------------
static func add_dot(target: Fighter, spec: Dictionary) -> void:
	var name := str(spec.get("name", "dot"))
	var mx := int(spec.get("max", 1))
	var same: Array = []
	for d in target.dots:
		if d["name"] == name:
			same.append(d)
	var entry := {"name": name, "age": 0, "life": int(spec.get("life", CombatData.rules()["dot_default_life"])), "dps": float(spec.get("dps", 0.0)),
		"grow": float(spec.get("grow", 0.0)), "burst": float(spec.get("burst", 0.0)), "ripe": int(spec.get("ripe", 0))}
	if same.size() >= mx:
		target.dots.erase(same[0])
	target.dots.append(entry)

static func dot_count(f: Fighter, name: String) -> int:
	var n := 0
	for d in f.dots:
		if d["name"] == name:
			n += 1
	return n

static func tick_dots(sim: CombatSim, f: Fighter) -> void:
	var i := 0
	while i < f.dots.size():
		var d: Dictionary = f.dots[i]
		d["age"] = int(d["age"]) + 1
		var dps: float = float(d["dps"]) + float(d["grow"]) * float(d["age"]) * sim.dt
		sim.damage(f, sim.fighters[1 - f.idx], dps * sim.dt, str(d["name"]))
		var remove := false
		if int(d["ripe"]) > 0 and int(d["age"]) >= int(d["ripe"]):
			sim.damage(f, sim.fighters[1 - f.idx], float(d["burst"]), str(d["name"]) + "_ripe")
			sim.emit("ripe", f.idx, str(d["name"]), f.pos, float(d["burst"]))
			remove = true
		if int(d["age"]) >= int(d["life"]):
			remove = true
		if remove:
			f.dots.remove_at(i)
		else:
			i += 1

## Ferment: stacks ripen sooner and grow faster.
static func ferment(sim: CombatSim, target: Fighter) -> void:
	for d in target.dots:
		if d["name"] == "culture":
			d["ripe"] = int(d["age"]) + int(sim.R["ripen_frames"])
			d["grow"] = float(d["grow"]) * 2.0

## Aged to Perfection: every Culture ripens right now.
static func ripen_all(sim: CombatSim, target: Fighter, source: Fighter) -> void:
	var n := 0
	for d in target.dots.duplicate():
		if d["name"] == "culture":
			sim.damage(target, source, float(d["burst"]) * float(sim.R["ripen_burst_mult"]), "culture_ripe")
			target.dots.erase(d)
			n += 1
	sim.emit("ripe", target.idx, "culture", target.pos, 0.0, {"stacks": n})

static func steal_buff(sim: CombatSim, thief: Fighter, victim: Fighter) -> void:
	for name in sim.R["buff_list"]:
		if victim.has(name):
			thief.add_status(name, int(victim.st[name]))
			victim.st.erase(name)
			victim.add_status("slowed", 90)
			sim.emit("steal", thief.idx, name, victim.pos, 0.0)
			return

## Day 20: clears every debuff, DOT and compulsion.
static func cleanse(sim: CombatSim, f: Fighter) -> void:
	for k in sim.R["cleanse_statuses"]:
		f.st.erase(k)
	f.dots.clear()
	if not f.compel.is_empty():
		sim.mind.end_compel(sim, f)
	sim.emit("cleanse", f.idx, "", f.pos, 0.0)

# --- ticking ---------------------------------------------------------------------
static func tick(sim: CombatSim, f: Fighter) -> void:
	var R: Dictionary = sim.R
	if f.raging:
		f.rage -= float(R["rage_drain"]) * sim.dt
		f.vit = maxf(1.0, f.vit - f.max_vit * float(R["rage_strain"]) * sim.dt)   # Strain: never below 1 Vitality
		if f.rage <= 0.0:
			f.rage = 0.0
			toggle_rage(sim, f)
	if float(f.T["reserve_max"]) > 0.0 and f.reserve < float(f.T["reserve_max"]):
		f.reserve = minf(float(f.T["reserve_max"]), f.reserve + float(R["reserve_regen"]) * sim.dt)
	var b: bool = f.has("borrowed")
	if f.borrow_prev and not b:
		f.add_status("owed", int(R["owed_frames"]))
	f.borrow_prev = b
	if not f.dots.is_empty():
		tick_dots(sim, f)
	if int(f.T["cultivate_interval"]) > 0:
		f.fungus_timer += 1
		if f.fungus_timer >= int(f.T["cultivate_interval"]):
			f.fungus_timer = 0
			grow_fungus(sim, f)

static func grow_fungus(sim: CombatSim, f: Fighter) -> void:
	var n := 0
	for e in sim.ents:
		if e.tag == "fungus" and e.owner == f.idx:
			n += 1
	if n >= int(sim.R["fungus_max"]):
		return
	var e = Ent.new()
	e.kind = "zone"
	e.tag = "fungus"
	e.owner = f.idx
	e.pos = sim.arena.clamp_inside(f.pos - f.facing * 1.4 + Vector2(-f.facing.y, f.facing.x) * (1.0 if sim.rng.randf() < 0.5 else -1.0), float(sim.R["lip_margin"]))
	e.radius = float(sim.R["fungus_radius"])
	e.life = int(sim.R["fungus_life"])
	sim.ents.append(e)
	sim.emit("zone", f.idx, "fungus", e.pos, 0.0, {"radius": e.radius, "tag": "fungus"})

## Fungus patch: feeds and heals its owner, withers when the enemy tramples it.
static func fungus_step(sim: CombatSim, e) -> bool:
	var owner: Fighter = sim.fighters[e.owner]
	var foe: Fighter = sim.fighters[1 - e.owner]
	if foe.alive and foe.pos.distance_to(e.pos) <= e.radius + foe.radius:
		sim.emit("trample", foe.idx, "fungus", e.pos, 0.0)
		return true
	if owner.alive and owner.pos.distance_to(e.pos) <= e.radius + owner.radius:
		owner.vit = minf(owner.max_vit, owner.vit + float(sim.R["cultivate_heal"]) * sim.dt)
		owner.pressure = minf(float(owner.T["pressure_max"]), owner.pressure + float(sim.R["cultivate_brew"]) * sim.dt)
	return false

# --- Promise -------------------------------------------------------------------------
## Called when a move ends or is broken. A declared Promise that never connected costs stamina.
static func move_over(f: Fighter, rules: Dictionary) -> void:
	if f.move != null and not f.move.promise.is_empty() and not f.contact:
		f.sta = maxf(0.0, f.sta - float(f.move.promise.get("penalty", rules["promise_penalty"])))
		f.sta_delay = int(rules["sta_regen_delay"])
