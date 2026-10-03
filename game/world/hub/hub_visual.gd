extends Node3D
## Terrarium One — the Common (Agent 1, CONTRACTS §6). Builds the diorama geometry procedurally; the
## hotspot / camera / NPC markers and the cast billboards live in hub_visual.tscn so they are editable.
## No Camera3D here (Agent 2 owns the camera). Plaza centre = origin, camera side = +Z.

const ATLAS_TEX := preload("res://game/art/world/reaches_atlas.png")
const ATLAS_JSON := "res://game/art/world/reaches_atlas.json"

const FLOOR_STONE := Color(0.66, 0.52, 0.42)
const WALL := Color(0.62, 0.50, 0.44)
const WALL_DARK := Color(0.42, 0.33, 0.30)
const METAL := Color(0.42, 0.44, 0.48)
const METAL_DARK := Color(0.26, 0.27, 0.30)
const WOOD := Color(0.50, 0.33, 0.22)
const BRASS := Color(0.66, 0.52, 0.34)
const CLOTHS := [Color(0.72, 0.20, 0.16), Color(0.86, 0.62, 0.24), Color(0.30, 0.52, 0.50), Color(0.52, 0.32, 0.56), Color(0.40, 0.56, 0.30)]
const LIGHTS := [Color(0.55, 1.0, 0.85), Color(1.0, 0.82, 0.45), Color(0.70, 0.75, 1.0), Color(0.75, 1.0, 0.55)]

@export var with_lighting: bool = true

## Default facing for the ambient cast (world XZ direction).
const NPC_FACING := {"mollusk": Vector3(1, 0, 0.3), "bramvex": Vector3(-1, 0, 0.3), "nerit": Vector3(0.5, 0, 1),
	"zephyr": Vector3(1, 0, 0.2), "nyxaris": Vector3(0, 0, 1), "pharilux": Vector3(-1, 0, 0.6),
	"solmara": Vector3(0.4, 0, 1), "scarlith": Vector3(0, 0, 1), "mara": Vector3(-0.6, 0, 1)}
var _idle_t := 3.0
var _glass_quads: Array = []

var lighting: Node3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 2048
	var geo := Node3D.new()
	geo.name = "Geometry"
	add_child(geo)
	move_child(geo, 0)
	_build_floor(geo)
	var st := ToonKit.begin()
	var gst := ToonKit.begin()
	_build_walls(st, gst)
	_build_table(st)
	_build_stalls(st, gst)
	_build_habitat_wing(st, gst)
	_build_codex(st, gst)
	_build_lab(st, gst)
	_build_pool_rim(st)
	var mi := ToonKit.mesh_instance(ToonKit.finish(st), ToonKit.material({"outline": 0.035}), "Architecture")
	geo.add_child(mi)
	var glow := ToonKit.mesh_instance(gst.commit(), _vertex_glow(), "Glow")
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geo.add_child(glow)
	_build_glass(geo)
	_build_living_lights(geo)
	_build_pool_water(geo)
	_build_gate(geo)
	_build_plants(geo)
	_build_collision(geo)
	if with_lighting:
		lighting = load("res://game/world/common/world_lighting.gd").new()
		lighting.name = "Lighting"
		lighting.set("preset", "hub")
		add_child(lighting)
		_tune_lighting()
	_face_npcs()


func _face_npcs() -> void:
	for id in NPC_FACING:
		var bb := get_node_or_null("NPC_%s/Billboard" % id)
		if bb and bb.has_method("set_facing"):
			bb.set_facing(NPC_FACING[id])


## Ambient life: every few seconds someone glances somewhere else, then back.
func _process(delta: float) -> void:
	_idle_t -= delta
	if _idle_t > 0.0:
		return
	_idle_t = _rng.randf_range(2.5, 5.0)
	var ids: Array = NPC_FACING.keys()
	var id: String = ids[_rng.randi() % ids.size()]
	var bb := get_node_or_null("NPC_%s/Billboard" % id)
	if bb == null or not bb.has_method("set_facing"):
		return
	var base: Vector3 = NPC_FACING[id]
	bb.set_facing(base.rotated(Vector3.UP, _rng.randf_range(-1.2, 1.2)))
	var tw := bb.create_tween()
	tw.tween_interval(_rng.randf_range(1.5, 3.0))
	tw.tween_callback(bb.set_facing.bind(base))


