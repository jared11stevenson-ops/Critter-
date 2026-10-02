class_name PartyController
extends Node
## Owns the two partners. The player drives the leader; the partner is AI-driven
## (follows 3–5 m, engages what the leader engages, uses basics + occasional abilities,
## steps out of telegraphs, revives). Handles swap, revive, wipe → respawn, containment.

signal leader_changed(member)
signal contain_target_changed(target)

var members: Array = []
var leader_i := 0
var swap_cd := 0.0
var input_enabled := true
var ai_enabled := true           # level can take over the partner (scripted beats)
var locked_leader := ""          # e.g. "aruun" during the Burden moment
var contain_target: Node = null
var contain_channel := 0.0
var _contain_victim: Node = null
var _trail: Array = []
var _ai_attack_t := 0.0
var _ai_ability_t := 0.0
var _ai_stuck_t := 0.0
var _ai_last_pos := Vector3.ZERO
var _wipe_pending := false
var _q: Array = []
var _scan_ready := true
var scanner: Node = null

func spawn(at_leader: Vector3, at_partner: Vector3, parent: Node) -> void:
	var a := PlayableCritter.new()
	a.setup("aruun")
	var c := PlayableCritter.new()
	c.setup("cigarra")
	parent.add_child(a)
	parent.add_child(c)
	a.global_position = at_leader
	c.global_position = at_partner
	members = [a, c]
	for m in members:
		m.downed_changed.connect(_on_downed_changed)
	var want := str(GameState.get_flag("_leader", "aruun"))
	leader_i = 1 if want == "cigarra" else 0
	if leader_i == 1:
		a.global_position = at_partner
		c.global_position = at_leader
	_apply_leader(true)

func get_leader() -> PlayableCritter:
	return members[leader_i] if members.size() > leader_i else null

func get_partner() -> PlayableCritter:
	return members[1 - leader_i] if members.size() == 2 else null

func get_member(id: String) -> PlayableCritter:
	for m in members:
		if m.char_id == id:
			return m
	return null

func _apply_leader(snap: bool = false) -> void:
	for i in members.size():
		members[i].controlled = (i == leader_i)
	var l := get_leader()
	if Field.current and Field.current.camera_rig:
		Field.current.camera_rig.set_target(l, snap)
	GameState.flags["_leader"] = l.char_id
	leader_changed.emit(l)
	Events.party_member_changed.emit(l.char_id)
	_trail.clear()

# ---------------- swap ----------------
func can_swap() -> bool:
	var p := get_partner()
	return swap_cd <= 0.0 and p != null and not p.downed and locked_leader == "" and get_leader().state == "normal" and p.state != "leap"

func swap(force: bool = false) -> void:
	if not force and not can_swap():
		if locked_leader != "":
			Events.toast.emit("%s must hold this" % Canon.display_name(locked_leader), "warning")
		return
	var old := get_leader()
	old.in_move = Vector3.ZERO
	old.in_aim = Vector3.ZERO
	leader_i = 1 - leader_i
	swap_cd = Balance.f("global.swap_cooldown", 1.0)
	_apply_leader()
	var l := get_leader()
	Audio.sfx("ui_confirm", -4.0)
	if Field.current:
		Field.current.vfx("psychic_burst" if l.char_id == "cigarra" else "dust_puff", l.global_position + Vector3(0, 1.0, 0))
		Field.current.float_text(l.global_position + Vector3(0, l.height + 0.6, 0), l.display_name.to_upper(), UiKit.char_color(l.char_id).lightened(0.3), 46)
		Field.current.shake(0.08)
	l.vis("play_attack", "cast")
	l.invuln_t = maxf(l.invuln_t, 0.3)

func swap_to(id: String) -> void:
	if get_leader().char_id != id:
		swap(true)

# ---------------- main loop ----------------
func _process(delta: float) -> void:
	if members.size() < 2:
		return
	swap_cd = maxf(0.0, swap_cd - delta)
	var l := get_leader()
	if locked_leader != "" and l.char_id != locked_leader:
		swap_to(locked_leader)
		l = get_leader()
	_player_input(l)
	_record_trail(l)
	_ai(get_partner(), delta)
	_revive_tick(delta)
	_update_contain_target(l)
	_contain_tick(delta)

