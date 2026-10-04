extends Node3D
## Fallback Red Reaches terrain (Agent 2). Used only when Agent 1's terrain_builder.gd is absent.
## Implements the CONTRACTS §6 terrain API with simple flat-shaded meshes + heightmap collision
## built from layout.json floors/chasms, plus placeholder structures.

const LAYOUT := "res://game/world/red_reaches/layout.json"

var layout: Dictionary = {}
var _built := false
var _structures: Dictionary = {}
var _rope_body: StaticBody3D = null
var _span_root: Node3D = null
var _span_mat: StandardMaterial3D = null
var _floors: Array = []
var _chasms: Array = []
var _mesa := 12.0
var _chasm_d := -40.0
var _edge := 4.0

func _ready() -> void:
	build()

func build() -> void:
	if _built:
		return
	_built = true
	var f := FileAccess.open(LAYOUT, FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			layout = d
	_floors = layout.get("floors", [])
	_chasms = layout.get("chasms", [])
	_mesa = float(layout.get("mesa_height", 12.0))
	_chasm_d = float(layout.get("chasm_depth", -40.0))
	_edge = float(layout.get("edge_width", 4.0))
	_build_environment()
	_build_ground()
	_build_structures()

# ---------------- height function ----------------
static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Array:
	var ab := b - a
	var t := 0.0
	if ab.length_squared() > 0.0001:
		t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return [p.distance_to(a + ab * t), t]

func _shape_dist(s: Dictionary, p: Vector2) -> Array:
	# returns [signed distance to edge (negative inside), floor height]
	if s.get("type", "disc") == "disc":
		var c: Array = s["c"]
		return [p.distance_to(Vector2(c[0], c[1])) - float(s["r"]), float(s.get("h", 0.0))]
	var a: Array = s["a"]
	var b: Array = s["b"]
	var r := _seg_dist(p, Vector2(a[0], a[1]), Vector2(b[0], b[1]))
	var h := lerpf(float(s.get("h_a", 0.0)), float(s.get("h_b", 0.0)), float(r[1]))
	return [float(r[0]) - float(s["r"]), h]

func _noise(x: float, z: float) -> float:
	return sin(x * 0.21 + z * 0.13) * 0.9 + sin(x * 0.07 - z * 0.31) * 1.3 + sin(x * 0.5 + z * 0.45) * 0.3

func raw_height(x: float, z: float) -> float:
	var p := Vector2(x, z)
	for c in _chasms:
		var r := _shape_dist(c, p)
		if float(r[0]) < 0.0:
			return _chasm_d
	var best := _mesa + _noise(x, z)
	for fl in _floors:
		var r2 := _shape_dist(fl, p)
		var d := float(r2[0])
		var h := float(r2[1])
		var v: float
		if d <= 0.0:
			v = h
		elif d < _edge:
			var k := d / _edge
			k = k * k * (3.0 - 2.0 * k)
			v = lerpf(h, best, k)
		else:
			continue
		best = minf(best, v)
	return best

func height_at(x: float, z: float) -> float:
	return raw_height(x, z)

func surface_at(x: float, z: float) -> String:
	var p := Vector2(x, z)
	for fl in _floors:
		var r := _shape_dist(fl, p)
		if float(r[0]) <= 0.5:
			return str(fl.get("surface", "dirt"))
	return "mesa"

# ---------------- build ----------------
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#5d7fa3")
	sm.sky_horizon_color = Color("#e8b483")
	sm.ground_bottom_color = Color("#3a2018")
	sm.ground_horizon_color = Color("#c88a5a")
	sm.sun_angle_max = 30.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#a08070")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.9
	env.fog_enabled = true
	env.fog_density = 0.0025
	env.fog_light_color = Color("#d9a27a")
	env.fog_density = 0.004
	env.glow_enabled = false
	env.glow_intensity = 0.5
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -35, 0)
	sun.light_color = Color("#ffe2bf")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)
	if ToonKit.quality():
		ToonKit.quality().call("setup_sun", sun, 60.0)

