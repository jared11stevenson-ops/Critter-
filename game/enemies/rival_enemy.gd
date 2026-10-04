class_name RivalEnemy
extends EnemyBase
## A Ledger Rival in the field (LEDGER_SPEC §7). The AI is driven by Rivals.behavior_profile(id):
## base tactics + trait tactics + counter-tactics learned from how the player fought last time.
## A rival never dies. When HP falls to flee_at the rival YIELDS and the encounter manager offers the
## resolution options (force / terms / expose / let walk / bond). Design rules: no ranks, no promotions,
## no rival-vs-rival logic; one authored person with a memory, nothing more.
##
## Tactic -> behaviour map (ids come from rivals.json base_tactics / traits / counters):
##   hold_ground      stays near home, never chases past the leash       call_drones    summons survey drones once
##   ambush           waits unseen, strikes first                         snare_traps    lays telegraphed snares
##   plans_ahead      opens with a snare on the party's path             takes_bribes   (flavor; terms are offered)
##   rush             faster, shorter windups                             keeps_distance wider preferred range
##   refuses_retreat  yields only at half the usual threshold             targets_weakest picks the lowest-HP partner
##   shielded_advance heavy hits glance off (x0.65)                       stay_off_the_line zig-zags off straight lines
##   spread_formation resists Gravity Pull (pull time x0.3)               kite_and_wait  backs off, attacks slower
##   break_the_pairing goes after the partner, not the leader             bait_projectiles Bad Thought bolts hurt less (x0.6)
##   erratic_timing   randomizes windups (Premonition reads less)         ignore_echoes  ignores False Memory decoys
##   stagger_guard    stagger/stun halved                                 hunt_the_landing leads shots to where you will land

signal engaged(rival)
signal yielded(rival)

var rival_id := ""
var profile: Dictionary = {}
var tactics: Array = []
var attack_kind := "shot"          # "shot" (ranged) | "lunge" (melee dash)
var flee_frac := 0.25
var aggression := 0.5
var hit_by: Array = []
var talk_first := false
var engaged_once := false
var yielded_once := false

var _trap_t := 4.0
var _opened := false
var _called := false
var _taunted := false
var _shots_left := 0
var _shot_t := 0.0
var _strafe := 1.0
var _flip_t := 2.0
var _lunge_dir := Vector3.ZERO
var _lunge_hit := false
var _plate: Label3D

static func make(rid: String) -> RivalEnemy:
	var e := RivalEnemy.new()
	e.rival_id = rid
	e.species_id = "rival"
	e.profile = Rivals.behavior_profile(rid)
	return e

func _make_visual() -> Node3D:
	var r := Rivals.get_rival(rival_id)
	# faction body: skinned 3D model (res://game/art/models/npcs/rival_<faction>), primitive fallback if missing
	return VisualFactory.character("rival_" + str(r.get("faction", "dominion")))

func has_tactic(t: String) -> bool:
	return t in tactics

func _enemy_ready() -> void:
	var r := Rivals.get_rival(rival_id)
	profile = Rivals.behavior_profile(rival_id)
	tactics = profile.get("tactics", [])
	display_name = str(r.get("name", "Rival"))
	aggression = float(profile.get("aggression", 0.5))
	flee_frac = float(profile.get("flee_at", 0.25))
	if has_tactic("refuses_retreat"):
		flee_frac *= 0.5
	attack_kind = "lunge" if str(r.get("archetype", "")) == "contract_poacher" else "shot"
	if has_tactic("rush"):
		speed *= 1.2
	hp = max_hp
	accel = 22.0
	_strafe = 1.0 if randf() < 0.5 else -1.0
	var fac := str(r.get("faction", "dominion"))
	var col := {"dominion": Color("#d65a44"), "undermarket": Color("#e0b04a"), "free_scale": Color("#9ad08a"), "helix": Color("#7fd0d8")}.get(fac, Color.WHITE) as Color
	_plate = Label3D.new()
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.fixed_size = true
	_plate.pixel_size = 0.0011
	_plate.font_size = 34
	_plate.outline_size = 10
	_plate.no_depth_test = true
	_plate.modulate = col
	_plate.position = Vector3(0, height + 0.55, 0)
	add_child(_plate)
	_refresh_plate()
	state = "dormant" if has_tactic("ambush") else "idle"
	if state == "dormant":
		visual.visible = false
		_plate.visible = false
		passive = true      # not auto-aimed while unseen

