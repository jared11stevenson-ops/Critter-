extends RefCounted
## MeshBuilder: merges many smooth primitives (blobs, tubes, rings, face patches) into ONE ArrayMesh
## surface per rig group. Vertex color RGB = part color, A = emissive mask. Normals double as outline
## hull normals, so every primitive is closed and smooth (rounded "toy" shapes by construction).
## Triangle budget is the caller's job: use `tris()` and keep each critter under 3000 (x2 with outline).

var verts := PackedVector3Array()
var norms := PackedVector3Array()
var cols := PackedColorArray()
var idx := PackedInt32Array()

static func T(p: Vector3 = Vector3.ZERO, r_deg: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	var b := Basis.from_euler(Vector3(deg_to_rad(r_deg.x), deg_to_rad(r_deg.y), deg_to_rad(r_deg.z)))
	b = b.scaled(s)
	return Transform3D(b, p)

static func _sp(x: float, e: float) -> float:
	return signf(x) * pow(absf(x), e)

func tris() -> int:
	return idx.size() / 3

func _push(p: Vector3, n: Vector3, c: Color, xf: Transform3D, nb: Basis) -> void:
	verts.append(xf * p)
	var nn: Vector3 = (nb * n).normalized()
	norms.append(nn)
	cols.append(c)

## Superellipsoid. e=1 ellipsoid, e<1 boxy/rounded-cube, e>1 pinched/diamond.
## Poles on local Y. `cut_bottom` flattens below (-1..1 in unit-y) for feet/domes.
func blob(xf: Transform3D, radii: Vector3, color: Color, glow: float = 0.0, e: float = 1.0,
		segs: int = 10, rings: int = 6, cut_bottom: float = -1.0) -> void:
	var base := verts.size()
	var nb := xf.basis.inverse().transposed()
	var c := Color(color.r, color.g, color.b, glow)
	for j in range(rings + 1):
		var v := lerpf(-PI * 0.5, PI * 0.5, float(j) / rings)
		var cv := cos(v)
		var sv := sin(v)
		if sv < cut_bottom:
			sv = cut_bottom
			cv = sqrt(maxf(0.0, 1.0 - sv * sv))
		for i in range(segs + 1):
			var u := TAU * float(i) / segs
			var cu := cos(u)
			var su := sin(u)
			var p := Vector3(radii.x * _sp(cv, e) * _sp(cu, e), radii.y * _sp(sv, e), radii.z * _sp(cv, e) * _sp(su, e))
			var n := Vector3(_sp(cv, 2.0 - e) * _sp(cu, 2.0 - e) / radii.x, _sp(sv, 2.0 - e) / radii.y,
					_sp(cv, 2.0 - e) * _sp(su, 2.0 - e) / radii.z)
			if n.length() < 0.0001:
				n = Vector3(0, signf(sv), 0)
			_push(p, n, c, xf, nb)
	var row := segs + 1
	for j in range(rings):
		for i in range(segs):
			var a := base + j * row + i
			var b := a + 1
			var d := a + row
			var f := d + 1
			if j > 0:
				idx.append_array([a, b, d])
			if j < rings - 1:
				idx.append_array([b, f, d])

## Swept elliptical tube along a polyline. `rad[i]` = Vector2(wide_radius, thin_radius); radius 0 = sharp tip.
## `wide_hint` = direction the wide axis points (e.g. blade width). Rounded end caps unless radius is ~0.
func tube(xf: Transform3D, pts: Array, rad: Array, color: Color, glow: float = 0.0,
		wide_hint: Vector3 = Vector3(0, 0, 1), segs: int = 8, cap_start: bool = true, cap_end: bool = true,
		colors: Array = []) -> void:
	var nb := xf.basis.inverse().transposed()
	var n_pts := pts.size()
	var rings_data: Array = []   # each: [center, X1, X2, rx, rz, color, normal_tilt]
	var tans: Array = []
	for i in range(n_pts):
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, n_pts - 1)]
		tans.append((b - a).normalized())
	var cap_steps := [Vector2(0.55, 0.83), Vector2(0.0, 1.0)]  # (sin phi, cos phi) of two cap rings
	var seq: Array = []
	for i in range(n_pts):
		var t: Vector3 = tans[i]
		var h := wide_hint
		var x1: Vector3 = (h - t * h.dot(t))
		if x1.length() < 0.001:
			x1 = t.cross(Vector3.UP)
			if x1.length() < 0.001:
				x1 = t.cross(Vector3.RIGHT)
		x1 = x1.normalized()
		var x2: Vector3 = t.cross(x1).normalized()
		var r: Vector2 = rad[i]
		var col: Color = color
		if colors.size() > i:
			col = colors[i]
		seq.append({"c": pts[i], "x1": x1, "x2": x2, "r": r, "t": t, "col": col, "tilt": 0.0, "off": 0.0})
	# insert caps
	var full: Array = []
	if cap_start and (rad[0] as Vector2).length() > 0.002:
		var s0: Dictionary = seq[0]
		for cs in cap_steps:
			var d: Dictionary = s0.duplicate()
			var rmax: float = maxf(d["r"].x, d["r"].y)
			d["r"] = Vector2(d["r"].x * cs.y, d["r"].y * cs.y)
			d["c"] = d["c"] - d["t"] * rmax * cs.x
			d["tilt"] = -cs.x
			full.append(d)
	for s in seq:
		full.append(s)
	if cap_end and (rad[n_pts - 1] as Vector2).length() > 0.002:
		var s1: Dictionary = seq[n_pts - 1]
		for k in range(cap_steps.size()):
			var cs: Vector2 = cap_steps[cap_steps.size() - 1 - k]
			var d: Dictionary = s1.duplicate()
			var rmax: float = maxf(d["r"].x, d["r"].y)
			d["r"] = Vector2(d["r"].x * cs.y, d["r"].y * cs.y)
			d["c"] = d["c"] + d["t"] * rmax * cs.x
			d["tilt"] = cs.x
			full.append(d)
	# fix order of start caps (outermost first)
	if cap_start and (rad[0] as Vector2).length() > 0.002:
		var tmp: Array = [full[1], full[0]]
		full[0] = tmp[0]
		full[1] = tmp[1]
	var base := verts.size()
	for d in full:
		var col: Color = d["col"]
		var c := Color(col.r, col.g, col.b, glow)
		var r: Vector2 = d["r"]
		for i in range(segs + 1):
			var th := TAU * float(i) / segs
			var ct := cos(th)
			var st := sin(th)
			var p: Vector3 = d["c"] + d["x1"] * (r.x * ct) + d["x2"] * (r.y * st)
			var radial: Vector3 = d["x1"] * (ct * maxf(r.y, 0.002)) + d["x2"] * (st * maxf(r.x, 0.002))
			if radial.length() < 0.00001:
				radial = d["x1"] * ct + d["x2"] * st
			radial = radial.normalized()
			var n: Vector3 = (radial + (d["t"] as Vector3) * (d["tilt"] as float) * 1.2).normalized()
			_push(p, n, c, xf, nb)
	var row := segs + 1
	for j in range(full.size() - 1):
		for i in range(segs):
			var a := base + j * row + i
			var b := a + 1
			var d2 := a + row
			var f := d2 + 1
			idx.append_array([a, d2, b, b, d2, f])

