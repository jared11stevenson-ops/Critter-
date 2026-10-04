class_name RedReachesTerrain
extends Node3D
## Red Reaches world builder (Agent 1, CONTRACTS §6).
## Reads layout.json and builds: toon terrain mesh (chunked) + HeightMapShape3D collision (layer 1),
## distant backdrop mesas, sky/environment/sun, MultiMesh scatter, and the scripted structures.
##
## Height model (meters, see layout.json _doc):
##   inside a floor shape  -> the floor height (soft-min blended between overlapping floors)
##   outside               -> two-tier mesa cliff (lower tier over edge_width, upper tier set back) up to
##                            mesa_height + terraced noise
##   chasm shapes          -> chasm_depth (override)
## Visual-only "camera cut": terrain on the camera side (+Z) of a floor is capped low so the gameplay camera
## (yaw 0, pitch -40, 14 m) never looks through a cliff. Collision keeps the full walls.

signal built

const LAYOUT_PATH := "res://game/world/red_reaches/layout.json"
const TERRAIN_SHADER := preload("res://game/art/shaders/terrain_pbr.gdshader")
const PBR_DIR := "res://game/art/world/pbr/"
const CHUNK := 48   # 48 m chunks: tighter frustum culling + shadow-pass culling (was 64)

@export var layout_path: String = LAYOUT_PATH
@export var with_lighting: bool = true
@export var with_scatter: bool = true
@export var with_structures: bool = true
@export var with_backdrop: bool = true
@export var with_collision: bool = true

var layout: Dictionary = {}
var lighting: Node3D
var terrain_material: ShaderMaterial

var _built := false
var _min_x := 0.0
var _min_z := 0.0
var _cell := 1.0
var _nx := 0
var _nz := 0
var _h := PackedFloat32Array()      # collision heights (full walls)
var _hv := PackedFloat32Array()     # visual heights (camera cut)
var _fw := PackedFloat32Array()     # walkable floor weight 0..1
var _sw := PackedFloat32Array()     # stone paving weight 0..1
var _floors: Array = []
var _chasms: Array = []
var _structures: Dictionary = {}
var _markers: Dictionary = {}
var _decks: Array = []              # [{a: Vector3, b: Vector3, width: float, node: Node3D}]
var _n_edge := FastNoiseLite.new()
var _n_mesa := FastNoiseLite.new()
var _n_tier := FastNoiseLite.new()
var _n_fine := FastNoiseLite.new()


func _ready() -> void:
	build()


# ======================================================================== public API (CONTRACTS §6)

func build() -> void:
	if _built:
		return
	_built = true
	_load_layout()
	_setup_noise()
	_compute_heights()
	_build_terrain_meshes()
	if with_collision:
		_build_collision()
	if with_backdrop:
		_build_backdrop()
	if with_lighting:
		_build_lighting()
	if with_structures:
		_build_structures()
	if with_scatter:
		_build_scatter()
	built.emit()


func height_at(x: float, z: float) -> float:
	if _h.is_empty():
		build()
	var best := _sample(_h, x, z)
	for d in _decks:
		var node: Node3D = d["node"]
		if node != null and is_instance_valid(node) and not node.visible:
			continue
		var a: Vector3 = d["a"]
		var b: Vector3 = d["b"]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var ap := Vector2(x - a.x, z - a.z)
		var L2 := ab.length_squared()
		if L2 < 0.001:
			continue
		var t := ap.dot(ab) / L2
		if t < 0.0 or t > 1.0:
			continue
		var perp := absf(ap.cross(ab)) / sqrt(L2)
		if perp <= float(d["width"]) * 0.5:
			var deck_y := lerpf(a.y, b.y, t) - float(d.get("sag", 0.0)) * sin(t * PI)
			best = maxf(best, deck_y)
	return best


