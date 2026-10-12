class_name FxPrims
extends RefCounted
## Procedural VFX building blocks (unshaded, additive or alpha meshes + CPU particles). Every call attaches a short-lived node to `parent`
## and frees itself. Cheap on Compatibility: one draw per piece, no shaders beyond StandardMaterial3D, concurrent pieces are capped by BoutVfx.

static var _cres: ArrayMesh
static var density := 1.0   # particle amount multiplier from the quality setting (Low 0.45, Medium 0.75, High 1.0)
const K := 1.9            # global boldness: widths, particle sizes, ring thickness (the bout camera is far, thin effects vanish)

static func mat(col: Color, additive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m

static func _mi(parent: Node3D, mesh: Mesh, col: Color, pos: Vector3, additive := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(col, additive)
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func _fade_free(mi: Node3D, dur: float, grow := Vector3.ONE, ease_out := true) -> void:
	var tw := mi.create_tween().set_parallel(true)
	if grow != Vector3.ONE:
		tw.tween_property(mi, "scale", mi.scale * grow, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if ease_out else Tween.EASE_IN)
	if mi is GeometryInstance3D:
		var m := (mi as GeometryInstance3D).material_override as StandardMaterial3D
		if m != null:
			tw.tween_property(m, "albedo_color:a", 0.0, dur).set_delay(dur * 0.35)
	tw.chain().tween_callback(mi.queue_free)

## expanding flat ring on the ground (or vertical when `vertical`)
static func ring(parent: Node3D, pos: Vector3, r0: float, r1: float, col: Color, dur := 0.4, thick := 0.1, vertical := false) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = 1.0 - clampf(thick * K, 0.05, 0.6)
	t.outer_radius = 1.0
	t.rings = 20
	t.ring_segments = 6
	var under := _mi(parent, t, Color(0.08, 0.05, 0.1, 0.45), pos - Vector3(0, 0.01, 0), false)   # ink underlay keeps additive color readable on light ground
	under.scale = Vector3(r0, r0 * 0.3, r0)
	if vertical:
		under.rotation.x = PI * 0.5
	_fade_free(under, dur, Vector3(r1 / maxf(r0, 0.01), 1.0, r1 / maxf(r0, 0.01)))
	var mi := _mi(parent, t, col, pos)
	mi.scale = Vector3(r0, r0 * 0.3, r0)
	if vertical:
		mi.rotation.x = PI * 0.5
	_fade_free(mi, dur, Vector3(r1 / maxf(r0, 0.01), 1.0, r1 / maxf(r0, 0.01)))
	return mi

static func disc(parent: Node3D, pos: Vector3, r: float, col: Color, dur := 0.3, grow := 1.6) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = 1.0
	c.bottom_radius = 1.0
	c.height = 0.02
	c.radial_segments = 20
	c.rings = 1
	var mi := _mi(parent, c, col, pos)
	mi.scale = Vector3(r, 1, r)
	_fade_free(mi, dur, Vector3(grow, 1, grow))
	return mi

## beam/streak between two world points
static func streak(parent: Node3D, a: Vector3, b: Vector3, col: Color, dur := 0.25, width := 0.12) -> MeshInstance3D:
	var bx := BoxMesh.new()
	bx.size = Vector3(1, 1, 1)
	var mi := _mi(parent, bx, col, (a + b) * 0.5)
	var d := b - a
	var L := maxf(d.length(), 0.01)
	var wd := width * K
	mi.scale = Vector3(wd, wd, L)
	mi.look_at_from_position((a + b) * 0.5, b, Vector3.UP)
	mi.scale = Vector3(wd, wd, L)
	_fade_free(mi, dur, Vector3(0.2, 0.2, 1.0))
	return mi

## radial star of streaks (impact spark)
static func burst(parent: Node3D, pos: Vector3, col: Color, n := 8, length := 1.2, dur := 0.25, width := 0.09) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in n:
		var a := TAU * float(i) / float(n) + rng.randf_range(-0.2, 0.2)
		var dir := Vector3(cos(a), rng.randf_range(0.0, 0.6), sin(a)).normalized()
		var L := length * rng.randf_range(0.6, 1.0)
		streak(parent, pos + dir * 0.15, pos + dir * L, col, dur, width)

## crescent slash mesh (cached): inner/outer radius over an arc, flat in the XZ plane
static func _crescent() -> ArrayMesh:
	if _cres != null:
		return _cres
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	var segs := 14
	for i in segs + 1:
		var f := float(i) / float(segs)
		var a := lerpf(-1.1, 1.1, f)
		var w := sin(f * PI)            # thick in the middle, tapering to points
		verts.append(Vector3(sin(a) * 1.0, 0, -cos(a) * 1.0 + 1.0))
		verts.append(Vector3(sin(a) * (1.0 - 0.38 * w), 0, -cos(a) * (1.0 - 0.38 * w) + 1.0))
	for i in segs:
		var k := i * 2
		idx.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])
	var am := ArrayMesh.new()
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_cres = am
	return am

