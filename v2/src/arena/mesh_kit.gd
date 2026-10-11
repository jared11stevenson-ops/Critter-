class_name MeshKit extends RefCounted
## Tiny flat-shaded mesh merger for the arena set dressing: boxes, cylinders, blobs and floor fans with a color each,
## all appended to ONE ArrayMesh (one draw call, vertex colors, per-face normals). Pure geometry, no Nodes.
## Winding: callers give triangles counter-clockwise seen from OUTSIDE (right-hand rule); the kit flips to Godot's clockwise.

var _st := SurfaceTool.new()
var tris := 0
var seed_n := 1
var xf := Transform3D.IDENTITY   # applied to every vertex (set per landmark, reset to IDENTITY after)

func _init() -> void:
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)

func tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	if xf != Transform3D.IDENTITY:
		a = xf * a; b = xf * b; c = xf * c
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	n = n.normalized()
	_st.set_color(col); _st.set_normal(n); _st.add_vertex(a)
	_st.set_color(col); _st.set_normal(n); _st.add_vertex(c)
	_st.set_color(col); _st.set_normal(n); _st.add_vertex(b)
	tris += 1

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	tri(a, b, c, col)
	tri(a, c, d, col)

## Deterministic brightness wobble so repeated primitives do not look stamped.
func jitter(col: Color, amount: float) -> Color:
	seed_n = (seed_n * 1103515245 + 12345) & 0x7fffffff
	var k := (float(seed_n % 1000) / 1000.0 - 0.5) * 2.0 * amount
	return Color(clampf(col.r + k, 0.0, 1.0), clampf(col.g + k, 0.0, 1.0), clampf(col.b + k * 0.8, 0.0, 1.0), col.a)

func box_xf(xf: Transform3D, size: Vector3, col: Color) -> void:
	var h := size * 0.5
	var p: Array = []
	for i in 8:
		p.append(xf * Vector3(h.x if (i & 1) else -h.x, h.y if (i & 2) else -h.y, h.z if (i & 4) else -h.z))
	# corner index bits: x=1 y=2 z=4
	quad(p[1], p[3], p[7], p[5], col)    # +x
	quad(p[0], p[4], p[6], p[2], col)    # -x
	quad(p[2], p[6], p[7], p[3], col)    # +y
	quad(p[0], p[1], p[5], p[4], col)    # -y
	quad(p[4], p[5], p[7], p[6], col)    # +z
	quad(p[0], p[2], p[3], p[1], col)    # -z

func box(center: Vector3, size: Vector3, col: Color, yaw_deg := 0.0, pitch_deg := 0.0, roll_deg := 0.0) -> void:
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), deg_to_rad(roll_deg)))
	box_xf(Transform3D(b, center), size, col)

## Truncated cone / cylinder standing on `base` (y up).
func cyl(base: Vector3, r_bottom: float, r_top: float, h: float, seg: int, col: Color, cap_top := true, cap_bottom := false, col_top := Color(0, 0, 0, 0)) -> void:
	var ct := col if col_top.a == 0.0 else col_top
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var b0 := base + Vector3(cos(a0) * r_bottom, 0, sin(a0) * r_bottom)
		var b1 := base + Vector3(cos(a1) * r_bottom, 0, sin(a1) * r_bottom)
		var t0 := base + Vector3(cos(a0) * r_top, h, sin(a0) * r_top)
		var t1 := base + Vector3(cos(a1) * r_top, h, sin(a1) * r_top)
		quad(b1, b0, t0, t1, col)
		if cap_top and r_top > 0.0:
			tri(base + Vector3(0, h, 0), t1, t0, ct)
		if cap_bottom and r_bottom > 0.0:
			tri(base, b0, b1, col)

## Flat ring band on the ground plane (annulus sector), normal up.
func ring_band(center: Vector3, r0: float, r1: float, seg: int, col: Color, a_from := 0.0, a_to := TAU) -> void:
	for i in seg:
		var a0 := a_from + (a_to - a_from) * float(i) / float(seg)
		var a1 := a_from + (a_to - a_from) * float(i + 1) / float(seg)
		var p00 := center + Vector3(cos(a0) * r0, 0, sin(a0) * r0)
		var p01 := center + Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		var p10 := center + Vector3(cos(a0) * r1, 0, sin(a0) * r1)
		var p11 := center + Vector3(cos(a1) * r1, 0, sin(a1) * r1)
		quad(p00, p01, p11, p10, col)    # CCW seen from above (+y) -> normal up

## Squashed low-poly sphere.
func blob(center: Vector3, radius: Vector3, col: Color, lon := 8, lat := 5) -> void:
	for j in lat:
		var v0 := PI * float(j) / float(lat)
		var v1 := PI * float(j + 1) / float(lat)
		for i in lon:
			var u0 := TAU * float(i) / float(lon)
			var u1 := TAU * float(i + 1) / float(lon)
			var p00 := center + Vector3(sin(v0) * cos(u0), cos(v0), sin(v0) * sin(u0)) * radius
			var p01 := center + Vector3(sin(v0) * cos(u1), cos(v0), sin(v0) * sin(u1)) * radius
			var p10 := center + Vector3(sin(v1) * cos(u0), cos(v1), sin(v1) * sin(u0)) * radius
			var p11 := center + Vector3(sin(v1) * cos(u1), cos(v1), sin(v1) * sin(u1)) * radius
			if j == 0:
				tri(p00, p11, p10, col)
			elif j == lat - 1:
				tri(p00, p01, p10, col)
			else:
				quad(p00, p01, p11, p10, col)

## Arch in the XY plane (extruded along z by `depth`) made of box segments between two angles (deg, 0 = +x, 90 = up).
func arch(center: Vector3, radius: float, thick: float, depth: float, from_deg: float, to_deg: float, segs: int, col: Color) -> void:
	for i in segs:
		var a := deg_to_rad(from_deg + (to_deg - from_deg) * (float(i) + 0.5) / float(segs))
		var seg_len := absf(deg_to_rad(to_deg - from_deg)) / float(segs) * radius * 1.04
		var pos := center + Vector3(cos(a) * radius, sin(a) * radius, 0)
		var basis := Basis(Vector3(0, 0, 1), a + PI * 0.5)
		box_xf(Transform3D(basis, pos), Vector3(seg_len, thick, depth), jitter(col, 0.03))

func build(mat: Material) -> MeshInstance3D:
	var mesh := _st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func vertex_color_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m
