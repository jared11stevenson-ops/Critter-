extends RefCounted
## Ability effect vocabulary: motion (dash / leap / teleport), stance, projectile, zone / trap,
## phantom summon, on-hit statuses (root, slow, burn, drain), Pressure resource, hazards.
const Ent = preload("res://src/combat/entity.gd")
const Hits = preload("res://src/combat/sim_hits.gd")
const Actions = preload("res://src/combat/sim_actions.gd")
const Res = preload("res://src/combat/sim_res.gd")
const Mind = preload("res://src/combat/sim_mind.gd")
const Fighter = preload("res://src/combat/fighter.gd")

static func on_start(_sim: CombatSim, _f, _o, _m: MoveDef) -> void:
	pass

## Per-tick: motion segments, frame-triggered spawns and stance activation for f's current move.
static func motion(sim: CombatSim, f: Fighter, o: Fighter) -> void:
	var m: MoveDef = f.move
	if m == null or f.stun > 0 or not f.alive:
		return
	var af: int = f.af
	for seg in m.motion:
		var at := int(seg["at"])
		var ln := int(seg.get("len", 1))
		if af < at or af >= at + ln:
			continue
		var dist := float(seg.get("dist", 0.0))
		var kind := str(seg.get("dir", "fwd"))
		if seg.get("nocollide", false):
			f.add_status("ghost", int(sim.R["ghost_frames"]))
		if af == at:
			match kind:
				"random":
					var ang := deg_to_rad(sim.rng.randf_range(-float(sim.R["random_dodge_arc"]), float(sim.R["random_dodge_arc"])))
					f.mvec = (f.facing.rotated(ang) * (1.0 if sim.rng.randf() < 0.5 else -1.0)).normalized()
				"input":
					f.mvec = f.mvec if f.action == "dodge" else (f.move_in.normalized() if f.move_in.length() > float(sim.R["input_deadzone"]) else f.facing)
				"side":
					var perp := Vector2(-f.facing.y, f.facing.x)
					f.mvec = perp * (signf(f.move_in.dot(perp)) if absf(f.move_in.dot(perp)) > float(sim.R["side_deadzone"]) else 1.0)
				"to_target":
					var v: Vector2 = o.pos - f.pos
					var gap := float(seg.get("gap", 0.1))
					var travel := clampf(v.length() - f.radius - o.radius - gap, 0.0, dist)
					f.mvec = v.normalized() * travel / float(ln)
				"behind":
					var gp := float(seg.get("gap", 0.2))
					f.pos = sim.arena.clamp_inside(o.pos - o.facing * (f.radius + o.radius + gp), float(sim.R["lip_margin"]))
					f.facing = (o.pos - f.pos).normalized()
					sim.emit("teleport", f.idx, m.id, f.pos, 0.0)
		var step := Vector2.ZERO
		match kind:
			"fwd": step = f.facing * dist / float(ln)
			"back": step = -f.facing * dist / float(ln)
			"input", "side", "random": step = f.mvec * dist / float(ln)
			"to_target": step = f.mvec
		if f.has("rooted") and f.action != "dodge":
			step = Vector2.ZERO
		f.pos = sim.arena.clamp_inside(f.pos + step, float(sim.R["lip_margin"]))
	for sp in m.spawns:
		if int(sp["at"]) == af:
			_spawn(sim, f, o, m, sp)
	if not m.stance.is_empty() and int(m.stance.get("from", 0)) == af:
		f.add_status(str(m.stance["status"]), int(m.stance["frames"]))
		sim.emit("stance", f.idx, m.id, f.pos, 0.0, {"status": m.stance["status"]})

static func _hit_from_spec(spec: Dictionary) -> Dictionary:
	return MoveDef._merge({}, MoveDef._norm(spec), 0, 1)

