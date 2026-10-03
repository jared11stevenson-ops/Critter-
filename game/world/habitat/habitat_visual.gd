extends Node3D
## Habitat enclosure visual (Agent 1, CONTRACTS §6): raised brass-and-glass terrarium in the Habitat Wing.
## Markers (in the .tscn): Slot_Substrate, Slot_Symbiont, Slot_Climate (ceiling mount), Slot_Anchor, SpecimenSpot.
## Helpers for gameplay: set_module(slot, module_id), set_slot_highlight(slot, on), set_thriving(v), set_stress(v).
## No Camera3D. Front (camera side) = +Z.

const MODULE_DIR := "res://game/art/habitat/"
const BRASS := Color(0.72, 0.56, 0.32)
const METAL := Color(0.38, 0.40, 0.44)
const METAL_DARK := Color(0.24, 0.25, 0.28)
const WALL := Color(0.46, 0.38, 0.36)

@export var with_lighting: bool = true

var lighting: Node3D
var _rings: Dictionary = {}
var _modules: Dictionary = {}
var _glass_mat: StandardMaterial3D
var _t := 0.0


func _ready() -> void:
	var geo := Node3D.new()
	geo.name = "Geometry"
	add_child(geo)
	move_child(geo, 0)
	var st := ToonKit.begin()
	var gst := ToonKit.begin()
	# room: floor, back wall with pipes and specimen labels
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, -0.1, -2)), Vector3(26, 0.2, 18), Color(0.40, 0.34, 0.32))
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 4.5, -7.5)), Vector3(26, 9, 0.6), WALL)
	for i in 6:
		var x := -11.0 + i * 4.4
		ToonKit.box(st, Transform3D(Basis(), Vector3(x, 4.5, -7.1)), Vector3(0.7, 9, 0.5), WALL.darkened(0.2))
	for y in [6.6, 7.2]:
		ToonKit.cylinder(st, Vector3(-13, y, -6.9), Vector3(13, y, -6.9), 0.16, 0.16, 6, METAL, false)
	for i in 5:
		var x := -9.0 + i * 4.4
		ToonKit.box(st, Transform3D(Basis(), Vector3(x, 3.6, -7.15)), Vector3(1.6, 1.0, 0.06), Color(0.86, 0.80, 0.66))
		ToonKit.box(gst, Transform3D(Basis(), Vector3(x, 3.9, -7.1)), Vector3(1.0, 0.07, 0.02), Color(0.6, 0.9, 0.85))
	# plinth
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(9.4, 0.6, 7.4), METAL_DARK)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.62, 0)), Vector3(9.0, 0.06, 7.0), Color(0.46, 0.34, 0.28))
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.45, 3.71)), Vector3(9.2, 0.18, 0.04), BRASS)
	# frame: corner posts, top rails, ceiling mount rail
	var hx := 4.5
	var hz := 3.5
	var top := 5.2
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			ToonKit.box(st, Transform3D(Basis(), Vector3(sx * hx, (0.6 + top) * 0.5, sz * hz)), Vector3(0.22, top - 0.6, 0.22), BRASS)
	for sz: float in [-1.0, 1.0]:
		ToonKit.box(st, Transform3D(Basis(), Vector3(0, top, sz * hz)), Vector3(hx * 2 + 0.22, 0.2, 0.22), BRASS)
	for sx: float in [-1.0, 1.0]:
		ToonKit.box(st, Transform3D(Basis(), Vector3(sx * hx, top, 0)), Vector3(0.22, 0.2, hz * 2 + 0.22), BRASS)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, top, 0)), Vector3(hx * 2, 0.14, 0.3), METAL)
	# low front rail (the front glass is only knee-high so the camera sees in)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 1.3, hz)), Vector3(hx * 2, 0.1, 0.12), BRASS)
	# backdrop inside: painted rock wall facet
	for i in 7:
		ToonKit.rock(st, Vector3(-3.8 + i * 1.25, 0.9, -3.0), Vector3(0.75, 1.2 + 0.4 * float(i % 3), 0.45), Color(0.62, 0.34, 0.24), i + 90, 1)
	var mi := ToonKit.mesh_instance(ToonKit.finish(st), ToonKit.material({"outline": 0.03}), "Enclosure")
	geo.add_child(mi)
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.vertex_color_use_as_albedo = true
	gm.albedo_color = Color(1.4, 1.4, 1.4)
	var glow := ToonKit.mesh_instance(gst.commit(), gm, "Labels")
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geo.add_child(glow)
	_build_glass(geo, hx, hz, top)
	_build_rings(geo)
	if with_lighting:
		lighting = load("res://game/world/common/world_lighting.gd").new()
		lighting.name = "Lighting"
		lighting.set("preset", "hub")
		add_child(lighting)
		var env: Environment = lighting.get("env")
		env.background_color = Color(0.13, 0.11, 0.12)
		env.ambient_light_energy = 0.65
		env.ambient_light_color = Color(0.80, 0.72, 0.70)
		var sun: DirectionalLight3D = lighting.get("sun")
		sun.light_energy = 0.9
		sun.rotation_degrees = Vector3(-62, -20, 0)