func _tune_lighting() -> void:
	var env: Environment = lighting.get("env")
	var sun: DirectionalLight3D = lighting.get("sun")
	if env:
		env.background_color = Color(0.16, 0.12, 0.13)
		env.ambient_light_color = Color(0.82, 0.70, 0.66)
		env.ambient_light_energy = 0.62
		env.fog_density = 0.008
		env.fog_light_color = Color(0.36, 0.26, 0.26)
	if sun:
		sun.light_energy = 0.95
		sun.rotation_degrees = Vector3(-58, -24, 0)
		sun.directional_shadow_max_distance = 45.0


func _vertex_glow() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1.6, 1.6, 1.6)
	return m


# ------------------------------------------------------------------ floor

func _build_floor(geo: Node3D) -> void:
	# flagstone plaza (terrain shader, stone weight 1) on a 1 m grid with a sunken pool basin
	var x0 := -22.0
	var z0 := -18.0
	var nx := 45
	var nz := 31
	var verts := PackedVector3Array()
	var nrm := PackedVector3Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()
	for iz in nz:
		for ix in nx:
			var x := x0 + ix
			var z := z0 + iz
			verts.append(Vector3(x, _floor_h(x, z), z))
			nrm.append(Vector3.UP)
			var pool := 1.0 - smoothstep(4.0, 5.0, Vector2(x + 5.0, z + 11.0).length())
			col.append(Color(1.0 - pool * 0.6, 1.0, 0.0, pool * 0.5))
	for iz in nz - 1:
		for ix in nx - 1:
			var a := iz * nx + ix
			idx.append_array([a, a + 1, a + nx + 1, a, a + nx + 1, a + nx])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = nrm
	arrays[Mesh.ARRAY_COLOR] = col
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/shaders/terrain_toon.gdshader")
	m.set_shader_parameter("noise_tex", load("res://game/art/world/terrain_noise.png"))
	m.set_shader_parameter("flag_tex", load("res://game/art/world/flagstone.png"))
	m.set_shader_parameter("stone_a", Color(0.70, 0.58, 0.48))
	m.set_shader_parameter("stone_b", Color(0.55, 0.43, 0.38))
	m.set_shader_parameter("flag_scale", 0.42)
	var fl := ToonKit.mesh_instance(am, m, "Floor")
	geo.add_child(fl)


func _floor_h(x: float, z: float) -> float:
	var d := Vector2(x + 5.0, z + 11.0).length()
	return -0.9 * (1.0 - smoothstep(3.6, 4.4, d))


# ------------------------------------------------------------------ architecture