static func _spawn(sim: CombatSim, f: Fighter, o: Fighter, m: MoveDef, sp: Dictionary) -> void:
	var t := str(sp["type"])
	match t:
		"projectile":
			var angles: Array = sp.get("angles", [0.0])
			for ai in angles.size():
				var e = Ent.new()
				e.kind = "proj"
				e.owner = f.idx
				e.move_id = m.id
				e.dir = f.facing.rotated(deg_to_rad(float(angles[ai])))
				e.pos = f.pos + f.facing * (f.radius + float(sp.get("start", 0.3)))
				e.speed = float(sp["speed"]) * sim.dt
				e.radius = float(sp.get("radius", 0.4))
				e.life = int(sp.get("life", 60))
				e.pierce = bool(sp.get("pierce", false))
				e.wait = int(sp.get("wait", 0)) + int(sp.get("wait_step", 0)) * ai
				e.turn_at = int(sp.get("return_after", 0))
				e.hit = _hit_from_spec(sp)
				sim.ents.append(e)
				sim.emit("projectile", f.idx, m.id, e.pos, 0.0, {"angle": angles[ai]})
		"zone":
			var e = Ent.new()
			e.kind = "zone"
			e.owner = f.idx
			e.move_id = m.id
			e.tag = str(sp.get("tag", m.id))
			var place := str(sp.get("place", "front"))
			match place:
				"self": e.pos = f.pos
				"target": e.pos = o.pos
				_: e.pos = f.pos + f.facing * float(sp.get("dist", 2.0)) + Vector2(-f.facing.y, f.facing.x) * float(sp.get("lateral", 0.0))
			e.radius = float(sp.get("radius", 1.2))
			e.life = int(sp.get("life", 300))
			e.dps = float(sp.get("dps", 0.0))
			e.once = bool(sp.get("once", false))
			e.affect = str(sp.get("affect", "enemy"))
			e.on_enter = sp.get("on_enter", {})
			e.buff = sp.get("buff", {})
			e.arm = int(sp.get("arm", 0))
			var mx := int(sp.get("max", 0))
			if mx > 0:
				var same: Array = []
				for x in sim.ents:
					if x.kind == "zone" and x.owner == f.idx and x.tag == e.tag:
						same.append(x)
				while same.size() >= mx:
					sim.ents.erase(same[0])
					same.remove_at(0)
			sim.ents.append(e)
			sim.emit("zone", f.idx, m.id, e.pos, 0.0, {"radius": e.radius, "tag": e.tag})
		"fungus":
			Res.grow_fungus(sim, f)
		"ripen_all":
			Res.ripen_all(sim, o, f)
			f.pressure = float(f.T["pressure_max"])
		"false_memory":
			Mind.start_decoy(sim, f, o, sp)
		"gust":
			var n := 0
			for pe in sim.ents:
				if pe.kind == "proj" and pe.owner != f.idx and pe.pos.distance_to(f.pos) <= float(sim.R["gust_reflect_range"]):
					pe.owner = f.idx                       # reflected
					pe.dir = f.facing
					pe.returning = false
					n += 1
			sim.emit("gust", f.idx, m.id, f.pos, 0.0, {"reflected": n})
		"shatter":
			sim.shatter(f.pos + f.facing * float(sp.get("dist", 3.0)), float(sp.get("radius", 2.0)))
		"phantom":
			var cnt := int(sp.get("count", 3))
			for i in cnt:
				var e = Ent.new()
				e.kind = "phantom"
				e.owner = f.idx
				e.move_id = m.id
				var ang := TAU * float(i) / float(cnt)
				e.pos = f.pos + Vector2(cos(ang), sin(ang)) * float(sp.get("spread", 1.0))
				e.speed = float(sp.get("speed", 3.0)) * sim.dt
				e.life = int(sp.get("life", 300))
				e.reach = float(sp.get("reach", 1.4))
				e.interval = int(sp.get("interval", 40))
				e.timer = int(sp.get("interval", 40)) * (i + 1) / cnt
				e.radius = float(sp.get("radius", 0.35))
				e.hit = _hit_from_spec(sp)
				sim.ents.append(e)
			sim.emit("summon", f.idx, m.id, f.pos, 0.0, {"count": cnt})

