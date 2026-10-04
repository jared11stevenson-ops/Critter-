class_name LevelPickup
extends Node3D
## Material pickup: glint, bob, magnet to the controlled partner, collect on touch.

signal collected(pickup)

const COLORS := {
	"reach_soil": Color("#c4683f"), "lichen_culture": Color("#9ccf5a"), "thoughtstone_dust": Color("#8fd0ef"),
	"salvage": Color("#9aa3ad"), "thoughtstone_cache": Color("#7fe0ff"),
	"spanwright_cable": Color("#d9b36a"), "red_slate_plate": Color("#8a8296"), "keth_water_flask": Color("#7fc8d8"),
}

var kind := "salvage"
var amount := 1
var key := ""
var _t := 0.0
var _mesh: MeshInstance3D
var _magnet := false
var _glint_t := 0.0
var _done := false
var _label: Label3D
var _near_t := 0.0

func setup(k: String, n: int, save_key: String) -> void:
	kind = k
	amount = n
	key = save_key

func _ready() -> void:
	_t = randf() * 3.0
	_mesh = MeshInstance3D.new()
	var col: Color = COLORS.get(kind, Color.WHITE)
	if kind == "thoughtstone_cache" or kind == "keth_water_flask":
		var pm := PrismMesh.new()
		pm.size = Vector3(0.7, 1.1, 0.7)
		_mesh.mesh = pm
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.42, 0.42, 0.42)
		_mesh.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col * 0.6
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	_mesh.material_override = m
	_mesh.rotation_degrees = Vector3(35, 0, 45)
	add_child(_mesh)
	var l := Label3D.new()
	l.text = UiKit.item_name(kind)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = 0.0008
	l.font_size = 26
	l.outline_size = 8
	l.modulate = col.lightened(0.4)
	l.position.y = 1.1
	l.no_depth_test = true
	var f := UiKit.font("bold")
	if f:
		l.font = f
	l.visible = false
	_label = l
	add_child(l)

func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_mesh.position.y = 0.55 + sin(_t * 2.6) * 0.12
	_mesh.rotation.y += delta * 1.6
	_glint_t -= delta
	if _glint_t <= 0.0:
		_glint_t = 2.2
		if Field.current:
			Field.current.vfx("pickup_glint", global_position + Vector3(0, 0.6, 0))
	var f := Field.current
	if f == null:
		return
	var l: Node3D = f.leader()
	if l == null:
		return
	var d := global_position.distance_to(l.global_position + Vector3(0, 0.3, 0))
	_near_t -= delta
	if _near_t <= 0.0:
		_near_t = 0.25
		_label.visible = d < 9.0       # the name tag only shows up close (draw-call budget)
	var mr := Balance.f("pickups.magnet_radius", 4.5)
	if kind == "thoughtstone_cache":
		mr *= 2.0
	if d < mr:
		_magnet = true
	if _magnet:
		global_position = global_position.move_toward(l.global_position + Vector3(0, 0.4, 0), (8.0 + (mr - d) * 3.0) * delta)
	if d < 0.9:
		_collect()

func _collect() -> void:
	_done = true
	GameState.add_item(kind, amount)
	if key != "":
		GameState.flags[key] = true
	Audio.sfx("pickup")
	Events.toast.emit("+%d %s" % [amount, UiKit.item_name(kind)], "item")
	if Field.current:
		Field.current.vfx("pickup_glint", global_position)
	collected.emit(self)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.15)
	tw.tween_callback(queue_free)