func get_marker(marker_name: String) -> Vector3:
	if layout.is_empty():
		_load_layout()
	if _markers.has(marker_name):
		var m: Array = _markers[marker_name]
		return Vector3(float(m[0]), float(m[1]), float(m[2]))
	for s in layout.get("structures", []):
		if s.get("id", "") == marker_name and s.has("pos"):
			var p: Array = s["pos"]
			return Vector3(float(p[0]), float(p[1]), float(p[2]))
	for tr in layout.get("triggers", []):
		if tr.get("id", "") == marker_name and tr.has("pos"):
			var p: Array = tr["pos"]
			return Vector3(float(p[0]), float(p[1]), float(p[2]))
	push_warning("RedReachesTerrain: unknown marker " + marker_name)
	return Vector3.ZERO


func get_structure(id: String) -> Node3D:
	if not _built:
		build()
	return _structures.get(id, null)


func set_rope_span_visible(on: bool) -> void:
	var s := get_structure("rope_span")
	if s and s.has_method("set_unrolled"):
		s.set_unrolled(on)


func break_boulder() -> void:
	var s := get_structure("thought_boulder")
	if s and s.has_method("shatter"):
		s.shatter()


func shake_span(intensity: float) -> void:
	var s := get_structure("ochre_span")
	if s and s.has_method("shake"):
		s.shake(intensity)


func set_span_state(state: String) -> void:
	var s := get_structure("ochre_span")
	if s and s.has_method("set_state"):
		s.set_state(state)


## Extra helpers (art/QA)
func get_floor_weight(x: float, z: float) -> float:
	return _sample(_fw, x, z)


func get_visual_height(x: float, z: float) -> float:
	return _sample(_hv, x, z)


func get_bounds() -> Rect2:
	return Rect2(_min_x, _min_z, (_nx - 1) * _cell, (_nz - 1) * _cell)


func floor_sdf(x: float, z: float) -> float:
	var r := _floor_eval(x, z)
	return r[0]


func chasm_sdf(x: float, z: float) -> float:
	var best := 1e9
	for c in _chasms:
		best = minf(best, _shape_sdf(c, x, z))
	return best


func register_deck(a: Vector3, b: Vector3, width: float, node: Node3D, sag: float = 0.0) -> void:
	_decks.append({"a": a, "b": b, "width": width, "node": node, "sag": sag})


# ======================================================================== layout / shapes

func _load_layout() -> void:
	if not layout.is_empty():
		return
	var txt := FileAccess.get_file_as_string(layout_path)
	var parsed: Variant = JSON.parse_string(txt)
	if not (parsed is Dictionary):
		push_error("RedReachesTerrain: cannot parse " + layout_path)
		layout = {"bounds": {"min_x": -20, "max_x": 20, "min_z": -20, "max_z": 20}, "floors": [], "chasms": []}
	else:
		layout = parsed
	_markers = layout.get("markers", {})
	_floors = layout.get("floors", [])
	_chasms = layout.get("chasms", [])
	var b: Dictionary = layout.get("bounds", {})
	_cell = float(layout.get("cell_size", 1.0))
	_min_x = float(b.get("min_x", -20))
	_min_z = float(b.get("min_z", -20))
	_nx = int(round((float(b.get("max_x", 20)) - _min_x) / _cell)) + 1
	_nz = int(round((float(b.get("max_z", 20)) - _min_z) / _cell)) + 1


func _setup_noise() -> void:
	_n_edge.seed = 11
	_n_edge.frequency = 0.09
	_n_edge.fractal_octaves = 2
	_n_mesa.seed = 23
	_n_mesa.frequency = 0.022
	_n_mesa.fractal_octaves = 3
	_n_tier.seed = 37
	_n_tier.frequency = 0.05
	_n_fine.seed = 41
	_n_fine.frequency = 0.25
	_n_fine.fractal_octaves = 1


