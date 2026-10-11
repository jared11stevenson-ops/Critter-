extends RefCounted
## Mind effects (Cigarra): compel (Puppet Thought), decoy (False Memory), Premonition ghosts and Brain Skip.
const Fighter = preload("res://src/combat/fighter.gd")
const Ent = preload("res://src/combat/entity.gd")
const Actions = preload("res://src/combat/sim_actions.gd")

static func _interrupt(f: Fighter) -> void:
	f.move = null
	f.af = 0
	f.contact = false
	f.chain_idx = 0
	f.mvec = Vector2.ZERO
	f.buf_kind = ""

## Compel: the target is forced into one action for ~1.2 s. Poise (max) shortens it.
static func apply_compel(sim: CombatSim, atk: Fighter, dfn: Fighter, spec: Dictionary) -> void:
	var R: Dictionary = sim.R
	var resist: float = clampf(dfn.max_poise / float(R["compel_poise_ref"]), 0.0, float(R["compel_max_resist"]))
	var frames: int = maxi(8, int(float(spec.get("frames", R["compel_frames"])) * (1.0 - resist)))
	var mode := str(spec.get("mode", "auto"))
	if mode == "auto":
		var inside: float = -sim.arena.depth(dfn.pos)
		if inside < float(R["compel_edge_range"]) and sim.arena.edge_type(dfn.pos) == "drop":
			mode = "stumble"
		elif dfn.action == "guard" or dfn.want_guard:
			mode = "drop_guard"
		else:
			mode = "whiff" if sim.rng.randf() < 0.5 else "drop_guard"
	_interrupt(dfn)
	dfn.compel = {}
	dfn.add_status("compelled", frames)
	match mode:
		"stumble":
			var outward: Vector2 = dfn.pos.normalized() if dfn.pos.length_squared() > 0.0 else Vector2.RIGHT
			if sim.arena.shape == "rect":
				outward = Vector2(signf(dfn.pos.x), 0.0) if absf(dfn.pos.x) / sim.arena.half.x > absf(dfn.pos.y) / sim.arena.half.y else Vector2(0.0, signf(dfn.pos.y))
			dfn.action = "hit"
			dfn.stun_kind = "compelled"
			dfn.stun = frames
			dfn.compel = {"mode": "stumble", "left": frames, "dir": outward}
		"drop_guard":
			dfn.action = "stagger"
			dfn.stun_kind = "compelled"
			dfn.stun = int(float(frames) * float(R["compel_drop_ratio"]))
			dfn.compel = {"mode": "drop_guard", "left": dfn.stun}
		"whiff":
			var m: MoveDef = Actions.move_for(dfn, "light")
			Actions.start_move(sim, dfn, atk, m, "light")
			var sgn := 1.0 if sim.rng.randf() < 0.5 else -1.0
			dfn.facing = dfn.facing.rotated(deg_to_rad(float(R["compel_whiff_angle"])) * sgn)
			dfn.facing_lock = m.total
			dfn.compel = {"mode": "whiff", "left": m.total}
	sim.emit("compel", dfn.idx, "", dfn.pos, 0.0, {"mode": mode, "frames": frames, "attacker": atk.idx})

## False Memory: the target chases and strikes a decoy for a few seconds.
static func start_decoy(sim: CombatSim, caster: Fighter, target: Fighter, spec: Dictionary) -> void:
	var R: Dictionary = sim.R
	var resist: float = clampf(target.max_poise / float(R["compel_poise_ref"]), 0.0, float(R["compel_max_resist"]))
	var frames: int = maxi(12, int(float(spec.get("frames", 180)) * (1.0 - resist)))
	var away: Vector2 = (caster.pos - target.pos).normalized()
	var p: Vector2 = target.pos + away.rotated(deg_to_rad(float(spec.get("angle", 55.0)))) * float(R["decoy_offset"])
	p = sim.arena.clamp_inside(p, float(R["lip_margin"]))
	for e in sim.ents:
		if e.kind == "decoy" and e.owner == caster.idx:
			sim.ents.erase(e)
			break
	var e = Ent.new()
	e.kind = "decoy"
	e.owner = caster.idx
	e.pos = p
	e.life = frames
	e.radius = 0.5
	e.tag = "decoy"
	sim.ents.append(e)
	target.compel = {"mode": "decoy", "left": frames, "pos": p, "timer": int(R["decoy_strike_interval"]) / 2}
	target.add_status("compelled", frames)
	sim.emit("compel", target.idx, "", p, 0.0, {"mode": "decoy", "frames": frames, "attacker": caster.idx})

