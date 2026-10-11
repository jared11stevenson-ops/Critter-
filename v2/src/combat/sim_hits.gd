extends RefCounted
## Hit detection and resolution: the Strike / Guard / Grab / Dodge triangle, parry, clash,
## armor, poise and stagger. Static helpers operating on a CombatSim.

static func in_range(a, d, h: Dictionary) -> bool:
	var to: Vector2 = d.pos - a.pos
	var dist := to.length()
	if dist > a.radius + float(h["reach"]) + d.radius:
		return false
	if dist < float(h["offset"]) - d.radius:
		return false
	if float(h["arc"]) >= 359.0 or dist < 0.05:
		return true
	return a.facing.dot(to / dist) >= float(h["cos_half"]) or dist < a.radius + d.radius + 0.05

static func facing_ok(sim: CombatSim, d, src: Vector2) -> bool:
	var to: Vector2 = src - d.pos
	if to.length_squared() < 0.0001:
		return true
	return d.facing.dot(to.normalized()) >= float(sim.R["guard_cos_half"])

static func resolve_tick(sim: CombatSim) -> void:
	var att: Array = []
	for f in sim.fighters:
		if not f.alive or not f.is_attacking():
			continue
		var m: MoveDef = f.move
		var o = sim.fighters[1 - f.idx]
		for i in m.hits.size():
			if f.hits_done[i] == 1:
				continue
			var h: Dictionary = m.hits[i]
			if f.af < int(h["at"]) or f.af >= int(h["at"]) + int(h["len"]):
				continue
			if not in_range(f, o, h):
				continue
			att.append([f, i, h, m.id, m.kind])
			break
	if att.size() == 2:
		var fa = att[0][0]
		var fb = att[1][0]
		var ha: Dictionary = att[0][2]
		var hb: Dictionary = att[1][2]
		if ha["grab"] and hb["grab"]:
			fa.hits_done[att[0][1]] = 1
			fb.hits_done[att[1][1]] = 1
			_grab_clash(sim, fa, fb)
			return
		if ha["grab"] != hb["grab"]:
			# Strike beats Grab: only the strike lands.
			att = [att[1]] if ha["grab"] else [att[0]]
		elif not ha["no_clash"] and not hb["no_clash"] and fa.armor_now() <= 0.0 and fb.armor_now() <= 0.0 \
				and not fa.invulnerable() and not fb.invulnerable():
			fa.hits_done[att[0][1]] = 1
			fb.hits_done[att[1][1]] = 1
			_clash(sim, fa, fb)
			return
	for e in att:
		var f = e[0]
		var o = sim.fighters[1 - f.idx]
		var h: Dictionary = e[2]
		var r := apply_hit(sim, f, o, h, e[3], f.pos, f.facing, e[4], false, f.hits_done[e[1]] == 2)
		if r == 1:
			f.hits_done[e[1]] = 1
		elif r == 2 and f.hits_done[e[1]] == 0:
			f.hits_done[e[1]] = 2

static func _clash(sim: CombatSim, a, b) -> void:
	var R: Dictionary = sim.R
	var mid: Vector2 = (a.pos + b.pos) * 0.5
	var dir: Vector2 = (b.pos - a.pos).normalized()
	for f in [a, b]:
		var mv: MoveDef = f.move
		f.move = null
		f.af = 0
		f.action = "clash"
		f.stun_kind = "clash"
		f.stun = int(R["clash_frames"])
		f.poise = maxf(1.0, f.poise - float(R["clash_poise"]))
		f.poise_delay = int(R["poise_regen_delay"])
		f.contact = false
		f.chain_idx = 0
	a.forced = -dir * float(R["clash_push"]) * (1.0 - float(R["knock_decay"]))
	b.forced = dir * float(R["clash_push"]) * (1.0 - float(R["knock_decay"]))
	sim.hitstop = maxi(sim.hitstop, int(R["clash_hitstop"]))
	sim.emit("clash", a.idx, "", mid, 0.0, {"hitstop": R["clash_hitstop"], "other": b.idx})
	sim.emit("clash", b.idx, "", mid, 0.0, {"hitstop": R["clash_hitstop"], "other": a.idx})

