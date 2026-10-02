class_name Decoy
extends Node3D
## False Memory: a hallucinated Cigarra echo. Enemies believe it and attack it.

var alive := true
var body_radius := 0.5
var height := 1.6
var _t := 5.0
var _visual: Node3D

func setup(char_id: String, dur: float) -> void:
	_t = dur
	_visual = VisualFactory.character(char_id)
	add_child(_visual)
	VisualFactory.call_v(_visual, "set_ghost", [0.55])
	VisualFactory.call_v(_visual, "set_highlight", [Color(0.7, 0.9, 0.4), true])
	if Field.current:
		Field.current.decoys.append(self)

func is_targetable() -> bool:
	return alive

func aim_height() -> float:
	return 0.8

func receive_hit(_hit: Dictionary) -> float:
	VisualFactory.call_v(_visual, "flash_hit")
	return 0.0

func _process(delta: float) -> void:
	_t -= delta
	if _visual:
		_visual.rotation.y += delta * 0.4
	if _t <= 0.0 and alive:
		alive = false
		if Field.current:
			Field.current.decoys.erase(self)
			Field.current.vfx("false_memory_echo", global_position)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3(1.4, 0.05, 1.4), 0.25)
		tw.tween_callback(queue_free)

func _exit_tree() -> void:
	if Field.current:
		Field.current.decoys.erase(self)