## Replaces a compelled fighter's inputs (decoy mode); other modes act through state.
static func compel_input(sim: CombatSim, f: Fighter, inp: CombatInput) -> CombatInput:
	if f.compel.is_empty() or f.compel.get("mode", "") != "decoy":
		return inp
	var out := CombatInput.new()
	out.yield_pressed = inp.yield_pressed
	var c: Dictionary = f.compel
	var to: Vector2 = c["pos"] - f.pos
	if to.length() > float(sim.R["decoy_reach"]):
		out.move = to.normalized()
	elif int(c["timer"]) <= 0:
		out.strike_tap = true
		c["timer"] = int(sim.R["decoy_strike_interval"])
	c["timer"] = int(c["timer"]) - 1
	return out

static func tick(sim: CombatSim, f: Fighter) -> void:
	if f.compel.is_empty():
		return
	var c: Dictionary = f.compel
	c["left"] = int(c["left"]) - 1
	if c["mode"] == "stumble":
		f.forced = (c["dir"] as Vector2) * float(sim.R["compel_stumble_speed"]) * sim.dt
	if int(c["left"]) <= 0:
		end_compel(sim, f)

static func end_compel(sim: CombatSim, f: Fighter) -> void:
	if f.compel.get("mode", "") == "decoy":
		for e in sim.ents:
			if e.kind == "decoy" and e.owner == 1 - f.idx:
				sim.ents.erase(e)
				break
	f.compel = {}
	f.st.erase("compelled")

## A hit on the target snaps the illusion.
static func on_damaged(sim: CombatSim, f: Fighter) -> void:
	if f.compel.get("mode", "") == "decoy":
		end_compel(sim, f)

# --- Premonition / Brain Skip -------------------------------------------------
static func spawn_ghost(sim: CombatSim, seer: Fighter, enemy: Fighter, m: MoveDef) -> void:
	if m.hits.is_empty():
		return
	var h: Dictionary = m.hits[0]
	var lead: int = maxi(int(sim.R["ghost_min_life"]), int(h["at"]) - enemy.af)
	var e = Ent.new()
	e.kind = "ghost"
	e.owner = seer.idx
	e.move_id = m.id
	e.tag = "ghost"
	e.pos = enemy.pos + enemy.facing * (float(h["reach"]) * 0.5 + enemy.radius)
	e.radius = float(h["reach"]) * 0.5
	e.life = lead + int(h["len"])
	sim.ents.append(e)
	sim.emit("ghost", seer.idx, m.id, e.pos, 0.0, {"lead": lead})

## Dodging through a ghost (or Future Touched's automatic dodge) counters: the enemy loses time and stumbles.
static func try_brain_skip(sim: CombatSim, seer: Fighter, enemy: Fighter, auto: bool) -> bool:
	var R: Dictionary = sim.R
	if not auto:
		if seer.cooldowns.get("brain_skip", 0) > 0:
			return false
		if seer.pressure >= float(R["noise_threshold"]) and sim.rng.randf() < float(R["noise_fail"]):
			return false
		seer.cooldowns["brain_skip"] = int(R["brain_skip_cd"])
	_interrupt(enemy)
	enemy.action = "stagger"
	enemy.stun_kind = "skipped"
	enemy.stun = int(R["brain_skip_stun"])
	enemy.poise = maxf(1.0, enemy.poise - float(R["brain_skip_poise"]))
	seer.add_status("riposte", int(R["brain_skip_riposte"]))
	sim.hitstop = maxi(sim.hitstop, int(R["parry_hitstop"]))
	sim.emit("brain_skip", seer.idx, "", seer.pos, 0.0, {"enemy": enemy.idx, "auto": auto})
	return true