static func on_hit(sim: CombatSim, atk: Fighter, dfn: Fighter, h: Dictionary) -> void:
	var oh: Dictionary = h.get("on_hit", {})
	if oh.is_empty():
		return
	if oh.has("dot"):
		Res.add_dot(dfn, oh["dot"])
	if oh.get("ripen", false):
		Res.ferment(sim, dfn)
	if oh.get("ripen_all", false):
		Res.ripen_all(sim, dfn, atk)
	if oh.get("steal", false):
		Res.steal_buff(sim, atk, dfn)
	if oh.has("status"):
		for k in oh["status"].keys():
			dfn.add_status(str(k), int(oh["status"][k]))
	if oh.has("root"):
		dfn.add_status("rooted", int(oh["root"]))
	if oh.has("slow"):
		dfn.add_status("slowed", int(oh["slow"]))
	if oh.has("burn"):
		dfn.add_status("burning", int(oh["burn"]))
	if oh.has("drain_sta"):
		dfn.sta = maxf(0.0, dfn.sta - float(oh["drain_sta"]))
		dfn.sta_delay = int(sim.R["sta_regen_delay"])
	if oh.has("pull_to") and not h["grab"]:
		var gap: float = (dfn.pos - atk.pos).length() - atk.radius - dfn.radius
		var pull := maxf(0.0, gap - float(oh["pull_to"]))
		dfn.forced = (atk.pos - dfn.pos).normalized() * pull * (1.0 - float(sim.R["knock_decay"]))
	if oh.has("self_heal"):
		atk.vit = minf(atk.max_vit, atk.vit + float(oh["self_heal"]))

## Per-tick world update: statuses, hazards, entities.
static func tick_world(sim: CombatSim) -> void:
	var R: Dictionary = sim.R
	for f in sim.fighters:
		if not f.alive:
			continue
		if f.has("burning"):
			sim.damage(f, sim.fighters[1 - f.idx], float(R["burn_dps"]) * sim.dt, "burn")
		if f.debt > 0.0 and not f.has("delay_hold"):
			var pay: float = minf(f.debt, float(R["debt_rate"]) * sim.dt)
			f.debt -= pay
			sim.damage(f, null, pay, "borrowed_seconds")
		if f.has("wall"):
			f.sta = maxf(0.0, f.sta - float(R["wall_idle_drain"]) * sim.dt)
			f.sta_delay = int(R["sta_regen_delay"])
			if f.sta <= 0.0:
				f.st.erase("wall")
				f.winded = true
	var hz_list: Array = sim.arena.hazards if sim.hazards_on else []
	if sim.hazards_on and hz_list.is_empty():
		hz_list = [R["hazard_default"]]
	for hz in hz_list:
		var kind := str(hz.get("kind", "dps"))
		for f in sim.fighters:
			if not f.alive or not sim.arena.hazard_contains(hz, f.pos):
				continue
			match kind:
				"dps":
					sim.damage(f, null, float(hz["dps"]) * sim.dt, "hazard")
				"slow":
					f.add_status("slowed", 2)
				"pulse":
					var period := int(hz.get("period", 90))
					if sim.frame % period == 0 and not f.invulnerable():
						var c := Vector2(float(hz["pos"][0]), float(hz["pos"][1]))
						var away: Vector2 = (f.pos - c)
						away = away.normalized() if away.length_squared() > 0.001 else Vector2.RIGHT
						f.forced = away * float(hz.get("knock", 2.0)) * (1.0 - float(R["knock_decay"]))
						sim.damage(f, null, float(hz.get("damage", 0.0)), "hazard")
						sim.emit("hazard", f.idx, "", f.pos, float(hz.get("damage", 0.0)))
	_update_entities(sim)

static func _update_entities(sim: CombatSim) -> void:
	var i := 0
	while i < sim.ents.size():
		var e = sim.ents[i]
		var dead := false
		e.life -= 1
		if e.life <= 0:
			dead = true
		else:
			match e.kind:
				"proj": dead = _proj(sim, e)
				"zone": dead = _zone(sim, e)
				"phantom": dead = _phantom(sim, e)
		if dead:
			sim.ents.remove_at(i)
		else:
			i += 1