func _player_input(l: PlayableCritter) -> void:
	if not input_enabled or Router.is_busy():
		l.in_move = Vector3.ZERO
		l.in_aim = Vector3.ZERO
		return
	var v := TouchInput.move
	if v.length() < 0.08:
		v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var mv := Vector3(v.x, 0, v.y)
	l.in_move = mv
	l.in_aim = mv if mv.length() > 0.3 else Vector3.ZERO
	if l.downed:
		return
	if Input.is_action_pressed("attack"):
		l.request_attack()
	if Input.is_action_just_pressed("ability_1"):
		l.request_ability(0)
	if Input.is_action_just_pressed("ability_2"):
		l.request_ability(1)
	if Input.is_action_just_pressed("ability_3"):
		l.request_ability(2)
	if Input.is_action_just_pressed("dash"):
		l.request_dash()
	if Input.is_action_just_pressed("swap"):
		swap()
	if Input.is_action_just_pressed("capture"):
		try_contain()
	if Input.is_action_just_pressed("scan") and scanner:
		scanner.scan(l)

func _record_trail(l: PlayableCritter) -> void:
	if l.state == "leap":
		_trail.clear()
		return
	if not l.is_on_floor() or l.state != "normal":
		return
	var p := l.global_position
	if _trail.is_empty() or (_trail[_trail.size() - 1] as Vector3).distance_to(p) > 1.2:
		_trail.append(p)
		if _trail.size() > 80:
			_trail.pop_front()

# ---------------- partner AI ----------------
func _ai(p: PlayableCritter, delta: float) -> void:
	if p == null:
		return
	if not ai_enabled:
		return
	p.in_move = Vector3.ZERO
	p.in_aim = Vector3.ZERO
	if p.downed or p.state != "normal":
		return
	var l := get_leader()
	var f := Field.current
	if f == null:
		return
	_ai_attack_t -= delta
	_ai_ability_t -= delta
	var pos := p.global_position
	var to_leader := l.global_position - pos
	to_leader.y = 0
	var dl := to_leader.length()
	# 1) revive downed leader (should rarely happen — leader auto-swaps) — handled by proximity
	# 2) step out of hostile telegraphs
	var danger := _danger_escape(pos)
	if danger != Vector3.ZERO:
		p.in_move = danger
		if p.dash_cd <= 0.0 and randf() < 0.05:
			p.request_dash()
		return
	# 3) catch-up teleport
	if dl > Balance.f("ai_partner.teleport_dist", 28.0) and f.level and f.level.has_method("can_partner_reach"):
		if f.level.can_partner_reach(pos, l.global_position):
			var tp := _trail_point_behind(4)
			if tp != Vector3.INF:
				p.teleport(tp + Vector3(0, 0.3, 0))
				return
	# 4) engage
	var engage_r := Balance.f("ai_partner.engage_radius", 12.0)
	var target: Node = null
	if dl < engage_r + 6.0:
		target = f.nearest_enemy(l.global_position, engage_r, true)
		if target and not target.hostile_now():
			target = null
	if target:
		var to_t: Vector3 = target.global_position - pos
		to_t.y = 0
		var dt: float = to_t.length() - target.body_radius
		var want := 1.6 if p.char_id == "aruun" else 7.5
		var dir := to_t.normalized() if to_t.length() > 0.01 else p.facing
		if dt > want + 0.8:
			p.in_move = _steer(p, dir)
		elif p.char_id == "cigarra" and dt < want - 3.0:
			p.in_move = -dir * 0.8
		else:
			p.face_toward(dir)
		p.in_aim = dir
		if dt < want + 1.5 and _ai_attack_t <= 0.0:
			_ai_attack_t = Balance.f("ai_partner.attack_interval", 0.7) * randf_range(0.8, 1.2)
			p.face_toward(dir)
			p.request_attack()
		if _ai_ability_t <= 0.0:
			_ai_ability_t = 1.0
			if randf() < Balance.f("ai_partner.ability_chance_per_s", 0.16) and p.kit:
				f.enemies_in_radius(target.global_position, 6.0, _q)
				var slot: int = p.kit.ai_choose(target, _q.size())
				if slot >= 0:
					p.face_toward(dir)
					p.request_ability(slot)
		return
	# 5) follow
	var fmin := Balance.f("ai_partner.follow_min", 3.0)
	var fmax := Balance.f("ai_partner.follow_max", 5.0)
	if dl > fmax or (dl > fmin and l.velocity.length() > 0.5):
		var goal := l.global_position
		var direct: bool = dl < 9.0 and (f.level == null or not f.level.has_method("path_clear") or f.level.path_clear(pos, goal))
		if not direct:
			goal = _trail_next(pos)
		var d := goal - pos
		d.y = 0
		if d.length() > 0.3:
			var spd := clampf((dl - fmin) / 3.0, 0.4, 1.0)
			p.in_move = _steer(p, d.normalized()) * spd
	# stuck detection → small teleport along trail
	if p.in_move.length() > 0.3:
		if pos.distance_to(_ai_last_pos) < 0.05:
			_ai_stuck_t += delta
			if _ai_stuck_t > 2.5:
				_ai_stuck_t = 0.0
				var tp2 := _trail_point_behind(3)
				if tp2 != Vector3.INF and (f.level == null or not f.level.has_method("can_partner_reach") or f.level.can_partner_reach(pos, tp2)):
					p.teleport(tp2 + Vector3(0, 0.3, 0))
		else:
			_ai_stuck_t = 0.0
	_ai_last_pos = pos

