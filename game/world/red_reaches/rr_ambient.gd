class_name RrAmbient
extends Node3D
## Red Reaches ambience (Agent 2): a slow day clock (day -> amber dusk -> dawn) that grades the zone lighting and drives NPC
## schedules, a weather machine (clear / dust devils / red dusk wind / rare glittering mineral storm) and ambient creatures
## (ticking mites tracing cracks, plate beetles leaning on warm slate at dusk). Cost: 1 MultiMesh (mites), <= 3 CPUParticles
## emitters that only run near the player, nothing allocates per frame; the lighting grade updates at 2 Hz.

signal phase_changed(phase: String)

const CYCLE_S := 780.0                  # one full day (real seconds)
const WEATHER := [["clear", 0.42], ["devils", 0.28], ["wind", 0.2], ["glitter", 0.1]]
const DEVIL_FIELDS := [[118.0, -2.0, 15.0], [196.0, 8.0, 22.0], [110.0, 34.0, 7.0], [60.0, 0.0, 6.0], [232.0, 3.0, 6.0]]
## crack polylines the skitter mites trace and tick along (x, z)
const CRACKS := [
	[[44.0, -6.0], [48.0, -4.0], [51.0, -5.5], [55.0, -3.0], [58.0, -4.5]],
	[[62.0, -29.0], [65.0, -31.0], [68.0, -30.0], [70.0, -33.0]],
	[[178.0, 14.0], [182.0, 12.0], [186.0, 15.0], [191.0, 13.0]],
]
const MITES_PER_CRACK := 14

var level: Node = null
var lighting: Node = null               # CritterLighting
var ground_fn: Callable
var focus_fn: Callable
var t_day := 0.03                       # 0 = high noon, 0.5 = deep dusk
var phase := "day"
var weather := "clear"
var dusk_k := 0.0
var dust_k := 0.0
var _dust_target := 0.0
var _weather_t := 40.0
var _grade_t := 0.0
var _rng := RandomNumberGenerator.new()
var _devils: Array = []                 # [{node: CPUParticles3D, from, to, t, dur}]
var _glitter: CPUParticles3D = null
var _mites: MultiMeshInstance3D = null
var _mite_state: Array = []             # per mite: [crack, t, speed, dir]
var _mite_t := 0.0
var _beetles: Array = []
var _focus := Vector3.ZERO
var _mite_n := 0

func setup(lvl: Node, ground_cb: Callable, focus_cb: Callable) -> void:
	level = lvl
	ground_fn = ground_cb
	focus_fn = focus_cb
	_rng.randomize()
	for n in get_tree().root.find_children("*", "CritterLighting", true, false):
		lighting = n
		break
	_build_devils()
	_build_glitter()
	_build_mites()
	_build_beetles()
	_apply_grade()

func qa_set_clock(t: float) -> void:
	t_day = t
	_grade_t = 0.0

func qa_set_weather(w: String) -> void:
	_set_weather(w)

# ------------------------------------------------------------------ builders
func _dust_mesh() -> BoxMesh:
	var bm := BoxMesh.new()
	bm.size = Vector3(0.14, 0.14, 0.14)
	return bm

func _build_devils() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.5, 0.34, 0.55)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := _dust_mesh()
	mesh.material = mat
	for i in 2:
		var p := CPUParticles3D.new()
		p.name = "DustDevil_%d" % i
		p.amount = 56
		p.lifetime = 2.6
		p.mesh = mesh
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.35
		p.direction = Vector3.UP
		p.spread = 8.0
		p.initial_velocity_min = 1.6
		p.initial_velocity_max = 2.6
		p.orbit_velocity_min = 0.9
		p.orbit_velocity_max = 1.4
		p.radial_accel_min = 0.6
		p.radial_accel_max = 1.2
		p.gravity = Vector3.ZERO
		p.scale_amount_min = 0.6
		p.scale_amount_max = 2.2
		p.local_coords = false
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.emitting = false
		p.visible = false
		add_child(p)
		_devils.append({"node": p, "from": Vector3.ZERO, "to": Vector3.ZERO, "t": 0.0, "dur": 1.0, "on": false})

