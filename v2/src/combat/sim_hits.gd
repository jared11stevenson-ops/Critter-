extends RefCounted
## Hit detection and resolution: the Strike / Guard / Grab / Dodge triangle, parry, clash,
## armor, poise and stagger. Static helpers operating on a CombatSim.

const Fighter = preload("res://src/combat/fighter.gd")
const Actions = preload("res://src/combat/sim_actions.gd")
const Mind = preload("res://src/combat/sim_mind.gd")
const Res = preload("res://src/combat/sim_res.gd")

static func in_range(a: Fighter, d: Fighter, h: Dictionary) -> bool:
	var to: Vector2 = d.pos - a.pos
	var dist := to.length()
	if dist > a.radius + float(h["reach"]) + d.radius:
		return false
	if dist < float(h["offset"]) - d.radius:
		return false
	var eps: float = float(CombatData.rules()["contact_epsilon"])
	if float(h["arc"]) >= 359.0 or dist < eps:
		return true
	return a.facing.dot(to / dist) >= float(h["cos_half"]) or dist < a.radius + d.radius + eps

static func facing_ok(sim: CombatSim, d: Fighter, src: Vector2) -> bool:
	var to: Vector2 = src - d.pos
	if to.length_squared() <= 0.0:
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

static func _clash(sim: CombatSim, a: Fighter, b: Fighter) -> void:
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

static func _grab_clash(sim: CombatSim, a: Fighter, b: Fighter) -> void:
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
static func apply_hit(sim: CombatSim, atk: Fighter, dfn: Fighter, h: Dictionary, move_id: String, src: Vector2, kdir: Vector2, atk_kind: String, projectile: bool = false, quiet: bool = false) -> int:
	var R: Dictionary = sim.R
	if not dfn.alive or dfn.action == "ko":
		return 0
	if dfn.action == "knockdown":
		return 0
	var is_grab: bool = h["grab"]
	# Future Touched: every incoming attack is ghosted early and dodged automatically (and counters).
	if dfn.has("touched") and not is_grab and not h.get("ignore_iframes", false) and Mind.try_brain_skip(sim, dfn, atk, true):
		return 2
	if dfn.invulnerable() and not h.get("ignore_iframes", false):
		# dodging through a Premonition ghost triggers Brain Skip
		if dfn.action == "dodge" and dfn.has("premonition") and Mind.try_brain_skip(sim, dfn, atk, false):
			return 2
		if not quiet:
			sim.emit("dodge", dfn.idx, move_id, dfn.pos, 0.0, {"attacker": atk.idx})
		return 2
	var front := facing_ok(sim, dfn, src)
	# "Who gave you permission?": a strike entering the counter-stance's space is punished.
	if dfn.has("permission") and front and not is_grab and not projectile:
		_permission(sim, atk, dfn, move_id)
		return 1
	# Shield Wall: frontal invulnerability (command grabs bypass it).
	if dfn.has("wall") and front and not (is_grab and h["command"]):
		_wall_absorb(sim, atk, dfn, h, move_id)
		return 1
	if is_grab:
		_grab(sim, atk, dfn, h, move_id)
		return 1
	if dfn.action == "guard" and front and not h["unblockable"]:
		var age: int = sim.frame - dfn.guard_press_frame
		# Loophole (Zephyr): a freshly raised guard slips through a light strike
		if int(dfn.T["loophole_window"]) > 0 and dfn.stun == 0 and age <= int(dfn.T["loophole_window"]) and not h["guard_crush"] and atk_kind != "heavy" and not h["unblockable"]:
			if not quiet:
				sim.emit("dodge", dfn.idx, move_id, dfn.pos, 0.0, {"attacker": atk.idx, "loophole": true})
			return 2
		var window := int(dfn.T["parry_window"]) + (int(R["intel_window"] * dfn.intel) if float(dfn.T["intel_gain"]) > 0.0 else 0) + (int(R["borrowed_window"]) if dfn.has("borrowed") else 0)
		var eligible: bool = dfn.stun == 0 and sim.frame - dfn.guard_press_frame <= window and not h["unparryable"]
		if eligible:
			_parry(sim, atk, dfn, h, move_id, atk_kind, projectile)
		else:
			_block(sim, atk, dfn, h, move_id, kdir)
		return 1
	_hurt(sim, atk, dfn, h, move_id, kdir)
	return 1

