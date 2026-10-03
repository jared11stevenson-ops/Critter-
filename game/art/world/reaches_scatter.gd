extends Node3D
## Red Reaches scatter (Agent 1). Painted props from the Reaches kit as camera-facing billboards in ONE
## MultiMesh (one draw call), plus 3D toon props (crates, survey flags, broken pillars, rock chunks) in one
## MultiMesh per mesh. Placement from layout.json props_scatter; keeps paths, markers and triggers clear.

const ATLAS_TEX := preload("res://game/art/world/reaches_atlas.png")
const ATLAS_JSON := "res://game/art/world/reaches_atlas.json"
const SCATTER_SHADER_PATH := "res://game/art/shaders/scatter_billboard.gdshader"

## layout kind -> atlas items (weighted by repetition)
const KIND_ITEMS := {
	"rock_small": ["rock_pile", "rock_stone", "rock_needle", "rock_round", "rock_round", "rock_stone"],
	"rock_spire": ["rock_horn", "rock_pillar", "rock_pillar"],
	"flat_tree": ["tree_big", "tree_big", "tree_small", "tree_bone"],
	"bone": ["horn_hanging"],
	"shrub": ["shrub_red", "plant_agave", "plant_redbush", "plant_blue", "plant_bulb", "plant_orange", "plant_cone"],
	"lichen_patch": ["plant_bulb", "plant_blue", "plant_agave"],
}
const MESH_KINDS := ["crate", "survey_flag", "pillar_broken"]

var _atlas: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _bb: Array = []        # [Transform3D, Color, rect Color]
var _props: Dictionary = {}  # kind -> Array[Transform3D]
var _clear: Array = []     # [Vector2 center, radius]
var _t: Node


func populate(t: Node) -> void:
	_rng.seed = 1977
	_t = t
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_JSON))
	if parsed is Dictionary:
		_atlas = parsed.get("items", {})
	var layout: Dictionary = t.layout
	_build_clear_zones(layout)
	var floors := {}
	for f in layout.get("floors", []):
		floors[f.get("id", "")] = f
	for entry in layout.get("props_scatter", []):
		var area: String = entry.get("area", "")
		var kinds: Array = entry.get("kinds", [])
		var count := int(entry.get("count", 0))
		if area == "mesa_top":
			_scatter_mesa(t, kinds, count)
		elif floors.has(area):
			_scatter_floor(t, floors[area], kinds, count)
	_extra_backdrop_trees(t)
	_commit_billboards()
	_commit_props()


func _build_clear_zones(layout: Dictionary) -> void:
	for k in layout.get("markers", {}):
		var m: Array = layout["markers"][k]
		_clear.append([Vector2(float(m[0]), float(m[2])), 2.5])
	for tr in layout.get("triggers", []):
		var p: Array = tr["pos"]
		_clear.append([Vector2(float(p[0]), float(p[2])), 2.5])
	for pk in layout.get("pickups", []):
		var p: Array = pk["pos"]
		_clear.append([Vector2(float(p[0]), float(p[2])), 1.6])
	for s in layout.get("structures", []):
		if s.has("pos"):
			var p: Array = s["pos"]
			_clear.append([Vector2(float(p[0]), float(p[2])), float(s.get("radius", 5.0)) + 1.5])
		elif s.has("a"):
			var a: Array = s["a"]
			var b: Array = s["b"]
			var va := Vector2(float(a[0]), float(a[2]))
			var vb := Vector2(float(b[0]), float(b[2]))
			var n := int(va.distance_to(vb) / 3.0) + 1
			for i in n + 1:
				_clear.append([va.lerp(vb, float(i) / n), float(s.get("width", 3.0)) * 0.5 + 2.0])


func _is_clear(p: Vector2, r: float) -> bool:
	for c in _clear:
		var cc: Vector2 = c[0]
		if cc.distance_to(p) < float(c[1]) + r:
			return false
	return true


