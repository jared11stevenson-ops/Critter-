class_name CritterRig extends Node3D
## CRITTER v2 rig (INTERFACES.md contract v1): a hierarchy of rigid toon parts built in code per critter, driven by a
## procedural pose system keyed to the move's frame data. Forward = +X, up = +Y, origin = ground between the feet.
##   setup(id) / apply_fighter_state(fs, dt) / play_event(ev) / set_expression(name) / socket(name)
## Events are about THIS rig's fighter: BoutScene forwards "hit/block/stagger/ko/..." to the victim's rig and
## "parry/clash/laststand/grab/dodge/tell" to the actor's rig. Optional ev keys: pos (Vector2/Vector3 world), heavy (bool).

const Rb := preload("res://src/critters/rig_build.gd")
const Pal := preload("res://src/critters/palettes.gd")
const PoseLib := preload("res://src/critters/pose_lib.gd")
const Timing := preload("res://src/critters/timing.gd")
const FaceCtl := preload("res://src/critters/face_ctl.gd")
const FxCtl := preload("res://src/critters/fx_ctrl.gd")
const Toon := preload("res://src/critters/toon.gd")

const DESIGN_PATH := "res://src/critters/designs/%s.gd"

## ---- presentation constants (NOT gameplay numbers) ----
const BLEND_FRAMES := {"idle": 8, "walk": 8, "guard": 3, "hit": 1, "stagger": 3, "ko": 3, "dodge": 1}
const BLEND_DEFAULT := 2
const TURN_RATE := 22.0
const FIDGET_GAP := Vector2(6.0, 10.0)
const FIDGET_LEN := 1.4
const LOW_VIT_SCARED := 0.3
const LOW_VIT_DYING := 0.12
const WALK_RATE := 9.0

## 3/4 turn toward the camera (deg). Side-on bouts read faces best at ~30; lookdev sets 0 and orbits the camera.
var three_quarter := 38.0
var critter_id := ""
var palette: Dictionary = {}
var cfg: Dictionary = {}
var tri_count := 0
var bounds := AABB()   # rest-pose bounds in rig space (meters)
var face: FaceCtl = null
var fx: FxCtl = null

var _pivot: Node3D          # yaw / facing
var _body: Node3D           # pose root (squash anchored at the feet)
var _nodes: Dictionary = {}
var _rest: Dictionary = {}
var _rest_basis: Dictionary = {}
var _mat: ShaderMaterial
var _sockets: Dictionary = {}
var _cur: Dictionary = {}
var _from: Dictionary = {}
var _blend_f := 99
var _blend_n := 2
var _action := "idle"
var _move_id := ""
var _keys: Dictionary = {}
var _keys_action := ""
var _time := 0.0
var _tick := 0
var _walk_phase := 0.0
var _walk_amt := 0.0
var _yaw := 0.0
var _facing := 1.0
var _sq := 0.0
var _sqv := 0.0
var _shake_f := 0
var _shake_amp := 0.0
var _idle_time := 0.0
var _next_fidget := 7.0
var _fidget_t := -1.0
var _lag := {}               # part -> [angle, vel]
var _drv_prev := {}
var _vit := 1.0
var _expr_manual := ""
var _smear_active := false
var _hit_dir := 1.0
var _action_frame := 0
var _timing := Vector3i(1, 1, 1)