func _build_walls(st: SurfaceTool, gst: SurfaceTool) -> void:
	# back wall with buttresses + a glazed clerestory (terrarium glass) above
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 4.0, -17.0)), Vector3(44, 8, 1.2), WALL)
	ToonKit.box(st, Transform3D(Basis(), Vector3(0, 0.3, -16.2)), Vector3(44, 0.6, 0.6), WALL_DARK)
	for i in 9:
		var x := -20.0 + i * 5.0
		ToonKit.box(st, Transform3D(Basis(), Vector3(x, 4.5, -16.1)), Vector3(1.0, 9.0, 1.0), WALL_DARK)
		ToonKit.box(st, Transform3D(Basis(), Vector3(x, 9.1, -16.1)), Vector3(1.3, 0.4, 1.3), BRASS)
	# glass ribs arching overhead toward the camera (open front) — the Terrarium dome
	for i in 5:
		var x := -16.0 + i * 8.0
		var prev := Vector3(x, 9.0, -16.5)
		for k in 7:
			var t := float(k + 1) / 7.0
			var p := Vector3(x, 9.0 + sin(t * PI * 0.5) * 5.0, -16.5 + t * 9.0)
			ToonKit.cylinder(st, prev, p, 0.18, 0.18, 5, METAL, false)
			prev = p
	# translation boards: dark slates with glowing glyph rows (many scripts, one wall)
	var boards := [Vector3(-14, 4.6, -16.3), Vector3(-8.5, 5.2, -16.3), Vector3(8.5, 5.0, -16.3), Vector3(14, 4.4, -16.3), Vector3(0, 6.3, -16.3)]
	for bi in boards.size():
		var b: Vector3 = boards[bi]
		var w := 3.6 if bi != 4 else 6.0
		var h := 2.4 if bi != 4 else 1.6
		ToonKit.box(st, Transform3D(Basis(), b), Vector3(w + 0.3, h + 0.3, 0.12), WOOD)
		ToonKit.box(st, Transform3D(Basis(), b + Vector3(0, 0, 0.08)), Vector3(w, h, 0.06), Color(0.16, 0.15, 0.17))
		var rows := int(h / 0.32)
		for r in rows:
			var y := b.y + h * 0.5 - 0.25 - r * 0.32
			var x := b.x - w * 0.5 + 0.25
			var c: Color = [Color(0.95, 0.85, 0.6), Color(0.6, 0.95, 0.9), Color(0.95, 0.7, 0.9)][(r + bi) % 3]
			while x < b.x + w * 0.5 - 0.4:
				var gw := _rng.randf_range(0.12, 0.42)
				ToonKit.box(gst, Transform3D(Basis(), Vector3(x + gw * 0.5, y, b.z + 0.13)), Vector3(gw, 0.07, 0.02), c * 0.9)
				x += gw + _rng.randf_range(0.06, 0.16)
	# side walls (low, so the camera sees over them)
	for s: float in [-1.0, 1.0]:
		ToonKit.box(st, Transform3D(Basis(), Vector3(s * 21.5, 2.0, -6.0)), Vector3(1.0, 4.0, 22.0), WALL)
		ToonKit.box(st, Transform3D(Basis(), Vector3(s * 21.5, 4.1, -6.0)), Vector3(1.3, 0.25, 22.3), BRASS)


func _build_table(st: SurfaceTool) -> void:
	# The Common Table: reinforced, built from discarded Habitat panels (mismatched), nobody owns it
	var c := Vector3(0, 0, -1.0)
	var panels := [[Vector3(-1.6, 0, -0.5), Vector3(2.6, 0.12, 1.6), METAL], [Vector3(1.2, 0, -0.55), Vector3(3.0, 0.12, 1.5), WOOD],
		[Vector3(-1.4, 0, 0.75), Vector3(3.0, 0.12, 1.1), Color(0.36, 0.52, 0.48)], [Vector3(1.4, 0, 0.7), Vector3(2.6, 0.12, 1.2), METAL_DARK]]
	for p in panels:
		var off: Vector3 = p[0]
		ToonKit.box(st, Transform3D(Basis(Vector3.UP, _rng.randf_range(-0.03, 0.03)), c + off + Vector3(0, 1.0, 0)), p[1], p[2])
	# rivets / brackets
	for i in 6:
		ToonKit.box(st, Transform3D(Basis(), c + Vector3(-2.5 + i, 1.07, 0.12)), Vector3(0.5, 0.04, 0.16), BRASS)
	# legs: pipes and crates
	for lp in [Vector3(-2.6, 0, -1.0), Vector3(2.6, 0, -1.0), Vector3(-2.6, 0, 1.0), Vector3(2.6, 0, 1.0)]:
		var l: Vector3 = lp
		ToonKit.cylinder(st, c + l, c + l + Vector3(0, 0.95, 0), 0.14, 0.12, 6, METAL_DARK)
	ToonKit.box(st, Transform3D(Basis(), c + Vector3(0, 0.45, 0)), Vector3(1.1, 0.9, 0.9), WOOD.darkened(0.15))
	# stools / crates around it
	for a in [0.3, 1.2, 2.2, 3.4, 4.4, 5.5]:
		var p := c + Vector3(cos(a) * 3.8, 0, sin(a) * 2.4)
		if p.z > 0.9:
			ToonKit.cylinder(st, p, p + Vector3(0, 0.45, 0), 0.32, 0.3, 7, WOOD)
		else:
			ToonKit.box(st, Transform3D(Basis(Vector3.UP, a), p + Vector3(0, 0.3, 0)), Vector3(0.7, 0.6, 0.6), CLOTHS[int(a * 3) % CLOTHS.size()].darkened(0.2))
	# things on the table: cups, a map, a jar, a pot
	ToonKit.box(st, Transform3D(Basis(Vector3.UP, 0.2), c + Vector3(-1.0, 1.075, -0.2)), Vector3(1.2, 0.02, 0.8), Color(0.88, 0.80, 0.64))
	for p in [Vector3(1.5, 1.06, 0.2), Vector3(-2.0, 1.06, 0.6), Vector3(0.4, 1.06, 0.8)]:
		var pp: Vector3 = p
		ToonKit.cylinder(st, c + pp, c + pp + Vector3(0, 0.16, 0), 0.07, 0.08, 6, Color(0.82, 0.78, 0.7))
	ToonKit.cylinder(st, c + Vector3(2.2, 1.06, -0.6), c + Vector3(2.2, 1.4, -0.6), 0.22, 0.16, 8, Color(0.62, 0.36, 0.24))


