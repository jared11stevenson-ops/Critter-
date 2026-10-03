class_name CharacterModel
extends Node3D
## Skinned 3D character. Drop-in for CharacterBillboard (CONTRACTS §3): same API, plus
## play_anim(name) / get_impact_time(name). Model faces +Z at rest (glTF), facing dir is world XZ.
##
## Runtime animation (Agent 4): an AnimationTree built in code -
##   locoA (BlendSpace1D idle/walk/jog/run, driven by real ground speed in m/s; every moving clip is time-scaled to
##          one common cycle period so they stay phase-locked and the stride matches the speed -> no foot sliding)
##   act   (two action slots A/B, each Animation -> TimeSeek -> TimeScale, cross-faded by Blend2 "act_x")
##   mix   (Blend2 locoA <-> act, weight = action fade)
##   legs  (Blend2 mix <-> locoB, filtered to hips+legs: when an action plays while moving, legs keep walking)
## Actions are time-warped so the clip's authored impact frame lands on the gameplay hit time (Balance windups),
## then recover at a rate that fits the gameplay action lock. Hit reactions pick a direction from the parent's knock.

@export var model_scene: PackedScene
## res:// path of <id>_anim.json (durations, loops, impact times, loco speeds exported by tools/animation)
@export_file("*.json") var anim_json: String = ""
@export var height_m: float = 2.4
@export var character_id: String = ""
@export var cast_blob_shadow: bool = true
## Attack kind -> clip. "light" cycles through combo_clips.
@export var combo_clips: PackedStringArray = ["attack_1", "attack_2", "attack_3"]
@export var attack_map: Dictionary = {"heavy": "attack_3", "cast": "gravity_pull", "leap": "reaching_strike"}
@export var turn_speed: float = 10.0
## Max speed for set_move_amount(1.0) when the parent has no velocity to read.
@export var max_speed: float = 4.6

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
const LOCO := ["idle", "walk", "jog", "run"]
const LOWER_BONES := ["root", "hips", "thigh.L", "shin.L", "foot.L", "toe.L", "thigh.R", "shin.R", "foot.R", "toe.R"]
const FADE_IN := 0.08
const FADE_OUT := 0.22
const XFADE := 0.1

var _model: Node3D
var _player: AnimationPlayer
var _tree: AnimationTree
var _meshes: Array[MeshInstance3D] = []
var _overlay: ShaderMaterial
var _ghost_mat: ShaderMaterial
var _meta := {}
var _move := 0.0
var _speed := 0.0
var _yaw_target := 0.0
var _yaw_vel := 0.0
var _downed := false
var _combo := 0
var _combo_timer := 0.0
var _flash := 0.0
var _hl_on := false
var _hl := 0.0
# loco
var _loco_pts: Array = []        # [{name, speed, len, stride}] for moving clips, sorted by speed
var _move_w := 0.0
# actions
var _slot := 0                   # active slot 0 = A, 1 = B
var _act_name := ""
var _act_t := 0.0                # clip-time position of the active action
var _act_len := 0.0
var _act_loop := false
var _act_w := 0.0
var _act_x := 0.0
var _warp := []                  # [[clip_t, rate], ...] piecewise playback rates
var _hold_end := false
var _hit_pending := 0
var _ext_state := ""


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
		for n in _player.get_animation_list():
			var a := _player.get_animation(n)
			a.loop_mode = Animation.LOOP_LINEAR if bool(_meta.get(n, {}).get("loop", false)) else Animation.LOOP_NONE
		_build_tree()
	if cast_blob_shadow:
		_add_shadow()


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


# ------------------------------------------------------------------ tree
func _loco_space() -> AnimationNodeBlendSpace1D:
	var bs := AnimationNodeBlendSpace1D.new()
	bs.sync = true
	bs.min_space = 0.0
	bs.max_space = 12.0
	for n in LOCO:
		if not _player.has_animation(n):
			continue
		var sub := AnimationNodeBlendTree.new()
		var an := AnimationNodeAnimation.new()
		an.animation = n
		sub.add_node("anim", an)
		sub.add_node("ts", AnimationNodeTimeScale.new())
		sub.connect_node("ts", 0, "anim")
		sub.connect_node("output", 0, "ts")
		bs.add_blend_point(sub, 0.0 if n == "idle" else float(_meta.get(n, {}).get("speed", 1.0)), -1, n)
	return bs