func _color_for(x: float, z: float, h: float) -> Color:
	if h < -12.0:
		return Color("#3a1d16").lerp(Color("#1c0f0c"), clampf((-12.0 - h) / 20.0, 0.0, 1.0))
	var s := surface_at(x, z)
	match s:
		"stone":
			return Color("#9c7352").lerp(Color("#86603f"), 0.5 + 0.5 * sin(x * 0.7) * sin(z * 0.6))
		"dirt":
			return Color("#a8553a").lerp(Color("#8e4129"), 0.5 + 0.5 * sin(x * 0.3 + z * 0.2))
	# mesa cliffs: strata bands
	var band := 0.5 + 0.5 * sin(h * 2.2)
	var c := Color("#9c3f25").lerp(Color("#d07a45"), band)
	if h > _mesa - 1.5:
		c = Color("#b5643a").lerp(Color("#8a4a2a"), 0.5 + 0.5 * sin(x * 0.4 + z * 0.3))
	return c

func _build_ground() -> void:
	var b: Dictionary = layout.get("bounds", {"min_x": -24, "max_x": 348, "min_z": -48, "max_z": 48})
	var x0 := float(b["min_x"])
	var x1 := float(b["max_x"])
	var z0 := float(b["min_z"])
	var z1 := float(b["max_z"])
	# --- collision heightmap (1 m) ---
	var w := int(x1 - x0) + 1
	var dpt := int(z1 - z0) + 1
	var data := PackedFloat32Array()
	data.resize(w * dpt)
	for iz in dpt:
		for ix in w:
			data[iz * w + ix] = raw_height(x0 + ix, z0 + iz)
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var hm := HeightMapShape3D.new()
	hm.map_width = w
	hm.map_depth = dpt
	hm.map_data = data
	cs.shape = hm
	cs.position = Vector3(x0 + (w - 1) * 0.5, 0, z0 + (dpt - 1) * 0.5)
	body.add_child(cs)
	add_child(body)
	# --- visual mesh (2 m, flat shaded, vertex colours) ---
	var step := 2.0
	var nx := int((x1 - x0) / step)
	var nz := int((z1 - z0) / step)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hs := PackedFloat32Array()
	hs.resize((nx + 1) * (nz + 1))
	for iz in nz + 1:
		for ix in nx + 1:
			hs[iz * (nx + 1) + ix] = raw_height(x0 + ix * step, z0 + iz * step)
	for iz in nz:
		for ix in nx:
			var xa := x0 + ix * step
			var za := z0 + iz * step
			var h00 := hs[iz * (nx + 1) + ix]
			var h10 := hs[iz * (nx + 1) + ix + 1]
			var h01 := hs[(iz + 1) * (nx + 1) + ix]
			var h11 := hs[(iz + 1) * (nx + 1) + ix + 1]
			var p00 := Vector3(xa, h00, za)
			var p10 := Vector3(xa + step, h10, za)
			var p01 := Vector3(xa, h01, za + step)
			var p11 := Vector3(xa + step, h11, za + step)
			_tri(st, p00, p10, p11)
			_tri(st, p00, p11, p01)
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "TerrainMesh"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (c - a).cross(b - a).normalized()
	if n.y < 0.0:
		n = -n
		var t := b
		b = c
		c = t
	var cen := (a + b + c) / 3.0
	var col := _color_for(cen.x, cen.z, cen.y)
	# darker on steep faces for readable cliffs
	col = col.darkened(clampf(1.0 - n.y, 0.0, 1.0) * 0.35)
	st.set_color(col)
	st.set_normal(n)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