static func _proj(sim: CombatSim, e) -> bool:
	if e.wait > 0:
		e.wait -= 1
		return false
	e.age += 1
	var owner_f: Fighter = sim.fighters[e.owner]
	if e.turn_at > 0 and e.age == e.turn_at:
		e.returning = true
		e.timer = 0
		e.dodged = false
	if e.returning:
		var back: Vector2 = owner_f.pos - e.pos
		if back.length() <= e.radius + owner_f.radius + e.speed:
			return true
		e.dir = back.normalized()
	e.pos += e.dir * e.speed
	if sim.arena.depth(e.pos) > float(sim.R["projectile_margin"]):
		return true
	var owner: Fighter = sim.fighters[e.owner]
	var tgt: Fighter = sim.fighters[1 - e.owner]
	if e.cool > 0:
		e.cool -= 1
	elif e.pos.distance_to(tgt.pos) <= e.radius + tgt.radius:
		var r := Hits.apply_hit(sim, owner, tgt, e.hit, e.move_id, e.pos, e.dir, "ranged", true, e.timer == 1)
		if r == 2:
			e.timer = 1
		if r == 1 and e.turn_at > 0 and not e.returning:
			e.returning = true      # boomerang: a connecting throw recalls itself
			e.timer = 0
			e.cool = int(sim.R["boomerang_cooldown"])
		elif r == 1 and not e.pierce:
			return true
	return false

static func _zone(sim: CombatSim, e) -> bool:
	if e.tag == "fungus":
		return Res.fungus_step(sim, e)
	if e.arm > 0:
		e.arm -= 1
		return false
	var R: Dictionary = sim.R
	for f in sim.fighters:
		if not f.alive:
			continue
		var is_owner: bool = f.idx == e.owner
		if (e.affect == "enemy" and is_owner) or (e.affect == "self" and not is_owner):
			continue
		if f.pos.distance_to(e.pos) > e.radius + f.radius:
			continue
		if e.dps > 0.0 and not f.invulnerable():
			sim.damage(f, sim.fighters[e.owner], e.dps * sim.dt, e.move_id)
		var b: Dictionary = e.buff
		if b.has("slow") and not is_owner:
			f.add_status("slowed", 2)
		if b.has("haste") and is_owner:
			f.add_status("haste", 2)
		if b.has("inertia") and not is_owner:
			f.add_status("inertia", 2)
		if b.has("mark") and not is_owner:
			f.add_status("marked", int(b["mark"]))
		if b.has("archive") and is_owner:
			f.add_status("archive", 2)
		if b.has("confuse") and not is_owner:
			f.add_status("confused", 2)
		if b.has("regen_block") and not is_owner:
			f.add_status("regen_block", 2)
		if e.once and not f.invulnerable():
			var oe: Dictionary = e.on_enter
			if oe.has("damage"):
				sim.damage(f, sim.fighters[e.owner], float(oe["damage"]), e.move_id)
			if oe.has("root"):
				f.add_status("rooted", int(oe["root"]))
			if oe.has("slow"):
				f.add_status("slowed", int(oe["slow"]))
			if oe.has("poise"):
				f.poise -= float(oe["poise"])
				f.poise_delay = int(R["poise_regen_delay"])
			sim.emit("trap", f.idx, e.move_id, e.pos, float(oe.get("damage", 0.0)))
			return true
	return false

static func _phantom(sim: CombatSim, e) -> bool:
	var owner = sim.fighters[e.owner]
	var tgt = sim.fighters[1 - e.owner]
	var to: Vector2 = tgt.pos - e.pos
	var d := to.length()
	if d > e.reach * 0.8:
		e.pos += to.normalized() * minf(e.speed, d)
	e.timer -= 1
	if e.timer <= 0 and d <= e.reach + tgt.radius:
		e.timer = e.interval
		var dir: Vector2 = to.normalized() if d > 0.01 else Vector2.RIGHT
		Hits.apply_hit(sim, owner, tgt, e.hit, e.move_id, e.pos, dir, "ranged", true)
	return false