func _build_glitter() -> void:
	_glitter = CPUParticles3D.new()
	_glitter.name = "MineralGlitter"
	_glitter.amount = 70
	_glitter.lifetime = 3.2
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.93, 0.7)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.material = m
	_glitter.mesh = bm
	_glitter.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_glitter.emission_box_extents = Vector3(14, 3, 12)
	_glitter.direction = Vector3(1, 0.1, 0.2)
	_glitter.spread = 25.0
	_glitter.initial_velocity_min = 1.4
	_glitter.initial_velocity_max = 3.0
	_glitter.gravity = Vector3.ZERO
	_glitter.local_coords = false
	_glitter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glitter.emitting = false
	_glitter.visible = false
	add_child(_glitter)

func _build_mites() -> void:
	var st := ToonKit.begin()
	ToonKit.rock(st, Vector3(0, 0.07, 0), Vector3(0.09, 0.06, 0.12), Color(0.45, 0.30, 0.26), 77, 0)
	for k in 3:
		var z := -0.05 + float(k) * 0.05
		ToonKit.cylinder(st, Vector3(-0.12, 0.02, z), Vector3(0.12, 0.02, z), 0.008, 0.008, 3, Color(0.3, 0.2, 0.18), false)
	var mesh := ToonKit.finish(st)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	_mite_n = CRACKS.size() * MITES_PER_CRACK
	mm.instance_count = _mite_n
	_mites = MultiMeshInstance3D.new()
	_mites.name = "TickingMites"
	_mites.multimesh = mm
	_mites.material_override = ToonKit.material({"roughness": 0.9, "outline": 0.0})
	_mites.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mites.custom_aabb = AABB(Vector3(30, -12, -45), Vector3(180, 24, 70))
	add_child(_mites)
	for c in CRACKS.size():
		for i in MITES_PER_CRACK:
			_mite_state.append([c, _rng.randf() * float(CRACKS[c].size() - 1), _rng.randf_range(0.25, 0.7), 1.0 if _rng.randf() < 0.5 else -1.0])
	_update_mites(0.0)

func _build_beetles() -> void:
	# plate beetles leaning on warm slate at dusk (decor only: not enemies, no AI)
	var spots := [[193.5, 4.5, 40.0], [195.0, 6.8, 25.0], [201.5, 14.0, -140.0]]
	for sp in spots:
		var v := VisualFactory.creature("plate_beetle")
		if v == null:
			continue
		v.name = "RestingBeetle"
		v.visible = false
		add_child(v)
		var x: float = sp[0]
		var z: float = sp[1]
		v.position = Vector3(x, float(ground_fn.call(x, z)), z)
		v.rotation = Vector3(0.0, deg_to_rad(float(sp[2])), 0.28)
		v.scale = Vector3.ONE * 0.85
		if v.has_method("set_process"):
			v.set_process(false)
		_beetles.append(v)

# ------------------------------------------------------------------ per frame
func _process(delta: float) -> void:
	_focus = focus_fn.call()
	t_day = fmod(t_day + delta / CYCLE_S, 1.0)
	_grade_t -= delta
	if _grade_t <= 0.0:
		_grade_t = 0.5
		_apply_grade()
	_weather_t -= delta
	if _weather_t <= 0.0:
		_pick_weather()
	dust_k = move_toward(dust_k, _dust_target, delta * 0.04)
	for d in _devils:
		_tick_devil(d, delta)
	if _glitter.emitting:
		_glitter.global_position = Vector3(_focus.x, _focus.y + 2.0, _focus.z)
	_mite_t -= delta
	if _mite_t <= 0.0:
		_mite_t = 0.1
		_update_mites(0.1)

func _apply_grade() -> void:
	dusk_k = 0.6 * (0.5 - 0.5 * cos(TAU * t_day))
	var ph := "day"
	if dusk_k > 0.12:
		ph = "dusk" if t_day < 0.5 else "dawn"
	if ph != phase:
		phase = ph
		phase_changed.emit(phase)
		var dusk_on := phase == "dusk"
		for b in _beetles:
			b.visible = dusk_on or phase == "dawn"
	if lighting and lighting.has_method("set_grade"):
		lighting.set_grade(dusk_k, dust_k)

