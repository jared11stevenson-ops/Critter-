extends Node3D
## Red Reaches scatter (Agent 1). Painted props from the Reaches kit as camera-facing billboards in ONE
## MultiMesh (one draw call), plus 3D toon props (crates, survey flags, broken pillars, rock chunks) in one
## MultiMesh per mesh. Placement from layout.json props_scatter; keeps paths, markers and triggers clear.

const MESH_KINDS := ["crate", "survey_flag", "pillar_broken", "rock_a", "rock_b", "rock_c", "spire", "lichen_rock",
	"grass_tuft", "pebbles", "dead_tree"]
## v0.12: EVERY scatter kind is a real 3D mesh now (rocks, spires, trees, shrubs, lichen, bones); the painted card atlas is gone.
const KIND_MESH := {
	"rock_small": ["rock_a", "rock_b", "rock_c", "rock_a", "pebbles"],
	"rock_spire": ["spire"],
	"flat_tree": ["flat_tree_a", "flat_tree_b", "dead_tree"],
	"shrub": ["reach_shrub", "reach_shrub_b", "grass_tuft"],
	"lichen_patch": ["lichen_rock", "grass_tuft"],
	"bone": ["bone_ribs", "bone_horn"],      # v0.12: the painted horn card is now a real 3D bleached ribcage / horn
}

## Legacy kind -> Blender kit piece (res://game/art/world/kit). Kinds not listed stay procedural (grass tuft, pebbles).
const KIT_MAP := {"crate": "dom_stack", "survey_flag": "survey_flag", "pillar_broken": "pillar_broken", "rock_a": "boulder_a",
	"rock_b": "boulder_b", "rock_c": "boulder_c", "spire": "hoodoo_lo", "lichen_rock": "lichen_mat", "dead_tree": "dead_tree",
	"bone_ribs": "bone_ribs", "bone_horn": "bone_ribs", "flat_tree_a": "flat_tree_a", "flat_tree_b": "flat_tree_b",
	"reach_shrub": "reach_shrub", "reach_shrub_b": "reach_shrub_b"}

var _rng := RandomNumberGenerator.new()
var _props: Dictionary = {}  # kind -> Array[Transform3D]
var _clear: Array = []     # [Vector2 center, radius]
var _t: Node
## Spatial chunking (Agent 2 perf pass): every kind is split into CHUNK_X-metre slices along the level so frustum
## culling skips off-screen instances (was one level-wide MultiMesh per kind = every instance drawn + shadowed
## every frame). Instances are shuffled per chunk so `visible_instance_count` thins them evenly for the graphics
## quality scatter density (Quality.scatter_density()).
const CHUNK_X := 32.0
const CHUNK_Z := 32.0
## Visibility range (m, before the quality multiplier) per kind: cover is dropped early (fog hides it), silhouettes stay.
const RANGE := {"grass_tuft": 38.0, "pebbles": 34.0, "lichen_mat": 48.0, "rock_c": 48.0, "rock_a": 64.0, "rock_b": 80.0,
	"reach_shrub": 64.0, "reach_shrub_b": 64.0, "bone_ribs": 52.0, "dead_tree": 100.0, "flat_tree_a": 112.0, "flat_tree_b": 112.0,
	"spire": 120.0, "pillar_broken": 100.0, "survey_flag": 80.0, "crate": 80.0, "lichen_rock": 48.0}
var _mms: Array = []       # [MultiMesh, full count, is_cover]


func populate(t: Node) -> void:
	_rng.seed = 1977
	_t = t
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
	_ground_cover(t, floors)
	_commit_props()
	if OS.get_cmdline_user_args().has("qa"):
		var tot := 0
		var parts: Array = []
		for kind in _props:
			var m: Mesh = ReachesKit.mesh(KIT_MAP[kind]) if KIT_MAP.has(kind) and ReachesKit.available(KIT_MAP[kind]) else null
			var tr := 0
			if m:
				for si in m.get_surface_count():
					tr += m.surface_get_array_index_len(si) / 3
			parts.append("%s=%d(x%d tri)" % [kind, _props[kind].size(), tr])
		print("[PERF] scatter ", ", ".join(parts))