func _build_stalls(st: SurfaceTool, gst: SurfaceTool) -> void:
	# market stalls along the back wall (right of the pool)
	var xs := [1.5, 6.0, 10.5]
	for i in xs.size():
		var x: float = xs[i]
		var z := -13.0
		var cloth: Color = CLOTHS[i % CLOTHS.size()]
		var cloth2: Color = CLOTHS[(i + 2) % CLOTHS.size()]
		ToonKit.box(st, Transform3D(Basis(), Vector3(x, 0.55, z + 0.6)), Vector3(3.4, 1.1, 1.0), WOOD)
		ToonKit.box(st, Transform3D(Basis(), Vector3(x, 1.12, z + 0.6)), Vector3(3.6, 0.08, 1.2), WOOD.lightened(0.1))
		for s: float in [-1.0, 1.0]:
			ToonKit.cylinder(st, Vector3(x + s * 1.7, 0, z + 1.2), Vector3(x + s * 1.7, 2.9, z + 1.2), 0.07, 0.07, 5, WOOD.darkened(0.2))
			ToonKit.cylinder(st, Vector3(x + s * 1.7, 0, z - 0.6), Vector3(x + s * 1.7, 3.3, z - 0.6), 0.07, 0.07, 5, WOOD.darkened(0.2))
		# striped awning sloping toward the plaza
		for k in 6:
			var u0 := -1.9 + k * (3.8 / 6.0)
			var u1 := u0 + 3.8 / 6.0
			var c := cloth if k % 2 == 0 else cloth2.lightened(0.2)
			var a := Vector3(x + u0, 3.35, z - 0.7)
			var b := Vector3(x + u1, 3.35, z - 0.7)
			var cc := Vector3(x + u1, 2.75, z + 1.6)
			var d := Vector3(x + u0, 2.75, z + 1.6)
			ToonKit.quad(st, a, b, cc, d, c)
			ToonKit.quad(st, d, cc, b, a, c.darkened(0.25))
			# scalloped edge
			ToonKit.tri(st, d, cc, (d + cc) * 0.5 + Vector3(0, -0.25, 0.02), c)
			ToonKit.tri(st, d, (d + cc) * 0.5 + Vector3(0, -0.25, 0.02), cc, c.darkened(0.25))
		# goods: fruit / jars / crystals
		for k in 7:
			var p := Vector3(x - 1.4 + k * 0.45, 1.25, z + 0.55 + _rng.randf_range(-0.2, 0.2))
			var gc: Color = [Color(0.9, 0.5, 0.2), Color(0.5, 0.8, 0.4), Color(0.85, 0.3, 0.35), Color(0.6, 0.5, 0.9)][(k + i) % 4]
			if (k + i) % 5 == 0:
				ToonKit.rock(gst, p + Vector3(0, 0.05, 0), Vector3(0.12, 0.2, 0.12), Color(0.55, 0.88, 1.0), k, 0)
			else:
				ToonKit.rock(st, p, Vector3(0.16, 0.13, 0.16), gc, k + i * 10, 0)
		# hanging sign
		ToonKit.box(st, Transform3D(Basis(), Vector3(x, 2.45, z + 1.62)), Vector3(1.4, 0.45, 0.06), Color(0.2, 0.18, 0.2))
		ToonKit.box(gst, Transform3D(Basis(), Vector3(x, 2.45, z + 1.66)), Vector3(1.0, 0.08, 0.02), Color(1.0, 0.85, 0.5))


