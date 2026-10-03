class_name SkitterMite
extends EnemyBase
## Swarm of 4–6. Nibbles. Flees when the swarm is broken (fewer than flee_below remain).

var swarm: Array = []     # shared Array of members
var _orbit := 0.0

func _enemy_ready() -> void:
	accel = 30.0
	_orbit = randf() * TAU

func _swarm_alive() -> int:
	var n := 0
	for m in swarm:
		if is_instance_valid(m) and m.alive:
			n += 1
	return n

func _on_hit(hit: Dictionary, amount: float) -> void:
	super._on_hit(hit, amount)
	for m in swarm:
		if is_instance_valid(m) and m.alive and not m.aggro:
			m.aggro = true
			m.target = hit.get("source", null)

func _think(delta: float) -> void:
	match state:
		"calm", "flee":
			return
		"windup":
			_desired = Vector3.ZERO
			if state_t >= _windup_total:
				_set_state("attack")
				vis("play_attack", "light")
				Audio.sfx_at("hit_flesh", global_position, -8.0)
				hit_party_in_radius(_attack_point, 0.9, make_hit(float(cfg.get("damage", 7)), "light", {"knockback": 1.5, "stagger": 0.1}))
			return
		"attack":
			if state_t > 0.15:
				_set_state("recover")
			return
		"recover":
			_desired = -flat_to(target.global_position).normalized() * speed * 0.4 if target and is_instance_valid(target) else Vector3.ZERO
			if state_t >= float(cfg.get("recover", 0.8)) * randf_range(0.8, 1.3):
				_set_state("chase")
			return
	# broken swarm → flee
	if aggro and swarm.size() > 2 and _swarm_alive() < int(cfg.get("flee_below", 2)):
		var away := Vector3.ZERO
		var l: Node = Field.current.leader() if Field.current else null
		if l:
			away = -flat_to(l.global_position)
		if away.length_squared() < 0.01:
			away = Vector3.RIGHT
		Field.current.float_text(global_position + Vector3(0, 1.0, 0), "flees", Color(0.9, 0.85, 0.7), 32)
		speed *= 1.3
		leave_peacefully(away, 3.5)
		return
	if _think_t <= 0.0:
		_think_t = 0.25
		target = pick_target()
		if target and not aggro:
			aggro = true
			for m in swarm:
				if is_instance_valid(m) and m.alive:
					m.aggro = true
	if not aggro or target == null or not is_instance_valid(target) or not target.is_targetable():
		# mill around home
		_orbit += delta * 0.8
		var hp2 := home + Vector3(cos(_orbit + _rid), 0, sin(_orbit + _rid)) * 2.5
		_desired = flat_to(hp2).limit_length(1.0) * speed * 0.35 + separation() * 2.0
		return
	_set_state_if("idle", "chase")
	var to := flat_to(target.global_position)
	var d: float = to.length() - target.body_radius
	if d < float(cfg.get("range", 1.4)):
		face_toward(to)
		start_windup(float(cfg.get("telegraph", 0.45)), target.global_position)
		_telegraph = Field.current.telegraph_circle(target.global_position, 0.9, _windup_total) if Field.current else null
		return
	# approach with a little flanking jitter
	_orbit += delta * 2.0
	var side := Vector3(-to.z, 0, to.x).normalized() * sin(_orbit + _rid) * 0.5
	_desired = (to.normalized() + side).normalized() * speed * speed_mult() + separation() * 3.0

func _set_state_if(from: String, to: String) -> void:
	if state == from:
		_set_state(to)