## Scatter density for the graphics quality level. Big silhouettes (trees, spires, pillars) are kept; small cover
## (pebbles, grass, small rocks, shrubs) thins out.
func _apply_density(_lv: int = -1) -> void:
	var q := ToonKit.quality()
	var d: float = q.call("scatter_density") if q else 1.0
	for e in _mms:
		var mm: MultiMesh = e[0]
		var n: int = e[1]
		var k: float = d if e[2] else clampf(d * 1.6, 0.0, 1.0)
		mm.visible_instance_count = -1 if k >= 0.999 else int(ceil(n * k))


## Splits [Transform3D or Array] entries into X slices -> {chunk index: Array}, shuffled deterministically.
func _bucket(list: Array) -> Dictionary:
	var out := {}
	for e in list:
		var xf: Transform3D = e if e is Transform3D else e[0]
		var ci := int(floor(xf.origin.x / CHUNK_X)) + 1000 * int(floor((xf.origin.z + 200.0) / CHUNK_Z))
		if not out.has(ci):
			out[ci] = []
		out[ci].append(e)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for ci in out:
		var a: Array = out[ci]
		for i in range(a.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp: Variant = a[i]
			a[i] = a[j]
			a[j] = tmp
	return out


static func _aabb_of(list: Array, pad: float) -> AABB:
	var first: Transform3D = list[0] if list[0] is Transform3D else list[0][0]
	var box := AABB(first.origin, Vector3.ZERO)
	for e in list:
		var xf: Transform3D = e if e is Transform3D else e[0]
		box = box.expand(xf.origin)
	return box.grow(pad)


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


## Dense grounded cover: pebble clusters and dry grass tufts on every floor (cheap instanced meshes), thicker at the
## floor rims and against cliffs, sparse on the paths.
func _ground_cover(t: Node, floors: Dictionary) -> void:
	for id in floors:
		var f: Dictionary = floors[id]
		var n := 260
		if f.get("type", "disc") == "capsule":
			var a: Array = f["a"]
			var b: Array = f["b"]
			n = int(Vector2(float(a[0]), float(a[1])).distance_to(Vector2(float(b[0]), float(b[1]))) * 6.0) + 120
		for i in n:
			var p := _random_in_shape(f)
			var sd: float = t.floor_sdf(p.x, p.y)
			if sd > -0.2 or t.chasm_sdf(p.x, p.y) < 1.5:
				continue
			if -sd > 3.0 and _rng.randf() < 0.85:
				continue
			if not _is_clear(p, 0.3):
				continue
			var y: float = t.height_at(p.x, p.y)
			var k := "pebbles" if _rng.randf() < 0.45 else "grass_tuft"
			_add_mesh(k, Vector3(p.x, y, p.y), _rng.randf_range(1.1, 1.9) if k == "grass_tuft" else _rng.randf_range(0.9, 1.6))


func _add_mesh(kind: String, pos: Vector3, s: float) -> void:
	if not _props.has(kind):
		_props[kind] = []
	var b := Basis(Vector3.UP, _rng.randf() * TAU)
	if kind.begins_with("rock") or kind == "lichen_rock":
		b = b * Basis(Vector3.RIGHT, _rng.randf_range(-0.25, 0.25))
		pos.y -= 0.15 * s
	_props[kind].append(Transform3D(b.scaled(Vector3(s, s * _rng.randf_range(0.8, 1.2), s)), pos))


func _add(kind: String, pos: Vector3, scale_mul: float) -> void:
	if KIND_MESH.has(kind):
		var opts: Array = KIND_MESH[kind]
		var mk: String = opts[_rng.randi() % opts.size()]
		var s := _rng.randf_range(1.0, 2.2) * scale_mul
		if mk == "grass_tuft":
			s = _rng.randf_range(1.2, 2.0) * scale_mul
		if mk == "bone_ribs" or mk == "bone_horn":
			s = _rng.randf_range(0.9, 1.5) * scale_mul
		if mk == "spire" or mk == "dead_tree" or mk.begins_with("flat_tree"):
			s = _rng.randf_range(0.8, 1.3) * scale_mul * (0.7 if mk == "spire" else 1.0)
			if _south_of_floor(pos.x, pos.z):
				return
		_add_mesh(mk, pos, s)
		return
	if kind in MESH_KINDS:
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


const COVER_KINDS := ["grass_tuft", "pebbles", "rock_c", "lichen_rock", "rock_a", "bone_ribs", "bone_horn", "reach_shrub", "reach_shrub_b"]
const GROUP_M := 40.0           # merge cell (m): one mesh per cell and class ("cover" drops at 52 m, "big" silhouettes at 128 m)
var _groups: Dictionary = {}
var _gkeys: Array = []
var _gresults: Array = []
var _gid := -1
var _joined := false
var _gnext := 0


## v0.14 (environment art pass): scatter is MERGED per 40 m cell into one mesh per material and class (cover / big) instead of
## one MultiMesh per kind per chunk -- 3-4x fewer draw calls -- built on the WorkerThreadPool and attached a few cells per
## frame. Visibility ranges drop cover early (fog hides it) and keep silhouettes; quality density thins instances at build.
func _commit_props() -> void:
	var grass_mat := _grass_material()
	var q := ToonKit.quality()
	var dens: float = q.call("scatter_density") if q else 1.0
	var vr: float = q.call("vis_range_mult") if q else 1.0
	set_meta("vr", vr)
	var kmesh: Dictionary = {}
	for kind in _props:
		var kit_mesh: Mesh = null
		if KIT_MAP.has(kind) and ReachesKit.available(KIT_MAP[kind]):
			kit_mesh = ReachesKit.mesh(KIT_MAP[kind])
		var mesh: Mesh = kit_mesh if kit_mesh else _prop_mesh(kind)
		if kit_mesh == null:
			var mat: Material
			if kind == "grass_tuft":
				mat = grass_mat
			elif kind in ["crate", "survey_flag"]:
				mat = ToonKit.material({"roughness": 0.7, "detail": 0.35})
			else:
				mat = ToonKit.material({"strata": 0.35, "roughness": 0.9})
			for si in mesh.get_surface_count():
				mesh.surface_set_material(si, mat)
		ReachesLandmarks.surfaces_of(mesh)           # warm the CPU-side surface cache on the main thread
		kmesh[kind] = mesh
	_groups.clear()
	for kind in _props:
		var cover: bool = kind in COVER_KINDS
		var k: float = dens if cover else clampf(dens * 1.6, 0.0, 1.0)
		var list: Array = _props[kind]
		for i in list.size():
			if k < 0.999 and fmod(float(i) * 0.6180339, 1.0) > k:
				continue
			var xf: Transform3D = list[i]
			var key := "%d_%d_%d" % [int(floor(xf.origin.x / GROUP_M)), int(floor((xf.origin.z + 200.0) / GROUP_M)), 0 if cover else 1]
			if not _groups.has(key):
				_groups[key] = []
			_groups[key].append({"mesh": kmesh[kind], "xf": xf})
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gkeys = _groups.keys()
	_gresults.clear()
	_gresults.resize(_gkeys.size())
	_gnext = 0
	_joined = false
	_gid = WorkerThreadPool.add_group_task(_merge_cell, _gkeys.size(), -1, true, "scatter_merge")
	set_process(true)


func _merge_cell(i: int) -> void:
	var m := ReachesLandmarks.merge(_groups[_gkeys[i]])
	_gresults[i] = m


func _process(_d: float) -> void:
	if _gid < 0:
		set_process(false)
		return
	if not _joined:
		if not WorkerThreadPool.is_group_task_completed(_gid):
			return
		WorkerThreadPool.wait_for_group_task_completion(_gid)      # joins (frees) the group: the id is invalid afterwards
		_joined = true
	for _k in 4:
		if _gnext >= _gkeys.size():
			break
		var key: String = _gkeys[_gnext]
		_gnext += 1
		var m: ArrayMesh = _gresults[_gnext - 1]
		if m == null:
			continue
		var big := key.ends_with("_1")
		var mi := MeshInstance3D.new()
		mi.name = "Scatter_" + key
		mi.mesh = m
		var vr: float = float(get_meta("vr", 1.0))
		mi.visibility_range_end = ((128.0 if big else 52.0) * vr) + 28.0
		mi.visibility_range_end_margin = 8.0
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		if big:
			var sp := MeshInstance3D.new()          # shadow-only twin, camera range 60 m (keeps far cells out of the sun pass)
			sp.name = "Shadow_" + key
			sp.mesh = m
			sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			sp.visibility_range_end = 46.0
			add_child(sp)
	if _gnext >= _gkeys.size():
		_gid = -1
		_groups.clear()
		set_process(false)


static func _grass_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.rim_enabled = true
	m.rim = 0.4
	m.rim_tint = 0.8
	return m


## Dry grass tuft: ~14 tapered blades, normals pointing up (soft, grass-like lighting), roots dark, tips bleached.
static func _grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 10:
		var a := rng.randf() * TAU
		var r := rng.randf() * 0.12
		var base := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var h := rng.randf_range(0.28, 0.62)
		var lean := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.08, 0.3) + Vector3(rng.randf() - 0.5, 0, rng.randf() - 0.5) * 0.1
		var side := Vector3(-sin(a), 0, cos(a)) * 0.022
		var tip := base + lean + Vector3(0, h, 0)
		var root := Color(0.36, 0.22, 0.14)
		var c := Color(0.86, 0.68, 0.42).lerp(Color(0.74, 0.52, 0.3), rng.randf())
		for v in [[base - side, root], [tip, c], [base + side, root]]:
			st.set_color(v[1])
			st.set_normal(Vector3(0, 1, 0).lerp(Vector3(cos(a), 0, sin(a)), 0.3).normalized())
			st.add_vertex(v[0])
	return st.commit()