func _build_habitat_wing(st: SurfaceTool, gst: SurfaceTool) -> void:
	# Habitat Wing entrance: brass-framed glass terrarium bay with plants inside, sign above
	var c := Vector3(15.0, 0, -9.0)
	var rot := Basis(Vector3.UP, deg_to_rad(-30.0))
	var xf := Transform3D(rot, c)
	ToonKit.box(st, xf.translated_local(Vector3(0, 0.25, 0)), Vector3(7.0, 0.5, 4.0), METAL_DARK)
	for s: float in [-1.0, 1.0]:
		ToonKit.box(st, xf.translated_local(Vector3(s * 3.4, 3.0, 1.8)), Vector3(0.35, 6.0, 0.35), BRASS)
		ToonKit.box(st, xf.translated_local(Vector3(s * 3.4, 3.0, -1.8)), Vector3(0.35, 6.0, 0.35), BRASS)
	ToonKit.box(st, xf.translated_local(Vector3(0, 6.1, 0)), Vector3(7.2, 0.4, 4.0), BRASS)
	for k in 3:
		ToonKit.box(st, xf.translated_local(Vector3(-2.2 + k * 2.2, 3.0, 1.8)), Vector3(0.12, 6.0, 0.12), BRASS.darkened(0.2))
	ToonKit.box(st, xf.translated_local(Vector3(0, 0.5, 2.0)), Vector3(2.0, 0.2, 1.4), METAL)   # step / door sill
	ToonKit.box(st, xf.translated_local(Vector3(0, 6.9, 1.9)), Vector3(3.6, 0.9, 0.12), Color(0.18, 0.2, 0.2))
	ToonKit.box(gst, xf.translated_local(Vector3(0, 6.9, 1.97)), Vector3(2.8, 0.14, 0.02), Color(0.6, 1.0, 0.8))
	# glass front (soft glow-tinted panes go in the glow mesh as faint quads)
	_glass_quads.append([xf * Vector3(-3.3, 0.5, 1.85), xf * Vector3(-1.1, 0.5, 1.85), xf * Vector3(-1.1, 5.9, 1.85), xf * Vector3(-3.3, 5.9, 1.85)])
	_glass_quads.append([xf * Vector3(1.1, 0.5, 1.85), xf * Vector3(3.3, 0.5, 1.85), xf * Vector3(3.3, 5.9, 1.85), xf * Vector3(1.1, 5.9, 1.85)])
	for s: float in [-1.0, 1.0]:
		_glass_quads.append([xf * Vector3(s * 3.4, 0.5, 1.8), xf * Vector3(s * 3.4, 0.5, -1.8), xf * Vector3(s * 3.4, 5.9, -1.8), xf * Vector3(s * 3.4, 5.9, 1.8)])