static func _scaled_damage(sim: CombatSim, atk: Fighter, dfn: Fighter, h: Dictionary) -> float:
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
	if atk.has("camo"):
		dmg *= float(R["camo_crit_mult"])
		atk.st.erase("camo")
	if dfn.has("marked") and float(atk.T["marks_bonus"]) > 0.0:
		dmg *= float(R["marked_bonus"])
	if atk.move != null:
		var pr: Dictionary = atk.move.props
		if not atk.move.promise.is_empty():
			dmg *= float(atk.move.promise.get("bonus", R["promise_bonus"]))
		if pr.has("culture_scale"):
			dmg *= 1.0 + float(Res.dot_count(dfn, "culture")) * float(pr["culture_scale"])
		if pr.has("intel_scale"):
			dmg *= 1.0 + atk.intel * float(pr["intel_scale"])
		if atk.move.charge_max > 0:
			dmg *= 1.0 + float(atk.charge) / float(atk.move.charge_max) * float(pr.get("charge_gain", 1.0))
	if atk.has("spoiled"):
		dmg *= float(R["spoil_mult"])
		atk.st.erase("spoiled")
	if atk.move != null and atk.move.props.has("stored_mult"):
		var pool: float = atk.stored
		if atk.move.props.get("release_debt", false):
			pool += atk.debt
			atk.debt = 0.0
		dmg += pool * float(atk.move.props["stored_mult"])
		atk.stored = 0.0
	return dmg

static func _hurt(sim: CombatSim, atk: Fighter, dfn: Fighter, h: Dictionary, move_id: String, kdir: Vector2) -> void:
	var R: Dictionary = sim.R
	var counter: bool = dfn.move != null and dfn.stun == 0
	var dmg: float = _scaled_damage(sim, atk, dfn, h)
	if counter:
		dmg *= float(R["counter_hit_mult"])
	var armor: float = dfn.armor_now()
	if armor > 0.0:
		if dfn.move != null and dfn.move.props.has("store_ratio"):
			dfn.stored += dmg * armor * float(dfn.move.props["store_ratio"])
		dmg *= (1.0 - armor)
	sim.damage(dfn, atk, dmg, move_id)
	Mind.on_damaged(sim, dfn)
	if atk.move != null and not atk.move.promise.is_empty():
		atk.sta = minf(atk.max_sta, atk.sta + float(atk.move.promise.get("refund", R["promise_refund"])))
	var pd: float = float(h["poise"]) * atk.dmg_mult * (float(R["rot_poise_mult"]) if dfn.has("rotted") else 1.0)
	if armor >= 1.0:
		pd = 0.0
	elif armor > 0.0:
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

static func kdir_to(dfn: Fighter, atk: Fighter, kdir: Vector2) -> Vector2:
	var d: Vector2 = dfn.pos - atk.pos
	if d.length_squared() <= 0.0:
		return kdir
	var bl: float = float(CombatData.rules()["knock_dir_blend"])
	return (d.normalized() * (1.0 - bl) + kdir * bl).normalized()

static func atk_kind_is_melee(h: Dictionary) -> bool:
	return not h.get("ranged", false)

static func _permission(sim: CombatSim, atk: Fighter, dfn: Fighter, move_id: String) -> void:
	var R: Dictionary = sim.R
	_interrupt(atk)
	atk.action = "stagger"
	atk.stun_kind = "permission"
	atk.stun = int(R["permission_stun"])
	atk.add_status("rooted", int(R["permission_root"]))
	dfn.st.erase("permission")
	sim.damage(atk, dfn, float(R["permission_damage"]) * dfn.out_mult(), "permission")
	sim.hitstop = maxi(sim.hitstop, int(R["parry_hitstop"]))
	sim.emit("parry", dfn.idx, move_id, dfn.pos, 0.0, {"attacker": atk.idx, "permission": true, "hitstop": R["parry_hitstop"]})

static func _interrupt(f: Fighter) -> void:
	Actions.release_store(f, CombatData.rules())
	Res.move_over(f, CombatData.rules())
	f.move = null
	f.af = 0
	f.contact = false
	f.chain_idx = 0
	f.last_stand_active = false
	f.mvec = Vector2.ZERO
	f.buf_kind = ""