## Round tapered tube: radius r0 at the first point to r1 at the last (linear along the point index).
func lim(xf: Transform3D, pts: Array, r0: float, r1: float, color: Color, glow: float = 0.0, segs: int = 6,
		cap_start: bool = true, cap_end: bool = true) -> void:
	var rad: Array = []
	for i in range(pts.size()):
		var r := lerpf(r0, r1, float(i) / maxf(pts.size() - 1, 1))
		rad.append(Vector2(r, r))
	tube(xf, pts, rad, color, glow, Vector3(0, 0, 1), segs, cap_start, cap_end)

## Flat ribbon / blade / leaf: width w0 -> w1 along the path, thickness `th`; `wide` = direction the width runs.
## `bulge` > 0 swells the middle (leaf shape); the last radius is 0 when `point` is true.
func flat(xf: Transform3D, pts: Array, w0: float, w1: float, th: float, color: Color, wide: Vector3 = Vector3(0, 1, 0),
		glow: float = 0.0, bulge: float = 0.0, point: bool = false, segs: int = 4) -> void:
	var rad: Array = []
	var n := pts.size()
	for i in range(n):
		var f := float(i) / maxf(n - 1, 1)
		var w := lerpf(w0, w1, f) * (1.0 + bulge * sin(f * PI))
		if point and i == n - 1:
			w = 0.0
		rad.append(Vector2(w, th))
	tube(xf, pts, rad, color, glow, wide, segs, false, false)

