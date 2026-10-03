@tool
class_name CharacterBillboard
extends Node3D
## HD-2D character billboard cut from the approved model sheets (Agent 1, CONTRACTS §3).
## Front/side/back views chosen relative to the active camera; procedural animation in the vertex shader.

const SHADER := preload("res://game/art/shaders/billboard.gdshader")
const GHOST_SHADER := preload("res://game/art/shaders/billboard_ghost.gdshader")
const SHADOW_SHADER := preload("res://game/art/shaders/blob_shadow.gdshader")
const ROOT := "res://game/art/characters/"
const MARGIN_PX := 6.0

@export var character_id: String = "":
	set(v):
		character_id = v
		if is_inside_tree():
			_load_character()
## Seconds of random phase so a crowd does not breathe in sync.
@export var idle_phase: float = -1.0
@export var cast_blob_shadow: bool = true
## Overrides canon height (meters) when > 0.
@export var height_override: float = 0.0
## Auto light tint from the scene's sun / ambient / nearby omni lights.
@export var auto_light: bool = true

var _mesh: MeshInstance3D
var _shadow: MeshInstance3D
var _mat: ShaderMaterial
var _ghost_mat: ShaderMaterial
var _tex := {}            # view -> Texture2D
var _height := 1.8
var _views: Array = []
var _view := "front"
var _flip := false
var _facing := Vector3(0, 0, 1)
var _move := 0.0
var _move_target := 0.0
var _t := 0.0
var _last_pos := Vector3.ZERO
var _vel_screen_x := 0.0
# attack timeline
var _atk_kind := ""
var _atk_t := 0.0
# hit
var _flash := 0.0
var _wobble := 0.0
var _wobble_v := 0.0
# states
var _downed := false
var _downed_amt := 0.0
var _ghost := 1.0
var _highlight_on := false
var _highlight_amt := 0.0
var _highlight_col := Color(0.4, 0.9, 1.0)
var _light_timer := 0.0


func _ready() -> void:
	if idle_phase < 0.0:
		idle_phase = randf() * 10.0
	_t = idle_phase
	_build()
	_load_character()
	_last_pos = global_position


func _build() -> void:
	if _mesh:
		return
	_mesh = MeshInstance3D.new()
	_mesh.name = "Sprite"
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.center_offset = Vector3(0, 0.5, 0)
	_mesh.mesh = q
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mesh.material_override = _mat
	# generous AABB so the billboard is never culled while leaning / scaled
	_mesh.custom_aabb = AABB(Vector3(-3, -0.5, -3), Vector3(6, 7, 6))
	add_child(_mesh, false, Node.INTERNAL_MODE_FRONT)
	_shadow = MeshInstance3D.new()
	_shadow.name = "BlobShadow"
	var p := PlaneMesh.new()
	p.size = Vector2(1, 1)
	_shadow.mesh = p
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sm := ShaderMaterial.new()
	sm.shader = SHADOW_SHADER
	_shadow.material_override = sm
	_shadow.position = Vector3(0, 0.03, 0)
	add_child(_shadow, false, Node.INTERNAL_MODE_FRONT)