static func _grab_clash(sim: CombatSim, a, b) -> void:
	var R: Dictionary = sim.R
	var dir: Vector2 = (b.pos - a.pos).normalized()
	for f in [a, b]:
		f.move = null
		f.action = "clash"
		f.stun_kind = "clash"
		f.stun = int(R["clash_frames"])
		f.af = 0
	a.forced = -dir * float(R["clash_push"]) * (1.0 - float(R["knock_decay"]))
	b.forced = dir * float(R["clash_push"]) * (1.0 - float(R["knock_decay"]))
	sim.hitstop = maxi(sim.hitstop, int(R["clash_hitstop"]))
	sim.emit("clash", a.idx, "", (a.pos + b.pos) * 0.5, 0.0, {"grab": true, "other": b.idx})

## Returns 1 = resolved (hit / block / parry / grab), 2 = target was invulnerable (dodged), 0 = ignored.
static func apply_hit(sim: CombatSim, atk, dfn, h: Dictionary, move_id: String, src: Vector2, kdir: Vector2, atk_kind: String, projectile: bool = false, quiet: bool = false) -> int:
	var R: Dictionary = sim.R
	if not dfn.alive or dfn.action == "ko":
		return 0
	if dfn.action == "knockdown":
		return 0
	if dfn.invulnerable():
		if not quiet:
			sim.emit("dodge", dfn.idx, move_id, dfn.pos, 0.0, {"attacker": atk.idx})
		return 2
	var front := facing_ok(sim, dfn, src)
	var is_grab: bool = h["grab"]
	# Shield Wall: frontal invulnerability (command grabs bypass it).
	if dfn.has("wall") and front and not (is_grab and h["command"]):
		_wall_absorb(sim, atk, dfn, h, move_id)
		return 1
	# Riposte Stance: any parryable strike is auto-parried.
	if dfn.has("stance_riposte") and front and not is_grab and not h["unparryable"] and not projectile:
		_parry(sim, atk, dfn, h, move_id, atk_kind, true)
		return 1
	if is_grab:
		_grab(sim, atk, dfn, h, move_id)
		return 1
	if dfn.action == "guard" and front and not h["unblockable"]:
		var window := int(dfn.T["parry_window"])
		var eligible: bool = dfn.stun == 0 and sim.frame - dfn.guard_press_frame <= window and not h["unparryable"]
		if eligible:
			_parry(sim, atk, dfn, h, move_id, atk_kind, false, projectile)
		else:
			_block(sim, atk, dfn, h, move_id, kdir)
		return 1
	_hurt(sim, atk, dfn, h, move_id, kdir)
	return 1

static func _scaled_damage(sim: CombatSim, atk, dfn, h: Dictionary) -> float:
	var R: Dictionary = sim.R
	var dmg: float = float(h["damage"]) * atk.out_mult() * dfn.take_mult
	if atk.burst > 0.0 and atk.move != null and atk.move.props.has("pressure_damage"):
		dmg += atk.burst * float(atk.move.props["pressure_damage"]) * atk.out_mult()
	if atk.has("empower"):
		dmg *= float(atk.T["empower_value"])
	if dfn.action == "stagger" and dfn.stun_kind != "parried":
		dmg *= float(R["stagger_dmg_mult"])
	if dfn.combo_hits > 0:
		dmg *= pow(float(R["combo_scale"]), dfn.combo_hits)
	return dmg

static func _hurt(sim: CombatSim, atk, dfn, h: Dictionary, move_id: String, kdir: Vector2) -> void:
	var R: Dictionary = sim.R
	var counter: bool = dfn.move != null and dfn.stun == 0
	var dmg: float = _scaled_damage(sim, atk, dfn, h)
	if counter:
		dmg *= float(R["counter_hit_mult"])
	var armor: float = dfn.armor_now()
	if armor > 0.0:
		dmg *= (1.0 - armor)
	sim.damage(dfn, atk, dmg, move_id)
	var pd: float = float(h["poise"]) * atk.dmg_mult
	if armor > 0.0:
		pd *= float(R["armor_poise_mult"])
	if h.get("pressure_gain", 0.0) > 0.0:
		pass
	dfn.poise -= pd
	dfn.poise_delay = int(R["poise_regen_delay"])
	atk.contact = true
	_gain_pressure(sim, atk)
	var hs := int(h["hitstop"])
	sim.hitstop = maxi(sim.hitstop, hs)
	dfn.combo_hits += 1
	dfn.combo_timer = int(R["combo_window"])
	var staggered: bool = dfn.poise <= 0.0 and dfn.action != "stagger"
	if armor > 0.0 and not staggered:
		pass
	else:
		_interrupt(dfn)
		if staggered:
			dfn.action = "stagger"
			dfn.stun_kind = "stagger"
			dfn.stun = int(R["stagger_frames"])
			sim.emit("stagger", dfn.idx, move_id, dfn.pos, 0.0)
		elif bool(h["knockdown"]):
			dfn.action = "knockdown"
			dfn.stun_kind = "knockdown"
			dfn.stun = int(h["kd_frames"]) if int(h["kd_frames"]) > 0 else int(R["knockdown_frames"])
		elif dfn.action == "stagger":
			pass
		else:
			dfn.action = "hit"
			dfn.stun_kind = "hit"
			dfn.stun = maxi(1, int(h["hitstun"]))
		var k := float(h["knock"])
		if k > 0.0:
			dfn.forced = kdir_to(dfn, atk, kdir) * k * (1.0 - float(R["knock_decay"]))
	sim.emit("hit", dfn.idx, move_id, dfn.pos, dmg, {"attacker": atk.idx, "counter": counter, "hitstop": hs, "armor": armor > 0.0})
	sim.fx.on_hit(sim, atk, dfn, h)