static func _shape_sdf(s: Dictionary, x: float, z: float) -> float:
	if s.get("type", "disc") == "capsule":
		var a: Array = s["a"]
		var b: Array = s["b"]
		var ax := float(a[0])
		var az := float(a[1])
		var abx := float(b[0]) - ax
		var abz := float(b[1]) - az
		var L2 := abx * abx + abz * abz
		var t := 0.0
		if L2 > 0.0:
			t = clampf(((x - ax) * abx + (z - az) * abz) / L2, 0.0, 1.0)
		var dx := x - (ax + abx * t)
		var dz := z - (az + abz * t)
		return sqrt(dx * dx + dz * dz) - float(s["r"])
	var c: Array = s["c"]
	var ex := x - float(c[0])
	var ez := z - float(c[1])
	return sqrt(ex * ex + ez * ez) - float(s["r"])


static func _shape_h(s: Dictionary, x: float, z: float) -> float:
	if s.get("type", "disc") == "capsule":
		var a: Array = s["a"]
		var b: Array = s["b"]
		var abx := float(b[0]) - float(a[0])
		var abz := float(b[1]) - float(a[1])
		var L2 := abx * abx + abz * abz
		var t := 0.0
		if L2 > 0.0:
			t = clampf(((x - float(a[0])) * abx + (z - float(a[1])) * abz) / L2, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t) * 0.35 + t * 0.65    # eased ramps
		return lerpf(float(s.get("h_a", 0.0)), float(s.get("h_b", 0.0)), t)
	return float(s.get("h", 0.0))


## [min_sdf, blended floor height, stone weight]
func _floor_eval(x: float, z: float) -> Array:
	var sds: Array = []
	var mn := 1e9
	for f in _floors:
		var d := _shape_sdf(f, x, z)
		sds.append(d)
		mn = minf(mn, d)
	var wsum := 0.0
	var hsum := 0.0
	var ssum := 0.0
	for i in _floors.size():
		var d: float = sds[i]
		if d > mn + 6.0:
			continue
		var w := exp(-(d - mn) / 1.3)
		wsum += w
		hsum += w * _shape_h(_floors[i], x, z)
		ssum += w * (1.0 if _floors[i].get("surface", "dirt") == "stone" else 0.0)
	if wsum <= 0.0:
		return [mn, 0.0, 0.0]
	return [mn, hsum / wsum, ssum / wsum]


func _mesa_height(x: float, z: float) -> float:
	var base := float(layout.get("mesa_height", 12.0))
	var v := (_n_mesa.get_noise_2d(x, z) * 0.5 + 0.5) * 9.0
	var step_h := 2.6
	var t := v / step_h
	var fl := floorf(t)
	var fr := t - fl
	return base - 1.5 + (fl + smoothstep(0.7, 1.0, fr)) * step_h


func _height(x: float, z: float) -> Array:
	var fe := _floor_eval(x, z)
	var sd: float = fe[0]
	var fh: float = fe[1]
	var edge := float(layout.get("edge_width", 4.0))
	var en := (_n_edge.get_noise_2d(x, z) * 0.5 + 0.5)
	var s := sd - en * 1.3 + 0.35
	var h := fh
	if s > 0.0:
		var mh := _mesa_height(x, z)
		var tier_a := 0.42 + 0.3 * (_n_tier.get_noise_2d(x, z) * 0.5 + 0.5)
		var lower := smoothstep(0.0, edge, s) * tier_a
		var upper := smoothstep(edge + 1.0, edge + 4.0 + en * 3.0, s) * (1.0 - tier_a)
		h = lerpf(fh, maxf(mh, fh + 6.0), lower + upper)
		h += _n_fine.get_noise_2d(x, z) * 0.35 * smoothstep(0.0, 2.0, s)
	elif s > -2.0:
		h += _n_fine.get_noise_2d(x, z) * 0.06
	var fw := 1.0 - smoothstep(-0.6, 0.6, s)
	# chasms override
	var cs := 1e9
	for c in _chasms:
		cs = minf(cs, _shape_sdf(c, x, z))
	cs += _n_edge.get_noise_2d(x * 1.7, z * 1.7) * 0.7
	if cs < 1.4:
		var k := smoothstep(1.4, -0.8, cs)
		h = lerpf(h, float(layout.get("chasm_depth", -40.0)) + _n_fine.get_noise_2d(x, z) * 2.0, k)
		fw *= 1.0 - smoothstep(0.0, 0.5, k)
	return [h, fw, float(fe[2]) * fw]


