extends Node
## Scene router with transitions. Use Router.goto(path, "fade" | "gate").
## "gate" plays the Tilt — scale sickness on crossing (Bible §4).

signal transition_midpoint

var _layer: CanvasLayer
var _rect: ColorRect
var _busy := false
var tilt_material: ShaderMaterial

const TILT_SHADER := "res://game/art/shaders/tilt_screen.gdshader"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_rect = ColorRect.new()
	_rect.color = Color(0.05, 0.04, 0.04, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_rect)
	if ResourceLoader.exists(TILT_SHADER):
		tilt_material = ShaderMaterial.new()
		tilt_material.shader = load(TILT_SHADER)

func is_busy() -> bool:
	return _busy

func goto(path: String, transition: String = "fade") -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var dur := 0.45 if transition == "fade" else 1.3
	if transition == "gate" and tilt_material:
		_rect.material = tilt_material
		tilt_material.set_shader_parameter("strength", 0.0)
		var tw0 := create_tween()
		tw0.tween_method(func(v): tilt_material.set_shader_parameter("strength", v), 0.0, 1.0, dur)
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, dur)
	await tw.finished
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Router: failed to load %s (%d)" % [path, err])
	await get_tree().process_frame
	await get_tree().process_frame
	transition_midpoint.emit()
	var tw2 := create_tween()
	tw2.tween_property(_rect, "color:a", 0.0, dur)
	if transition == "gate" and tilt_material:
		tw2.parallel().tween_method(func(v): tilt_material.set_shader_parameter("strength", v), 1.0, 0.0, dur * 1.6)
	await tw2.finished
	_rect.material = null
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