func _build_codex(st: SurfaceTool, gst: SurfaceTool) -> void:
	# Field Codex: carved lectern with an open book and a board of pinned specimen sketches
	var c := Vector3(-14.0, 0, 2.0)
	ToonKit.cylinder(st, c, c + Vector3(0, 1.0, 0), 0.35, 0.25, 7, WOOD)
	ToonKit.box(st, Transform3D(Basis(Vector3.RIGHT, -0.35), c + Vector3(0, 1.15, 0)), Vector3(1.3, 0.1, 0.9), WOOD.darkened(0.15))
	ToonKit.box(st, Transform3D(Basis(Vector3.RIGHT, -0.35) * Basis(Vector3.BACK, 0.08), c + Vector3(-0.3, 1.24, 0)), Vector3(0.6, 0.04, 0.8), Color(0.92, 0.86, 0.72))
	ToonKit.box(st, Transform3D(Basis(Vector3.RIGHT, -0.35) * Basis(Vector3.BACK, -0.08), c + Vector3(0.3, 1.24, 0)), Vector3(0.6, 0.04, 0.8), Color(0.92, 0.86, 0.72))
	ToonKit.rock(gst, c + Vector3(0, 1.6, -0.2), Vector3(0.12, 0.2, 0.12), Color(0.55, 0.88, 1.0), 3, 0)
	# board
	var b := c + Vector3(-1.2, 0, -2.8)
	ToonKit.box(st, Transform3D(Basis(Vector3.UP, 0.5), b + Vector3(0, 1.8, 0)), Vector3(3.2, 2.2, 0.15), WOOD)
	for i in 6:
		var p := b + Vector3(-0.9 + (i % 3) * 0.9, 1.4 + (i / 3) * 0.9, 0.0)
		var q := Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3.BACK, _rng.randf_range(-0.12, 0.12)), p)
		ToonKit.box(st, q.translated_local(Vector3(0, 0, 0.1)), Vector3(0.7, 0.55, 0.02), Color(0.9, 0.84, 0.7))
		ToonKit.box(st, q.translated_local(Vector3(0, 0.05, 0.12)), Vector3(0.4, 0.25, 0.01), Color(0.4, 0.25, 0.2))
	for s: float in [-1.0, 1.0]:
		ToonKit.cylinder(st, b + Vector3(s * 1.4, 0, s * -0.7), b + Vector3(s * 1.4, 1.0, s * -0.7), 0.06, 0.06, 4, WOOD.darkened(0.2))


func _build_lab(st: SurfaceTool, gst: SurfaceTool) -> void:
	# Mara's Lab corner: desk, three monitors, shelves with specimen jars
	var c := Vector3(14.5, 0, 2.5)
	ToonKit.box(st, Transform3D(Basis(Vector3.UP, 0.4), c + Vector3(0, 0.85, 0)), Vector3(3.2, 0.1, 1.3), METAL)
	for s: float in [-1.0, 1.0]:
		ToonKit.box(st, Transform3D(Basis(Vector3.UP, 0.4), c + Basis(Vector3.UP, 0.4) * Vector3(s * 1.3, 0.42, 0)), Vector3(0.2, 0.85, 1.2), METAL_DARK)
	var mb := Basis(Vector3.UP, 0.4)
	for k in 3:
		var p := c + mb * Vector3(-0.9 + k * 0.9, 1.35, -0.45)
		ToonKit.box(st, Transform3D(mb * Basis(Vector3.UP, (1 - k) * 0.25), p), Vector3(0.8, 0.55, 0.06), METAL_DARK)
		ToonKit.box(gst, Transform3D(mb * Basis(Vector3.UP, (1 - k) * 0.25), p + mb * Vector3(0, 0, 0.04)), Vector3(0.7, 0.45, 0.01), Color(0.35, 0.75, 0.95))
	# shelves behind
	var sh := c + Vector3(1.5, 0, -2.4)
	ToonKit.box(st, Transform3D(mb, sh + mb * Vector3(0, 1.6, -0.3)), Vector3(2.6, 3.2, 0.1), WOOD.darkened(0.25))
	for r in 4:
		ToonKit.box(st, Transform3D(mb, sh + mb * Vector3(0, 0.62 + r * 0.95, 0.0)), Vector3(2.6, 0.08, 0.6), WOOD)
	for sx: float in [-1.0, 1.0]:
		ToonKit.box(st, Transform3D(mb, sh + mb * Vector3(sx * 1.3, 1.6, 0.0)), Vector3(0.08, 3.2, 0.6), WOOD.darkened(0.1))
	for r in 3:
		for k in 4:
			var p := sh + mb * Vector3(-0.9 + k * 0.6, 0.66 + r * 0.95, 0.0)
			ToonKit.cylinder(st, p, p + Vector3(0, 0.4, 0), 0.14, 0.14, 6, Color(0.55, 0.75, 0.72))
			if (r + k) % 3 == 0:
				ToonKit.rock(gst, p + Vector3(0, 0.2, 0), Vector3(0.07, 0.1, 0.07), Color(0.7, 1.0, 0.6), r * 4 + k, 0)


