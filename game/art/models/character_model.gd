class_name CharacterModel
extends Node3D
## Skinned 3D character (Agent 3). Drop-in for CharacterBillboard (CONTRACTS §3): same API, plus
## play_anim(name) / get_impact_time(name). Model faces +Z at rest (glTF), facing dir is world XZ.

@export var model_scene: PackedScene
## res:// path of <id>_anim.json (durations, loops, impact times exported by tools/modeling/<id>/finish.py)
@export_file("*.json") var anim_json: String = ""
@export var height_m: float = 2.4
@export var character_id: String = ""
@export var cast_blob_shadow: bool = true
## Attack kind -> clip. "light" cycles through combo_clips.
@export var combo_clips: PackedStringArray = ["attack_1", "attack_2", "attack_3"]
@export var attack_map: Dictionary = {"heavy": "attack_3", "cast": "gravity_pull", "leap": "reaching_strike"}
@export var turn_speed: float = 14.0

const OVERLAY_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 highlight_color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float highlight = 0.0;
uniform float flash = 0.0;
uniform float rim = 0.18;
uniform vec4 rim_color : source_color = vec4(1.0, 0.72, 0.5, 1.0);
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = rim_color.rgb * f * rim + highlight_color.rgb * f * highlight * 1.6 + vec3(1.0, 0.85, 0.8) * flash;
}
"""
const GHOST_CODE := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;
uniform vec4 ghost_color : source_color = vec4(0.55, 0.8, 1.0, 1.0);
uniform float ghost_alpha = 0.5;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = ghost_color.rgb * (0.5 + f);
	ALPHA = ghost_alpha * (0.35 + 0.65 * f);
}
"""

var _model: Node3D
var _player: AnimationPlayer
var _meshes: Array[MeshInstance3D] = []
var _overlay: ShaderMaterial
var _ghost_mat: ShaderMaterial
var _meta := {}
var _move := 0.0
var _yaw_target := 0.0
var _action := ""
var _action_left := 0.0
var _downed := false
var _combo := 0
var _combo_timer := 0.0
var _flash := 0.0
var _hl_on := false
var _hl := 0.0
var _loco := ""


func _ready() -> void:
	if model_scene == null:
		return
	_model = model_scene.instantiate()
	add_child(_model)
	_player = _find_player(_model)
	_collect_meshes(_model)
	_overlay = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = OVERLAY_CODE
	_overlay.shader = sh
	for m in _meshes:
		m.material_overlay = _overlay
	if anim_json != "" and FileAccess.file_exists(anim_json):
		var d = JSON.parse_string(FileAccess.get_file_as_string(anim_json))
		if d is Dictionary:
			_meta = d.get("animations", {})
			height_m = float(d.get("height_m", height_m))
	if _player:
		for n in _meta:
			if _player.has_animation(n) and bool(_meta[n].get("loop", false)):
				_player.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_player.animation_finished.connect(_on_finished)
	if cast_blob_shadow:
		_add_shadow()
	_set_loco("idle")


func _find_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var p := _find_player(c)
		if p:
			return p
	return null


func _collect_meshes(n: Node) -> void:
	if n is MeshInstance3D:
		_meshes.append(n)
	for c in n.get_children():
		_collect_meshes(c)


func _add_shadow() -> void:
	var s := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.3, 1.3)
	q.orientation = PlaneMesh.FACE_Y
	s.mesh = q
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, blend_mix, depth_draw_never, shadows_disabled;\nvoid fragment(){ float d = length(UV - 0.5) * 2.0; ALBEDO = vec3(0.0); ALPHA = 0.45 * smoothstep(1.0, 0.2, d); }"
	m.shader = sh
	s.material_override = m
	s.position.y = 0.02
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(s)


# ------------------------------------------------------------------ CharacterBillboard API
func set_facing(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length_squared() < 1e-6:
		return
	_yaw_target = atan2(dir.x, dir.z)


func set_move_amount(v: float) -> void:
	_move = clampf(v, 0.0, 1.0)


func play_attack(kind: String = "light") -> void:
	var clip := ""
	if kind == "light":
		if _combo_timer <= 0.0:
			_combo = 0
		clip = combo_clips[_combo % combo_clips.size()]
		_combo += 1
		_combo_timer = 1.1
	else:
		clip = attack_map.get(kind, "attack_1")
	play_anim(clip)


func flash_hit() -> void:
	_flash = 1.0
	if not _downed:
		play_anim("hit")


func set_downed(downed: bool) -> void:
	if downed == _downed:
		return
	_downed = downed
	play_anim("downed" if downed else "revive")


func set_highlight(color: Color, on: bool) -> void:
	_overlay.set_shader_parameter("highlight_color", color)
	_hl_on = on


func set_ghost(alpha: float) -> void:
	if alpha >= 0.999:
		for m in _meshes:
			m.material_override = null
		return
	if _ghost_mat == null:
		_ghost_mat = ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = GHOST_CODE
		_ghost_mat.shader = sh
	_ghost_mat.set_shader_parameter("ghost_alpha", alpha)
	for m in _meshes:
		m.material_override = _ghost_mat


func set_ghost_color(c: Color) -> void:
	if _ghost_mat == null:
		set_ghost(0.6)
	_ghost_mat.set_shader_parameter("ghost_color", c)


func get_height() -> float:
	return height_m


# ------------------------------------------------------------------ 3D extras
## Plays any clip by name (non-looping clips return to locomotion when done). Returns duration.
func play_anim(anim_name: String, blend: float = 0.08) -> float:
	if _player == null or not _player.has_animation(anim_name):
		return 0.0
	_player.speed_scale = 1.0
	_player.play(anim_name, blend)
	var a := _player.get_animation(anim_name)
	if a.loop_mode == Animation.LOOP_NONE:
		_action = anim_name
		_action_left = a.length
	else:
		_action = ""
		_loco = anim_name
	return a.length


## Seconds from clip start to its impact frame (from <id>_anim.json); -1 if none.
func get_impact_time(anim_name: String) -> float:
	var m = _meta.get(anim_name, {})
	var t = m.get("impact", null)
	return -1.0 if t == null else float(t)


func get_anim_names() -> PackedStringArray:
	return _player.get_animation_list() if _player else PackedStringArray()


func _on_finished(anim_name: StringName) -> void:
	if String(anim_name) == _action:
		_action = ""
		if not _downed:
			_loco = ""


func _set_loco(n: String) -> void:
	if _loco == n or _player == null:
		return
	_loco = n
	_player.play(n, 0.2)


func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, _yaw_target, clampf(delta * turn_speed, 0.0, 1.0))
	_combo_timer -= delta
	_flash = move_toward(_flash, 0.0, delta * 5.0)
	_hl = move_toward(_hl, 1.0 if _hl_on else 0.0, delta * 6.0)
	if _overlay:
		_overlay.set_shader_parameter("flash", _flash * 0.6)
		_overlay.set_shader_parameter("highlight", _hl)
	if _player == null:
		return
	if _action != "":
		_action_left -= delta
		if _action_left > -0.05:
			return
		_action = ""
	if _downed:
		return
	var want := "idle"
	if _move > 0.6:
		want = "run"
	elif _move > 0.06:
		want = "walk"
	_set_loco(want)
	if want == "walk":
		_player.speed_scale = lerpf(0.6, 1.25, _move / 0.6)
	elif want == "run":
		_player.speed_scale = lerpf(0.9, 1.15, (_move - 0.6) / 0.4)
	else:
		_player.speed_scale = 1.0
