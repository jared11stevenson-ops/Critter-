class_name DustGrazer
extends EnemyBase
## Passive keystone grazer. Never attacks. Flees when hit. Harming one has consequences
## (the level sets `grazers_harmed`). May enter protective containment unharmed.

var herd_center := Vector3.ZERO
var _wander_to := Vector3.ZERO
var _flee_from := Vector3.ZERO

func _enemy_ready() -> void:
	passive = true
	accel = 10.0
	herd_center = global_position
	_wander_to = global_position

func hostile_now() -> bool:
	return false

func _on_hit(hit: Dictionary, amount: float) -> void:
	super._on_hit(hit, amount)
	var src: Node = hit.get("source", null)
	_flee_from = src.global_position if src is Node3D else global_position - Vector3.FORWARD
	_set_state("flee")
	# the herd startles together
	if Field.current:
		for e in Field.current.enemies:
			if e != self and e is DustGrazer and e.global_position.distance_to(global_position) < 12.0:
				e.startle(_flee_from)

func startle(from: Vector3) -> void:
	if state == "calm" or not alive:
		return
	_flee_from = from
	_set_state("flee")

func _think(_delta: float) -> void:
	match state:
		"calm":
			return
		"flee":
			var away := flat_to(_flee_from) * -1.0
			_desired = away.normalized() * float(cfg.get("flee_speed", 6.5)) + separation() * 2.0
			if state_t > 3.0:
				herd_center = global_position
				_set_state("idle")
			return
	if _think_t <= 0.0:
		_think_t = randf_range(2.0, 5.0)
		_wander_to = herd_center + Vector3(randf_range(-6, 6), 0, randf_range(-5, 5))
	var to := flat_to(_wander_to)
	if to.length() > 0.6:
		_desired = to.normalized() * speed + separation() * 1.5
	else:
		_desired = separation() * 1.5
