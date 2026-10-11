extends Node3D
## One VFX instance: up to 3 quad layers (1 draw each) animated by the vfx.gdshader pattern kinds. Driven by VfxStage.tick(dt) so hit-stop
## (dt = 0) freezes it. `persist` effects (zones, statuses, held stances) loop their middle phase until finish() or set_remaining() runs out.

const SHADER := preload("res://src/critters/shaders/vfx.gdshader")
const GROUND_Y := 0.05

var layers: Array = []
var age := 0.0
var persist := false
var finishing := false
var fin_t := 0.0
var expire_at := 0.0       # seconds of age at which a persistent effect fades (the real remaining time from the sim)
var key := ""              # state-driven identity (zone id, status name ...), "" for one-shots
var follow: Node3D = null  # follow a rig (statuses) or a moving thing
var follow_off := Vector3.ZERO
var done := false
var total := 0.0

func draw_count() -> int:
	return layers.size()

static func _quad(plane: String, w: float, h: float) -> ArrayMesh:
	var vs := PackedVector3Array()
	var uv := PackedVector2Array()
	match plane:
		"g":   # ground, centered, forward = +X
			vs = PackedVector3Array([Vector3(-w * 0.5, 0, h * 0.5), Vector3(w * 0.5, 0, h * 0.5), Vector3(w * 0.5, 0, -h * 0.5), Vector3(-w * 0.5, 0, -h * 0.5)])
			uv = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		"v":   # vertical standing on the ground, facing the side camera (+Z)
			vs = PackedVector3Array([Vector3(-w * 0.5, 0, 0), Vector3(w * 0.5, 0, 0), Vector3(w * 0.5, h, 0), Vector3(-w * 0.5, h, 0)])
			uv = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		"m":   # beam / centered vertical: x from 0..w, y centered
			vs = PackedVector3Array([Vector3(0, -h * 0.5, 0), Vector3(w, -h * 0.5, 0), Vector3(w, h * 0.5, 0), Vector3(0, h * 0.5, 0)])
			uv = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		_:     # billboard unit quad (scaled in the shader)
			vs = PackedVector3Array([Vector3(-0.5, -0.5, 0), Vector3(0.5, -0.5, 0), Vector3(0.5, 0.5, 0), Vector3(-0.5, 0.5, 0)])
			uv = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	m.custom_aabb = AABB(Vector3(-w, -h, -w), Vector3(2 * w, 2 * h + 2, 2 * w))
	return m

## layer: {k, pl, sz: Vector2, off: Vector3, t0, life, c1: Color, c2: Color, g0, g1, rot, seed, a}
func add_layer(L: Dictionary, facing: float) -> void:
	var pl: String = L.get("pl", "g")
	var sz: Vector2 = L.get("sz", Vector2(2, 2))
	var mi := MeshInstance3D.new()
	mi.mesh = _quad(pl, sz.x, sz.y)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.render_priority = 4
	m.set_shader_parameter("kind", int(L.get("k", 0)))
	m.set_shader_parameter("tint", L.get("c1", Color.WHITE))
	m.set_shader_parameter("tint2", L.get("c2", Color.WHITE))
	m.set_shader_parameter("seed", float(L.get("seed", randf() * 10.0)))
	m.set_shader_parameter("alpha", float(L.get("a", 1.0)))
	m.set_shader_parameter("aspect", sz.x / maxf(sz.y, 0.001) if pl != "g" else 1.0)
	if pl == "m":
		m.set_shader_parameter("aspect", sz.x / maxf(sz.y * 0.5, 0.001))
	if pl == "b":
		m.set_shader_parameter("billboard", 1.0)
		m.set_shader_parameter("size_x", sz.x)
		m.set_shader_parameter("size_y", sz.y)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	var off: Vector3 = L.get("off", Vector3.ZERO)
	mi.position = Vector3(off.x * facing, off.y + (GROUND_Y if pl == "g" else 0.0), off.z)
	if pl == "g" or pl == "m" or pl == "v":
		pass
	if pl == "m" and facing < 0.0:
		mi.rotation.y = PI
	if pl == "g" and facing < 0.0:
		mi.rotation.y = PI
	add_child(mi)
	var d := {"mi": mi, "mat": m, "t0": float(L.get("t0", 0.0)), "life": maxf(float(L.get("life", 0.5)), 0.05), "g0": float(L.get("g0", 1.0)),
			"g1": float(L.get("g1", 1.0)), "rot": float(L.get("rot", 0.0)), "pl": pl, "persist": bool(L.get("persist", false)), "base_rot": mi.rotation.y}
	layers.append(d)
	total = maxf(total, d["t0"] + d["life"])
	if d["persist"]:
		persist = true

func finish() -> void:
	if persist and not finishing:
		finishing = true
		fin_t = 0.0

func tick(dt: float) -> void:
	if done:
		return
	age += dt
	if finishing:
		fin_t += dt
	var alive := false
	for d in layers:
		var lt: float = (age - float(d["t0"])) / float(d["life"])
		var mi: MeshInstance3D = d["mi"]
		var tt := lt
		if d["persist"]:
			if finishing:
				tt = 0.72 + clampf(fin_t / 0.35, 0.0, 1.0) * 0.28     # fade-out phase
			elif lt < 0.3:
				tt = lt
			else:
				tt = 0.3 + 0.38 * (0.5 + 0.5 * sin((age - float(d["t0"])) * 2.6))
		if lt < 0.0:
			mi.visible = false
			alive = true
			continue
		if tt > 1.0:
			mi.visible = false
			continue
		alive = true
		mi.visible = true
		(d["mat"] as ShaderMaterial).set_shader_parameter("t", clampf(tt, 0.0, 1.0))
		var gs := lerpf(d["g0"], d["g1"], clampf(lt, 0.0, 1.0))
		if d["pl"] == "b":
			mi.scale = Vector3.ONE
		else:
			mi.scale = Vector3(gs, gs if d["pl"] != "m" else 1.0, gs)
		if d["rot"] != 0.0 and d["pl"] == "g":
			mi.rotation.y = d["base_rot"] + deg_to_rad(d["rot"]) * age
	if follow != null and is_instance_valid(follow):
		global_position = follow.global_position + follow_off
	if not alive or (finishing and fin_t > 0.4):
		done = true