## Walkable floors: props cluster toward the edges (paths stay open), big things only at the north edge
## (the gameplay camera looks -Z, so tall props on the south rim would block the view).
func _scatter_floor(t: Node, f: Dictionary, kinds: Array, count: int) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 40:
		tries += 1
		var p := _random_in_shape(f)
		var sd: float = t.floor_sdf(p.x, p.y)
		if sd > -0.4:
			continue
		var kind: String = kinds[_rng.randi() % kinds.size()]
		var tall := kind == "flat_tree" or kind == "rock_spire" or kind == "pillar_broken"
		var edge_t := -sd   # depth inside the floor
		# small props: anywhere off-path but prefer edges; tall: only near the north (-Z) rim
		if tall:
			if edge_t > 3.5:
				continue
			if t.floor_sdf(p.x, p.y - 3.0) < sd:   # deeper toward north means we're on the south rim
				continue
		elif edge_t > 2.0 + _rng.randf() * 5.0 and _rng.randf() < 0.7:
			continue
		if t.chasm_sdf(p.x, p.y) < 3.0:
			continue
		if not _is_clear(p, 1.2 if tall else 0.6):
			continue
		var y: float = t.height_at(p.x, p.y)
		_add(kind, Vector3(p.x, y, p.y), 1.0)
		placed += 1


func _random_in_shape(f: Dictionary) -> Vector2:
	var r := float(f.get("r", 5.0))
	if f.get("type", "disc") == "capsule":
		var a: Array = f["a"]
		var b: Array = f["b"]
		var va := Vector2(float(a[0]), float(a[1]))
		var vb := Vector2(float(b[0]), float(b[1]))
		var base := va.lerp(vb, _rng.randf())
		return base + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * r
	var c: Array = f["c"]
	return Vector2(float(c[0]), float(c[1])) + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * r


## Mesa tops: only where the visual surface is the real top (not the camera-cut south side).
func _scatter_mesa(t: Node, kinds: Array, count: int) -> void:
	var b: Rect2 = t.get_bounds()
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 30:
		tries += 1
		var x := b.position.x + _rng.randf() * b.size.x
		var z := b.position.y + _rng.randf() * b.size.y
		var h: float = t.height_at(x, z)
		var hv: float = t.get_visual_height(x, z)
		if absf(h - hv) > 0.3 or t.get_floor_weight(x, z) > 0.05:
			continue
		if t.floor_sdf(x, z) < 6.0 or t.chasm_sdf(x, z) < 4.0:
			continue
		# flat-ish only
		var gx: float = t.get_visual_height(x + 1.0, z) - t.get_visual_height(x - 1.0, z)
		var gz: float = t.get_visual_height(x, z + 1.0) - t.get_visual_height(x, z - 1.0)
		if absf(gx) + absf(gz) > 1.6:
			continue
		var kind: String = kinds[_rng.randi() % kinds.size()]
		_add(kind, Vector3(x, hv, z), 1.25)
		placed += 1


## A few large trees / spires on the backdrop rim north of the play space (silhouettes in the distance).
func _extra_backdrop_trees(t: Node) -> void:
	var b: Rect2 = t.get_bounds()
	for i in 22:
		var x := b.position.x + 10.0 + _rng.randf() * (b.size.x - 20.0)
		var z := b.position.y + 2.0 + _rng.randf() * 6.0
		if t.chasm_sdf(x, z) < 6.0:
			continue
		var hv: float = t.get_visual_height(x, z)
		var kind := "flat_tree" if _rng.randf() < 0.6 else "rock_spire"
		_add(kind, Vector3(x, hv, z), 1.5)


func _add(kind: String, pos: Vector3, scale_mul: float) -> void:
	if KIND_ITEMS.has(kind):
		var items: Array = KIND_ITEMS[kind]
		var id: String = items[_rng.randi() % items.size()]
		if not _atlas.has(id):
			return
		var it: Dictionary = _atlas[id]
		var px: Array = it["px"]
		var hm := float(it.get("height_m", 2.0)) * _rng.randf_range(0.8, 1.15) * scale_mul
		if hm > 3.0 and _south_of_floor(pos.x, pos.z):
			hm = minf(hm, 2.6) if kind == "rock_small" or kind == "shrub" else 0.0
			if hm <= 0.0:
				return
		var wm := hm * float(px[0]) / float(px[1])
		var xf := Transform3D(Basis().scaled(Vector3(wm, hm, 1.0)), pos + Vector3(0, -0.12, 0))
		var uv: Array = it["uv"]
		var sway := 0.0
		if kind == "shrub" or kind == "lichen_patch":
			sway = 1.0
		elif kind == "flat_tree":
			sway = 0.35
		var col := Color(sway, _rng.randf(), 1.0 if _rng.randf() < 0.5 else 0.0, 1.0)
		_bb.append([xf, col, Color(float(uv[0]), float(uv[1]), float(uv[2]), float(uv[3]))])
	elif kind in MESH_KINDS:
		if not _props.has(kind):
			_props[kind] = []
		var s := _rng.randf_range(0.85, 1.2)
		var xf := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), pos)
		_props[kind].append(xf)