func _build_tree() -> void:
	for n in LOCO:
		if n != "idle" and _player.has_animation(n):
			var m: Dictionary = _meta.get(n, {})
			var spd := float(m.get("speed", 1.0))
			var ln := _player.get_animation(n).length
			_loco_pts.append({"name": n, "speed": spd, "len": ln, "stride": spd * ln})
	_loco_pts.sort_custom(func(a, b): return a.speed < b.speed)
	var bt := AnimationNodeBlendTree.new()
	bt.add_node("locoA", _loco_space())
	bt.add_node("locoB", _loco_space())
	for s in ["A", "B"]:
		var an := AnimationNodeAnimation.new()
		an.animation = "idle"
		bt.add_node("act" + s, an)
		bt.add_node("seek" + s, AnimationNodeTimeSeek.new())
		bt.add_node("ts" + s, AnimationNodeTimeScale.new())
		bt.connect_node("seek" + s, 0, "act" + s)
		bt.connect_node("ts" + s, 0, "seek" + s)
	bt.add_node("act_x", AnimationNodeBlend2.new())
	bt.connect_node("act_x", 0, "tsA")
	bt.connect_node("act_x", 1, "tsB")
	bt.add_node("mix", AnimationNodeBlend2.new())
	bt.connect_node("mix", 0, "locoA")
	bt.connect_node("mix", 1, "act_x")
	var legs := AnimationNodeBlend2.new()
	legs.filter_enabled = true
	bt.add_node("legs", legs)
	bt.connect_node("legs", 0, "mix")
	bt.connect_node("legs", 1, "locoB")
	bt.connect_node("output", 0, "legs")
	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	_model.add_child(_tree)
	_tree.anim_player = _tree.get_path_to(_player)
	_tree.tree_root = bt
	# leg filter: every track of a lower-body bone
	var idle := _player.get_animation("idle")
	if idle:
		for i in idle.get_track_count():
			var p := idle.track_get_path(i)
			if String(p.get_concatenated_subnames()) in LOWER_BONES:
				legs.set_filter_path(p, true)
	_player.active = false
	_tree.active = true
	_set_p("mix/blend_amount", 0.0)
	_set_p("legs/blend_amount", 0.0)
	_set_p("act_x/blend_amount", 0.0)
	_update_loco(0.0)


func _set_p(path: String, v: Variant) -> void:
	_tree.set("parameters/" + path, v)


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
	var p := get_parent()
	var pstate = p.get("state") if p else null
	if pstate == "dash" and has_anim("dash"):
		play_anim("dash")
		return
	if kind == "light":
		if _combo_timer <= 0.0:
			_combo = 0
		clip = combo_clips[_combo % 2]
		_combo += 1
		_combo_timer = 1.1
	elif kind == "heavy":
		clip = _infer_heavy(p)
		if clip == "attack_3":
			_combo = 0
	else:
		clip = attack_map.get(kind, "attack_1")
		if kind == "leap" and pstate == "leap" and has_anim("dash"):
			clip = "dash"
	play_anim(clip, -1.0, _game_impact(clip))


## Kits call play_attack("heavy") for the combo finisher, Reaching Strike and Beetle Rage; tell them apart from the
## parent's state at call time (Beetle Rage: rage just started; Reaching Strike: begin_action(..., move_mult 0)).
func _infer_heavy(p: Node) -> String:
	if p == null:
		return attack_map.get("heavy", "attack_3")
	var kit = p.get("kit")
	if kit and kit.get("rage_t") != null and float(kit.get("rage_t")) > float(Balance.f("aruun.beetle_rage.duration", 8.0)) - 0.05:
		return "beetle_rage"
	if p.get("action_move_mult") != null and float(p.get("action_move_mult")) <= 0.0 and has_anim("reaching_strike"):
		return "reaching_strike"
	return attack_map.get("heavy", "attack_3")


## Gameplay time (s after the visual starts) at which the hit lands, or -1 if not timed by gameplay.
func _game_impact(clip: String) -> float:
	if character_id != "aruun" and character_id != "":
		return -1.0
	match clip:
		"attack_1", "attack_2":
			return Balance.arr("aruun.combo.windup", 0, 0.09) + Balance.arr("aruun.combo.active", 0, 0.08) * 0.5
		"attack_3":
			return Balance.arr("aruun.combo.windup", 2, 0.15) + Balance.arr("aruun.combo.active", 2, 0.1) * 0.5
		"reaching_strike":
			return Balance.f("aruun.reaching_strike.windup", 0.26)
	return -1.0