func _load_character() -> void:
	_build()
	_tex.clear()
	_views = []
	if character_id == "":
		return
	var dir := ROOT + character_id + "/"
	var meta := {}
	if FileAccess.file_exists(dir + "meta.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + "meta.json"))
		if parsed is Dictionary:
			meta = parsed
	_height = float(meta.get("height_m", 0.0))
	if _height <= 0.0:
		var canon_node := get_node_or_null("/root/Canon")
		if canon_node:
			_height = float(canon_node.character(character_id).get("height_m", 1.8))
		else:
			_height = 1.8
	if height_override > 0.0:
		_height = height_override
	for v in ["front", "side", "back"]:
		var p: String = dir + str(v) + ".png"
		if ResourceLoader.exists(p):
			_tex[v] = load(p)
			_views.append(v)
	if not _tex.has("front"):
		push_warning("CharacterBillboard: no front.png for " + character_id)
		return
	_apply_view("front", false)
	var front: Texture2D = _tex["front"]
	var w_m := _height * float(front.get_width()) / float(front.get_height())
	var r := clampf(minf(w_m, _height * 0.55), 0.35, 4.0)
	_shadow.scale = Vector3(r * 1.25, 1, r * 0.8)
	_shadow.visible = cast_blob_shadow


func _apply_view(view: String, flip: bool) -> void:
	if not _tex.has(view):
		view = "front"
	_view = view
	_flip = flip
	var t: Texture2D = _tex[view]
	var w := float(t.get_width())
	var h := float(t.get_height())
	var px_m := _height / h
	var mu := Vector2(MARGIN_PX / w, MARGIN_PX / h)
	for m in [_mat, _ghost_mat]:
		if m == null:
			continue
		m.set_shader_parameter("tex", t)
		m.set_shader_parameter("quad_size", Vector2(w * px_m, h * px_m) * (Vector2.ONE + 2.0 * mu))
		m.set_shader_parameter("margin_uv", mu)
		m.set_shader_parameter("flip_h", 1.0 if flip else 0.0)
		m.set_shader_parameter("outline_px", clampf(h / 240.0, 1.2, 3.2))


# ---------------------------------------------------------------- API (CONTRACTS §3)

func set_facing(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		_facing = dir.normalized()


func set_move_amount(v: float) -> void:
	_move_target = clampf(v, 0.0, 1.0)


func play_attack(kind: String = "light") -> void:
	_atk_kind = kind
	_atk_t = 0.0


func flash_hit() -> void:
	_flash = 1.0
	_wobble_v += (-1.0 if randf() < 0.5 else 1.0) * 2.6


func set_downed(downed: bool) -> void:
	_downed = downed


func set_highlight(color: Color, on: bool) -> void:
	_highlight_col = color
	_highlight_on = on


func set_ghost(alpha: float) -> void:
	_ghost = clampf(alpha, 0.0, 1.0)
	if _ghost < 0.999:
		if _ghost_mat == null:
			_ghost_mat = ShaderMaterial.new()
			_ghost_mat.shader = GHOST_SHADER
			_apply_view(_view, _flip)
		_mesh.material_override = _ghost_mat
		_ghost_mat.set_shader_parameter("ghost_alpha", _ghost)
		_shadow.visible = false
	else:
		_mesh.material_override = _mat
		_shadow.visible = cast_blob_shadow


func set_ghost_color(c: Color) -> void:
	if _ghost_mat == null:
		set_ghost(0.6)
	_ghost_mat.set_shader_parameter("ghost_color", c)


func get_height() -> float:
	return _height


## Extra helpers (optional for gameplay)
func get_view() -> String:
	return _view


func set_tint(c: Color) -> void:
	auto_light = false
	_mat.set_shader_parameter("light_tint", Vector3(c.r, c.g, c.b))


# ---------------------------------------------------------------- per-frame animation

func _process(delta: float) -> void:
	if _mat == null or _tex.is_empty():
		return
	_t += delta
	_move = move_toward(_move, _move_target, delta * 5.0)
	_update_view()
	_light_timer -= delta
	if auto_light and _light_timer <= 0.0:
		_light_timer = 0.25
		_update_light()
	var m := _move
	var h := _height
	var sx := 1.0
	var sy := 1.0
	var ox := 0.0
	var oy := 0.0
	var shear := 0.0
	# idle breathing (fades out while walking)
	var br := sin(_t * 2.1)
	sy += br * 0.012 * (1.0 - m)
	sx -= br * 0.006 * (1.0 - m)
	# walk cycle: bob, sway, lean into motion
	var freq := 9.0 / clampf(sqrt(h / 1.8), 0.6, 2.0)
	var ph := _t * freq
	oy += absf(sin(ph)) * 0.055 * h * 0.5 * m
	shear += sin(ph) * 0.035 * m
	sy += (absf(cos(ph)) - 0.5) * 0.03 * m
	var screen_dir := _screen_move_dir()
	shear += -screen_dir * 0.10 * m
	# attack timeline
	if _atk_kind != "":
		_atk_t += delta
		var r := _attack_pose(_atk_kind, _atk_t)
		if r.is_empty():
			_atk_kind = ""
		else:
			sx *= r[0]
			sy *= r[1]
			ox += r[2] * _side_sign()
			oy += r[3]
			shear += r[4] * -_side_sign()
	# hit wobble (damped spring)
	_wobble_v += (-_wobble * 120.0 - _wobble_v * 12.0) * delta
	_wobble += _wobble_v * delta
	shear += _wobble * 0.08
	_flash = maxf(0.0, _flash - delta * 5.5)
	# downed
	_downed_amt = move_toward(_downed_amt, 1.0 if _downed else 0.0, delta * 3.0)
	sy *= lerpf(1.0, 0.7, _downed_amt)
	sx *= lerpf(1.0, 1.08, _downed_amt)
	shear += 0.1 * _downed_amt
	_highlight_amt = move_toward(_highlight_amt, 1.0 if _highlight_on else 0.0, delta * 6.0)
	var mat: ShaderMaterial = _mesh.material_override
	mat.set_shader_parameter("anim_scale", Vector2(sx, sy))
	mat.set_shader_parameter("anim_offset", Vector2(ox, oy))
	mat.set_shader_parameter("anim_shear", shear)
	mat.set_shader_parameter("flash", _flash)
	mat.set_shader_parameter("flash_color", Color(1, 1, 1) if _flash > 0.6 else Color(1.0, 0.35, 0.3))
	mat.set_shader_parameter("desaturate", _downed_amt * 0.8)
	mat.set_shader_parameter("darken", _downed_amt * 0.25)
	mat.set_shader_parameter("highlight", _highlight_amt * (0.75 + 0.25 * sin(_t * 8.0)))
	mat.set_shader_parameter("highlight_color", _highlight_col)
	_shadow.scale.y = 1.0
	var sh_mat: ShaderMaterial = _shadow.material_override
	sh_mat.set_shader_parameter("strength", 0.5 * (1.0 - clampf(oy / maxf(h, 0.1), 0.0, 0.6)))


## Returns [scale_x, scale_y, offset_x(toward facing), offset_y, shear(toward facing)] or [] when finished.
func _attack_pose(kind: String, t: float) -> Array:
	var h := _height
	match kind:
		"light":
			if t < 0.08:
				var k := t / 0.08
				return [1.0 + 0.05 * k, 1.0 - 0.07 * k, -0.06 * k * h * 0.3, 0.0, -0.06 * k]
			elif t < 0.18:
				var k := (t - 0.08) / 0.1
				return [1.05 - 0.09 * k, 0.93 + 0.11 * k, lerpf(-0.02, 0.22, k) * h * 0.3, 0.0, lerpf(-0.06, 0.18, k)]
			elif t < 0.42:
				var k := _ease_out((t - 0.18) / 0.24)
				return [lerpf(0.96, 1.0, k), lerpf(1.04, 1.0, k), lerpf(0.22, 0.0, k) * h * 0.3, 0.0, lerpf(0.18, 0.0, k)]
		"heavy":
			if t < 0.22:
				var k := _ease_out(t / 0.22)
				return [1.0 + 0.1 * k, 1.0 - 0.14 * k, -0.15 * k * h * 0.3, 0.0, -0.16 * k]
			elif t < 0.34:
				var k := (t - 0.22) / 0.12
				return [lerpf(1.1, 0.9, k), lerpf(0.86, 1.12, k), lerpf(-0.15, 0.5, k) * h * 0.3, 0.0, lerpf(-0.16, 0.3, k)]
			elif t < 0.7:
				var k := _ease_out((t - 0.34) / 0.36)
				return [lerpf(0.9, 1.0, k) + sin(k * 9.0) * 0.03 * (1.0 - k), lerpf(1.12, 1.0, k), lerpf(0.5, 0.0, k) * h * 0.3, 0.0, lerpf(0.3, 0.0, k)]
		"cast":
			if t < 0.15:
				var k := t / 0.15
				return [1.0 - 0.04 * k, 1.0 + 0.06 * k, 0.0, 0.06 * k, -0.05 * k]
			elif t < 0.5:
				var k := _ease_out((t - 0.15) / 0.35)
				return [lerpf(0.96, 1.0, k), lerpf(1.06, 1.0, k), 0.0, lerpf(0.06, 0.0, k), lerpf(0.08, 0.0, k)]
		"leap":
			if t < 0.12:
				var k := t / 0.12
				return [1.0 + 0.12 * k, 1.0 - 0.22 * k, 0.0, 0.0, -0.05 * k]
			elif t < 0.5:
				var k := (t - 0.12) / 0.38
				return [lerpf(0.84, 0.95, k), lerpf(1.24, 1.05, k), 0.0, sin(k * PI) * 0.0, 0.12]
			elif t < 0.7:
				var k := (t - 0.5) / 0.2
				return [lerpf(1.14, 1.0, k), lerpf(0.84, 1.0, k), 0.0, 0.0, lerpf(0.05, 0.0, k)]
	return []


func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3.0)


func _camera() -> Camera3D:
	var vp := get_viewport()
	return vp.get_camera_3d() if vp else null


## +1 when the character faces screen-right, -1 when screen-left.
func _side_sign() -> float:
	var cam := _camera()
	var right := Vector3.RIGHT
	if cam:
		right = cam.global_transform.basis.x
	var d := _facing.dot(right)
	if absf(d) < 0.2:
		return -1.0 if _flip else 1.0
	return signf(d)


func _screen_move_dir() -> float:
	var p := global_position
	var cam := _camera()
	var right := Vector3.RIGHT
	if cam:
		right = cam.global_transform.basis.x
	var dv := p - _last_pos
	_last_pos = p
	var dt := get_process_delta_time()
	if dt > 0.0:
		var vx := dv.dot(right) / dt
		_vel_screen_x = lerpf(_vel_screen_x, clampf(vx / 5.0, -1.0, 1.0), 0.2)
	if _move < 0.01:
		return _side_sign() * 0.0
	return _vel_screen_x if absf(_vel_screen_x) > 0.05 else _side_sign() * 0.5


func _update_view() -> void:
	var cam := _camera()
	var fwd := Vector3(0, 0, -1)
	var right := Vector3.RIGHT
	if cam:
		fwd = -cam.global_transform.basis.z
		right = cam.global_transform.basis.x
	fwd.y = 0.0
	right.y = 0.0
	if fwd.length_squared() < 0.0001:
		return
	fwd = fwd.normalized()
	right = right.normalized()
	var toward_cam := -_facing.dot(fwd)   # 1 = facing the camera
	var side := _facing.dot(right)
	var view := _view
	# hysteresis bands
	var front_t := 0.5 if _view == "front" else 0.62
	var back_t := 0.5 if _view == "back" else 0.62
	if toward_cam > front_t:
		view = "front"
	elif toward_cam < -back_t:
		view = "back"
	elif absf(side) > 0.35:
		view = "side"
	var flip := _flip
	if view == "side":
		flip = side < 0.0
	elif view == "front":
		# 3/4 art: mirror when the character walks toward screen-left
		flip = false
	else:
		flip = false
	if not _tex.has(view):
		# fall back: side→front, back→front
		if view == "side" and _tex.has("front"):
			view = "front"
			flip = side < -0.35
		else:
			view = "front"
	if view != _view or flip != _flip:
		_apply_view(view, flip)


func _update_light() -> void:
	var tint := Color(1, 1, 1)
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var root := tree.current_scene
	var env: Environment = null
	var sun: DirectionalLight3D = null
	for n in _find_cached(root):
		if not is_instance_valid(n):
			continue
		if n is WorldEnvironment and env == null:
			env = (n as WorldEnvironment).environment
		elif n is DirectionalLight3D and sun == null and (n as DirectionalLight3D).visible:
			sun = n
	var amb := Color(0.55, 0.5, 0.5)
	if env:
		amb = env.ambient_light_color * env.ambient_light_energy
	tint = amb * 0.55
	if sun:
		var e := sun.light_energy
		tint += sun.light_color * clampf(e, 0.0, 2.0) * 0.6
	# nearby omni lights (hub living lights)
	for n in _omni_cache:
		if not is_instance_valid(n):
			continue
		var o := n as OmniLight3D
		if not o.visible:
			continue
		var d := o.global_position.distance_to(global_position + Vector3(0, _height * 0.5, 0))
		if d < o.omni_range:
			var att := pow(1.0 - d / o.omni_range, 1.5)
			tint += o.light_color * o.light_energy * att * 0.35
	tint.r = clampf(tint.r, 0.35, 1.25)
	tint.g = clampf(tint.g, 0.35, 1.25)
	tint.b = clampf(tint.b, 0.35, 1.25)
	_mat.set_shader_parameter("light_tint", Vector3(tint.r, tint.g, tint.b))
	if _ghost_mat:
		_ghost_mat.set_shader_parameter("light_tint", Vector3(1, 1, 1))
	if sun:
		# rim light comes from the side of the sun as seen on screen
		var cam := _camera()
		if cam:
			var ld := sun.global_transform.basis.z
			var rx := ld.dot(cam.global_transform.basis.x)
			_mat.set_shader_parameter("rim_dir", Vector2(rx, 0.8).normalized())
			_mat.set_shader_parameter("rim_color", sun.light_color.lightened(0.2))


static var _scan_frame := -1
static var _scan_scene_id := 0
static var _light_nodes: Array = []
static var _omni_cache: Array = []


## Light rig cache, shared by all billboards; rebuilt when the current scene changes (Router scene swaps),
## when a cached node was freed, or every 30 frames.
func _find_cached(root: Node) -> Array:
	var f := Engine.get_process_frames()
	var sid := root.get_instance_id()
	var stale := sid != _scan_scene_id
	if not stale and f != _scan_frame:
		for n in _light_nodes:
			if not is_instance_valid(n):
				stale = true
				break
	if stale or f - _scan_frame > 30 or _scan_frame < 0:
		_scan_scene_id = sid
		_scan_frame = f
		_light_nodes = []
		_omni_cache = []
		_collect(root)
	return _light_nodes


func _collect(n: Node) -> void:
	if n is WorldEnvironment or n is DirectionalLight3D:
		_light_nodes.append(n)
	elif n is OmniLight3D:
		_omni_cache.append(n)
	for c in n.get_children():
		_collect(c)