static func _prop_mesh(kind: String) -> ArrayMesh:
	if kind == "grass_tuft":
		return _grass_mesh()
	var st := ToonKit.begin()
	match kind:
		"rock_a":
			ToonKit.rock(st, Vector3(0, 0.3, 0), Vector3(0.75, 0.5, 0.6), Color(0.66, 0.36, 0.25), 11, 2)
			ToonKit.rock(st, Vector3(0.6, 0.12, 0.35), Vector3(0.3, 0.22, 0.28), Color(0.58, 0.3, 0.22), 12, 1)
		"rock_b":
			ToonKit.rock(st, Vector3(0, 0.45, 0), Vector3(0.6, 0.75, 0.55), Color(0.72, 0.42, 0.3), 23, 2)
		"rock_c":
			ToonKit.rock(st, Vector3(0, 0.15, 0), Vector3(0.55, 0.25, 0.5), Color(0.62, 0.33, 0.24), 31, 2)
			ToonKit.rock(st, Vector3(-0.5, 0.08, -0.2), Vector3(0.22, 0.14, 0.2), Color(0.7, 0.4, 0.28), 32, 1)
		"lichen_rock":
			ToonKit.rock(st, Vector3(0, 0.25, 0), Vector3(0.65, 0.42, 0.6), Color(0.6, 0.48, 0.3), 41, 2)
			ToonKit.rock(st, Vector3(0, 0.5, 0), Vector3(0.45, 0.12, 0.4), Color(0.56, 0.6, 0.36), 42, 1)
		"spire":
			ToonKit.rock(st, Vector3(0, 1.4, 0), Vector3(0.7, 1.9, 0.65), Color(0.72, 0.38, 0.26), 51, 2)
			ToonKit.rock(st, Vector3(0.1, 3.0, 0.05), Vector3(0.45, 0.8, 0.42), Color(0.8, 0.5, 0.34), 52, 1)
			ToonKit.rock(st, Vector3(0.7, 0.3, 0.3), Vector3(0.5, 0.4, 0.45), Color(0.62, 0.33, 0.24), 53, 1)
		"dead_tree":
			var rng := RandomNumberGenerator.new()
			rng.seed = 71
			var bark := Color(0.42, 0.32, 0.27)
			ToonKit.cylinder(st, Vector3(0, -0.2, 0), Vector3(0.15, 2.2, 0.05), 0.24, 0.13, 7, bark, true, 0.04, 7)
			for i in 5:
				var a := float(i) * 2.4 + rng.randf()
				var y0 := 1.3 + rng.randf() * 0.9
				var p0 := Vector3(0.1, y0, 0.03)
				var p1 := p0 + Vector3(cos(a) * 1.1, 0.7 + rng.randf() * 0.6, sin(a) * 1.1)
				ToonKit.cylinder(st, p0, p1, 0.09, 0.04, 5, bark.lightened(0.08), false)
				ToonKit.cylinder(st, p1, p1 + Vector3(cos(a + 0.7) * 0.5, 0.45, sin(a + 0.7) * 0.5), 0.04, 0.015, 4, bark.lightened(0.15), false)
			ToonKit.rock(st, Vector3(0, 0.0, 0), Vector3(0.5, 0.2, 0.5), Color(0.55, 0.32, 0.24), 72, 1)
		"bone_ribs":
			# half-buried ribcage: a spine and five tapering ribs arching over it
			var bone := Color(0.86, 0.80, 0.68)
			ToonKit.cylinder(st, Vector3(-1.1, 0.12, 0), Vector3(1.1, 0.2, 0.05), 0.07, 0.06, 5, bone.darkened(0.08), true)
			for i in 5:
				var x := -0.85 + float(i) * 0.42
				var prev := Vector3(x, 0.15, 0.0)
				for j in 6:
					var a := PI * float(j + 1) / 6.0
					var cur := Vector3(x + float(j) * 0.015, 0.15 + sin(a) * (0.75 - absf(float(i) - 2.0) * 0.08), -cos(a) * 0.62)
					ToonKit.cylinder(st, prev, cur, 0.055 * (1.0 - float(j) * 0.1), 0.05 * (1.0 - float(j + 1) * 0.1), 4, bone.lightened(0.02 * float(j)), false)
					prev = cur
		"bone_horn":
			# curved horn standing out of the dust
			var horn := Color(0.82, 0.76, 0.62)
			var hp := Vector3(0, -0.1, 0)
			for j in 6:
				var a2 := float(j) / 6.0
				var np := Vector3(sin(a2 * 1.6) * 0.55, -0.1 + a2 * 1.7, 0)
				ToonKit.cylinder(st, hp, np, 0.17 * (1.0 - a2 * 0.9), 0.17 * (1.0 - (a2 + 0.166) * 0.9), 6, horn.darkened(0.04 * float(j)), j == 0)
				hp = np
		"pebbles":
			var rng := RandomNumberGenerator.new()
			rng.seed = 61
			for i in 3:
				var c := Vector3(rng.randf_range(-0.4, 0.4), 0.02, rng.randf_range(-0.4, 0.4))
				var r := rng.randf_range(0.05, 0.13)
				ToonKit.rock(st, c, Vector3(r, r * 0.6, r * 0.9), Color(0.78, 0.5, 0.36).lerp(Color(0.6, 0.38, 0.3), rng.randf()), 62 + i, 0)
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