func _build_pool_rim(st: SurfaceTool) -> void:
	# stone rim around Solmara's tidal pool
	var c := Vector3(-5.0, 0, -11.0)
	var n := 20
	for i in n:
		var a := TAU * float(i) / n
		var p := c + Vector3(cos(a), 0, sin(a)) * 4.5
		ToonKit.rock(st, p + Vector3(0, 0.05, 0), Vector3(0.75, 0.35 + 0.12 * float(i % 3), 0.6), Color(0.52, 0.48, 0.46), i + 400, 0)
	for i in 5:
		var a := _rng.randf() * TAU
		ToonKit.rock(st, c + Vector3(cos(a), 0, sin(a)) * 3.0 + Vector3(0, -0.6, 0), Vector3(0.5, 0.5, 0.45), Color(0.40, 0.42, 0.44), i + 500, 0)


func _build_pool_water(geo: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "TidalPool"
	var q := QuadMesh.new()
	q.size = Vector2(9.0, 9.0)
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = load("res://game/art/shaders/water_toon.gdshader")
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(-5.0, -0.35, -11.0)
	geo.add_child(mi)


func _build_glass(geo: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in _glass_quads:
		for i in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(q[i])
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(0.70, 0.92, 0.95, 0.16)
	var mi := ToonKit.mesh_instance(st.commit(), m, "Glass")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geo.add_child(mi)


func _build_living_lights(geo: Node3D) -> void:
	# Nerit's living lights: strings of glowing bulbs swagged across the Common (one mesh each)
	var lst := ToonKit.begin()
	var wst := ToonKit.begin()
	var strings := [[Vector3(-20, 8.0, -15), Vector3(20, 8.0, -15)], [Vector3(-20, 7.4, -9), Vector3(20, 7.6, -10)],
		[Vector3(-16, 8.2, -16), Vector3(-2, 6.8, 2)], [Vector3(16, 8.2, -16), Vector3(4, 7.0, 2)], [Vector3(-20, 6.8, -3), Vector3(20, 7.0, -4)]]
	for si in strings.size():
		var a: Vector3 = strings[si][0]
		var b: Vector3 = strings[si][1]
		var n := 22
		var prev := a
		for k in n + 1:
			var t := float(k) / n
			var p := a.lerp(b, t) - Vector3(0, sin(t * PI) * 1.6, 0)
			if k > 0:
				ToonKit.cylinder(wst, prev, p, 0.025, 0.025, 3, Color(0.2, 0.25, 0.2), false)
			if k % 2 == 1:
				var c: Color = LIGHTS[(k + si) % LIGHTS.size()]
				ToonKit.rock(lst, p + Vector3(0, -0.28, 0), Vector3(0.24, 0.3, 0.24), c, k + si * 50, 1)
			prev = p
	var wire := ToonKit.mesh_instance(ToonKit.finish(wst), ToonKit.material({"outline": 0.0}), "LightWires")
	wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geo.add_child(wire)
	# a few real coloured pools under the strings so the bulbs actually light the Common (shadowless)
	var pools := [[Vector3(-9, 5.6, -11), 0], [Vector3(9, 5.8, -12), 2], [Vector3(0, 5.4, -3), 4]]
	for pl in pools:
		var ol := OmniLight3D.new()
		ol.name = "LivingLightPool"
		ol.position = pl[0]
		ol.light_color = (LIGHTS[int(pl[1]) % LIGHTS.size()] as Color).lerp(Color(1, 0.9, 0.75), 0.35)
		ol.light_energy = 2.0
		ol.omni_range = 11.0
		ol.omni_attenuation = 1.2
		ol.shadow_enabled = false
		geo.add_child(ol)
	var bulbs := ToonKit.mesh_instance(lst.commit(), _vertex_glow(), "LivingLights")
	bulbs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geo.add_child(bulbs)


func _build_gate(geo: Node3D) -> void:
	var g: Node3D = ReachesStructures.build({"kind": "gate_ring", "pos": [-14.0, 0.0, -8.0], "rot_y": 35.0}, null)
	g.name = "GateRing"
	geo.add_child(g)


func _build_plants(geo: Node3D) -> void:
	# painted plants (Reaches kit) in the Habitat bay, planters and corners — one MultiMesh
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_JSON))
	if not (parsed is Dictionary):
		return
	var items: Dictionary = parsed.get("items", {})
	var spots: Array = []
	var hab := Transform3D(Basis(Vector3.UP, deg_to_rad(-30.0)), Vector3(15.0, 0.5, -9.0))
	for i in 9:
		spots.append([hab * Vector3(_rng.randf_range(-2.8, 2.8), 0, _rng.randf_range(-1.4, 1.0)), ["tree_small", "plant_agave", "plant_blue", "plant_orange", "plant_cone"][i % 5]])
	for p in [Vector3(-19, 0, -14), Vector3(19, 0, -14), Vector3(-19.5, 0, 4), Vector3(19.5, 0, 6), Vector3(-9, 0, -15), Vector3(-1.5, 0, -15.2), Vector3(-10, 0, 6.5), Vector3(9.5, 0, 7.0)]:
		spots.append([p, "plant_redbush"])
		spots.append([p + Vector3(0.8, 0, 0.4), "plant_bulb"])
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.center_offset = Vector3(0, 0.5, 0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = q
	mm.instance_count = spots.size()
	for i in spots.size():
		var id: String = spots[i][1]
		var it: Dictionary = items.get(id, items.values()[0])
		var px: Array = it["px"]
		var hm := float(it.get("height_m", 1.5)) * (0.55 if id == "tree_small" else 0.9)
		var wm := hm * float(px[0]) / float(px[1])
		var pos: Vector3 = spots[i][0]
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(wm, hm, 1)), pos))
		mm.set_instance_color(i, Color(1.0, _rng.randf(), float(i % 2), 1))
		var uv: Array = it["uv"]
		mm.set_instance_custom_data(i, Color(float(uv[0]), float(uv[1]), float(uv[2]), float(uv[3])))
	var mat := ShaderMaterial.new()
	mat.shader = ToonKit.occluding_shader("res://game/art/shaders/scatter_billboard.gdshader")
	mat.set_shader_parameter("atlas", ATLAS_TEX)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Plants"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-25, -2, -20), Vector3(50, 15, 35))
	geo.add_child(mmi)