func aim_height() -> float:
	return height * 0.55

func _refresh_plate() -> void:
	if _plate == null:
		return
	var frac := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	var pips := ceili(frac * 8.0)
	var bar := "▮".repeat(pips) + "▯".repeat(8 - pips)
	_plate.text = "%s\n%s" % [display_name, bar]

# ---------------- damage ----------------
func _modify_incoming(amount: float, hit: Dictionary) -> float:
	var ab := str(hit.get("ability", ""))
	if has_tactic("shielded_advance") and str(hit.get("kind", "light")) == "heavy":
		amount *= 0.65
	if has_tactic("bait_projectiles") and ab == "bad_thought":
		amount *= 0.6
	return amount

func apply_pull(point: Vector3, dur: float, spd: float) -> void:
	super.apply_pull(point, dur * (0.3 if has_tactic("spread_formation") else 1.0), spd)

func _on_staggered() -> void:
	super._on_staggered()
	if has_tactic("stagger_guard"):
		stagger_t *= 0.5
		stun_t *= 0.5

func _on_hit(hit: Dictionary, amount: float) -> void:
	var ab := str(hit.get("ability", ""))
	if ab != "" and not (ab in hit_by):
		hit_by.append(ab)
	if state == "dormant" or state == "idle":
		_wake()
	super._on_hit(hit, amount)
	_refresh_plate()
	if state != "yield" and state != "calm" and hp <= max_hp * flee_frac:
		_yield()
	elif not _taunted and hp <= max_hp * 0.6 and not (profile.get("taunts", []) as Array).is_empty():
		_taunted = true
		if Field.current:
			Field.current.float_text(global_position + Vector3(0, height + 1.2, 0), str(profile["taunts"][0]), Color(1, 0.9, 0.7), 30)
	if not _called and has_tactic("call_drones") and hp <= max_hp * 0.7 and state != "yield":
		_called = true
		_call_drones()

func _on_zero_hp(_hit: Dictionary) -> void:
	# Rivals do not die. Treat a killing blow as the moment they yield.
	hp = 1.0
	hp_changed.emit(hp, max_hp)
	_refresh_plate()
	_yield()

func _play_hit_sfx(_hit: Dictionary) -> void:
	Audio.sfx_at("hit_flesh", global_position)

# ---------------- encounter lifecycle ----------------
func _wake() -> void:
	if engaged_once:
		return
	engaged_once = true
	visual.visible = true
	_plate.visible = true
	passive = false
	aggro = true
	state = "talk"
	engaged.emit(self)

## Called by the manager after the greeting: start fighting (or hold, if the player chose to talk first).
func begin_fight() -> void:
	aggro = true
	target = pick_target()
	_set_state("chase")
	_trap_t = 0.8 if has_tactic("plans_ahead") else 5.0

func _yield() -> void:
	if yielded_once:
		return
	yielded_once = true
	_cancel_telegraph()
	state = "yield"
	state_t = 0.0
	aggro = false
	downed = true         # not targetable, not auto-aimed, not a threat
	_desired = Vector3.ZERO
	vis("set_downed", true)
	if Field.current:
		Field.current.float_text(global_position + Vector3(0, height + 1.0, 0), "Enough!", Color(1, 0.9, 0.7), 40)
	yielded.emit(self)

## Terms were reached / released / exposed / bonded: they walk off the field.
func walk_away(dir: Vector3 = Vector3.ZERO) -> void:
	downed = false
	vis("set_downed", false)
	var d := dir if dir.length_squared() > 0.01 else (flat_to(home) if flat_to(home).length() > 2.0 else Vector3(1, 0, 0.3))
	speed = maxf(speed, 3.5)
	leave_peacefully(d, 3.2)

## Escaped under their own power (wipe, you walked off, or you did not decide in time).
func flee_field() -> void:
	downed = false
	vis("set_downed", false)
	_cancel_telegraph()
	var away := Vector3(1, 0, 0.2)
	if Field.current and Field.current.leader():
		away = -flat_to(Field.current.leader().global_position)
	speed *= 1.7
	if Field.current:
		Field.current.float_text(global_position + Vector3(0, height + 1.0, 0), "Not today.", Color(1, 0.85, 0.7), 34)
	leave_peacefully(away, 2.6)

## Stopped by force: detained, gear logged.
func detain() -> void:
	_cancel_telegraph()
	alive = false
	collision_layer = 0
	var t := 0.7
	var r: Variant = vis("play_die")
	if r != null:
		t = float(r)
	_remove(t)