func setup(critter_id_in: String) -> void:
	critter_id = critter_id_in
	for c in get_children():
		c.queue_free()
	_pivot = Node3D.new(); _pivot.name = "facing"; add_child(_pivot)
	_body = Node3D.new(); _body.name = "body"; _pivot.add_child(_body)
	var design = load(DESIGN_PATH % critter_id)
	assert(design != null, "unknown critter " + critter_id)
	palette = Pal.get_pal(critter_id)
	var b := Rb.new()
	b.pal = palette
	design.build(b)
	cfg = b.cfg
	var res := b.assemble(_body)
	_nodes = res["nodes"]
	_rest = res["rest"]
	for rn in res["rest_rot"]:
		var rr: Vector3 = res["rest_rot"][rn]
		_rest_basis[rn] = Basis.from_euler(Vector3(deg_to_rad(rr.x), deg_to_rad(rr.y), deg_to_rad(rr.z)))
	_mat = res["mat"]
	tri_count = res["tris"]
	bounds = res["bounds"]
	var sc := float(cfg.get("scale", 1.0))   # presentation scale (silhouette variety); gameplay reach lives in data
	_pivot.scale = Vector3.ONE * sc
	bounds = AABB(bounds.position * sc, bounds.size * sc)
	for n in _nodes:
		if str(n).begins_with("sock_"):
			_sockets[str(n).substr(5)] = _nodes[n]
	var g := Marker3D.new(); g.name = "socket_ground"; add_child(g); _sockets["ground"] = g
	if not _sockets.has("hand") and _nodes.has("arm_f"):
		_sockets["hand"] = _nodes["arm_f"]
	if not _sockets.has("head") and _nodes.has("head"):
		_sockets["head"] = _nodes["head"]
	if not _sockets.has("weapon_tip"):
		_sockets["weapon_tip"] = _sockets.get("hand", g)
	if res["face_mat"] != null:
		face = FaceCtl.new(res["face_mat"])
		face.blink_scale = float(cfg.get("blink_scale", 1.0))
		face.snap()
	fx = FxCtl.new(self, _mat, palette["accent"] if (palette["accent"] as Color).get_luminance() > 0.35 else palette["glow"], palette["glow"])
	for p in PoseLib.PARTS:
		_cur[p] = PackedFloat32Array(PoseLib.IDENT)
	_from = _cur.duplicate(true)
	for p in ["weapon", "extra"]:
		_lag[p] = [0.0, 0.0]
	_apply_pose(_cur)

func socket(sname: String) -> Node3D:
	return _sockets.get(sname, _sockets.get("ground"))

## Manual expression (wins over the automatic state/vitality expression). Pass "auto" to hand control back.
func set_expression(ename: String) -> void:
	_expr_manual = "" if ename == "auto" else ename
	if face and _expr_manual != "":
		face.set_base(_expr_manual)

