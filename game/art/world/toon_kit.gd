class_name ToonKit
extends RefCounted
## Procedural low-poly mesh + material helpers for the CRITTER toon/ink world (Agent 1).
## Everything is built with SurfaceTool, flat-shaded, vertex-coloured, so one material can colour many parts.

const PROP_SHADER_PATH := "res://game/art/shaders/toon_prop.gdshader"
const OUTLINE_SHADER_PATH := "res://game/art/shaders/ink_outline.gdshader"
const GLOBAL_FOCUS := "critter_focus_pos"
const GLOBAL_CAM := "critter_cam_pos"
const NOISE_TEX := preload("res://game/art/world/terrain_noise.png")
const DETAIL_TEX := preload("res://game/art/world/pbr/prop_detail.webp")
const DETAIL_NRM := preload("res://game/art/world/pbr/prop_rock_normal.webp")
## v0.7 painterly realism: ink outlines are off on all world/creature geometry (halves draw calls). Set true (or pass
## "force_outline") to bring the old inked look back.
static var outlines_enabled := false

static var _mat_cache: Dictionary = {}
static var _shader_cache: Dictionary = {}
static var _globals_ok := false


## Registers the camera-occlusion globals (vec3 critter_focus_pos / critter_cam_pos) if the project does not
## declare them (idempotent; call it instead of adding them yourself). Gameplay sets them each frame:
## RenderingServer.global_shader_parameter_set(name, Vector3).
static func ensure_globals() -> bool:
	if _globals_ok:
		return true
	for n in [GLOBAL_FOCUS, GLOBAL_CAM]:
		if not ProjectSettings.has_setting("shader_globals/" + n):
			RenderingServer.global_shader_parameter_add(n, RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3.ZERO)
	_globals_ok = true
	return true


## Loads a shader whose occlusion uniforms are plain `uniform`s in the file and rewires them to the globals.
static func occluding_shader(path: String) -> Shader:
	if _shader_cache.has(path):
		return _shader_cache[path]
	var base: Shader = load(path)
	var sh := base
	var code := base.code
	if ensure_globals() and base.code.contains("uniform vec3 critter_focus_pos;"):
		code = code.replace("\nuniform vec3 critter_focus_pos;", "\nglobal uniform vec3 critter_focus_pos;")
		code = code.replace("\nuniform vec3 critter_cam_pos;", "\nglobal uniform vec3 critter_cam_pos;")
		sh = Shader.new()
		sh.code = code
	# graphics quality variants (#define QUALITY_LOW / QUALITY_MEDIUM), recompiled live by the Quality autoload
	var q := quality()
	if q and code.contains("QUALITY_"):
		sh = q.call("shader", path, code)
	_shader_cache[path] = sh
	return sh


## The Quality autoload (graphics presets) or null (editor / tool contexts).
static func quality() -> Node:
	var ml := Engine.get_main_loop()
	if ml is SceneTree and (ml as SceneTree).root:
		return (ml as SceneTree).root.get_node_or_null("Quality")
	return null


## Shared toon material. opts: outline (float width, 0 = none), strata (0..1), emission (Color), energy, grain.
static func material(opts: Dictionary = {}) -> ShaderMaterial:
	var key := str(opts)
	if _mat_cache.has(key) and not opts.get("unique", false):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = occluding_shader(PROP_SHADER_PATH)
	m.set_shader_parameter("noise_tex", NOISE_TEX)
	m.set_shader_parameter("detail_tex", DETAIL_TEX)
	m.set_shader_parameter("detail_normal", DETAIL_NRM)
	m.set_shader_parameter("roughness", float(opts.get("roughness", 0.82)))
	m.set_shader_parameter("metallic", float(opts.get("metal", 0.0)))
	if opts.has("detail"):
		m.set_shader_parameter("detail_strength", float(opts["detail"]))
	m.set_shader_parameter("albedo", opts.get("albedo", Color(1, 1, 1)))
	m.set_shader_parameter("strata", float(opts.get("strata", 0.0)))
	m.set_shader_parameter("grain", float(opts.get("grain", 0.18)))
	if opts.has("emission"):
		m.set_shader_parameter("emission_color", opts["emission"])
		m.set_shader_parameter("emission_energy", float(opts.get("energy", 1.0)))
	m.set_shader_parameter("rim_strength", float(opts.get("rim", 0.25)))
	var ow := float(opts.get("outline", 0.035))
	if ow > 0.0 and (outlines_enabled or opts.get("force_outline", false)):
		var o := ShaderMaterial.new()
		o.shader = occluding_shader(OUTLINE_SHADER_PATH)
		o.set_shader_parameter("width", ow)
		m.next_pass = o
	if not opts.get("unique", false):
		_mat_cache[key] = m
	return m