func _compute_heights() -> void:
	var n := _nx * _nz
	_h.resize(n)
	_hv.resize(n)
	_fw.resize(n)
	_sw.resize(n)
	for iz in _nz:
		var z := _min_z + iz * _cell
		for ix in _nx:
			var x := _min_x + ix * _cell
			var r := _height(x, z)
			var i := iz * _nx + ix
			_h[i] = r[0]
			_fw[i] = r[1]
			_sw[i] = r[2]
	_hv = _h.duplicate()
	# camera cut: scan each column north -> south
	for ix in _nx:
		var zf := -1e9
		var hf := 0.0
		for iz in _nz:
			var i := iz * _nx + ix
			var z := _min_z + iz * _cell
			if _fw[i] > 0.5:
				zf = z
				hf = _h[i]
				continue
			if zf < -1e8:
				continue
			var dz := z - zf
			var cap := hf + 1.2 + smoothstep(0.0, 2.0, dz) * 1.0 + maxf(0.0, dz - 3.0) * 0.22
			if _hv[i] > cap:
				_hv[i] = cap + (_hv[i] - cap) * 0.04


func _sample(arr: PackedFloat32Array, x: float, z: float) -> float:
	if arr.is_empty():
		return 0.0
	var fx := clampf((x - _min_x) / _cell, 0.0, float(_nx - 1) - 0.001)
	var fz := clampf((z - _min_z) / _cell, 0.0, float(_nz - 1) - 0.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var i := iz * _nx + ix
	var a := lerpf(arr[i], arr[i + 1], tx)
	var b := lerpf(arr[i + _nx], arr[i + _nx + 1], tx)
	return lerpf(a, b, tz)


# ======================================================================== meshes

func _make_material() -> ShaderMaterial:
	if terrain_material:
		return terrain_material
	terrain_material = ShaderMaterial.new()
	var q := ToonKit.quality()
	terrain_material.shader = q.call("shader", TERRAIN_SHADER.resource_path, TERRAIN_SHADER.code) if q else TERRAIN_SHADER
	for set_name in ["dirt", "flag", "scrub", "cliff"]:
		var file: String = {"dirt": "ground_dirt", "flag": "ground_flag", "scrub": "scrub", "cliff": "cliff_rock"}[set_name]
		terrain_material.set_shader_parameter(set_name + "_albedo", load(PBR_DIR + file + "_albedo.webp"))
		terrain_material.set_shader_parameter(set_name + "_normal", load(PBR_DIR + file + "_normal.webp"))
	terrain_material.set_shader_parameter("macro_tex", load(PBR_DIR + "macro_var.webp"))
	return terrain_material


func _hv_at(ix: int, iz: int) -> float:
	ix = clampi(ix, 0, _nx - 1)
	iz = clampi(iz, 0, _nz - 1)
	return _hv[iz * _nx + ix]


func _build_terrain_meshes() -> void:
	var root := Node3D.new()
	root.name = "TerrainMesh"
	add_child(root)
	var mat := _make_material()
	# per-vertex normals + colours
	var n := _nx * _nz
	var normals := PackedVector3Array()
	normals.resize(n)
	var colors := PackedColorArray()
	colors.resize(n)
	for iz in _nz:
		for ix in _nx:
			var i := iz * _nx + ix
			var hl := _hv_at(ix - 1, iz)
			var hr := _hv_at(ix + 1, iz)
			var hd := _hv_at(ix, iz - 1)
			var hu := _hv_at(ix, iz + 1)
			normals[i] = Vector3(hl - hr, 2.0 * _cell, hd - hu).normalized()
			var avg := (hl + hr + hd + hu) * 0.25
			var lap := _hv[i] - avg
			var crest := clampf((lap - 0.5) * 0.4, 0.0, 0.8)
			# cavity: concave spots + the foot of cliffs (floor cells next to much higher terrain)
			var ao := clampf((-lap - 0.3) * 0.18, 0.0, 0.6)
			var hmax := maxf(maxf(hl, hr), maxf(hd, hu))
			for r in [2, 3]:
				hmax = maxf(hmax, maxf(_hv_at(ix - r, iz), _hv_at(ix + r, iz)))
				hmax = maxf(hmax, maxf(_hv_at(ix, iz - r), _hv_at(ix, iz + r)))
			ao = maxf(ao, clampf((hmax - _hv[i] - 0.8) * 0.12, 0.0, 0.55) * _fw[i])
			colors[i] = Color(_sw[i], _fw[i], crest, ao)
	var cx := int(ceil(float(_nx - 1) / CHUNK))
	var cz := int(ceil(float(_nz - 1) / CHUNK))
	for c_z in cz:
		for c_x in cx:
			var x0 := c_x * CHUNK
			var z0 := c_z * CHUNK
			var x1 := mini(x0 + CHUNK, _nx - 1)
			var z1 := mini(z0 + CHUNK, _nz - 1)
			var w := x1 - x0 + 1
			var verts := PackedVector3Array()
			var nrm := PackedVector3Array()
			var col := PackedColorArray()
			var idx := PackedInt32Array()
			for iz in range(z0, z1 + 1):
				for ix in range(x0, x1 + 1):
					var i := iz * _nx + ix
					verts.append(Vector3(_min_x + ix * _cell, _hv[i], _min_z + iz * _cell))
					nrm.append(normals[i])
					col.append(colors[i])
			for iz in range(z1 - z0):
				for ix in range(x1 - x0):
					var a := iz * w + ix
					var b := a + 1
					var c := a + w
					var d := c + 1
					# split along the shorter diagonal for nicer cliffs
					var ha := verts[a].y
					var hb := verts[b].y
					var hc := verts[c].y
					var hd := verts[d].y
					if absf(ha - hd) < absf(hb - hc):
						idx.append_array([a, b, d, a, d, c])
					else:
						idx.append_array([a, b, c, b, d, c])
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts
			arrays[Mesh.ARRAY_NORMAL] = nrm
			arrays[Mesh.ARRAY_COLOR] = col
			arrays[Mesh.ARRAY_INDEX] = idx
			var am := ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var mi := MeshInstance3D.new()
			mi.name = "Chunk_%d_%d" % [c_x, c_z]
			mi.mesh = am
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(mi)


func _build_collision() -> void:
	var sb := StaticBody3D.new()
	sb.name = "TerrainBody"
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var hm := HeightMapShape3D.new()
	hm.map_width = _nx
	hm.map_depth = _nz
	hm.map_data = _h
	cs.shape = hm
	cs.position = Vector3(_min_x + (_nx - 1) * _cell * 0.5, 0.0, _min_z + (_nz - 1) * _cell * 0.5)
	if absf(_cell - 1.0) > 0.001:
		cs.scale = Vector3(_cell, 1.0, _cell)
	sb.add_child(cs)
	add_child(sb)


## Distant mesas, buttes and canyons around the playable bounds (visual only, coarse grid).
func _build_backdrop() -> void:
	var step := 4.0
	var mx0 := _min_x - 180.0
	var mx1 := _min_x + (_nx - 1) * _cell + 180.0
	var mz0 := _min_z - 160.0
	var mz1 := _min_z + (_nz - 1) * _cell + 70.0
	var bx := int((mx1 - mx0) / step) + 1
	var bz := int((mz1 - mz0) / step) + 1
	var inner := Rect2(_min_x + 3.0, _min_z + 3.0, (_nx - 1) * _cell - 6.0, (_nz - 1) * _cell - 6.0)
	var hs := PackedFloat32Array()
	hs.resize(bx * bz)
	var nb := FastNoiseLite.new()
	nb.seed = 77
	nb.frequency = 0.012
	nb.fractal_octaves = 3
	var nbut := FastNoiseLite.new()
	nbut.seed = 78
	nbut.frequency = 0.03
	var max_z := _min_z + (_nz - 1) * _cell
	for iz in bz:
		var z := mz0 + iz * step
		for ix in bx:
			var x := mx0 + ix * step
			var h: float
			if inner.has_point(Vector2(x, z)):
				h = _sample(_hv, x, z) - 2.0
			else:
				var v := nb.get_noise_2d(x, z) * 0.5 + 0.5
				var mesa := _mesa_height(x, z) + v * 10.0
				var dn := maxf(0.0, _min_z - z)
				mesa += dn * 0.12                      # rising far wall in the north
				# buttes / canyons pattern
				var but := nbut.get_noise_2d(x, z)
				var low := -14.0 + v * 6.0
				var k := smoothstep(-0.05, 0.1, but + (v - 0.5) * 0.4)
				h = lerpf(low, mesa, k)
				if z > max_z:
					# camera side stays low so cinematic cameras see over it
					h = lerpf(h, -16.0 + v * 4.0, smoothstep(max_z, max_z + 12.0, z))
				# chasms continue through the backdrop as canyons
				for c in _chasms:
					var cc: Dictionary = c
					if cc.get("type", "") == "capsule":
						var a: Array = cc["a"]
						var d := absf(x - float(a[0]))
						if d < float(cc["r"]) + 2.0:
							h = lerpf(h, -40.0, smoothstep(float(cc["r"]) + 2.0, float(cc["r"]) - 1.0, d))
				# blend into the playable edge
				var ex := maxf(maxf(_min_x - x, x - (_min_x + (_nx - 1) * _cell)), maxf(_min_z - z, z - max_z))
				if ex < 10.0:
					h = lerpf(_sample(_hv, x, z), h, smoothstep(0.0, 10.0, ex))
			hs[iz * bx + ix] = h
	var verts := PackedVector3Array()
	var nrm := PackedVector3Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()
	for iz in bz:
		for ix in bx:
			var i := iz * bx + ix
			var hl := hs[iz * bx + maxi(ix - 1, 0)]
			var hr := hs[iz * bx + mini(ix + 1, bx - 1)]
			var hd := hs[maxi(iz - 1, 0) * bx + ix]
			var hu := hs[mini(iz + 1, bz - 1) * bx + ix]
			verts.append(Vector3(mx0 + ix * step, hs[i], mz0 + iz * step))
			nrm.append(Vector3(hl - hr, 2.0 * step, hd - hu).normalized())
			col.append(Color(0, 0, 0, 0))
	for iz in bz - 1:
		for ix in bx - 1:
			var x := mx0 + ix * step
			var z := mz0 + iz * step
			if inner.has_point(Vector2(x, z)) and inner.has_point(Vector2(x + step, z + step)):
				continue
			var a := iz * bx + ix
			idx.append_array([a, a + 1, a + bx + 1, a, a + bx + 1, a + bx])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = nrm
	arrays[Mesh.ARRAY_COLOR] = col
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "Backdrop"
	mi.mesh = am
	mi.material_override = _make_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_lighting() -> void:
	var L := load("res://game/world/common/world_lighting.gd")
	lighting = L.new()
	lighting.name = "Lighting"
	lighting.set("preset", "reaches")
	lighting.set("zone_blend", true)
	add_child(lighting)


func _build_structures() -> void:
	if not ResourceLoader.exists("res://game/art/world/reaches_structures.gd"):
		return
	var S: GDScript = load("res://game/art/world/reaches_structures.gd")
	if S == null:
		return
	var root := Node3D.new()
	root.name = "Structures"
	add_child(root)
	for spec in layout.get("structures", []):
		var node: Node3D = S.build(spec, self)
		if node == null:
			continue
		node.name = str(spec.get("id", "structure"))
		root.add_child(node)
		if node.has_method("on_added"):
			node.on_added(self)
		_structures[str(spec.get("id", ""))] = node


func _build_scatter() -> void:
	if not ResourceLoader.exists("res://game/art/world/reaches_scatter.gd"):
		return
	var S: GDScript = load("res://game/art/world/reaches_scatter.gd")
	if S == null:
		return
	var sc: Node3D = S.new()
	sc.name = "Scatter"
	add_child(sc)
	sc.populate(self)