## True when walkable floor lies within 10 m to the north (-Z): anything tall here sits between the
## gameplay camera and the player.
func _south_of_floor(x: float, z: float) -> bool:
	if _t == null:
		return false
	for k in range(3, 11):
		if _t.floor_sdf(x, z - float(k)) < -0.5:
			return true
	return false


func _commit_billboards() -> void:
	if _bb.is_empty():
		return
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.center_offset = Vector3(0, 0.5, 0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = q
	mm.instance_count = _bb.size()
	for i in _bb.size():
		var e: Array = _bb[i]
		mm.set_instance_transform(i, e[0])
		mm.set_instance_color(i, e[1])
		mm.set_instance_custom_data(i, e[2])
	var mat := ShaderMaterial.new()
	mat.shader = ToonKit.occluding_shader(SCATTER_SHADER_PATH)
	mat.set_shader_parameter("atlas", ATLAS_TEX)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "PaintedProps"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-400, -80, -300), Vector3(1200, 200, 600))
	add_child(mmi)


func _commit_props() -> void:
	for kind in _props:
		var mesh := _prop_mesh(kind)
		var list: Array = _props[kind]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Props_" + kind
		mmi.multimesh = mm
		mmi.material_override = ToonKit.material({"outline": 0.03})
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


static func _prop_mesh(kind: String) -> ArrayMesh:
	var st := ToonKit.begin()
	match kind:
		"crate":
			var wood := Color(0.36, 0.33, 0.33)
			ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(1.1, 0.9, 0.8), wood)
			ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.91, 0)), Vector3(1.14, 0.06, 0.84), Color(0.62, 0.12, 0.10))
			ToonKit.box(st, Transform3D(Basis(), Vector3(0.75, 0.3, 0.1)), Vector3(0.6, 0.6, 0.6), Color(0.42, 0.40, 0.38))
		"survey_flag":
			ToonKit.cylinder(st, Vector3(0, 0, 0), Vector3(0, 2.2, 0), 0.05, 0.04, 5, Color(0.30, 0.30, 0.32))
			ToonKit.quad(st, Vector3(0.04, 2.15, 0), Vector3(0.75, 1.98, 0), Vector3(0.75, 1.62, 0), Vector3(0.04, 1.75, 0), Color(0.78, 0.12, 0.10))
			ToonKit.quad(st, Vector3(0.04, 1.75, 0), Vector3(0.75, 1.62, 0), Vector3(0.75, 1.98, 0), Vector3(0.04, 2.15, 0), Color(0.62, 0.09, 0.08))
		"pillar_broken":
			ToonKit.cylinder(st, Vector3(0, -0.3, 0), Vector3(0, 2.4, 0), 0.62, 0.55, 7, Color(0.74, 0.52, 0.40), true, 0.08, 3)
			ToonKit.box(st, Transform3D(Basis(), Vector3(0, -0.1, 0)), Vector3(1.6, 0.4, 1.6), Color(0.66, 0.44, 0.34))
			ToonKit.rock(st, Vector3(1.0, 0.1, 0.6), Vector3(0.5, 0.35, 0.45), Color(0.72, 0.5, 0.38), 5, 0)
		_:
			ToonKit.rock(st, Vector3(0, 0.3, 0), Vector3(0.8, 0.6, 0.7), Color(0.7, 0.36, 0.24), 9, 1)
	return ToonKit.finish(st)