# ------------------------------------------------------------------ weather
func _pick_weather() -> void:
	var r := _rng.randf()
	var acc := 0.0
	for w in WEATHER:
		acc += float(w[1])
		if r <= acc:
			_set_weather(str(w[0]))
			return
	_set_weather("clear")

func _set_weather(w: String) -> void:
	weather = w
	_weather_t = _rng.randf_range(70.0, 130.0)
	match w:
		"wind":
			_dust_target = 0.55
		"glitter":
			_dust_target = 0.3
		_:
			_dust_target = 0.0
	var gl := w == "glitter"
	_glitter.emitting = gl
	_glitter.visible = gl
	if w == "devils":
		for d in _devils:
			_start_devil(d)
	else:
		for d in _devils:
			d["on"] = false
			(d["node"] as CPUParticles3D).emitting = false
			(d["node"] as CPUParticles3D).visible = false
	if level and level.has_method("_ambient_weather_changed"):
		level.call("_ambient_weather_changed", w)

func _start_devil(d: Dictionary) -> void:
	var f: Array = DEVIL_FIELDS[_rng.randi() % DEVIL_FIELDS.size()]
	# prefer fields near the player so the effect is seen
	var best := 1e9
	for fld in DEVIL_FIELDS:
		var dd := absf(float(fld[0]) - _focus.x)
		if dd < best + _rng.randf() * 30.0:
			best = dd
			f = fld
	var a := _rng.randf() * TAU
	var r1 := _rng.randf() * float(f[2])
	var a2 := a + _rng.randf_range(1.5, 3.5)
	var r2 := _rng.randf() * float(f[2])
	d["from"] = Vector3(float(f[0]) + cos(a) * r1, 0, float(f[1]) + sin(a) * r1)
	d["to"] = Vector3(float(f[0]) + cos(a2) * r2, 0, float(f[1]) + sin(a2) * r2)
	d["t"] = 0.0
	d["dur"] = _rng.randf_range(40.0, 70.0)
	d["on"] = true
	(d["node"] as CPUParticles3D).emitting = true
	(d["node"] as CPUParticles3D).visible = true

func _tick_devil(d: Dictionary, delta: float) -> void:
	if not bool(d["on"]):
		return
	d["t"] = float(d["t"]) + delta
	var u := float(d["t"]) / float(d["dur"])
	if u >= 1.0:
		_start_devil(d)
		return
	var p: Vector3 = (d["from"] as Vector3).lerp(d["to"], u)
	var n: CPUParticles3D = d["node"]
	n.global_position = Vector3(p.x, float(ground_fn.call(p.x, p.z)), p.z)
	# only emit when someone can see it
	var near := Vector2(p.x - _focus.x, p.z - _focus.z).length() < 70.0
	if n.emitting != near:
		n.emitting = near
		n.visible = near

# ------------------------------------------------------------------ mites
func _update_mites(dt: float) -> void:
	var mm := _mites.multimesh
	var near := _focus.x > 20.0 and _focus.x < 220.0
	if not near:
		mm.visible_instance_count = 0
		return
	mm.visible_instance_count = -1
	var i := 0
	for ms in _mite_state:
		var c: int = ms[0]
		var pts: Array = CRACKS[c]
		var t: float = ms[1] + float(ms[3]) * float(ms[2]) * dt
		var seg := pts.size() - 1
		if t >= float(seg):
			t = float(seg)
			ms[3] = -1.0
		elif t <= 0.0:
			t = 0.0
			ms[3] = 1.0
		ms[1] = t
		var k := mini(int(t), seg - 1)
		var u := t - float(k)
		var a: Array = pts[k]
		var b: Array = pts[k + 1]
		var x := lerpf(float(a[0]), float(b[0]), u) + sin(float(i) * 3.1) * 0.35
		var z := lerpf(float(a[1]), float(b[1]), u) + cos(float(i) * 2.3) * 0.3
		var y: float = ground_fn.call(x, z)
		var yaw := atan2(-(float(b[0]) - float(a[0])) * float(ms[3]), -(float(b[1]) - float(a[1])) * float(ms[3]))
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw + 1.5708), Vector3(x, y, z)))
		i += 1