func _build_glass(geo: Node3D, hx: float, hz: float, top: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quads := [
		[Vector3(-hx, 0.65, -hz), Vector3(hx, 0.65, -hz), Vector3(hx, top, -hz), Vector3(-hx, top, -hz)],
		[Vector3(-hx, 0.65, hz), Vector3(-hx, 0.65, -hz), Vector3(-hx, top, -hz), Vector3(-hx, top, hz)],
		[Vector3(hx, 0.65, -hz), Vector3(hx, 0.65, hz), Vector3(hx, top, hz), Vector3(hx, top, -hz)],
		[Vector3(-hx, 0.65, hz), Vector3(hx, 0.65, hz), Vector3(hx, 1.3, hz), Vector3(-hx, 1.3, hz)]]
	for q in quads:
		for i in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(q[i])
	_glass_mat = StandardMaterial3D.new()
	_glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass_mat.albedo_color = Color(0.72, 0.92, 0.95, 0.12)
	var mi := ToonKit.mesh_instance(st.commit(), _glass_mat, "Glass")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geo.add_child(mi)


func _build_rings(geo: Node3D) -> void:
	var tex: Texture2D = load("res://game/art/vfx/tex/ring.png")
	for slot in ["Substrate", "Symbiont", "Climate", "Anchor"]:
		var m: Node3D = get_node_or_null("Slot_" + slot)
		if m == null:
			continue
		var r := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(2.4, 2.4) if slot != "Substrate" else Vector2(4.4, 4.4)
		q.orientation = PlaneMesh.FACE_Y
		r.mesh = q
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_texture = tex
		mat.albedo_color = Color(0.5, 0.95, 1.0, 0.0)
		r.material_override = mat
		r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var p := m.position + Vector3(0, 0.03, 0)
		if slot == "Climate":
			p.y = 0.66
		r.position = p
		geo.add_child(r)
		_rings[slot] = r


func _norm(slot: String) -> String:
	var s := slot.replace("Slot_", "").to_lower()
	return s.capitalize()


## Places the module visual at Slot_<slot> (Substrate/Symbiont/Climate/Anchor). "" removes it.
func set_module(slot: String, module_id: String) -> Node3D:
	var sl := _norm(slot)
	if _modules.has(sl) and is_instance_valid(_modules[sl]):
		(_modules[sl] as Node).queue_free()
	_modules.erase(sl)
	if module_id == "":
		return null
	var path := MODULE_DIR + module_id + ".tscn"
	if not ResourceLoader.exists(path):
		push_warning("habitat_visual: no module " + module_id)
		return null
	var n: Node3D = load(path).instantiate()
	var m: Node3D = get_node_or_null("Slot_" + sl)
	if m:
		m.add_child(n)
	else:
		add_child(n)
	_modules[sl] = n
	return n


func get_module(slot: String) -> Node3D:
	return _modules.get(_norm(slot), null)


func set_slot_highlight(slot: String, on: bool) -> void:
	var r: MeshInstance3D = _rings.get(_norm(slot), null)
	if r:
		(r.material_override as StandardMaterial3D).albedo_color.a = 0.9 if on else 0.0


## 0 = barren / stressed glass haze, 1 = thriving (clear glass, warm).
func set_thriving(v: float) -> void:
	v = clampf(v, 0.0, 1.0)
	_glass_mat.albedo_color = Color(0.72, 0.92, 0.95, 0.12).lerp(Color(0.9, 1.0, 0.85, 0.06), v)
	for k in _modules:
		var n: Node = _modules[k]
		if is_instance_valid(n) and n.has_method("set_stress"):
			n.set_stress(1.0 - v)


func set_stress(v: float) -> void:
	for k in _modules:
		var n: Node = _modules[k]
		if is_instance_valid(n) and n.has_method("set_stress"):
			n.set_stress(v)


func _process(delta: float) -> void:
	_t += delta
	for k in _rings:
		var m := (_rings[k] as MeshInstance3D).material_override as StandardMaterial3D
		if m.albedo_color.a > 0.0:
			m.albedo_color.a = 0.6 + 0.3 * sin(_t * 4.0)
