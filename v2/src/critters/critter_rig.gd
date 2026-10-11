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
const SwarmCtl := preload("res://src/critters/swarm_ctl.gd")
const DetachCtl := preload("res://src/critters/detach_ctl.gd")
const GhostFx := preload("res://src/critters/ghost_fx.gd")
const RigEvents := preload("res://src/critters/rig_events.gd")

const DESIGN_PATH := "res://src/critters/designs/%s.gd"

## ---- presentation constants (NOT gameplay numbers) ----
const BLEND_FRAMES := {"idle": 8, "walk": 8, "guard": 3, "hit": 1, "stagger": 3, "ko": 3, "dodge": 1}
const BLEND_DEFAULT := 2
const TURN_RATE := 22.0
const FIDGET_GAP := Vector2(6.0, 10.0)
const FIDGET_LEN := 1.4
const WALK_RATE := 9.0

## 3/4 turn toward the camera (deg). Side-on bouts read faces best at ~30; lookdev sets 0 and orbits the camera.
var three_quarter := 38.0
## A-pose arm splay (deg outward from the body); 0 in play unless the BoutScene wants it, 35 for model sheets / .glb (modeling rule 1).
var apose_deg := 0.0
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
## Set by the BoutScene to its VfxStage (vfx/vfx_stage.gd): the rig then spawns ability VFX itself at tell / active / recovery frames.
var vfx: Node = null
var swarm: SwarmCtl = null
var _dcs: Dictionary = {}      # detachable part name -> DetachCtl
var _ghosted := -1
var _swarm_last_action := ""
var _vfx_frame := -1
var _dissolve := 0.0
var _plates := 0
var _rage := 0.0
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
	if res["swarm_node"] != null:
		swarm = SwarmCtl.new(self, res["swarm_node"], cfg.get("swarm_rest", []))
	for dn in cfg.get("detach", []):
		if _nodes.has(dn):
			_dcs[dn] = DetachCtl.new(self, dn, _nodes[dn])
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
	_update_expression(action)
	_update_smear(action, frame)
	if face:
		face.update(dt)
	fx.update(dt)
	_apply_rage(float(fs.get("rage", 0.0)))
	_apply_plates(fs)
	_vfx_hooks(action, frame, move_id, fs)
	_detach_logic(action, frame, dt)

func _timing_for(action: String) -> Vector3i:
	return Timing.resolve(critter_id, action, "", {})

## Visible overdrive (Aruun Rage / Strain, any critter's 'pressure' state): fs["rage"] 0..1 drives a hot rim aura, pulsing emissive
## (Morrow's dome-eye, veins, gems) and a heartbeat shake. The sim owns the value; the rig only displays it.
func _apply_rage(r: float) -> void:
	_rage = r
	var pulse := 0.5 + 0.5 * sin(_time * (8.0 + 8.0 * r))
	_mat.set_shader_parameter("rim_strength", 0.9 + r * (1.6 + pulse * 0.8))
	_mat.set_shader_parameter("rim_color", (palette["glow"] as Color).lerp(Color(1.0, 0.25, 0.1), r))
	_mat.set_shader_parameter("glow_strength", 1.0 + fx.glow_boost + r * (1.2 + pulse))

## Shell-plate crack tiers (0..3): fs.plates if the sim supplies it, otherwise derived from missing vitality (plates crack as he takes hits).
func _apply_plates(fs: Dictionary) -> void:
	var lv: int = int(fs["plates"]) if fs.has("plates") else int(ceil(clampf((1.0 - _vit) * 3.0, 0.0, 3.0) - 0.001))
	lv = maxi(lv, int(ceil(clampf(_rage * 3.0, 0.0, 3.0) - 0.001)))    # Rage strain: the shell fractures as the overdrive climbs
	_plates = lv
	Toon.set_both(_mat, "crack_level", float(lv))

## Auto detach behavior from cfg.detach_act[action] = {part, mode: goto|orbit, out: Vector3, spin, radius, hz, hold}: the part stays
## held through startup, flies out for the active phase (+hold frames), then is recalled. cfg.ghost_act[action] = {as, frame, offset, life, count}.
func _detach_logic(action: String, frame: int, dt: float) -> void:
	var da: Dictionary = cfg.get("detach_act", {})
	for dn in _dcs:
		var ctl: DetachCtl = _dcs[dn]
		var c: Dictionary = da.get(action, {})
		if c.get("part", "") == dn:
			var s := _timing.x
			var e := s + _timing.y + int(c.get("hold", 0))
			if frame >= s and frame < e:
				if str(c.get("mode", "goto")) == "orbit":
					ctl.orbit(c.get("out", Vector3(0, 1.2, 0)), float(c.get("radius", 2.0)), float(c.get("hz", 1.2)))
				else:
					ctl.goto(c.get("out", Vector3(2.5, 1.0, 0)), float(c.get("spin", 0.0)))
			elif frame >= e:
				ctl.recall()
		else:
			ctl.recall()
		ctl.update(dt)
	if swarm != null:
		var sa: Dictionary = cfg.get("swarm_act", {}).get(action, {})
		if not sa.is_empty():
			var s0 := _timing.x
			var e0 := s0 + _timing.y + int(sa.get("hold", 0))
			if frame == s0:
				match str(sa.get("mode", "orbit")):
					"orbit": swarm.orbit_all(sa.get("center", Vector3(0, 0.3, 0)), float(sa.get("radius", 1.6)), float(sa.get("hz", 1.0)))
					"flick": swarm.flick(sa.get("dir", Vector3(1, 0.1, 0)), float(sa.get("dist", 3.0)))
					"volley": swarm.volley(sa.get("dir", Vector3(1, 0.1, 0)), float(sa.get("dist", 3.5)), float(sa.get("fan", 1.2)))
			elif frame >= e0:
				swarm.recall()
		elif action != _swarm_last_action and swarm.any_away() and action in ["idle", "walk", "hit", "ko", "guard"]:
			swarm.recall()
		_swarm_last_action = action
		swarm.update(dt)
		var pairs := swarm.thread_pairs()
		if pairs.size() > 0:
			fx.thread_multi(pairs)
	var gc: Dictionary = cfg.get("ghost_act", {}).get(action, {})
	if not gc.is_empty() and frame == _timing.x and _ghosted != _tick - 1 and _timing.x >= 1:
		_ghosted = _tick
		for i in range(int(gc.get("count", 1))):
			GhostFx.spawn(self, str(gc.get("as", "strike_heavy")), int(gc.get("frame", 8)), (gc.get("offset", Vector3(1.4, 0, 0)) as Vector3) * float(1 + i), float(gc.get("life", 0.9)))

