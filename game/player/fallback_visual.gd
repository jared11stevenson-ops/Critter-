class_name FallbackVisual
extends Node3D
## Placeholder visual implementing the CONTRACTS §3 (character billboard) and §5 (creature) API
## so gameplay runs before Agent 1's art is merged. Simple toon-shaded primitives, tinted per id.
## Replaced automatically at runtime when the real scenes exist (see VisualFactory).

var character_id := ""
var kind := "character"     # "character" | "creature"
var _height := 1.8
var _radius := 0.5
var _pivot: Node3D
var _mats: Array = []
var _base_cols: Array = []
var _move := 0.0
var _t := 0.0
var _downed := false
var _ghost := 1.0
var _flash := 0.0
var _hl_col := Color(0, 0, 0, 0)
var _hl_on := false
var _glow := 0.0
var _hover := false
var markers: Dictionary = {}
var _beam: MeshInstance3D = null
var _vents: Array = []

const CHAR_SPECS := {
	"aruun": {"h": 2.4, "r": 0.55, "body": "#9c2f22", "acc": "#d9803a", "head": "#c8462b"},
	"cigarra": {"h": 1.65, "r": 0.42, "body": "#3b2a44", "acc": "#b8c24a", "head": "#8f8a52"},
	"mara": {"h": 1.7, "r": 0.35, "body": "#4f7a8c", "acc": "#e9dcc0", "head": "#d8b48c"},
	"dexter": {"h": 1.85, "r": 0.36, "body": "#3a3d46", "acc": "#c8462b", "head": "#d8b48c"},
	# Ledger Rivals (human opponents): a coat in the faction's colors; the accent is the hat / visor.
	"rival_dominion": {"h": 1.85, "r": 0.4, "body": "#4b5058", "acc": "#b53a2a", "head": "#c9a07a"},
	"rival_undermarket": {"h": 1.8, "r": 0.4, "body": "#6b4a2a", "acc": "#d9a43a", "head": "#b98c66"},
	"rival_free_scale": {"h": 1.75, "r": 0.4, "body": "#3a6b4a", "acc": "#e0d28a", "head": "#a97c5a"},
	"rival_helix": {"h": 1.85, "r": 0.38, "body": "#cfd5d8", "acc": "#2a8f9a", "head": "#d8b48c"},
}

## NPC placeholder specs registered at runtime by NpcLife (id -> {h, r, body, acc, head, shape}); real models replace them
## through game/art/models/npcs/npc_registry.json. shape: human | beetle | mantis | crane | herder.
static var extra_specs: Dictionary = {}

func setup(id: String, as_kind: String) -> void:
	character_id = id
	kind = as_kind
	_build()

func _build() -> void:
	_pivot = Node3D.new()
	add_child(_pivot)
	if kind == "character":
		_build_character()
	else:
		match character_id:
			"skitter_mite": _build_mite()
			"plate_beetle": _build_beetle()
			"dust_grazer": _build_grazer()
			"dominion_drone": _build_drone()
			"resonance_pylon": _build_pylon()
			"augur_rig": _build_rig()
			_: _build_mite()
	_bake()
	_add_shadow()

