class_name ResonancePylon
extends EnemyBase
## Dominion resonance pylon. Destructible object. Its vibration agitates Plate Beetles.

var pylon_id := ""
var _pulse_t := 0.0

func _enemy_ready() -> void:
	is_object = true
	wild = false
	poise = 999.0
	mass = 100.0
	collision_layer = 4 | 8
	collision_mask = 0

func hostile_now() -> bool:
	return false

func _modify_incoming(amount: float, hit: Dictionary) -> float:
	if hit.get("kind", "light") == "heavy":
		return amount * 1.3
	return amount

func _play_hit_sfx(_hit: Dictionary) -> void:
	Audio.sfx_at("hit_metal", global_position)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	tick_statuses(delta)
	knock = Vector3.ZERO
	_pulse_t -= delta
	if _pulse_t <= 0.0:
		_pulse_t = 1.6
		if Field.current and not bool(GameState.settings.get("reduce_flashing", false)):
			Field.current.burst(global_position + Vector3(0, 2.0, 0), Color(1.0, 0.25, 0.15, 0.22), 7.0, 1.0)

func _on_zero_hp(hit: Dictionary) -> void:
	super._on_zero_hp(hit)
	if Field.current:
		Field.current.vfx("heavy_impact", global_position + Vector3(0, 1.5, 0))
		Field.current.shake(0.3)