func flash_hit() -> void:
	_flash = 1.0
	_hit_pending = 2       # pick the reaction once the actor has applied knock/stagger (same or next frame)


func set_downed(downed: bool) -> void:
	if downed == _downed:
		return
	_downed = downed
	if downed:
		play_anim("downed")
		_hold_end = true
	else:
		_hold_end = false
		play_anim("revive")


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
func has_anim(n: String) -> bool:
	return _player != null and _player.has_animation(n)


## Plays any clip by name over locomotion (non-looping clips fade back to locomotion when done). Returns duration.
## game_impact > 0 time-warps the clip so its impact frame lands at that many seconds after the call.
func play_anim(anim_name: String, blend: float = -1.0, game_impact: float = -1.0) -> float:
	if _tree == null or not has_anim(anim_name):
		return 0.0
	var a := _player.get_animation(anim_name)
	if anim_name in LOCO:
		_end_action()
		return a.length
	_slot = 1 - _slot
	var s := "A" if _slot == 0 else "B"
	var bt: AnimationNodeBlendTree = _tree.tree_root
	(bt.get_node("act" + s) as AnimationNodeAnimation).animation = anim_name
	_set_p("seek" + s + "/seek_request", 0.0)
	# a fresh action from locomotion snaps the slot crossfade; chained actions cross-fade slot to slot
	if _act_w < 0.05:
		_act_x = float(_slot)
		_set_p("act_x/blend_amount", _act_x)
	_act_name = anim_name
	_act_t = 0.0
	_act_len = a.length
	_act_loop = a.loop_mode != Animation.LOOP_NONE
	_hold_end = _downed and anim_name == "downed"
	_warp = _make_warp(anim_name, game_impact)
	_set_p("ts" + s + "/scale", _rate_at(0.0))
	return a.length


func _make_warp(n: String, game_impact: float) -> Array:
	var imp := get_impact_time(n)
	if game_impact <= 0.0 or imp <= 0.0:
		return [[0.0, 1.0]]
	var r1 := clampf(imp / game_impact, 0.75, 1.9)
	# after impact: recover a little faster if gameplay unlocks early (cancel window), never slower than real time
	var cancel := float(_meta.get(n, {}).get("cancel", _act_len))
	return [[0.0, r1], [imp, 1.0], [cancel, 1.1]]


func _rate_at(t: float) -> float:
	var r := 1.0
	for w in _warp:
		if t >= float(w[0]):
			r = float(w[1])
	return r


func _end_action() -> void:
	_act_name = ""
	_hold_end = false


## Seconds from clip start to its impact frame (from <id>_anim.json); -1 if none.
func get_impact_time(anim_name: String) -> float:
	var m = _meta.get(anim_name, {})
	var t = m.get("impact", null)
	return -1.0 if t == null else float(t)


func get_anim_names() -> PackedStringArray:
	return _player.get_animation_list() if _player else PackedStringArray()


## Name of the action clip currently playing over locomotion ("" if none).
func current_action() -> String:
	return _act_name


# ------------------------------------------------------------------ per frame
func _update_loco(speed: float) -> void:
	_set_p("locoA/blend_position", speed)
	_set_p("locoB/blend_position", speed)
	if _loco_pts.is_empty():
		return
	# one common cycle period T for every moving clip (phase lock); stride interpolated between neighbours
	var T := 1.0
	var first: Dictionary = _loco_pts[0]
	var last: Dictionary = _loco_pts[_loco_pts.size() - 1]
	if speed <= first.speed:
		T = first.len / clampf(speed / first.speed, 0.55, 1.0)
	elif speed >= last.speed:
		T = last.len / (speed / last.speed)
	else:
		for i in _loco_pts.size() - 1:
			var a: Dictionary = _loco_pts[i]
			var b: Dictionary = _loco_pts[i + 1]
			if speed <= b.speed:
				var k: float = (speed - a.speed) / (b.speed - a.speed)
				T = lerpf(a.stride, b.stride, k) / speed
				break
	for p in _loco_pts:
		var sc: float = p.len / T
		_set_p("locoA/%s/ts/scale" % p.name, sc)
		_set_p("locoB/%s/ts/scale" % p.name, sc)


