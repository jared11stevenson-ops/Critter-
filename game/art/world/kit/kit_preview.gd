extends Node3D
## Art-review scene: every kit piece in a grid under the Reaches lighting rig. QA: Terrain-less; call set_cam().
var cam: Camera3D
var _lighting: Node3D
var _items := {}
func _ready() -> void:
	var L: Node3D = load("res://game/world/common/world_lighting.gd").new()
	L.set("preset", "gate")
	add_child(L)
	L.get('env').fog_enabled = false
	_lighting = L
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 200)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.74, 0.55, 0.40)
	floor_mi.material_override = fm
	add_child(floor_mi)
	var names := []
	var d := DirAccess.open("res://game/art/world/kit/")
	for f in d.get_files():
		if f.ends_with(".glb"):
			names.append(f.get_basename())
	names.sort()
	var i := 0
	for n in names:
		var mi := ReachesKit.instance(n)
		var big: bool = n.begins_with("mesa") or n.begins_with("butte") or n.begins_with("augur") or n.begins_with("rock_arch")
		var col := i % 8
		var row := i / 8
		mi.position = Vector3(col * 15.0 - 52, 0, row * 16.0 - 24)
		if big:
			mi.scale = Vector3.ONE * 0.35
		_items[n] = mi
		if n.begins_with('span_bay') or n.begins_with('span_pier'):
			mi.position.y = 6.0
		add_child(mi)
		var lb := Label3D.new()
		lb.text = n
		lb.position = mi.position + Vector3(0, -0.05, 4.5)
		lb.rotation.x = -PI / 2
		lb.font_size = 48
		lb.pixel_size = 0.012
		add_child(lb)
		i += 1
	cam = Camera3D.new()
	cam.far = 600
	add_child(cam)
	set_cam(0, 60, 50, 0, 0, -4, 60)
func set_cam(px: float, py: float, pz: float, tx: float, ty: float, tz: float, fov: float = 60.0) -> void:
	cam.fov = fov
	cam.global_position = Vector3(px, py, pz)
	cam.look_at(Vector3(tx, ty, tz), Vector3.UP)
	cam.make_current()

## Orbit camera around a named piece: dist (m), elevation deg, yaw deg.
func focus(piece: String, dist: float, elev: float = 22.0, yaw: float = 25.0, fov: float = 45.0) -> void:
	var mi: MeshInstance3D = _items.get(piece)
	if mi == null:
		return
	var bb := mi.get_aabb()
	var c := mi.global_transform * (bb.position + bb.size * 0.5)
	var d := Vector3(sin(deg_to_rad(yaw)) * cos(deg_to_rad(elev)), sin(deg_to_rad(elev)), cos(deg_to_rad(yaw)) * cos(deg_to_rad(elev)))
	cam.fov = fov
	cam.global_position = c + d * dist
	cam.look_at(c, Vector3.UP)
	cam.make_current()
