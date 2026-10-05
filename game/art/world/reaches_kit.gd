class_name ReachesKit
extends RefCounted
## World kit loader (Blender-built GLB pieces in res://game/art/world/kit/, built by tools/modeling/world).
## Meshes are cached; materials: "kit" (toon_kit shader + shared decal atlas, vertex-colour paint + baked AO) and "glow"
## (unshaded vertex-colour emissive: Thoughtstone, cressets, Dominion beacons, windows).
## Usage: ReachesKit.instance("span_tower") -> MeshInstance3D;  ReachesKit.mesh("boulder_a") for MultiMesh use.

const DIR := "res://game/art/world/kit/"
const ATLAS := preload("res://game/art/world/kit/kit_atlas.webp")

static var _meshes: Dictionary = {}      # name -> Mesh
static var _mats: Dictionary = {}


static func available(piece: String) -> bool:
	return ResourceLoader.exists(DIR + piece + ".glb")


## Starts background loads of the given pieces (ResourceLoader threads); mesh() then picks them up without a stall.
static func prefetch(pieces: Array) -> void:
	for p in pieces:
		var path := DIR + str(p) + ".glb"
		if _meshes.has(p) or not ResourceLoader.exists(path):
			continue
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_request(path)


static func mesh(piece: String) -> Mesh:
	if _meshes.has(piece):
		return _meshes[piece]
	var m: Mesh = null
	var path := DIR + piece + ".glb"
	var ps: PackedScene
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		ps = load(path) as PackedScene
	else:
		ps = ResourceLoader.load_threaded_get(path) as PackedScene
	if ps:
		var root := ps.instantiate()
		var mi := _first_mesh(root)
		if mi:
			m = mi.mesh
		root.free()
	else:
		push_warning("ReachesKit: missing piece " + piece)
	if m:
		_assign_materials(m, piece)
	_meshes[piece] = m
	return m


static func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r:
			return r
	return null


static func kit_material(opts: Dictionary = {}) -> ShaderMaterial:
	var key := "kit" + str(opts)
	if _mats.has(key):
		return _mats[key]
	var o := {"shader": "res://game/art/shaders/kit_prop.gdshader", "kit_tex": ATLAS, "roughness": 0.88, "detail": 0.42, "strata": 0.0, "rim": 0.18, "outline": 0.0}
	o.merge(opts, true)
	var m := ToonKit.material(o)
	_mats[key] = m
	return m


static func glow_material(energy: float = 1.8, pulse: float = 0.22) -> ShaderMaterial:
	var key := "glow%.2f/%.2f" % [energy, pulse]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/shaders/glow_pulse.gdshader")
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("pulse", pulse)
	_mats[key] = m
	return m


static func _assign_materials(m: Mesh, piece: String) -> void:
	var opts := {}
	if piece.begins_with("flat_tree") or piece.begins_with("reach_shrub") or piece == "shade_awning":
		opts = {"wind": 1.0, "roughness": 0.95, "detail": 0.25}
	elif piece.begins_with("augur") or piece.begins_with("dom_") or piece.begins_with("floodlight") or piece.begins_with("resonance") or piece.begins_with("bore") or piece.begins_with("survey_flag"):
		opts = {"metal": 0.35, "roughness": 0.55, "detail": 0.3}
	for i in m.get_surface_count():
		var cur := m.surface_get_material(i)
		var nm := cur.resource_name if cur else ""
		if nm == "glow":
			var lumen := piece.begins_with("lumen") or piece in ["glow_colony", "lantern_kelp", "glass_bloom", "bell_moss", "hanging_walkway", "sleeping_den"]
			m.surface_set_material(i, glow_material(2.2 if (lumen or piece.begins_with("thought")) else 1.8, 0.45 if lumen else 0.2))
		else:
			m.surface_set_material(i, kit_material(opts))


## A ready MeshInstance3D for `piece`.
static func instance(piece: String, xf: Transform3D = Transform3D.IDENTITY, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(piece)
	mi.name = piece
	mi.transform = xf
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