# ---------------- AI ----------------
func pick_target() -> Node:
	var f := Field.current
	if f == null:
		return null
	var rng := float(cfg.get("aggro", 16.0)) * (1.6 if aggro else 1.0)
	if not has_tactic("ignore_echoes"):
		for d in f.decoys:
			if is_instance_valid(d) and d.alive and d.global_position.distance_to(global_position) < rng * 1.2:
				return d
	var best: Node = null
	var bd := INF
	var lead: Node = f.leader()
	for p in f.party_members:
		if not is_instance_valid(p) or not p.is_targetable():
			continue
		var dist: float = p.global_position.distance_to(global_position)
		if dist >= rng:
			continue
		var score := dist
		if has_tactic("targets_weakest"):
			score = dist + float(p.hp) / maxf(1.0, float(p.max_hp)) * 14.0
		if has_tactic("break_the_pairing") and p != lead:
			score -= 8.0
		if score < bd:
			best = p
			bd = score
	return best

func _think(delta: float) -> void:
	_trap_t -= delta
	match state:
		"dormant":
			if _think_t <= 0.0:
				_think_t = 0.2
				var l: Node = Field.current.leader() if Field.current else null
				if l and flat_to(l.global_position).length() < 11.0:
					_wake()
			return
		"idle":
			if _think_t <= 0.0:
				_think_t = 0.3
				var t := pick_target()
				if t != null and flat_to(t.global_position).length() < float(cfg.get("aggro", 16.0)) * 0.8:
					_wake()
			return
		"talk", "yield", "calm":
			_desired = Vector3.ZERO
			return
		"windup":
			_desired = Vector3.ZERO
			if has_tactic("shielded_advance") and target and is_instance_valid(target):
				_desired = flat_to(target.global_position).normalized() * speed * 0.35
			if target and is_instance_valid(target):
				face_toward(flat_to(target.global_position))
			if state_t >= _windup_total:
				_begin_attack()
			return
		"attack":
			_attack_tick(delta)
			return
		"recover":
			var back := Vector3.ZERO
			if target and is_instance_valid(target) and attack_kind == "shot":
				back = -flat_to(target.global_position).normalized() * speed * 0.35
			_desired = back
			_maybe_trap()
			var rec := float(cfg.get("recover", 1.6)) / (0.5 + aggression)
			if has_tactic("kite_and_wait"):
				rec *= 1.4
			if state_t >= rec:
				_set_state("chase")
			return
	# chase
	if _think_t <= 0.0:
		_think_t = 0.3
		target = pick_target()
	if target == null or not is_instance_valid(target) or not target.is_targetable():
		_desired = flat_to(home).limit_length(1.0) * speed * 0.4
		return
	_maybe_trap()
	var to := flat_to(target.global_position)
	var d := to.length()
	var n := to.normalized()
	var side := Vector3(-n.z, 0, n.x) * _strafe
	_flip_t -= delta
	if _flip_t <= 0.0:
		_flip_t = randf_range(1.2, 2.6) if not has_tactic("stay_off_the_line") else randf_range(0.5, 1.1)
		if randf() < 0.6:
			_strafe = -_strafe
	var pref := float(cfg.get("pref_range", 9.0))
	if attack_kind == "lunge":
		pref = float(cfg.get("lunge_range", 6.5)) * 0.8
	if has_tactic("keeps_distance") or has_tactic("kite_and_wait"):
		pref += 3.0
	var radial := 0.0
	if d > pref + 1.5:
		radial = 1.0
	elif d < pref - 1.5 and attack_kind == "shot":
		radial = -1.0
	var hold := has_tactic("hold_ground")
	if hold:
		var from_home := flat_to(home)
		if from_home.length() > 10.0 and radial > 0.0:
			radial = 0.0
			side = from_home.normalized() * 0.6
	_desired = (n * radial + side * 0.75).normalized() * speed * speed_mult() + separation() * 2.0
	var rng := float(cfg.get("range", 13.0)) if attack_kind == "shot" else float(cfg.get("lunge_range", 6.5))
	var cooldown := 0.9 / (0.5 + aggression)
	if d < rng and state_t > cooldown:
		_start_attack(d)