## Perf: merge every static part that shares a material into one mesh (a Skitter Mite goes from
## 10 draws to 3) and let small creatures rely on the blob shadow instead of casting real shadows.
func _bake() -> void:
	var groups: Dictionary = {}
	var order: Array = []
	for c in _pivot.get_children():
		if c is MeshInstance3D and not _vents.has(c):
			var m: Material = (c as MeshInstance3D).material_override
			if not groups.has(m):
				groups[m] = []
				order.append(m)
			groups[m].append(c)
	for m in order:
		var parts: Array = groups[m]
		if parts.size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mi in parts:
			st.append_from((mi as MeshInstance3D).mesh, 0, (mi as MeshInstance3D).transform)
		var merged := MeshInstance3D.new()
		merged.mesh = st.commit()
		merged.material_override = m
		_pivot.add_child(merged)
		for mi in parts:
			_pivot.remove_child(mi)
			mi.queue_free()
	if kind == "creature" and _radius < 1.0:
		for c in _pivot.get_children():
			if c is GeometryInstance3D:
				(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ---------------- builders ----------------
func _mat(col: Color, emissive: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.8
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.4
	m.emission_enabled = true
	m.emission = col * emissive
	_mats.append(m)
	_base_cols.append(col)
	return m

func _mesh(m: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	(parent if parent else _pivot).add_child(mi)
	return mi

func _sphere(r: float, segs: int = 12) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = maxi(4, segs / 2)
	return s

func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 4
	return c

func _box(sz: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = sz
	return b

func _cyl(r_top: float, r_bot: float, h: float, segs: int = 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return c

func _build_character() -> void:
	var spec: Dictionary = CHAR_SPECS.get(character_id, extra_specs.get(character_id, {}))
	var col := UiKit.char_color(character_id)
	_height = float(spec.get("h", float(Canon.character(character_id).get("height_m", 1.8))))
	_height = clampf(_height, 0.3, 6.0)
	_radius = float(spec.get("r", clampf(_height * 0.2, 0.15, 1.2)))
	var body := _mat(Color(spec.get("body", col.darkened(0.2).to_html())))
	var acc := _mat(Color(spec.get("acc", col.lightened(0.3).to_html())), 0.15)
	var headm := _mat(Color(spec.get("head", col.to_html())))
	var torso_h := _height * 0.62
	_mesh(_capsule(_radius, torso_h), body, Vector3(0, torso_h * 0.5 + _height * 0.08, 0))
	var head_r := _radius * 0.78
	_mesh(_sphere(head_r), headm, Vector3(0, _height - head_r, 0))
	# eyes so facing reads
	var eye := _mat(Color(0.95, 0.9, 0.6), 0.8)
	_mesh(_sphere(head_r * 0.22, 6), eye, Vector3(head_r * 0.4, _height - head_r * 0.9, -head_r * 0.85))
	_mesh(_sphere(head_r * 0.22, 6), eye, Vector3(-head_r * 0.4, _height - head_r * 0.9, -head_r * 0.85))
	if character_id == "aruun":
		# giraffe-beetle neck horns + Morrow the mace
		_mesh(_cyl(0.06, 0.12, 0.7), acc, Vector3(0.2, _height + 0.2, 0), Vector3(0, 0, -15))
		_mesh(_cyl(0.06, 0.12, 0.7), acc, Vector3(-0.2, _height + 0.2, 0), Vector3(0, 0, 15))
		var arm := Node3D.new()
		arm.name = "Weapon"
		arm.position = Vector3(_radius + 0.25, _height * 0.55, -0.1)
		_pivot.add_child(arm)
		var stone := _mat(Color("#7b8794"), 0.25)
		_mesh(_cyl(0.07, 0.07, 1.2), _mat(Color("#4a3226")), Vector3(0, 0, -0.5), Vector3(90, 0, 0), Vector3.ONE, arm)
		_mesh(_sphere(0.36, 10), stone, Vector3(0, 0, -1.15), Vector3.ZERO, Vector3.ONE, arm)
	elif character_id.begins_with("rival_"):
		# peaked cap / visor band + a satchel so the silhouette reads as "person with a job", not a partner
		_mesh(_cyl(head_r * 1.05, head_r * 1.15, 0.12, 12), acc, Vector3(0, _height - head_r * 0.1, 0))
		_mesh(_box(Vector3(head_r * 1.6, 0.05, head_r * 0.9)), acc, Vector3(0, _height - head_r * 0.25, -head_r * 0.85))
		_mesh(_box(Vector3(_radius * 0.9, _height * 0.2, 0.18)), acc, Vector3(_radius * 0.9, _height * 0.42, 0.05))
		var wp := Node3D.new()
		wp.name = "Weapon"
		wp.position = Vector3(-_radius - 0.12, _height * 0.55, -0.1)
		_pivot.add_child(wp)
		_mesh(_box(Vector3(0.1, 0.1, 0.7)), _mat(Color("#2a2a30")), Vector3(0, 0, -0.35), Vector3.ZERO, Vector3.ONE, wp)
	elif spec.has("shape"):
		_npc_shape(str(spec["shape"]), acc, body, headm, head_r)
	elif character_id == "cigarra":
		var crown := _mat(Color("#b8c24a"), 0.6)
		for i in 5:
			var a := TAU * float(i) / 5.0
			_mesh(_sphere(0.09, 6), crown, Vector3(cos(a) * 0.32, _height + 0.12, sin(a) * 0.32))
		_mesh(_box(Vector3(_radius * 2.6, _height * 0.55, 0.08)), _mat(Color("#8f8a52")), Vector3(0, _height * 0.5, _radius * 0.9), Vector3(10, 0, 0))

## Species silhouettes for named NPCs (placeholders until Agent 1's models land): readable at 15 m, <= 4 draws after bake.
func _npc_shape(shape: String, acc: Material, body: Material, headm: Material, head_r: float) -> void:
	match shape:
		"beetle":
			# plate-beetle elder: domed slate shell on the back, two short antennae
			_mesh(_sphere(_radius * 1.25, 10), acc, Vector3(0, _height * 0.52, _radius * 0.55), Vector3.ZERO, Vector3(1.0, 0.8, 0.7))
			_mesh(_cyl(0.03, 0.04, 0.45), acc, Vector3(0.12, _height + 0.1, -0.05), Vector3(-20, 0, -18))
			_mesh(_cyl(0.03, 0.04, 0.45), acc, Vector3(-0.12, _height + 0.1, -0.05), Vector3(-20, 0, 18))
		"mantis":
			# stick mantis: folded forearms, long thin limbs, a wide brow
			_mesh(_cyl(0.04, 0.05, _height * 0.5), acc, Vector3(_radius + 0.08, _height * 0.55, -0.12), Vector3(-35, 0, -8))
			_mesh(_cyl(0.04, 0.05, _height * 0.5), acc, Vector3(-_radius - 0.08, _height * 0.55, -0.12), Vector3(-35, 0, 8))
			_mesh(_box(Vector3(head_r * 2.2, 0.06, head_r * 0.8)), acc, Vector3(0, _height - head_r * 0.4, -head_r * 0.5))
		"crane":
			# long-legged crane: stilt legs, a beak and a cable coil at the hip
			_mesh(_cyl(0.03, 0.04, _height * 0.42), acc, Vector3(0.14, _height * 0.2, 0), Vector3.ZERO)
			_mesh(_cyl(0.03, 0.04, _height * 0.42), acc, Vector3(-0.14, _height * 0.2, 0), Vector3.ZERO)
			_mesh(_cyl(0.0, 0.07, 0.5), acc, Vector3(0, _height - head_r * 0.9, -head_r - 0.2), Vector3(-90, 0, 0))
			_mesh(_cyl(0.2, 0.2, 0.12, 10), body, Vector3(_radius, _height * 0.45, 0.1), Vector3(0, 0, 90))
		"herder":
			# wide hat and a staff
			_mesh(_cyl(head_r * 1.9, head_r * 1.9, 0.05, 12), acc, Vector3(0, _height - head_r * 0.2, 0))
			_mesh(_cyl(0.03, 0.03, _height * 1.05), body, Vector3(_radius + 0.3, _height * 0.52, -0.05))
		"clerk":
			# Dominion clerk: stiff cap, ledger board held to the chest
			_mesh(_cyl(head_r * 1.0, head_r * 1.1, 0.14, 12), acc, Vector3(0, _height - head_r * 0.1, 0))
			_mesh(_box(Vector3(0.5, 0.65, 0.06)), acc, Vector3(0, _height * 0.55, -_radius - 0.05), Vector3(10, 0, 0))
		"scarf":
			# Free Scale contact: green scarf and a wide pack
			_mesh(_cyl(_radius * 1.05, _radius * 1.05, 0.16, 12), acc, Vector3(0, _height * 0.78, 0))
			_mesh(_box(Vector3(_radius * 1.6, _height * 0.38, 0.4)), body, Vector3(0, _height * 0.5, _radius + 0.12))
		_:
			# human work cap + satchel
			_mesh(_cyl(head_r * 1.0, head_r * 1.1, 0.1, 12), acc, Vector3(0, _height - head_r * 0.1, 0))
			_mesh(_box(Vector3(_radius * 0.9, _height * 0.2, 0.18)), acc, Vector3(_radius * 0.9, _height * 0.42, 0.05))

func _legs(mat: Material, n: int, r: float, len: float, y: float, thick: float = 0.05) -> void:
	for i in n:
		var side := 1.0 if i % 2 == 0 else -1.0
		var z := lerpf(-r * 0.7, r * 0.7, float(i / 2) / maxf(1.0, float(n / 2 - 1)))
		_mesh(_cyl(thick, thick * 0.6, len), mat, Vector3(side * (r + len * 0.3), y - len * 0.25, z), Vector3(0, 0, side * 55.0))

func _build_mite() -> void:
	_height = 0.6
	_radius = 0.5
	var body := _mat(Color("#a8452a"))
	var dark := _mat(Color("#5a2416"))
	_mesh(_sphere(0.42), body, Vector3(0, 0.32, 0.05), Vector3.ZERO, Vector3(1.0, 0.6, 1.25))
	_mesh(_sphere(0.22), dark, Vector3(0, 0.34, -0.45))
	_legs(dark, 6, 0.32, 0.4, 0.3, 0.035)
	var eye := _mat(Color(1, 0.8, 0.3), 0.9)
	_mesh(_sphere(0.05, 6), eye, Vector3(0.1, 0.42, -0.62))
	_mesh(_sphere(0.05, 6), eye, Vector3(-0.1, 0.42, -0.62))

func _build_beetle() -> void:
	_height = 1.8
	_radius = 1.4
	var plate := _mat(Color("#5d6470"))
	var under := _mat(Color("#3a3230"))
	_mesh(_sphere(1.2), under, Vector3(0, 0.8, 0), Vector3.ZERO, Vector3(1.0, 0.55, 1.3))
	for i in 3:
		_mesh(_sphere(1.15 - i * 0.12), plate, Vector3(0, 1.05 + i * 0.14, 0.4 - i * 0.45), Vector3.ZERO, Vector3(1.0, 0.45, 0.7))
	_mesh(_sphere(0.5), under, Vector3(0, 0.75, -1.45), Vector3.ZERO, Vector3(1.1, 0.8, 0.9))
	_mesh(_cyl(0.05, 0.14, 0.7), _mat(Color("#2a2420")), Vector3(0.25, 0.8, -1.9), Vector3(-70, 0, 0))
	_mesh(_cyl(0.05, 0.14, 0.7), _mat(Color("#2a2420")), Vector3(-0.25, 0.8, -1.9), Vector3(-70, 0, 0))
	_legs(under, 6, 0.9, 0.8, 0.6, 0.09)
	var eye := _mat(Color(1, 0.4, 0.2), 1.0)
	_mesh(_sphere(0.08, 6), eye, Vector3(0.25, 0.95, -1.8))
	_mesh(_sphere(0.08, 6), eye, Vector3(-0.25, 0.95, -1.8))

func _build_grazer() -> void:
	_height = 2.6
	_radius = 0.9
	var hide := _mat(Color("#cfa36a"))
	var dark := _mat(Color("#7a5a3a"))
	_mesh(_sphere(0.7), hide, Vector3(0, 1.9, 0), Vector3.ZERO, Vector3(0.8, 0.7, 1.3))
	_mesh(_cyl(0.12, 0.18, 0.9), hide, Vector3(0, 2.3, -0.8), Vector3(-40, 0, 0))
	_mesh(_sphere(0.26), dark, Vector3(0, 2.6, -1.15))
	for sx in [-1.0, 1.0]:
		for sz in [-0.5, 0.5]:
			_mesh(_cyl(0.05, 0.04, 1.7), dark, Vector3(sx * 0.35, 0.85, sz), Vector3(0, 0, sx * 6.0))

func _build_drone() -> void:
	_height = 0.9
	_radius = 0.6
	_hover = true
	var metal := _mat(Color("#4a4f58"))
	var red := _mat(Color("#d42a1e"), 1.4)
	_mesh(_sphere(0.45), metal, Vector3(0, 0.45, 0), Vector3.ZERO, Vector3(1.2, 0.7, 1.2))
	_mesh(_cyl(0.6, 0.6, 0.06, 16), _mat(Color("#2b2e33")), Vector3(0, 0.5, 0))
	_mesh(_sphere(0.14, 8), red, Vector3(0, 0.45, -0.48))
	_mesh(_box(Vector3(0.08, 0.08, 0.5)), metal, Vector3(0, 0.3, -0.45))

func _build_pylon() -> void:
	_height = 4.2
	_radius = 0.8
	var metal := _mat(Color("#3e434b"))
	var red := _mat(Color("#d42a1e"), 1.2)
	_mesh(_cyl(0.7, 0.9, 0.4, 8), metal, Vector3(0, 0.2, 0))
	_mesh(_cyl(0.18, 0.32, 3.8, 6), metal, Vector3(0, 2.2, 0))
	for i in 3:
		_mesh(_cyl(0.42, 0.42, 0.12, 12), red, Vector3(0, 1.4 + i * 1.0, 0))
	_mesh(_sphere(0.26, 8), red, Vector3(0, 4.2, 0))

func _build_rig() -> void:
	_height = 11.0
	_radius = 6.0
	var metal := _mat(Color("#4a4f58"))
	var dark := _mat(Color("#2b2e33"))
	var red := _mat(Color("#c8261c"), 0.8)
	_mesh(_cyl(5.0, 6.0, 2.4, 16), dark, Vector3(0, 1.2, 0))
	_mesh(_box(Vector3(6.5, 6.0, 6.5)), metal, Vector3(0, 5.2, 0))
	_mesh(_box(Vector3(7.0, 0.6, 7.0)), red, Vector3(0, 8.4, 0))
	_mesh(_cyl(0.6, 1.2, 4.0, 10), dark, Vector3(0, 10.4, 0))
	# drill arm toward -X (the arena)
	var arm := Node3D.new()
	arm.name = "Arm"
	arm.position = Vector3(-3.0, 6.5, 0)
	_pivot.add_child(arm)
	_mesh(_box(Vector3(7.0, 1.2, 1.2)), metal, Vector3(-3.5, 0, 0), Vector3.ZERO, Vector3.ONE, arm)
	_mesh(_cyl(0.05, 1.0, 3.0, 10), _mat(Color("#9aa3ad"), 0.2), Vector3(-7.5, -1.5, 0), Vector3(0, 0, -30), Vector3.ONE, arm)
	var tip := Marker3D.new()
	tip.name = "DrillTip"
	tip.position = Vector3(-8.5, -3.0, 0)
	arm.add_child(tip)
	markers["DrillTip"] = tip
	var core := Marker3D.new()
	core.name = "Core"
	core.position = Vector3(0, 5.5, 0)
	_pivot.add_child(core)
	markers["Core"] = core
	var vent_pos := [Vector3(-3.4, 3.0, -2.6), Vector3(-3.4, 3.0, 2.6), Vector3(-1.5, 3.0, 3.4)]
	for i in 3:
		var vm := Marker3D.new()
		vm.name = "Vent%d" % (i + 1)
		vm.position = vent_pos[i]
		_pivot.add_child(vm)
		markers[vm.name] = vm
		var v := _mesh(_cyl(0.9, 0.9, 0.3, 12), red, vent_pos[i], Vector3(0, 0, 90))
		_vents.append(v)
	_pivot.rotation.y = 0.0

func _add_shadow() -> void:
	var s := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(_radius * 2.6, _radius * 2.6)
	s.mesh = pm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.45))
	grad.set_color(1, Color(0, 0, 0, 0))
	g.gradient = grad
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	m.albedo_texture = g
	s.material_override = m
	s.position.y = 0.04
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(s)
	if _hover:
		s.position.y = -1.55

# ---------------- API (§3 + §5) ----------------
func _process(delta: float) -> void:
	_t += delta
	if _downed:
		return
	var bob := sin(_t * 12.0) * 0.06 * _move
	if _hover:
		bob = sin(_t * 3.0) * 0.12
	_pivot.position.y = bob
	_pivot.rotation.z = sin(_t * 6.0) * 0.05 * _move
	if _flash > 0.0 or _glow > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
		_glow = maxf(0.0, _glow - delta * 0.5)
		_apply_emission()

func _apply_emission() -> void:
	for i in _mats.size():
		var m: StandardMaterial3D = _mats[i]
		var base: Color = _base_cols[i]
		var e := Color(0, 0, 0)
		if _hl_on:
			e = _hl_col * 0.45
		e = e.lerp(Color(1, 0.3, 0.15), clampf(_glow, 0.0, 1.0) * 0.8)
		e = e.lerp(Color(1, 1, 1), clampf(_flash, 0.0, 1.0))
		m.emission = e
		var c := base
		if _downed:
			var g := (c.r + c.g + c.b) / 3.0
			c = Color(g, g, g).lerp(c, 0.3)
		c.a = _ghost
		m.albedo_color = c

func set_facing(dir: Vector3) -> void:
	var d := Vector3(dir.x, 0, dir.z)
	if d.length_squared() < 0.0001:
		return
	rotation.y = atan2(-d.x, -d.z)

func set_move_amount(v: float) -> void:
	_move = clampf(v, 0.0, 1.0)

func play_attack(attack_kind: String = "light") -> void:
	var tw := create_tween()
	var lunge := 0.35 if attack_kind == "heavy" else 0.2
	if attack_kind == "leap":
		tw.tween_property(_pivot, "scale", Vector3(1.2, 0.7, 1.2), 0.12)
		tw.tween_property(_pivot, "scale", Vector3(0.85, 1.25, 0.85), 0.12)
		tw.tween_property(_pivot, "scale", Vector3.ONE, 0.2)
		return
	if attack_kind == "cast":
		tw.tween_property(_pivot, "scale", Vector3(1.1, 0.9, 1.1), 0.08)
		tw.tween_property(_pivot, "scale", Vector3.ONE, 0.16)
		return
	tw.tween_property(_pivot, "position:z", -lunge, 0.06)
	tw.parallel().tween_property(_pivot, "rotation:x", -0.25, 0.06)
	tw.tween_property(_pivot, "position:z", 0.0, 0.18)
	tw.parallel().tween_property(_pivot, "rotation:x", 0.0, 0.18)
	var w := _pivot.get_node_or_null("Weapon")
	if w:
		var tw2 := create_tween()
		tw2.tween_property(w, "rotation:y", 1.6 if attack_kind != "heavy" else 2.4, 0.05)
		tw2.tween_property(w, "rotation:y", -1.2, 0.1)
		tw2.tween_property(w, "rotation:y", 0.0, 0.2)

func play_telegraph(duration: float) -> void:
	_glow = 1.0
	var tw := create_tween()
	tw.tween_property(_pivot, "scale", Vector3(1.12, 0.86, 1.12), duration * 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pivot, "scale", Vector3.ONE, 0.1)
	var tw2 := create_tween()
	tw2.tween_method(_set_glow, 0.2, 1.0, duration)

func _set_glow(v: float) -> void:
	_glow = v
	_apply_emission()

func _set_ghost_alpha(v: float) -> void:
	_ghost = v
	for m in _mats:
		(m as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_apply_emission()

func flash_hit() -> void:
	if bool(GameState.settings.get("reduce_flashing", false)):
		_flash = 0.45
	else:
		_flash = 1.0
	_apply_emission()
	var tw := create_tween()
	tw.tween_property(_pivot, "scale", Vector3(1.12, 0.9, 1.12), 0.04)
	tw.tween_property(_pivot, "scale", Vector3.ONE, 0.1)

func play_die() -> float:
	var tw := create_tween()
	tw.tween_property(_pivot, "scale", Vector3(1.3, 0.2, 1.3), 0.35).set_ease(Tween.EASE_IN)
	tw.parallel().tween_method(_set_ghost_alpha, 1.0, 0.0, 0.5)
	return 0.55

func set_downed(on: bool) -> void:
	_downed = on
	var tw := create_tween()
	tw.tween_property(_pivot, "rotation:x", (PI * 0.45) if on else 0.0, 0.3)
	tw.parallel().tween_property(_pivot, "position:y", -_height * 0.3 if on else 0.0, 0.3)
	_apply_emission()

func set_highlight(col: Color, on: bool) -> void:
	_hl_col = col
	_hl_on = on
	_apply_emission()

func set_ghost(alpha: float) -> void:
	_ghost = clampf(alpha, 0.0, 1.0)
	for m in _mats:
		(m as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if _ghost < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
		if _ghost < 0.99:
			(m as StandardMaterial3D).albedo_color = Color(0.6, 0.85, 1.0, _ghost)
	if _ghost < 0.99:
		_base_cols = _base_cols.map(func(_c): return Color(0.55, 0.85, 1.0))
		_hl_col = Color(0.4, 0.8, 1.0)
		_hl_on = true
		_apply_emission()

func get_height() -> float:
	return _height

func get_radius() -> float:
	return _radius

# --- boss extras ---
func set_phase(_p: int) -> void:
	_glow = 0.6
	_apply_emission()

func open_vents(on: bool) -> void:
	for v in _vents:
		var tw := create_tween()
		tw.tween_property(v, "scale", Vector3(1.4, 1.0, 1.4) if on else Vector3.ONE, 0.3)
		var m: StandardMaterial3D = (v as MeshInstance3D).material_override
		m.emission = Color(0.3, 0.9, 1.0) * 2.0 if on else Color(0.8, 0.15, 0.1)

func play_drill_slam() -> void:
	var arm := _pivot.get_node_or_null("Arm")
	if arm:
		var tw := create_tween()
		tw.tween_property(arm, "rotation:z", 0.35, 0.5)
		tw.tween_property(arm, "rotation:z", -0.35, 0.12)
		tw.tween_property(arm, "rotation:z", 0.0, 0.6)

func set_beam(on: bool, angle: float) -> void:
	if _beam == null:
		_beam = MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(34.0, 0.7, 0.7)
		_beam.mesh = b
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.35, 0.2)
		_beam.material_override = m
		add_child(_beam)
	_beam.visible = on
	# angle is world-space, about Y, direction (cos a, 0, sin a)
	var d := Vector3(cos(angle), 0, sin(angle))
	_beam.global_position = global_position + Vector3(0, 1.2, 0) + d * 17.0
	_beam.global_rotation = Vector3(0, -angle, 0)

func get_marker(n: String) -> Node3D:
	return markers.get(n, null)