func input_enabled_ai() -> bool:
	return ai_enabled

func _steer(p: PlayableCritter, dir: Vector3) -> Vector3:
	# avoid walking off ledges into chasms
	var f := Field.current
	if f and f.level and f.level.has_method("is_hazard"):
		var ahead := p.global_position + dir * 1.6
		if f.level.is_hazard(ahead.x, ahead.z):
			var left := Vector3(-dir.z, 0, dir.x)
			for alt in [dir.rotated(Vector3.UP, 0.7), dir.rotated(Vector3.UP, -0.7), left, -left]:
				var a2: Vector3 = p.global_position + (alt as Vector3) * 1.6
				if not f.level.is_hazard(a2.x, a2.z):
					return alt
			return Vector3.ZERO
	return dir

func _danger_escape(pos: Vector3) -> Vector3:
	var f := Field.current
	for t in f.dangers:
		if not is_instance_valid(t):
			continue
		var push: Vector3 = t.escape_vector(pos)
		if push != Vector3.ZERO:
			return push
	return Vector3.ZERO

func _trail_next(pos: Vector3) -> Vector3:
	if _trail.is_empty():
		return get_leader().global_position
	var best := 0
	var bd := INF
	for i in _trail.size():
		var d := (_trail[i] as Vector3).distance_squared_to(pos)
		if d < bd:
			bd = d
			best = i
	var idx := mini(best + 1, _trail.size() - 1)
	if (_trail[best] as Vector3).distance_to(pos) > 2.0:
		idx = best
	return _trail[idx]

func _trail_point_behind(n: int) -> Vector3:
	if _trail.size() == 0:
		return Vector3.INF
	return _trail[maxi(0, _trail.size() - 1 - n)]

func clear_trail() -> void:
	_trail.clear()

# ---------------- downed / revive / wipe ----------------
func _on_downed_changed(m: PlayableCritter, is_down: bool) -> void:
	if not is_down:
		return
	var other: PlayableCritter = members[1 - members.find(m)]
	if other.downed:
		_wipe()
		return
	if m == get_leader() and locked_leader == "":
		leader_i = members.find(other)
		_apply_leader()
		Events.toast.emit("%s is down! Stand beside %s to revive." % [m.display_name, "him" if m.char_id == "aruun" else "her"], "warning")
	elif m == get_leader():
		# locked (Burden): the hold fails gracefully — level decides
		Events.toast.emit("%s is down!" % m.display_name, "warning")

func _revive_tick(delta: float) -> void:
	var r := Balance.f("global.revive_radius", 2.4)
	for m in members:
		if not m.downed:
			continue
		var other: PlayableCritter = members[1 - members.find(m)]
		if other.downed:
			continue
		var near := other.global_position.distance_to(m.global_position) < r
		if not near and other != get_leader():
			# AI partner walks over to revive
			var d: Vector3 = m.global_position - other.global_position
			d.y = 0
			other.in_move = d.normalized()
		if near:
			m.revive_progress += delta
			if m.revive_progress >= Balance.f("global.revive_time", 2.0):
				m.revive(Balance.f("global.revive_hp_frac", 0.35))
				Events.toast.emit("%s is back up" % m.display_name, "info")
		else:
			m.revive_progress = maxf(0.0, m.revive_progress - delta * 0.5)