static func kdir_to(dfn, atk, kdir: Vector2) -> Vector2:
	var d: Vector2 = dfn.pos - atk.pos
	if d.length_squared() < 0.0001:
		return kdir
	return (d.normalized() * 0.5 + kdir * 0.5).normalized()

static func _interrupt(f) -> void:
	f.move = null
	f.af = 0
	f.contact = false
	f.chain_idx = 0
	f.last_stand_active = false
	f.mvec = Vector2.ZERO
	f.buf_kind = ""

static func _gain_pressure(sim: CombatSim, atk) -> void:
	if atk.move != null and atk.move.pressure_gain > 0.0:
		atk.pressure = minf(float(atk.T["pressure_max"]), atk.pressure + atk.move.pressure_gain)

static func _block(sim: CombatSim, atk, dfn, h: Dictionary, move_id: String, kdir: Vector2) -> void:
	var R: Dictionary = sim.R
	var dmg: float = float(h["damage"]) * atk.out_mult()
	var chip := float(dfn.T["block_chip"])
	if dfn.winded:
		chip = maxf(chip, float(R["winded_chip"]))
	var cd: float = dmg * chip
	sim.damage(dfn, atk, cd, move_id, true)
	var drain: float = float(h["damage"]) * atk.out_mult() * float(dfn.T["guard_drain"])
	var crush: bool = h["guard_crush"]
	if crush:
		drain *= float(R["crush_drain_mult"])
	dfn.sta = maxf(0.0, dfn.sta - drain)
	dfn.sta_delay = int(R["sta_regen_delay"])
	dfn.poise -= float(h["poise"]) * float(dfn.T["block_poise"])
	dfn.poise_delay = int(R["poise_regen_delay"])
	atk.contact = true
	_gain_pressure(sim, atk)
	var broke: bool = crush or dfn.sta <= 0.0 or dfn.poise <= 0.0
	if dfn.sta <= 0.0:
		dfn.winded = true
	var hs := int(R["block_hitstop"])
	sim.hitstop = maxi(sim.hitstop, hs)
	if broke:
		_interrupt(dfn)
		dfn.action = "stagger"
		dfn.stun_kind = "guardbreak"
		dfn.stun = maxi(8, int(float(R["guard_break_frames"]) * (1.0 - float(dfn.T["crush_resist"]))))
		if crush:
			sim.damage(dfn, atk, dmg * float(R["crush_dmg_mult"]), move_id)
		sim.emit("stagger", dfn.idx, move_id, dfn.pos, 0.0, {"guardbreak": true})
	else:
		dfn.stun = maxi(1, int(h["blockstun"]))
		dfn.stun_kind = "block"
		var k := float(h["knock"]) * float(R["block_push_mult"])
		if k > 0.0:
			dfn.forced = kdir_to(dfn, atk, kdir) * k * (1.0 - float(R["knock_decay"]))
	sim.emit("block", dfn.idx, move_id, dfn.pos, cd, {"attacker": atk.idx, "broke": broke, "hitstop": hs})
	if dfn.T["parry_blast"] > 0.0 and false:
		pass