## Unshaded glow material (lamps, Thoughtstone, Dominion lights).
static func glow(c: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c * energy
	m.albedo_color.a = c.a
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func finish(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	return st.commit()


static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	# Godot front faces are clockwise as seen from the outside: emit a, c, b for CCW-authored triangles
	st.set_color(col)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	tri(st, a, b, c, col)
	tri(st, a, c, d, col)


## Oriented box. xf = transform of the unit box centre; size in meters.
static func box(st: SurfaceTool, xf: Transform3D, size: Vector3, col: Color, shade_sides: bool = true) -> void:
	var h := size * 0.5
	var p := [
		Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z),
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	for i in 8:
		p[i] = xf * p[i]
	var side := col.darkened(0.06) if shade_sides else col
	quad(st, p[4], p[5], p[6], p[7], side)   # +z
	quad(st, p[1], p[0], p[3], p[2], side)   # -z
	quad(st, p[5], p[1], p[2], p[6], col)    # +x
	quad(st, p[0], p[4], p[7], p[3], col)    # -x
	quad(st, p[7], p[6], p[2], p[3], col.lightened(0.05))   # top
	quad(st, p[0], p[1], p[5], p[4], col.darkened(0.2))     # bottom


## Cylinder / frustum between a and b (radii ra at a, rb at b).
static func cylinder(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, segs: int, col: Color, caps: bool = true, jitter: float = 0.0, seed_v: int = 0) -> void:
	var axis := b - a
	if axis.length() < 0.0001:
		return
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var ring_a: Array = []
	var ring_b: Array = []
	for i in segs:
		var ang := TAU * float(i) / float(segs)
		var d := x * cos(ang) + z * sin(ang)
		var ja := 1.0 + rng.randf_range(-jitter, jitter)
		var jb := 1.0 + rng.randf_range(-jitter, jitter)
		ring_a.append(a + d * ra * ja)
		ring_b.append(b + d * rb * jb)
	for i in segs:
		var j := (i + 1) % segs
		quad(st, ring_a[j], ring_a[i], ring_b[i], ring_b[j], col)
	if caps:
		for i in segs:
			var j := (i + 1) % segs
			tri(st, b, ring_b[j], ring_b[i], col.lightened(0.05))
			tri(st, a, ring_a[i], ring_a[j], col.darkened(0.2))


## Low-poly boulder: jittered, squashed octahedron-sphere. Returns nothing; adds to st.
static func rock(st: SurfaceTool, center: Vector3, radius: Vector3, col: Color, seed_v: int, detail: int = 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var verts: Array = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var faces: Array = [[0, 4, 3], [0, 3, 5], [0, 5, 2], [0, 2, 4], [1, 3, 4], [1, 5, 3], [1, 2, 5], [1, 4, 2]]
	for _d in detail:
		var nf: Array = []
		var mid := {}
		for f in faces:
			var m: Array = []
			for e in 3:
				var i0: int = f[e]
				var i1: int = f[(e + 1) % 3]
				var k := str(mini(i0, i1)) + "_" + str(maxi(i0, i1))
				if not mid.has(k):
					verts.append(((verts[i0] + verts[i1]) * 0.5).normalized())
					mid[k] = verts.size() - 1
				m.append(mid[k])
			nf.append([f[0], m[0], m[2]])
			nf.append([f[1], m[1], m[0]])
			nf.append([f[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		faces = nf
	var pts: Array = []
	for v in verts:
		var vv: Vector3 = v
		var j := 1.0 + rng.randf_range(-0.22, 0.18)
		var p := vv * j
		if p.y < -0.2:
			p.y = -0.2 - (p.y + 0.2) * 0.15    # flat-ish base sunk into the ground
		if p.y > 0.55:
			p.y = 0.55 + (p.y - 0.55) * 0.5    # flattened top facets
		pts.append(center + Vector3(p.x * radius.x, p.y * radius.y, p.z * radius.z))
	for f in faces:
		var a: Vector3 = pts[f[0]]
		var b: Vector3 = pts[f[1]]
		var c: Vector3 = pts[f[2]]
		var n := (b - a).cross(c - a)
		var up := clampf(n.normalized().y, -1.0, 1.0)
		var shade := col.lightened(0.06 * up) if up > 0.0 else col.darkened(-0.12 * up)
		tri(st, a, c, b, shade)


## Torus (ring) lying in the XY plane around center, facing +Z.
static func torus(st: SurfaceTool, xf: Transform3D, r_major: float, r_minor: float, segs: int, sides: int, col: Color) -> void:
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		for j in sides:
			var b0 := TAU * float(j) / float(sides)
			var b1 := TAU * float(j + 1) / float(sides)
			var p00 := xf * _tp(a0, b0, r_major, r_minor)
			var p10 := xf * _tp(a1, b0, r_major, r_minor)
			var p11 := xf * _tp(a1, b1, r_major, r_minor)
			var p01 := xf * _tp(a0, b1, r_major, r_minor)
			quad(st, p00, p10, p11, p01, col)


static func _tp(a: float, b: float, R: float, r: float) -> Vector3:
	var c := Vector3(cos(a), sin(a), 0.0)
	return c * (R + r * cos(b)) + Vector3(0, 0, r * sin(b))


static func mesh_instance(mesh: Mesh, mat: Material, name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if name != "":
		mi.name = name
	return mi


static func static_box(parent: Node3D, xf: Transform3D, size: Vector3, layer: int = 1, name: String = "Collision") -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = name
	sb.collision_layer = 1 << (layer - 1)
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.transform = xf
	parent.add_child(sb)
	return sb


static func static_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, layer: int = 1) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1 << (layer - 1)
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = height
	cs.shape = c
	cs.position = Vector3(0, height * 0.5, 0)
	sb.add_child(cs)
	sb.position = pos
	parent.add_child(sb)
	return sb