func _wipe() -> void:
	if _wipe_pending:
		return
	_wipe_pending = true
	var f := Field.current
	if f and f.level and f.level.has_method("on_party_wiped"):
		await f.level.on_party_wiped()
	_wipe_pending = false

func respawn_at(p_leader: Vector3, p_partner: Vector3, hp_frac: float) -> void:
	var l := get_leader()
	var pa := get_partner()
	for m in members:
		m.hp = m.max_hp * hp_frac
		if m.downed:
			m.set_downed(false)
		m.hp = m.max_hp * hp_frac
		m.hp_changed.emit(m.hp, m.max_hp)
	l.teleport(p_leader)
	pa.teleport(p_partner)
	_trail.clear()
	if Field.current and Field.current.camera_rig:
		Field.current.camera_rig.set_target(l, true)

func any_downed() -> bool:
	for m in members:
		if m.downed:
			return true
	return false

# ---------------- containment ----------------
func _update_contain_target(l: PlayableCritter) -> void:
	var f := Field.current
	var best: Node = null
	if f and contain_channel <= 0.0 and not l.downed:
		var bd := Balance.f("global.contain_range", 7.0)
		for e in f.enemies:
			if not is_instance_valid(e) or not e.is_targetable() or not e.wild:
				continue
			# Passive keystone wildlife may enter protective containment unharmed (Bible §52).
			if not e.passive and e.hp > e.max_hp * Balance.f("global.contain_hp_frac", 0.3):
				continue
			var d: float = e.global_position.distance_to(l.global_position)
			if d < bd:
				bd = d
				best = e
	if best != contain_target:
		if contain_target and is_instance_valid(contain_target):
			contain_target.vis("set_highlight", Color(0.4, 0.9, 1.0), false)
		contain_target = best
		if best:
			best.vis("set_highlight", Color(0.4, 0.9, 1.0), true)
		contain_target_changed.emit(best)

func try_contain() -> void:
	var l := get_leader()
	if contain_channel > 0.0 or l.downed or l.state != "normal":
		return
	if contain_target == null:
		var f := Field.current
		if f:
			var near: Node = f.nearest_enemy(l.global_position, 8.0, false)
			if near and not near.wild:
				Events.toast.emit("Scanner: %s — containment refused" % ("DOMINION ASSET" if near.team == "enemy" else "NOT WILDLIFE"), "warning")
			elif near and near.wild:
				Events.toast.emit("Weaken it below 30% first", "info")
		return
	_contain_victim = contain_target
	contain_channel = Balance.f("global.contain_channel", 1.2)
	l.interrupt_action()
	l.state = "channel"
	l.face_toward(_contain_victim.global_position - l.global_position)
	_contain_victim.apply_stun(contain_channel + 0.3)
	Audio.sfx("capture")
	if Field.current:
		Field.current.vfx("capture_beam", l.global_position + Vector3(0, 1.2, 0), {"from": l.global_position + Vector3(0, 1.2, 0), "to": _contain_victim.global_position + Vector3(0, 0.6, 0), "duration": contain_channel})

func _contain_tick(delta: float) -> void:
	if contain_channel <= 0.0:
		return
	var l := get_leader()
	contain_channel -= delta
	if not is_instance_valid(_contain_victim) or not _contain_victim.is_targetable() or l.downed:
		contain_channel = 0.0
		if l.state == "channel":
			l.state = "normal"
		return
	if contain_channel <= 0.0:
		l.state = "normal"
		var sp: String = _contain_victim.species_id
		_contain_victim.contained()
		GameState.add_specimen(sp)
		Events.toast.emit("Contained: %s → Terrarium" % Canon.species(sp).get("name", sp), "item")
		if Field.current:
			Field.current.vfx("capture_beam", l.global_position, {})

func contain_progress() -> float:
	if contain_channel <= 0.0:
		return 0.0
	return 1.0 - contain_channel / Balance.f("global.contain_channel", 1.2)