static func _gain_pressure(sim: CombatSim, atk: Fighter) -> void:
	if atk.move != null and atk.move.pressure_gain > 0.0:
		atk.pressure = minf(float(atk.T["pressure_max"]), atk.pressure + atk.move.pressure_gain)

static func _block(sim: CombatSim, atk: Fighter, dfn: Fighter, h: Dictionary, move_id: String, kdir: Vector2) -> void:
	var R: Dictionary = sim.R
	var dmg: float = float(h["damage"]) * atk.out_mult()
	var chip := float(dfn.T["block_chip"])
	if dfn.winded:
		chip = maxf(chip, float(R["winded_chip"]))
	if dfn.has("rotted"):
		chip += float(R["rot_chip"])
	var cd: float = dmg * chip
	var delayed: float = cd * float(dfn.T["guard_delay"])      # Hold: blocked force is delayed, not erased
	dfn.debt += delayed
	cd -= delayed
	sim.damage(dfn, atk, cd, move_id, true)
	var drain: float = float(h["damage"]) * atk.out_mult() * float(dfn.T["guard_drain"])
	var crush: bool = h["guard_crush"] or (atk.raging and atk_kind_is_melee(h))
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

static func _parry(sim: CombatSim, atk: Fighter, dfn: Fighter, h: Dictionary, move_id: String, atk_kind: String, projectile: bool = false) -> void:
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
			atk.poise = float(R["parry_min_poise"])
	_interrupt(dfn)
	dfn.action = "parry"
	dfn.stun_kind = "parry"
	dfn.stun = int(R["parry_action_frames"])
	dfn.iframes = maxi(dfn.iframes, int(R["parry_iframes"]))
	dfn.sta = minf(dfn.max_sta, dfn.sta + float(R["parry_sta_refund"]))
	if not projectile:
		dfn.add_status("riposte", int(R["riposte_frames"]))
	if float(dfn.T["intel_gain"]) > 0.0:
		dfn.intel = minf(1.0, dfn.intel + float(R["intel_per_parry"]))
	if int(dfn.T["parry_spoil"]) > 0 and not projectile:
		atk.add_status("spoiled", int(R["spoil_frames"]))
	var blast := float(dfn.T["parry_blast"])
	if blast > 0.0 and not projectile:
		sim.damage(atk, dfn, blast, "parry_blast")
	var hs := int(R["parry_hitstop"])
	sim.hitstop = maxi(sim.hitstop, hs)
	if dfn.def.move_ids.has("auto_counter") and not projectile:
		var cm: MoveDef = dfn.def.move(str(dfn.def.move_ids["auto_counter"]))     # Morrow moves first
		dfn.stun = 0
		dfn.stun_kind = ""
		Actions.start_move(sim, dfn, atk, cm, "light")
		sim.emit("morrow_first", dfn.idx, cm.id, dfn.pos, 0.0)
	sim.emit("parry", dfn.idx, move_id, dfn.pos, 0.0, {"attacker": atk.idx, "hitstop": hs})

static func _wall_absorb(sim: CombatSim, atk: Fighter, dfn: Fighter, h: Dictionary, move_id: String) -> void:
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

static func _grab(sim: CombatSim, atk: Fighter, dfn: Fighter, h: Dictionary, move_id: String) -> void:
	var R: Dictionary = sim.R
	var dmg: float = _scaled_damage(sim, atk, dfn, h)
	sim.damage(dfn, atk, dmg, move_id)
	Mind.on_damaged(sim, dfn)
	dfn.poise -= float(h["poise"])
	dfn.poise_delay = int(R["poise_regen_delay"])
	atk.contact = true
	_gain_pressure(sim, atk)
	_interrupt(dfn)
	var oh: Dictionary = h["on_hit"]
	if oh.has("compel"):
		Mind.apply_compel(sim, atk, dfn, oh["compel"])      # Puppet Thought: no throw, the target is compelled
		sim.emit("grab", dfn.idx, move_id, dfn.pos, dmg, {"attacker": atk.idx, "hitstop": int(h["hitstop"]), "compel": true})
		sim.hitstop = maxi(sim.hitstop, int(h["hitstop"]))
		return
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