func _toon(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.roughness = 0.9
	return m

func _box_body(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, layer: int = 1) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = layer
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	sb.add_child(mi)
	parent.add_child(sb)
	sb.position = pos
	return sb

func _build_structures() -> void:
	for s in layout.get("structures", []):
		var id: String = s.get("id", "")
		var root := Node3D.new()
		root.name = id
		add_child(root)
		_structures[id] = root
		match s.get("kind", ""):
			"gate_ring":
				var p: Array = s["pos"]
				root.position = Vector3(p[0], p[1], p[2])
				root.rotation_degrees.y = float(s.get("rot_y", 0))
				var tm := TorusMesh.new()
				tm.inner_radius = 3.4
				tm.outer_radius = 4.2
				var mi := MeshInstance3D.new()
				mi.mesh = tm
				mi.rotation_degrees.x = 90
				mi.position.y = 4.2
				var gm := _toon(Color("#5a6470"))
				gm.emission_enabled = true
				gm.emission = Color(0.3, 0.7, 0.9) * 0.6
				mi.material_override = gm
				root.add_child(mi)
			"rope_bridge":
				var a: Array = s["a"]
				var bb: Array = s["b"]
				var va := Vector3(a[0], a[1], a[2])
				var vb := Vector3(bb[0], bb[1], bb[2])
				var len := va.distance_to(vb)
				var mid := (va + vb) * 0.5
				root.position = mid
				var dd := vb - va
				root.rotation = Vector3(0, atan2(-dd.z, dd.x), atan2(dd.y, Vector2(dd.x, dd.z).length()))
				_rope_body = _box_body(root, Vector3(len + 1.0, 0.3, float(s.get("width", 2.6))), Vector3(0, -0.15, 0), _toon(Color("#8a6a42")))
				for side in [-1.0, 1.0]:
					var rope := MeshInstance3D.new()
					var cm := CylinderMesh.new()
					cm.top_radius = 0.05
					cm.bottom_radius = 0.05
					cm.height = len
					rope.mesh = cm
					rope.rotation_degrees.z = 90
					rope.position = Vector3(0, 0.9, side * float(s.get("width", 2.6)) * 0.5)
					rope.material_override = _toon(Color("#5a4026"))
					_rope_body.add_child(rope)
				if s.get("starts_hidden", false):
					set_rope_span_visible(false, true)
			"stone_bridge":
				var a2: Array = s["a"]
				var b2: Array = s["b"]
				var va2 := Vector3(a2[0], a2[1], a2[2])
				var vb2 := Vector3(b2[0], b2[1], b2[2])
				var len2 := va2.distance_to(vb2)
				var mid2 := (va2 + vb2) * 0.5
				root.position = mid2
				_span_root = root
				_span_mat = _toon(Color("#c49a62"))
				var w2 := float(s.get("width", 7.0))
				_box_body(root, Vector3(len2 + 2.0, 1.2, w2), Vector3(0, -0.6, 0), _span_mat)
				# arches / pillars into the chasm
				for i in 4:
					var px := -len2 * 0.5 + len2 * (float(i) + 0.5) / 4.0
					var pil := MeshInstance3D.new()
					var pb := BoxMesh.new()
					pb.size = Vector3(2.2, 36.0, w2 * 0.8)
					pil.mesh = pb
					pil.position = Vector3(px, -19.0, 0)
					pil.material_override = _span_mat
					root.add_child(pil)
				for side in [-1.0, 1.0]:
					_box_body(root, Vector3(len2 + 2.0, 0.8, 0.5), Vector3(0, 0.4, side * (w2 * 0.5 - 0.25)), _span_mat)
			"ruins":
				var p3: Array = s["pos"]
				root.position = Vector3(p3[0], p3[1], p3[2])
				var r := float(s.get("radius", 12.0))
				for i in 9:
					var a3 := TAU * float(i) / 9.0 + 0.3
					if i % 3 == 1:
						continue
					var h := 2.0 + float((i * 7) % 4)
					_box_body(root, Vector3(1.4, h, 1.4), Vector3(cos(a3) * r, h * 0.5, sin(a3) * r), _toon(Color("#a89070")))
			"marker_stone":
				var p4: Array = s["pos"]
				root.position = Vector3(p4[0], p4[1], p4[2])
				var ms := _box_body(root, Vector3(1.2, 2.8, 0.6), Vector3(0, 1.4, 0), _toon(Color("#7d7f86")), 1)
				var glyph := Label3D.new()
				glyph.text = "◇ ⟁ ◇"
				glyph.font_size = 64
				glyph.modulate = Color(0.85, 0.75, 0.5)
				glyph.position = Vector3(0, 0.4, 0.31)
				ms.add_child(glyph)
			"cracked_boulder":
				var p5: Array = s["pos"]
				root.position = Vector3(p5[0], p5[1], p5[2])
				var rad := float(s.get("radius", 3.6))
				var sb := StaticBody3D.new()
				sb.name = "Body"
				sb.collision_layer = 1 | 8
				var cs := CollisionShape3D.new()
				var sph := SphereShape3D.new()
				sph.radius = rad
				cs.shape = sph
				cs.position.y = rad * 0.6
				sb.add_child(cs)
				var mi5 := MeshInstance3D.new()
				var sm5 := SphereMesh.new()
				sm5.radius = rad
				sm5.height = rad * 1.7
				sm5.radial_segments = 10
				sm5.rings = 6
				mi5.mesh = sm5
				mi5.position.y = rad * 0.6
				var bm5 := _toon(Color("#6e7c8a"))
				bm5.emission_enabled = true
				bm5.emission = Color(0.2, 0.45, 0.6) * 0.5
				mi5.material_override = bm5
				sb.add_child(mi5)
				root.add_child(sb)
			"dominion_camp":
				var p6: Array = s["pos"]
				root.position = Vector3(p6[0], p6[1], p6[2])
				for i in 5:
					_box_body(root, Vector3(1.6, 1.2, 1.6), Vector3(float(i % 3) * 2.2 - 2.0, 0.6, float(i / 3) * 2.4 - 1.0), _toon(Color("#4a4f58")))
			_:
				var p7: Array = s.get("pos", [0, 0, 0])
				root.position = Vector3(p7[0], p7[1], p7[2])

# ---------------- API ----------------
func get_marker(marker_name: String) -> Vector3:
	var m: Variant = layout.get("markers", {}).get(marker_name, null)
	if m is Array:
		return Vector3(m[0], m[1], m[2])
	return Vector3.ZERO

func get_structure(id: String) -> Node3D:
	return _structures.get(id, null)

func set_rope_span_visible(on: bool, instant: bool = false) -> void:
	if _rope_body == null:
		return
	_rope_body.collision_layer = 1 if on else 0
	if instant:
		_rope_body.visible = on
		return
	_rope_body.visible = true
	_rope_body.scale = Vector3(0.05, 1, 1) if on else Vector3.ONE
	var tw := create_tween()
	tw.tween_property(_rope_body, "scale", Vector3.ONE if on else Vector3(0.05, 1, 1), 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not on:
		tw.tween_callback(_rope_body.hide)

func break_boulder() -> void:
	var root: Node3D = _structures.get("thought_boulder", null)
	if root == null:
		return
	var body := root.get_node_or_null("Body")
	if body:
		body.collision_layer = 0
		var tw := create_tween()
		tw.tween_property(body, "scale", Vector3(1.4, 0.1, 1.4), 0.35).set_ease(Tween.EASE_IN)
		tw.tween_callback(body.hide)

func shake_span(intensity: float) -> void:
	if _span_root == null:
		return
	var base := _span_root.position
	var tw := create_tween()
	for i in 4:
		tw.tween_property(_span_root, "position", base + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.08 * intensity, 0.05)
	tw.tween_property(_span_root, "position", base, 0.05)

func set_span_state(state: String) -> void:
	if _span_mat == null:
		return
	match state:
		"braced":
			_span_mat.albedo_color = Color("#d4b07a")
			_span_mat.emission_enabled = true
			_span_mat.emission = Color(0.3, 0.5, 0.6) * 0.25
		"failing":
			_span_mat.albedo_color = Color("#8a6a4a")
			if _span_root:
				_span_root.rotation_degrees.x = 1.5
		_:
			_span_mat.albedo_color = Color("#c49a62")
