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


static func mesh(piece: String) -> Mesh:
	if _meshes.has(piece):
		return _meshes[piece]
	var m: Mesh = null
	var ps: PackedScene = load(DIR + piece + ".glb") as PackedScene
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


static func glow_material(energy: float = 1.8) -> StandardMaterial3D:
	var key := "glow%.2f" % energy
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(energy, energy, energy, 1.0)
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
			m.surface_set_material(i, glow_material(2.2 if piece.begins_with("thought") else 1.8))
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