func _build_collision(geo: Node3D) -> void:
	# floor + walls + table + stalls + habitat bay + pool basin (layer 1) so Agent 2 can walk the Common
	var sb := StaticBody3D.new()
	sb.name = "Collision"
	sb.collision_layer = 1
	sb.collision_mask = 0
	geo.add_child(sb)
	_cbox(sb, Vector3(0, -0.5, -5), Vector3(46, 1.0, 34))
	_cbox(sb, Vector3(0, 4, -17), Vector3(44, 8, 1.2))
	for s: float in [-1.0, 1.0]:
		_cbox(sb, Vector3(s * 21.5, 2, -6), Vector3(1, 4, 22))
	_cbox(sb, Vector3(0, 0.55, -1.0), Vector3(5.8, 1.1, 3.0))
	for x in [1.5, 6.0, 10.5]:
		_cbox(sb, Vector3(x, 0.6, -12.4), Vector3(3.6, 1.2, 1.4))
	var hab := CollisionShape3D.new()
	var hb := BoxShape3D.new()
	hb.size = Vector3(7.0, 6.0, 3.6)
	hab.shape = hb
	hab.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-30.0)), Vector3(15.0, 3.0, -9.3))
	sb.add_child(hab)
	# pool: a ring of low posts keeps walkers out of the water (Solmara stands in it)
	var pool := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 4.2
	cyl.height = 1.2
	pool.shape = cyl
	pool.position = Vector3(-5, 0.6, -11)
	sb.add_child(pool)


func _cbox(sb: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	c.shape = b
	c.position = pos
	sb.add_child(c)
