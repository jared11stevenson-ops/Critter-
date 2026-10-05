class_name ReachesAtmosphere
extends Node3D
## Red Reaches atmosphere dressing (cheap volumetric feel): god-ray light shafts (open 3D cones along the sun direction, additive)
## and horizontal mist sheets in the chasms. Placement: world_art.json "atmos": {"shafts": [...], "mist": [...]}.
## No particles, no billboards: a handful of meshes, 1 draw call each, culled by visibility range.

const ART_PATH := "res://game/world/red_reaches/world_art.json"

var lighting: Node3D
var _shafts: Array = []     # [MeshInstance3D, base position]
var _t := 0.0


func populate(t: Node) -> void:
	lighting = t.get("lighting")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ART_PATH))
	if not (parsed is Dictionary):
		return
	var at: Dictionary = (parsed as Dictionary).get("atmos", {})
	var sh: Shader = load("res://game/art/shaders/light_shaft.gdshader")
	for s in at.get("shafts", []):
		var mi := MeshInstance3D.new()
		mi.name = "Shaft"
		var cm := CylinderMesh.new()
		var r := float(s.get("r", 3.0))
		var L := float(s.get("len", 30.0))
		cm.top_radius = r * 1.6      # sun end is wider
		cm.bottom_radius = r * 0.7
		cm.height = L
		cm.radial_segments = 14
		cm.rings = 1
		cm.cap_top = false
		cm.cap_bottom = false
		mi.mesh = cm
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("intensity", float(s.get("i", 0.5)))
		m.set_shader_parameter("seed", float(s.get("seed", 0.0)))
		var col: Array = s.get("c", [1.0, 0.78, 0.5])
		m.set_shader_parameter("shaft_color", Color(float(col[0]), float(col[1]), float(col[2])))
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = float(s.get("vis", 140.0))
		mi.position = Vector3(float(s["x"]), float(s["y"]), float(s["z"]))
		add_child(mi)
		_shafts.append([mi, mi.position, L])
	var msh: Shader = load("res://game/art/shaders/mist_sheet.gdshader")
	for ms in at.get("mist", []):
		var mi := MeshInstance3D.new()
		mi.name = "Mist"
		var q := PlaneMesh.new()
		q.size = Vector2(float(ms["w"]), float(ms["d"]))
		mi.mesh = q
		var m := ShaderMaterial.new()
		m.shader = msh
		m.set_shader_parameter("noise_tex", load("res://game/art/world/terrain_noise.png"))
		m.set_shader_parameter("density", float(ms.get("a", 0.5)))
		var col: Array = ms.get("c", [0.86, 0.58, 0.46])
		m.set_shader_parameter("mist_color", Color(float(col[0]), float(col[1]), float(col[2])))
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = float(ms.get("vis", 220.0))
		mi.position = Vector3(float(ms["x"]), float(ms["y"]), float(ms["z"]))
		add_child(mi)
	set_process(not _shafts.is_empty())
	_orient()


## Shafts hang along the sun's direction (re-aimed 2x a second: the sun moves between zone moods).
func _orient() -> void:
	if lighting == null:
		return
	var sun: Node3D = lighting.get("sun")
	if sun == null:
		return
	var dir := -sun.global_transform.basis.z          # direction light travels
	var up := -dir                                     # toward the sun
	var b := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT)
	# CylinderMesh axis is +Y: align +Y with the direction toward the sun
	var ax := Vector3.UP.cross(up)
	var ang := Vector3.UP.angle_to(up)
	var basis := Basis(ax.normalized(), ang) if ax.length() > 0.001 else Basis()
	for s in _shafts:
		var mi: MeshInstance3D = s[0]
		mi.basis = basis
		mi.position = (s[1] as Vector3) + up * (float(s[2]) * 0.5)


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = 0.5
		_orient()