## Manual control for the BoutScene / sim events (counters, "moves on its own"): rig.detach_part("weapon").goto(...)
func detach_part(pname: String) -> DetachCtl:
	return _dcs.get(pname)

func spawn_ghost(action: String, frame: int, offset: Vector3, life: float = 0.9) -> Node3D:
	return GhostFx.spawn(self, action, frame, offset, life)

const VFX_ACTIONS := ["ability1", "ability2", "ability3", "laststand", "grab"]

## Spawns this ability's VFX from real frames: tell on the first frame, go on the first active frame, end when recovery starts. Also drives the camouflage dissolve.
func _vfx_hooks(action: String, frame: int, move_id: String, fs: Dictionary) -> void:
	var camo := false
	for st in fs.get("status", []):
		var nm := str(st.get("name", st.get("status", ""))) if st is Dictionary else str(st)
		if nm == "camo":
			camo = true
	_dissolve = move_toward(_dissolve, 0.62 if camo else 0.0, 0.05)
	Toon.set_both(_mat, "dissolve", _dissolve)
	if vfx == null or not (action in VFX_ACTIONS) or move_id == "" or frame == _vfx_frame:
		_vfx_frame = frame
		return
	var s := _timing.x
	var e := s + _timing.y
	var style: String = str((_keys.get("style_name", "")))
	if frame == 0 or (_vfx_frame < 0 and frame < s):
		vfx.ability(self, move_id, "tell", style)
	if frame == s:
		vfx.ability(self, move_id, "go", style)
	if frame == e:
		vfx.ability(self, move_id, "end", style)
	_vfx_frame = frame

func _begin_action(action: String, move_id: String, fs: Dictionary) -> void:
	_from = _cur.duplicate(true)
	_blend_f = 0
	_blend_n = int(BLEND_FRAMES.get(action, BLEND_DEFAULT))
	_action = action
	_move_id = move_id
	var c := cfg
	var ta: String = Timing.tell_anim(critter_id, move_id, fs)   # data/moves `tell_anim` names a swing style in PoseLib.STYLES
	if ta != "" and PoseLib.STYLES.has(ta):
		c = cfg.duplicate()
		var st: Dictionary = (cfg.get("style", {}) as Dictionary).duplicate()
		st[action] = ta
		c["style"] = st
	var key_action := {"knockdown": "ko", "clash": "hit"}.get(action, action) as String
	_keys = PoseLib.keys_for(key_action, c) if action not in ["idle", "walk"] else {}
	if action == "knockdown":
		_keys["hold"] = false   # fall, lie, get back up (recovery frames)
	if action in ["strike_heavy", "strike_light", "ability1", "ability2", "grab", "laststand"]:
		_kick(-0.0)
	_idle_time = 0.0
	_vfx_frame = -1
	if action in ["ability1", "ability2", "laststand"]:
		fx.boost_glow(1.8)
	elif action != "idle":
		fx.boost_glow(0.0)

func _eval_action(action: String, frame: int) -> Dictionary:
	if action == "idle" or action == "walk":
		return _rest_pose()
	return PoseLib.evaluate(_keys, _timing, frame, _tick)

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
		elif _nodes.has(p) and not (_dcs.has(p) and (_dcs[p] as DetachCtl).is_free()):
			if _rest_basis.has(p):
				basis = basis * (_rest_basis[p] as Basis)
			if apose_deg != 0.0 and (p == "arm_f" or p == "arm_b"):
				var sgn := -1.0 if (_rest[p] as Vector3).z > 0.0 else 1.0
				basis = Basis(Vector3.RIGHT, deg_to_rad(apose_deg) * sgn) * basis
			(_nodes[p] as Node3D).transform = Transform3D(basis, (_rest[p] as Vector3) + Vector3(a[3], a[4], a[5]))

func _update_facing(dt: float) -> void:
	var tq := deg_to_rad(three_quarter)
	var goal := -tq if _facing >= 0.0 else PI + tq
	_yaw = lerp_angle(_yaw, goal, 1.0 - exp(-TURN_RATE * maxf(dt, 1.0 / 60.0)))
	_pivot.rotation.y = _yaw

func _update_expression(action: String) -> void:
	if face == null:
		return
	face.set_base(_expr_manual if _expr_manual != "" else FaceCtl.auto_pick(action, _vit))

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

## ---------------------------------------------------------------- events (see rig_events.gd)
func _kick(amount: float) -> void:
	_sqv += amount * 60.0

func play_event(ev: Dictionary) -> void:
	if _body != null:
		RigEvents.play(self, ev)