func _measure_speed() -> float:
	var p := get_parent()
	if p is CharacterBody3D:
		var v: Vector3 = (p as CharacterBody3D).velocity
		var hs := Vector2(v.x, v.z).length()
		# stand still if the controller asks for no movement (avoids shuffling on tiny residual velocity)
		return 0.0 if hs < 0.15 else hs
	return _move * max_speed


func _pick_hit() -> void:
	if _downed or _tree == null:
		return
	var p := get_parent()
	var heavy := p != null and p.get("stagger_t") != null and float(p.get("stagger_t")) > 0.2
	# Aruun's poise: light hits don't interrupt his swings, they only flash
	if _act_name != "" and not _act_name.begins_with("hit") and not heavy:
		return
	var clip := "hit"
	var kn = p.get("knock") if p else null
	if heavy and has_anim("hit_heavy"):
		clip = "hit_heavy"
	elif kn is Vector3 and Vector2(kn.x, kn.z).length() > 0.05:
		# knock = direction the hit pushes us; express in model space (+Z = facing)
		var local: Vector3 = global_transform.basis.inverse() * Vector3(kn.x, 0, kn.z)
		var ang := atan2(local.x, local.z)
		if absf(ang) < PI * 0.25:
			clip = "hit_back"            # pushed forward -> struck from behind
		elif absf(ang) > PI * 0.75:
			clip = "hit"                 # pushed back -> struck from the front
		elif ang > 0.0:
			clip = "hit_right"           # pushed toward +X (his left) -> struck from his right
		else:
			clip = "hit_left"
	if not has_anim(clip):
		clip = "hit"
	play_anim(clip)


func _process(delta: float) -> void:
	# critically damped facing turn (no snapping, no overshoot)
	var diff := wrapf(_yaw_target - rotation.y, -PI, PI)
	var k := turn_speed
	_yaw_vel += (diff * k * k - 2.0 * k * _yaw_vel) * delta
	rotation.y += _yaw_vel * delta
	_combo_timer -= delta
	_flash = move_toward(_flash, 0.0, delta * 5.0)
	_hl = move_toward(_hl, 1.0 if _hl_on else 0.0, delta * 6.0)
	if _overlay:
		_overlay.set_shader_parameter("flash", _flash * 0.6)
		_overlay.set_shader_parameter("highlight", _hl)
	if _tree == null:
		return
	if _hit_pending > 0:
		_hit_pending -= 1
		if _hit_pending == 0:
			_pick_hit()
	# scripted states from the parent (Burden moments)
	var p := get_parent()
	var st = p.get("state") if p else null
	if st == "burden" and _ext_state != "burden" and has_anim("burden_hold"):
		play_anim("burden_hold")
	elif st != "burden" and _ext_state == "burden" and _act_name == "burden_hold":
		_act_len = minf(_act_len, _act_t + FADE_OUT)
		_act_loop = false
	_ext_state = str(st)
	# locomotion
	_speed = lerpf(_speed, _measure_speed(), clampf(delta * 12.0, 0.0, 1.0))
	_update_loco(_speed)
	_move_w = move_toward(_move_w, 1.0 if _speed > 0.6 else 0.0, delta * 5.0)
	# action timing / fades
	var want_w := 0.0
	if _act_name != "":
		var s := "A" if _slot == 0 else "B"
		var r := _rate_at(_act_t)
		_set_p("ts" + s + "/scale", r)
		_act_t += delta * r
		if _act_loop:
			want_w = 1.0
		elif _hold_end:
			want_w = 1.0
			if _act_t >= _act_len:
				_set_p("ts" + s + "/scale", 0.0)
		elif _act_t < _act_len - FADE_OUT:
			want_w = 1.0
		else:
			want_w = clampf((_act_len - _act_t) / FADE_OUT, 0.0, 1.0)
			if _act_t >= _act_len:
				_act_name = ""
	if _downed and _act_name == "":
		want_w = _act_w
	var rate := 1.0 / (FADE_IN if want_w > _act_w else FADE_OUT)
	_act_w = move_toward(_act_w, want_w, delta * rate)
	_act_x = move_toward(_act_x, float(_slot), delta / XFADE)
	_set_p("act_x/blend_amount", _act_x)
	_set_p("mix/blend_amount", _act_w)
	# legs keep running under upper-body actions while the body is actually travelling
	var legs_w := _act_w * _move_w
	if _act_name in ["downed", "revive", "burden_hold", "beetle_rage", "dash"]:
		legs_w = 0.0
	_set_p("legs/blend_amount", legs_w)