func _maybe_trap() -> void:
	if _trap_t > 0.0 or target == null or not is_instance_valid(target):
		return
	if not (has_tactic("snare_traps") or (has_tactic("plans_ahead") and not _opened)):
		return
	_opened = true
	_trap_t = float(cfg.get("trap_every", 9.0))
	var lead_pos: Vector3 = target.global_position + Vector3(target.velocity.x, 0, target.velocity.z) * 0.5
	var r := float(cfg.get("trap_radius", 2.2))
	var dur := 1.1
	if Field.current:
		Field.current.telegraph_circle(lead_pos, r, dur, Color(1.0, 0.55, 0.12))
	var t := get_tree().create_timer(dur, false)
	t.timeout.connect(_spring_trap.bind(lead_pos, r))

func _spring_trap(pos: Vector3, r: float) -> void:
	if not is_inside_tree() or Field.current == null:
		return
	var n := 0
	for p in Field.current.party_members:
		if is_instance_valid(p) and p.is_targetable():
			if Vector2(p.global_position.x - pos.x, p.global_position.z - pos.z).length() < r + p.body_radius:
				var h := make_hit(float(cfg.get("trap_damage", 8)), "light", {"knockback": 0.0, "slow": [0.5, 2.5]})
				p.receive_hit(h)
				n += 1
	Audio.sfx_at("hit_metal", pos)

func _call_drones() -> void:
	var lv: Node = Field.current.level if Field.current else null
	if lv == null or not lv.has_method("spawn_enemy"):
		return
	if Field.current:
		Field.current.float_text(global_position + Vector3(0, height + 1.2, 0), "Drones, now.", Color(1, 0.8, 0.6), 34)
	for k in int(cfg.get("drone_count", 2)):
		var a := TAU * float(k) / 2.0 + 0.7
		lv.spawn_enemy("dominion_drone", global_position + Vector3(cos(a) * 3.0, 0, sin(a) * 3.0))

func _start_attack(d: float) -> void:
	var tel := float(cfg.get("telegraph", 0.75))
	if has_tactic("rush"):
		tel *= 0.7
	if has_tactic("erratic_timing"):
		tel *= randf_range(0.65, 1.4)
	var aim: Vector3 = target.global_position
	if has_tactic("hunt_the_landing"):
		aim += Vector3(target.velocity.x, 0, target.velocity.z) * 0.6
	_lunge_dir = flat_to(aim).normalized()
	_lunge_hit = false
	start_windup(maxf(0.45, tel), aim)
	if Field.current:
		var length := d + 1.0 if attack_kind == "shot" else float(cfg.get("lunge_range", 6.5)) + 1.5
		_telegraph = Field.current.telegraph_rect(global_position, _lunge_dir, length, 0.9 if attack_kind == "shot" else 1.4, _windup_total)

func _begin_attack() -> void:
	_set_state("attack")
	vis("play_attack", "heavy" if attack_kind == "lunge" else "light")
	if attack_kind == "shot":
		_shots_left = int(cfg.get("burst", 2))
		_shot_t = 0.0
	else:
		Audio.sfx_at("swing_heavy", global_position)

func _attack_tick(delta: float) -> void:
	if attack_kind == "shot":
		_desired = Vector3.ZERO
		_shot_t -= delta
		if _shot_t <= 0.0 and _shots_left > 0:
			_shots_left -= 1
			_shot_t = float(cfg.get("burst_gap", 0.3))
			var from := global_position + Vector3(0, height * 0.65, 0)
			var dir := (_attack_point + Vector3(0, 0.9, 0) - from).normalized()
			Audio.sfx_at("drone_shot", global_position)
			if Field.current:
				Field.current.spawn_projectile(from, dir, float(cfg.get("shot_speed", 14.0)), float(cfg.get("range", 13.0)) + 4.0, make_hit(float(cfg.get("damage", 11)), "light", {"knockback": 1.5}), "enemy", null, "dominion")
		if _shots_left <= 0:
			_set_state("recover")
	else:
		_desired = _lunge_dir * float(cfg.get("lunge_speed", 12.0))
		if not _lunge_hit:
			var n := hit_party_in_radius(global_position + _lunge_dir * 0.8, 1.3, make_hit(float(cfg.get("lunge_damage", 15)), "heavy", {"knockback": 5.0, "stagger": 0.3, "dir": _lunge_dir}))
			if n > 0:
				_lunge_hit = true
		if state_t >= 0.38:
			_set_state("recover")

func make_ghost_visual() -> Node3D:
	var g := _make_visual()
	VisualFactory.call_v(g, "set_ghost", [0.42])
	return g
