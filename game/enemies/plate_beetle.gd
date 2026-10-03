class_name PlateBeetle
extends EnemyBase
## Agitated by Dominion resonance pylons: slow charge with a long telegraph, heavy hit.
## When every pylon near it is destroyed it calms, wanders away and despawns (non-violent path).

var agitated := true
var _charge_dir := Vector3.FORWARD
var _hit_set: Array = []

func _enemy_ready() -> void:
	accel = 14.0
	mass = 3.0

func calm_down() -> void:
	if not alive or not agitated:
		return
	agitated = false
	aggro = false
	_cancel_telegraph()
	if Field.current:
		Field.current.float_text(global_position + Vector3(0, height + 0.8, 0), "calmed", Color(0.7, 1.0, 0.75), 44)
	var away := flat_to(home + Vector3(0, 0, 40))
	if away.length_squared() < 0.01:
		away = Vector3.BACK
	speed = 2.4
	leave_peacefully(away, 6.0)

func hostile_now() -> bool:
	return agitated and super.hostile_now()

func _think(_delta: float) -> void:
	match state:
		"calm":
			return
		"windup":
			_desired = Vector3.ZERO
			if target and is_instance_valid(target) and state_t < _windup_total * 0.5:
				# track during the first half of the telegraph only (readable)
				var to := flat_to(target.global_position)
				if to.length() > 0.5:
					_charge_dir = _charge_dir.slerp(to.normalized(), 0.1).normalized()
					face_toward(_charge_dir)
					if _telegraph and is_instance_valid(_telegraph):
						_telegraph.queue_free()
					var len := float(cfg.get("charge_speed", 11.0)) * float(cfg.get("charge_time", 0.9))
					_telegraph = Field.current.telegraph_rect(global_position, _charge_dir, len, body_radius * 2.0, _windup_total - state_t)
					_attack_point = global_position + _charge_dir * len
			if state_t >= _windup_total:
				_set_state("attack")
				_hit_set.clear()
				vis("play_attack", "heavy")
				Audio.sfx_at("rage_roar", global_position, -4.0)
			return
		"attack":
			_desired = _charge_dir * float(cfg.get("charge_speed", 11.0))
			velocity.x = _desired.x
			velocity.z = _desired.z
			_knock_applied = Vector3.ZERO
			var f := Field.current
			if f:
				for p in f.party_members:
					if p.is_targetable() and not _hit_set.has(p) and p.global_position.distance_to(global_position) < body_radius + p.body_radius + 0.4:
						_hit_set.append(p)
						var h := make_hit(float(cfg.get("damage", 34)), "heavy", {"knockback": 10.0, "stagger": 0.6, "dir": _charge_dir})
						p.receive_hit(h)
				for d in f.decoys:
					if is_instance_valid(d) and d.alive and d.global_position.distance_to(global_position) < body_radius + 0.8:
						d.receive_hit({})
			if state_t >= float(cfg.get("charge_time", 0.9)) or (state_t > 0.2 and is_on_wall()):
				if is_on_wall():
					Field.current.shake(0.25)
					apply_stun(0.8)
				_set_state("recover")
			return
		"recover":
			_desired = Vector3.ZERO
			if state_t >= float(cfg.get("recover", 1.6)):
				_set_state("chase")
			return
	if not agitated:
		return
	if _think_t <= 0.0:
		_think_t = 0.3
		target = pick_target()
		if target:
			aggro = true
	if target == null or not is_instance_valid(target) or not target.is_targetable():
		_desired = flat_to(home).limit_length(1.0) * speed * 0.4
		return
	var to := flat_to(target.global_position)
	var d := to.length()
	if d < 10.0 and state_t > 0.6:
		_charge_dir = to.normalized()
		face_toward(_charge_dir)
		start_windup(float(cfg.get("telegraph", 1.0)), target.global_position)
		var len := float(cfg.get("charge_speed", 11.0)) * float(cfg.get("charge_time", 0.9))
		_telegraph = Field.current.telegraph_rect(global_position, _charge_dir, len, body_radius * 2.0, _windup_total)
		_attack_point = global_position + _charge_dir * len
		return
	_desired = to.normalized() * speed * speed_mult() + separation() * 2.0

func future_point(lead: float) -> Vector3:
	if state == "windup" or state == "attack":
		return _attack_point
	return super.future_point(lead)