## sweeping slash arc facing `dir`
static func slash(parent: Node3D, pos: Vector3, dir: Vector3, col: Color, size := 1.6, dur := 0.22, tilt := 0.0) -> void:
	var mi := _mi(parent, _crescent(), col, pos)
	mi.scale = Vector3(size, 1, size)
	mi.look_at_from_position(pos, pos + Vector3(dir.x, 0, dir.z), Vector3.UP)
	mi.rotate_object_local(Vector3(0, 0, 1), tilt)
	mi.scale = Vector3(size, 1, size)
	_fade_free(mi, dur, Vector3(1.25, 1, 1.25))

## one-shot CPU particle puff
static func sparks(parent: Node3D, pos: Vector3, col: Color, n := 14, speed := 4.0, grav := -6.0, life := 0.5, size := 0.12, spread := 180.0, dir := Vector3.UP) -> void:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size * K, size * K)
	q.material = _billboard_mat(col)
	p.mesh = q
	p.amount = maxi(2, int(float(n) * 1.3 * density))
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, grav, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.position = pos
	p.emitting = true
	parent.add_child(p)
	p.finished.connect(p.queue_free)

static func _billboard_mat(col: Color) -> StandardMaterial3D:
	var m := mat(col, false)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return m

## continuous emitter attached to a node (auras, clouds); caller frees it
static func emitter(parent: Node3D, pos: Vector3, col: Color, n := 18, life := 0.9, size := 0.1, rise := 0.8, radius := 0.6) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = _billboard_mat(col)
	p.mesh = q
	p.amount = maxi(2, int(float(n) * density))
	p.lifetime = life
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3.UP
	p.spread = 30.0
	p.initial_velocity_min = rise * 0.5
	p.initial_velocity_max = rise
	p.gravity = Vector3.ZERO
	p.position = pos
	p.emitting = true
	parent.add_child(p)
	return p

## helix/spiral ribbon that spins and fades; inward spirals contract
static func spiral(parent: Node3D, pos: Vector3, col: Color, radius := 1.4, height := 1.6, turns := 2.0, dur := 0.6, inward := false) -> void:
	var n := 26
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	for i in n:
		var f := float(i) / float(n - 1)
		var a := f * turns * TAU
		var r := radius * (f if inward else 1.0 - f * 0.4)
		var sp := SphereMesh.new()
		sp.radius = 0.07
		sp.height = 0.14
		sp.radial_segments = 6
		sp.rings = 3
		_mi(holder, sp, col, Vector3(cos(a) * r, f * height, sin(a) * r))
	var tw := holder.create_tween().set_parallel(true)
	tw.tween_property(holder, "rotation:y", TAU * (-1.0 if inward else 1.0), dur)
	tw.tween_property(holder, "scale", Vector3(0.2, 1, 0.2) if inward else Vector3(1.4, 1, 1.4), dur).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(holder.queue_free)

## ground spikes erupting (thorns, ice, crystals)
static func spikes(parent: Node3D, pos: Vector3, col: Color, n := 6, radius := 1.0, h := 1.0, dur := 0.5) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in n:
		var a := TAU * float(i) / float(n) + rng.randf_range(-0.3, 0.3)
		var r := radius * rng.randf_range(0.2, 1.0)
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.12
		c.height = h * rng.randf_range(0.6, 1.0)
		c.radial_segments = 5
		c.rings = 1
		var mi := _mi(parent, c, col, pos + Vector3(cos(a) * r, c.height * 0.5, sin(a) * r), false)
		mi.scale = Vector3(1, 0.05, 1)
		mi.rotation = Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
		var tw := mi.create_tween()
		tw.tween_property(mi, "scale", Vector3.ONE, dur * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(dur * 0.4)
		tw.tween_property(mi, "scale", Vector3(1, 0.02, 1), dur * 0.35)
		tw.tween_callback(mi.queue_free)

## vertical light pillar
static func column(parent: Node3D, pos: Vector3, col: Color, h := 5.0, r := 0.7, dur := 0.5) -> void:
	var c := CylinderMesh.new()
	c.top_radius = r * 0.5
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 1
	var mi := _mi(parent, c, Color(col.r, col.g, col.b, 0.55), pos + Vector3(0, h * 0.5, 0))
	_fade_free(mi, dur, Vector3(0.3, 1.1, 0.3))

## translucent dome (fields, shields)
static func dome(parent: Node3D, pos: Vector3, r: float, col: Color, dur := 0.7) -> void:
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 16
	s.rings = 8
	var mi := _mi(parent, s, Color(col.r, col.g, col.b, 0.22), pos)
	mi.scale = Vector3(r * 0.3, r * 0.3, r * 0.3)
	_fade_free(mi, dur, Vector3(3.2, 3.2, 3.2))

## camera-facing icon sprite that pops up over a fighter (shows WHICH ability was cast)
static func glyph(parent: Node3D, pos: Vector3, tex: Texture2D, dur := 0.9, size := 1.7) -> void:
	if tex == null:
		return
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.shaded = false
	sp.pixel_size = size / 256.0
	sp.position = pos
	sp.scale = Vector3(0.2, 0.2, 0.2)
	parent.add_child(sp)
	var tw := sp.create_tween()
	tw.tween_property(sp, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sp, "position:y", pos.y + 0.8, dur)
	tw.tween_property(sp, "modulate:a", 0.0, 0.25)
	tw.tween_callback(sp.queue_free)
