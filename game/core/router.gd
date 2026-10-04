extends Node
## Scene router with transitions. Use Router.goto(path, "fade" | "gate").
## "gate" plays the Tilt — scale sickness on crossing (Bible §4).

signal transition_midpoint

var _layer: CanvasLayer
var _rect: ColorRect
var _busy := false
var tilt_material: ShaderMaterial

## Runtime load() calls a scene makes in _ready (terrain textures, atlases...) block the main thread for hundreds of ms on a
## phone. List them here so they are decoded on worker threads during the fade-out; the scene's own load() then hits the cache.
const PBR := "res://game/art/world/pbr/"
const EXTRA := {
	"res://game/world/red_reaches/red_reaches.tscn": [
		PBR + "cliff_rock_albedo.webp", PBR + "cliff_rock_normal.webp", PBR + "ground_dirt_albedo.webp", PBR + "ground_dirt_normal.webp",
		PBR + "ground_flag_albedo.webp", PBR + "ground_flag_normal.webp", PBR + "macro_var.webp", PBR + "prop_detail.webp",
		PBR + "prop_rock_normal.webp", PBR + "scrub_albedo.webp", PBR + "scrub_normal.webp",
		"res://game/art/world/reaches_atlas.png", "res://game/art/world/terrain_noise.png",
	],
	"res://game/world/hub/hub.tscn": [
		"res://game/art/world/flagstone.png", "res://game/art/world/terrain_noise.png", "res://game/art/world/reaches_atlas.png",
	],
}
var _hold: Array = []

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
	# Load the next scene's resources on a worker thread while the screen fades out, so the swap itself is short.
	var threaded := ResourceLoader.load_threaded_request(path) == OK
	var extras: Array = []
	for ex in EXTRA.get(path, []):
		if ResourceLoader.exists(ex) and ResourceLoader.load_threaded_request(ex) == OK:
			extras.append(ex)
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, dur)
	await tw.finished
	get_tree().paused = false
	var packed: PackedScene = null
	if threaded:
		var guard := 0
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS and guard < 600:
			guard += 1
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
			packed = ResourceLoader.load_threaded_get(path) as PackedScene
	for ex in extras:
		var g2 := 0
		while ResourceLoader.load_threaded_get_status(ex) == ResourceLoader.THREAD_LOAD_IN_PROGRESS and g2 < 600:
			g2 += 1
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status(ex) == ResourceLoader.THREAD_LOAD_LOADED:
			_hold.append(ResourceLoader.load_threaded_get(ex))
	var err := get_tree().change_scene_to_packed(packed) if packed else get_tree().change_scene_to_file(path)
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
	_hold.clear()
	_busy = false