## Torus ring (goggles, hard-hat brims, spectacle lenses, rivets). Axis = local Z.
func ring(xf: Transform3D, big_r: float, small_r: float, color: Color, glow: float = 0.0, segs: int = 14, tsegs: int = 6,
		squash: float = 1.0) -> void:
	var base := verts.size()
	var nb := xf.basis.inverse().transposed()
	var c := Color(color.r, color.g, color.b, glow)
	for j in range(tsegs + 1):
		var v := TAU * float(j) / tsegs
		for i in range(segs + 1):
			var u := TAU * float(i) / segs
			var cu := cos(u)
			var su := sin(u)
			var ring_p := Vector3(cu * (big_r + small_r * cos(v)), su * (big_r + small_r * cos(v)), small_r * sin(v) * squash)
			var n := Vector3(cu * cos(v), su * cos(v), sin(v) / maxf(squash, 0.05))
			_push(ring_p, n, c, xf, nb)
	var row := segs + 1
	for j in range(tsegs):
		for i in range(segs):
			var a := base + j * row + i
			var b := a + 1
			var d := a + row
			var f := d + 1
			idx.append_array([a, b, d, b, f, d])

## Face patch hugging an ellipsoid (the head). Covers lon in [-half_lon, half_lon] around +X, lat in [-half_lat, half_lat].
## UV x -1..1 across (left..right when looking at the face from the front), y 0..1 bottom..top ->
## the face shader reads UV in 0..1.
func face_patch(center: Vector3, radii: Vector3, half_lon: float, half_lat: float, lat_center: float = 0.0,
		lon_n: int = 10, lat_n: int = 8, bulge: float = 1.015, yaw: float = 0.0, e: float = 1.0) -> void:
	var base := verts.size()
	var uvs_local := PackedVector2Array()
	for j in range(lat_n + 1):
		var fv := float(j) / lat_n
		var lat := lat_center + lerpf(half_lat, -half_lat, fv)
		for i in range(lon_n + 1):
			var fu := float(i) / lon_n
			# looking at the face from +X toward -X, screen-right is -Z... we map UV x so +x is rig-left? keep +Z = right of viewer.
			var lon := yaw + lerpf(-half_lon, half_lon, fu)
			var cl := cos(lat)
			var dir := Vector3(_sp(cl, e) * _sp(cos(lon), e), _sp(sin(lat), e), _sp(cl, e) * _sp(sin(lon), e))
			var p := center + Vector3(dir.x * radii.x, dir.y * radii.y, dir.z * radii.z) * bulge
			var n := Vector3(_sp(cl, 2.0 - e) * _sp(cos(lon), 2.0 - e) / radii.x, _sp(sin(lat), 2.0 - e) / radii.y,
					_sp(cl, 2.0 - e) * _sp(sin(lon), 2.0 - e) / radii.z).normalized()
			verts.append(p)
			norms.append(n)
			cols.append(Color(1, 1, 1, 0))
			uvs_local.append(Vector2(fu, fv))
	var row := lon_n + 1
	for j in range(lat_n):
		for i in range(lon_n):
			var a := base + j * row + i
			var b := a + 1
			var d := a + row
			var f := d + 1
			idx.append_array([a, d, b, b, d, f])
	_last_uvs = uvs_local

var _last_uvs := PackedVector2Array()

func build(with_uv: bool = false) -> ArrayMesh:
	var m := ArrayMesh.new()
	if verts.is_empty():
		return m
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	if with_uv:
		arr[Mesh.ARRAY_TEX_UV] = _last_uvs
	arr[Mesh.ARRAY_INDEX] = idx
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m
