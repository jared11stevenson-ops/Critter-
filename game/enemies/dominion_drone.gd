class_name DominionDrone
extends EnemyBase
## Dominion survey drone: hovers 1.6 m, strafes at range, telegraphed 3-shot burst.
## Weak to heavy impact (×heavy_mult). Not containable (DOMINION ASSET).

var _strafe := 1.0
var _shots_left := 0
var _shot_t := 0.0

func _enemy_ready() -> void:
	fly_height = 1.6
	accel = 12.0
	_strafe = 1.0 if randf() < 0.5 else -1.0
	Audio.sfx_at("drone_hum", global_position, -10.0)

func _modify_incoming(amount: float, hit: Dictionary) -> float:
	if hit.get("kind", "light") == "heavy":
		return amount * float(cfg.get("heavy_mult", 1.6))
	return amount

func _play_hit_sfx(_hit: Dictionary) -> void:
	Audio.sfx_at("hit_metal", global_position)

func aim_height() -> float:
	return 0.4

func _think(delta: float) -> void:
	match state:
		"calm":
			return
		"windup":
			_desired = Vector3.ZERO
			if target and is_instance_valid(target):
				face_toward(flat_to(target.global_position))
			if state_t >= _windup_total:
				_set_state("attack")
				_shots_left = int(cfg.get("burst", 3))
				_shot_t = 0.0
			return
		"attack":
			_desired = Vector3.ZERO
			_shot_t -= delta
			if _shot_t <= 0.0 and _shots_left > 0:
				_shots_left -= 1
				_shot_t = float(cfg.get("burst_gap", 0.16))
				var aim := _attack_point + Vector3(0, 0.9, 0)
				var from := global_position + Vector3(0, 0.45, 0)
				var dir := (aim - from).normalized()
				vis("play_attack", "light")
				Audio.sfx_at("drone_shot", global_position)
				if Field.current:
					Field.current.spawn_projectile(from, dir, float(cfg.get("shot_speed", 15.0)), float(cfg.get("range", 13.0)) + 4.0, make_hit(float(cfg.get("damage", 9)), "light", {"knockback": 1.0}), "enemy", null, "dominion")
			if _shots_left <= 0:
				_set_state("recover")
			return
		"recover":
			_strafe_move(0.6)
			if state_t >= float(cfg.get("recover", 1.8)):
				_set_state("chase")
			return
	if _think_t <= 0.0:
		_think_t = 0.3
		target = pick_target()
		if target:
			aggro = true
	if target == null or not is_instance_valid(target) or not target.is_targetable():
		_desired = flat_to(home).limit_length(1.0) * speed * 0.3
		return
	var d := flat_to(target.global_position).length()
	if d < float(cfg.get("range", 13.0)) and state_t > 1.0:
		start_windup(float(cfg.get("telegraph", 0.6)), target.global_position)
		var dir := flat_to(target.global_position).normalized()
		_telegraph = Field.current.telegraph_rect(global_position, dir, d + 1.0, 0.9, _windup_total) if Field.current else null
		return
	_strafe_move(1.0)

func _strafe_move(mult: float) -> void:
	if target == null or not is_instance_valid(target):
		_desired = Vector3.ZERO
		return
	var to := flat_to(target.global_position)
	var d := to.length()
	var n := to.normalized()
	var side := Vector3(-n.z, 0, n.x) * _strafe
	var radial := 0.0
	var pref := float(cfg.get("pref_range", 8.0))
	if d > pref + 1.5:
		radial = 1.0
	elif d < pref - 1.5:
		radial = -1.0
	_desired = (n * radial + side * 0.8).normalized() * speed * mult * speed_mult() + separation() * 2.0
	if randf() < 0.005:
		_strafe = -_strafe