## Flat-black rendering for the silhouette gate (hides the face and FX).
func set_silhouette(on: bool) -> void:
	Toon.set_both(_mat, "silhouette", 1.0 if on else 0.0)
	var fn := _body.get_node_or_null("head/face")
	if fn:
		fn.visible = not on
	for gp in _nodes:
		var gn = _nodes[gp]
		if gn is MeshInstance3D and (gn as MeshInstance3D).material_override != _mat and (gn as MeshInstance3D).material_override is ShaderMaterial:
			((gn as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("silhouette", 1.0 if on else 0.0)
	fx.smear.visible = false if on else fx.smear.visible

func part(pname: String) -> Node3D:
	return _nodes.get(pname)

func nominal_height() -> float:
	return bounds.end.y

## ---------------------------------------------------------------- state-driven pose
func apply_fighter_state(fs: Dictionary, dt: float) -> void:
	if _body == null:
		return
	_tick += 1
	_time += dt
	var action: String = str(fs.get("action", "idle"))
	var frame: int = int(fs.get("action_frame", 0))
	var move_id: String = str(fs.get("move_id", ""))
	_vit = float(fs.get("vitality_ratio", 1.0))
	if fs.has("facing"):
		var f: float = float(fs["facing"])
		if f != 0.0:
			_facing = signf(f)
	if action != _action or move_id != _move_id:
		_begin_action(action, move_id, fs)
	_action_frame = frame
	_timing = Timing.resolve(critter_id, action, move_id, fs)
	var target := _eval_action(action, frame)
	var w := 1.0
	if _blend_f < _blend_n:
		w = float(_blend_f + 1) / float(_blend_n + 1)
		w = w * w * (3.0 - 2.0 * w)
		_blend_f += 1
	var pose := PoseLib.blend(_from, target, w) if w < 1.0 else PoseLib.copy(target)
	_layer_procedural(pose, action, fs, dt)
	_cur = pose
	_apply_pose(pose)
	_update_facing(dt)
	_update_expression(action, dt)
	_update_smear(action, frame)
	if face:
		face.update(dt)
	fx.update(dt)

func _timing_for(action: String) -> Vector3i:
	return Timing.resolve(critter_id, action, "", {})

func _begin_action(action: String, move_id: String, fs: Dictionary) -> void:
	_from = _cur.duplicate(true)
	_blend_f = 0
	_blend_n = int(BLEND_FRAMES.get(action, BLEND_DEFAULT))
	_action = action
	_move_id = move_id
	var c := cfg
	var ta: String = str(fs.get("tell_anim", ""))   # data/moves `tell_anim` may name any swing style in PoseLib.STYLES
	if ta != "" and PoseLib.STYLES.has(ta):
		c = cfg.duplicate()
		var st: Dictionary = (cfg.get("style", {}) as Dictionary).duplicate()
		st[action] = ta
		c["style"] = st
	_keys = PoseLib.keys_for(action, c) if action not in ["idle", "walk"] else {}
	if action in ["strike_heavy", "strike_light", "ability1", "ability2", "grab", "laststand"]:
		_kick(-0.0)
	_idle_time = 0.0
	if action in ["ability1", "ability2", "laststand"]:
		fx.boost_glow(1.8)
	elif action != "idle":
		fx.boost_glow(0.0)

func _ease_out(u: float) -> float:
	return 1.0 - pow(1.0 - clampf(u, 0.0, 1.0), 3.0)

## Evaluates anticipation / strike / recovery from frame counts. Returns a full pose dict.
func _eval_action(action: String, frame: int) -> Dictionary:
	if action == "idle" or action == "walk":
		return _rest_pose()
	var k: Dictionary = _keys
	var s := maxi(_timing.x, 1)
	var a := maxi(_timing.y, 1)
	var r := maxi(_timing.z, 1)
	var rest := _rest_pose()
	if frame < s:
		var u := float(frame) / float(s)
		var pose := PoseLib.blend(rest, k["ant"], _ease_out(u / 0.7))
		var sh: float = float(k.get("shake", 0.0))
		if sh > 0.0 and u > 0.6:   # tremble = the "tell" before the strike
			var m := (u - 0.6) / 0.4 * sh
			var bp: PackedFloat32Array = pose["body"]
			bp[3] += sin(_tick * 2.3) * 0.012 * m
			bp[4] += cos(_tick * 3.1) * 0.01 * m
			bp[2] += sin(_tick * 1.7) * 1.5 * m
			pose["body"] = bp
		return pose
	if frame < s + a:
		var v := float(frame - s) / float(a)
		# strike lands within ~2 frames then holds, drifting toward recovery (follow-through)
		var snap := clampf(float(frame - s + 1) / minf(float(a), 2.0), 0.0, 1.0)
		var pose2 := PoseLib.blend(k["ant"], k["strike"], snap)
		if bool(k.get("hold", false)):
			return pose2
		return PoseLib.blend(pose2, k["rec"], v * 0.25)
	if bool(k.get("hold", false)):
		return k["strike"]
	var u3 := float(frame - s - a) / float(r)
	if u3 >= 1.0:
		return rest
	var settle := PoseLib.blend(k["strike"], k["rec"], clampf(u3 / 0.35, 0.0, 1.0))
	return PoseLib.blend(settle, rest, _ease_out((u3 - 0.2) / 0.8))

## Packed arrays inside a Dictionary are copy-on-write: always modify through these helpers (read, change, write back).
func _padd(pose: Dictionary, part_name: String, i: int, v: float) -> void:
	var a: PackedFloat32Array = pose[part_name]
	a[i] += v
	pose[part_name] = a

func _pmul(pose: Dictionary, part_name: String, i: int, v: float) -> void:
	var a: PackedFloat32Array = pose[part_name]
	a[i] *= v
	pose[part_name] = a

func _rest_pose() -> Dictionary:
	var d := {}
	for p in PoseLib.PARTS:
		d[p] = PackedFloat32Array(PoseLib.IDENT)
	return d

## breathing, sway, walk cycle, fidgets, squash spring, shake, low-vitality slouch, lag springs (all additive)
func _layer_procedural(pose: Dictionary, action: String, fs: Dictionary, dt: float) -> void:
	for pn in PoseLib.PARTS:
		if not pose.has(pn):
			pose[pn] = PackedFloat32Array(PoseLib.IDENT)
	var calm := 1.0 if action == "idle" else 0.35
	var br := sin(_time * (2.2 + (1.0 - _vit) * 2.2))
	var torso: PackedFloat32Array = pose["torso"]
	var head: PackedFloat32Array = pose["head"]
	var body: PackedFloat32Array = pose["body"]
	torso[7] *= 1.0 + br * 0.022 * calm
	torso[6] *= 1.0 - br * 0.01 * calm
	head[4] += br * 0.01 * calm
	var sway := float(cfg.get("sway", 2.5))
	_padd(pose, "arm_f", 2, sin(_time * 1.3) * sway * calm)
	_padd(pose, "arm_b", 2, sin(_time * 1.3 + 1.2) * sway * 0.6 * calm)
	# slouch at low vitality
	var tired := clampf((0.5 - _vit) / 0.5, 0.0, 1.0)
	torso[2] -= tired * 8.0 * calm
	head[2] -= tired * 10.0 * calm
	# walk cycle
	var spd := absf(float(fs.get("speed", 1.0 if action == "walk" else 0.0)))
	_walk_amt = move_toward(_walk_amt, 1.0 if action == "walk" else 0.0, dt * 8.0)
	if action == "walk":
		_walk_phase += dt * WALK_RATE * float(cfg.get("stride", 1.0)) * clampf(spd, 0.5, 1.6)
	if _walk_amt > 0.01:
		var s := sin(_walk_phase)
		var c := cos(_walk_phase * 2.0)
		var m := _walk_amt
		_padd(pose, "leg_f", 2, s * 30.0 * m)
		_padd(pose, "leg_b", 2, -(s * 30.0 * m))
		body[4] += absf(s) * 0.07 * m * float(cfg.get("bob", 1.0))
		torso[0] += s * 5.0 * m * float(cfg.get("waddle", 1.0))
		torso[2] -= 5.0 * m
		body[7] *= 1.0 + c * 0.03 * m
		_padd(pose, "arm_b", 2, s * 22.0 * m)
		_padd(pose, "arm_f", 2, -(s * 6.0 * m))
		head[2] += s * 2.0 * m
	# idle fidget
	if action == "idle":
		_idle_time += dt
		if _fidget_t < 0.0 and _idle_time > _next_fidget:
			_fidget_t = 0.0
		if _fidget_t >= 0.0:
			_fidget_t += dt
			var u := _fidget_t / FIDGET_LEN
			var env := sin(clampf(u, 0.0, 1.0) * PI)
			var fp: Dictionary = cfg.get("fidget", {})
			for part_name in fp:
				var kf: PackedFloat32Array = fp[part_name]
				var tp: PackedFloat32Array = pose[part_name]
				for i in range(9):
					tp[i] = tp[i] + (kf[i] - PoseLib.IDENT[i]) * env + (tp[i] * 0.0)
			if u >= 1.0:
				_fidget_t = -1.0
				_idle_time = 0.0
				_next_fidget = randf_range(FIDGET_GAP.x, FIDGET_GAP.y)
	else:
		_fidget_t = -1.0
	# squash spring + shake
	_sqv += (-420.0 * _sq - 24.0 * _sqv) * dt
	_sq += _sqv * dt
	var sq := clampf(_sq, -0.35, 0.45)
	body[7] *= 1.0 - sq
	body[6] *= 1.0 + sq * 0.5
	body[8] *= 1.0 + sq * 0.5
	if _shake_f > 0:
		_shake_f -= 1
		body[3] += sin(_tick * 12.9) * _shake_amp * 0.05
		body[4] += cos(_tick * 15.3) * _shake_amp * 0.035
	var hover := float(cfg.get("hover", 0.0))
	if hover > 0.0 and action != "ko":
		body[4] += hover + sin(_time * 2.4) * hover * 0.2
	# wings flap / secondary lag for weapon + extra
	var ex: PackedFloat32Array = pose["extra"]
	var flap := float(cfg.get("flap", 0.0))
	if flap > 0.0:
		var airborne := 1.0 if action in ["dodge", "strike_heavy", "ability1", "ability2", "laststand", "walk"] else 0.45
		ex[0] += sin(_time * float(cfg.get("flap_hz", 38.0))) * flap * airborne
	pose["torso"] = torso
	pose["head"] = head
	pose["extra"] = ex
	pose["body"] = body
	_lag_update(pose, dt)
	body = pose["body"]

func _lag_update(pose: Dictionary, dt: float) -> void:
	for pn in PoseLib.PARTS:
		if not pose.has(pn):
			pose[pn] = PackedFloat32Array(PoseLib.IDENT)
	var drv: float = (pose["body"] as PackedFloat32Array)[2] + (pose["torso"] as PackedFloat32Array)[2] \
			+ (pose["body"] as PackedFloat32Array)[3] * 45.0 + (pose["arm_f"] as PackedFloat32Array)[2] * 0.5
	var last: float = _drv_prev.get("v", drv)
	_drv_prev["v"] = drv
	var vel := (drv - last) / maxf(dt, 1.0 / 240.0) if dt > 0.0 else 0.0
	for part_name in ["weapon", "extra"]:
		var st: Array = _lag[part_name]
		var gain: float = float(cfg.get("lag_" + part_name, 0.018))
		var tgt := clampf(-vel * gain, -70.0, 70.0)
		if dt > 0.0:
			st[1] += (260.0 * (tgt - st[0]) - 20.0 * st[1]) * dt
			st[0] += st[1] * dt
		var arr: PackedFloat32Array = pose[part_name]
		arr[2] += st[0] + sin(_time * 2.0 + (1.0 if part_name == "extra" else 0.0)) * 2.0
		pose[part_name] = arr
	if dt > 0.0 and cfg.has("lag_extra_x"):
		_padd(pose, "extra", 0, sin(_time * 3.1) * float(cfg["lag_extra_x"]))

func _apply_pose(pose: Dictionary) -> void:
	for p in pose:
		var a: PackedFloat32Array = pose[p]
		var basis := Basis.from_euler(Vector3(deg_to_rad(a[0]), deg_to_rad(a[1]), deg_to_rad(a[2])))
		basis = basis.scaled(Vector3(a[6], a[7], a[8]))
		if p == "body":
			_body.transform = Transform3D(basis, Vector3(a[3], a[4], a[5]))
		elif _nodes.has(p):
			if _rest_basis.has(p):
				basis = basis * (_rest_basis[p] as Basis)
			(_nodes[p] as Node3D).transform = Transform3D(basis, (_rest[p] as Vector3) + Vector3(a[3], a[4], a[5]))

func _update_facing(dt: float) -> void:
	var tq := deg_to_rad(three_quarter)
	var goal := -tq if _facing >= 0.0 else PI + tq
	_yaw = lerp_angle(_yaw, goal, 1.0 - exp(-TURN_RATE * maxf(dt, 1.0 / 60.0)))
	_pivot.rotation.y = _yaw

func _update_expression(action: String, dt: float) -> void:
	if face == null:
		return
	var e := "calm"
	if _vit < LOW_VIT_DYING:
		e = "dying"
	elif _vit < LOW_VIT_SCARED:
		e = "scared"
	match action:
		"strike_heavy", "ability1", "ability2", "laststand", "guard", "parry":
			e = "angry"
		"strike_light", "grab", "dodge":
			e = "grin" if _vit >= LOW_VIT_SCARED else e
		"hit", "stagger":
			e = "hurt"
		"ko":
			e = "dying"
	face.set_base(_expr_manual if _expr_manual != "" else e)

func _update_smear(action: String, frame: int) -> void:
	if not is_inside_tree():
		return
	var want := false
	if _keys.get("smear", false):
		want = frame >= _timing.x - 1 and frame < _timing.x + _timing.y + 3
	if want and not _smear_active:
		fx.start_smear()
	elif not want and _smear_active:
		fx.stop_smear()
	_smear_active = want
	var tip: Node3D = socket("weapon_tip")
	var base_s: Node3D = socket("weapon_base") if _sockets.has("weapon_base") else socket("hand")
	fx.sample(tip.global_position, base_s.global_position)

## ---------------------------------------------------------------- events
func _kick(amount: float) -> void:
	_sqv += amount * 60.0

func _event_local_pos(ev: Dictionary) -> Vector3:
	var wp = ev.get("world_pos", null)   # optional Vector3 impact point; otherwise the chest, front side
	if wp is Vector3:
		return to_local(wp)
	return Vector3(0.45 * _facing, 0.95, 0.5)

func play_event(ev: Dictionary) -> void:
	if _body == null:
		return
	var t: String = str(ev.get("type", ""))
	var heavy: bool = bool(ev.get("heavy", false))
	match t:
		"hit":
			fx.flash()
			_kick(0.28 if not heavy else 0.45)
			_shake_f = 8 if not heavy else 14
			_shake_amp = 1.0 if not heavy else 2.2
			fx.hit_spark(_event_local_pos(ev), 1.5 if not heavy else 2.4, palette["glow"].lerp(Color(1.0, 0.95, 0.7), 0.5))
			if face:
				face.flash_expression("hurt", 0.5)
			if heavy:
				fx.impact_frame()
		"block":
			_kick(0.1)
			_shake_f = 4; _shake_amp = 0.5
			fx.hit_spark(_event_local_pos(ev), 0.7, Color(0.8, 0.95, 1.0))
		"parry":
			fx.flash()
			_kick(-0.12)
			fx.hit_spark(_event_local_pos(ev), 1.5, Color(1.0, 0.95, 0.6))
			fx.impact_frame()
			if face:
				face.flash_expression("grin", 0.8)
		"clash":
			_kick(0.2)
			_shake_f = 6; _shake_amp = 1.2
			fx.hit_spark(_event_local_pos(ev), 1.3, Color(1.0, 1.0, 1.0))
		"grab":
			if face:
				face.flash_expression("grin", 0.8)
			_kick(0.15)
		"dodge":
			_kick(-0.2)
		"stagger":
			if face:
				face.flash_expression("hurt", 0.8)
			_shake_f = 10; _shake_amp = 1.4
		"tell":
			_kick(-0.1)
			fx.boost_glow(1.2)
		"ringout":
			if face:
				face.flash_expression("scared", 2.0)
		"ko":
			fx.impact_frame()
			fx.flash()
			if face:
				face.flash_expression("dying", 10.0)
		"laststand":
			fx.flash()
			fx.boost_glow(2.4)
			_kick(-0.25)
			_shake_f = 18; _shake_amp = 1.0
			if face:
				face.flash_expression("angry", 3.0)
		"yield":
			if face:
				face.flash_expression("hurt", 1.2)
	if face:
		face.update(0.0)