static func _parry(sim: CombatSim, atk, dfn, h: Dictionary, move_id: String, atk_kind: String, auto: bool, projectile: bool = false) -> void:
	var R: Dictionary = sim.R
	if not projectile:
		_interrupt(atk)
		atk.action = "stagger"
		atk.stun_kind = "parried"
		var st := float(R["parry_attacker_stun"])
		if atk_kind == "heavy" or atk_kind == "ability" or atk_kind == "laststand":
			st *= float(R["parry_heavy_mult"])
		atk.stun = int(st)
		atk.poise -= float(R["parry_poise_dmg"])
		atk.poise_delay = int(R["poise_regen_delay"])
		if atk.poise <= 0.0:
			atk.poise = 1.0
	_interrupt(dfn)
	dfn.action = "parry"
	dfn.stun_kind = "parry"
	dfn.stun = int(R["parry_action_frames"])
	dfn.iframes = maxi(dfn.iframes, int(R["parry_iframes"]))
	dfn.sta = minf(dfn.max_sta, dfn.sta + float(R["parry_sta_refund"]))
	if not projectile:
		dfn.add_status("riposte", int(R["riposte_frames"]))
	var blast := float(dfn.T["parry_blast"])
	if blast > 0.0 and not projectile:
		sim.damage(atk, dfn, blast, "parry_blast")
	if auto:
		sim.fx.on_auto_parry(sim, dfn, atk)
	var hs := int(R["parry_hitstop"])
	sim.hitstop = maxi(sim.hitstop, hs)
	sim.emit("parry", dfn.idx, move_id, dfn.pos, 0.0, {"attacker": atk.idx, "hitstop": hs, "auto": auto})

static func _wall_absorb(sim: CombatSim, atk, dfn, h: Dictionary, move_id: String) -> void:
	var R: Dictionary = sim.R
	dfn.sta = maxf(0.0, dfn.sta - float(h["damage"]) * atk.out_mult() * float(R["wall_drain"]))
	dfn.sta_delay = int(R["sta_regen_delay"])
	atk.contact = true
	atk.poise -= float(R["wall_attacker_poise"])
	if dfn.sta <= 0.0:
		dfn.st.erase("wall")
		dfn.winded = true
	sim.hitstop = maxi(sim.hitstop, int(R["block_hitstop"]))
	sim.emit("block", dfn.idx, move_id, dfn.pos, 0.0, {"attacker": atk.idx, "wall": true, "hitstop": R["block_hitstop"]})

static func _grab(sim: CombatSim, atk, dfn, h: Dictionary, move_id: String) -> void:
	var R: Dictionary = sim.R
	var dmg: float = _scaled_damage(sim, atk, dfn, h)
	sim.damage(dfn, atk, dmg, move_id)
	dfn.poise -= float(h["poise"])
	dfn.poise_delay = int(R["poise_regen_delay"])
	atk.contact = true
	_gain_pressure(sim, atk)
	_interrupt(dfn)
	var oh: Dictionary = h["on_hit"]
	var dir: Vector2 = atk.facing
	var td := str(oh.get("throw_dir", "fwd"))
	if td == "back":
		dir = -atk.facing
	elif td == "side":
		dir = Vector2(-atk.facing.y, atk.facing.x)
	var kd := int(h["kd_frames"]) if int(h["kd_frames"]) > 0 else int(R["knockdown_frames"])
	if oh.has("pull_to"):
		var gap: float = (dfn.pos - atk.pos).length() - atk.radius - dfn.radius
		var pull := maxf(0.0, gap - float(oh["pull_to"]))
		dfn.forced = (atk.pos - dfn.pos).normalized() * pull * (1.0 - float(R["knock_decay"]))
		dfn.action = "hit"
		dfn.stun_kind = "thrown"
		dfn.stun = maxi(1, int(h["hitstun"]))
	else:
		dfn.action = "knockdown"
		dfn.stun_kind = "knockdown"
		dfn.stun = kd + int(h["throw_stun"])
		if float(h["throw_dist"]) > 0.0:
			dfn.forced = dir * float(h["throw_dist"]) * (1.0 - float(R["knock_decay"]))
	var hs := int(h["hitstop"])
	sim.hitstop = maxi(sim.hitstop, hs)
	sim.emit("grab", dfn.idx, move_id, dfn.pos, dmg, {"attacker": atk.idx, "hitstop": hs, "throw_dist": h["throw_dist"]})
	sim.fx.on_hit(sim, atk, dfn, h)
