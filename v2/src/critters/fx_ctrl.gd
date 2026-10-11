extends RefCounted
## Per-rig FX: swing smear trail (ribbon between weapon base and tip sampled over recent frames), flat star-burst hit spark,
## white hit flash and the 2-frame impact inversion. Two extra draw calls at most (smear + spark), hidden when idle.
## All visuals are presentation constants (seconds / pixels), not gameplay numbers.

const Toon := preload("res://src/critters/toon.gd")

const TRAIL_LEN := 9            # samples (frames) kept for the smear ribbon
const SMEAR_WIDTH := 0.55       # ribbon width as a fraction of base->tip length
const SPARK_LIFE := 0.2
const FLASH_LIFE := 0.11
const IMPACT_FRAMES := 2

var rig: Node3D
var mat: ShaderMaterial          # character material (toon + outline)
var smear: MeshInstance3D
var smear_mat: ShaderMaterial
var spark: MeshInstance3D
var spark_mat: ShaderMaterial
var trail: Array = []            # [ [tip, base], ... ] in rig space, newest last
var smear_on := false
var smear_alpha := 0.0
var spark_t := 1.0
var spark_active := false
var flash_t := 0.0
var impact_left := 0
var thread: MeshInstance3D
var thread_mat: ShaderMaterial
var thread_t := 1.0
var glow_boost := 0.0
var glow_target := 0.0

func _init(r: Node3D, character_mat: ShaderMaterial, accent: Color, glow: Color) -> void:
	rig = r
	mat = character_mat
	smear = MeshInstance3D.new()
	smear.name = "smear"
	smear_mat = Toon.fx(glow.lerp(Color.WHITE, 0.25), 0)
	smear.material_override = smear_mat
	smear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smear.visible = false
	smear.top_level = false
	rig.add_child(smear)
	spark = MeshInstance3D.new()
	spark.name = "spark"
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	spark.mesh = q
	spark_mat = Toon.fx(accent.lerp(Color.WHITE, 0.2), 1)
	spark.material_override = spark_mat
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spark.visible = false
	rig.add_child(spark)
	thread = MeshInstance3D.new()
	thread.name = "thread"
	thread_mat = Toon.fx(glow, 0)
	thread.material_override = thread_mat
	thread.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	thread.visible = false
	rig.add_child(thread)

func start_smear() -> void:
	smear_on = true

func stop_smear() -> void:
	smear_on = false

func sample(tip_world: Vector3, base_world: Vector3) -> void:
	if smear_on:
		trail.append([rig.to_local(tip_world), rig.to_local(base_world)])
		if trail.size() > TRAIL_LEN:
			trail.pop_front()
	elif trail.size() > 0:
		trail.pop_front()
	var show := trail.size() >= 2 and (smear_on or smear_alpha > 0.02)
	smear_alpha = move_toward(smear_alpha, 1.0 if smear_on else 0.0, 0.25)
	if not show:
		smear.visible = false
		return
	smear.visible = true
	smear_mat.set_shader_parameter("alpha", smear_alpha)
	var vs := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var n := trail.size()
	for i in range(n):
		var tip: Vector3 = trail[i][0]
		var bs: Vector3 = trail[i][1]
		var inner: Vector3 = tip.lerp(bs, SMEAR_WIDTH)
		vs.append(tip); uv.append(Vector2(float(i) / (n - 1), 1.0))
		vs.append(inner); uv.append(Vector2(float(i) / (n - 1), 0.0))
		if i > 0:
			var a := (i - 1) * 2
			idx.append_array([a, a + 1, a + 2, a + 2, a + 1, a + 3])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	smear.mesh = m

func hit_spark(local_pos: Vector3, size: float, color: Color) -> void:
	spark.position = local_pos
	spark.scale = Vector3(size, size, size)
	spark_mat.set_shader_parameter("tint", color)
	spark_t = 0.0
	spark_active = true
	spark.visible = true

## A wavering psychic thread (ribbon) between two world points for `life` seconds (compel / mind control).
func thread_from(a: Vector3, b: Vector3, life: float) -> void:
	_th_a = rig.to_local(a)
	_th_b = rig.to_local(b)
	thread_t = 0.0
	_th_life = life
	thread.visible = true

var _th_a := Vector3.ZERO
var _th_b := Vector3.ZERO
var _th_life := 1.0

func _update_thread(dt: float) -> void:
	if thread_t >= 1.0:
		return
	thread_t += dt / _th_life
	if thread_t >= 1.0:
		thread.visible = false
		return
	var vs := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var n := 14
	var side := (_th_b - _th_a).cross(Vector3.UP).normalized()
	for i in range(n + 1):
		var f := float(i) / n
		var p := _th_a.lerp(_th_b, f) + Vector3(0, sin(f * 9.0 + thread_t * 20.0) * 0.12 * sin(f * PI), 0)
		vs.append(p + side * 0.04); uv.append(Vector2(f, 1.0))
		vs.append(p - side * 0.04); uv.append(Vector2(f, 0.0))
		if i > 0:
			var a := (i - 1) * 2
			idx.append_array([a, a + 1, a + 2, a + 2, a + 1, a + 3])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	thread.mesh = m
	thread_mat.set_shader_parameter("alpha", 1.0 - thread_t)

func flash() -> void:
	flash_t = FLASH_LIFE

func impact_frame(frames: int = IMPACT_FRAMES) -> void:
	impact_left = frames

func boost_glow(amount: float) -> void:
	glow_target = amount

func update(dt: float) -> void:
	_update_thread(dt)
	if spark_active:
		spark_t += dt / SPARK_LIFE
		spark_mat.set_shader_parameter("t", spark_t)
		if spark_t >= 1.0:
			spark_active = false
			spark.visible = false
	if flash_t > 0.0:
		flash_t = maxf(0.0, flash_t - dt)
	Toon.set_both(mat, "flash", clampf(flash_t / FLASH_LIFE, 0.0, 1.0))
	if impact_left > 0:
		Toon.set_both(mat, "invert_mode", 1.0)
		impact_left -= 1
	else:
		Toon.set_both(mat, "invert_mode", 0.0)
	glow_boost = lerpf(glow_boost, glow_target, 1.0 - exp(-10.0 * dt))
	mat.set_shader_parameter("glow_strength", 1.0 + glow_boost)

## Optional full-screen 2-frame inversion for the BoutScene: add the returned node under the UI, set visible for 2 frames.
## (One screen read, only while visible. Skip on low-end tiers.)
static func make_invert_overlay() -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = 90
	var cr := ColorRect.new()
	cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform sampler2D scr : hint_screen_texture, filter_nearest;\nvoid fragment(){ vec3 c = texture(scr, SCREEN_UV).rgb; float l = dot(c, vec3(0.33)); COLOR = vec4(vec3(1.0 - step(0.35, l)), 1.0); }\n"
	var m := ShaderMaterial.new()
	m.shader = sh
	cr.material = m
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(cr)
	cl.visible = false
	return cl
