class_name BoutScene extends Node3D
## One duel: owns the CombatSim (fixed 60 Hz accumulator, independent of render FPS), two CritterRigs, the 3D arena, the lock-on
## camera and the HUD. Maps sim state -> rig.apply_fighter_state every frame and sim events -> rig.play_event / camera shake /
## impact frames. Emits `finished(result)` once, after the KO beat; the scene then idles on a slow orbit so a result screen can sit on top.
##   var b := BoutScene.new(); parent.add_child(b); b.start(cfg)

signal finished(result: Dictionary)
signal fight_event(ev: Dictionary)          # every sim event (HUD floating text, audio later)
signal phase_changed(phase: String)

const Stage := preload("res://src/critters/stage.gd")
const FxCtl := preload("res://src/critters/fx_ctrl.gd")
const TICK := 1.0 / 60.0
const MAX_FRAME := 0.1
const INTRO_SEC := 2.4
const OUTRO_SEC := 2.6
const HEAVY_KINDS := ["heavy", "ability", "laststand", "grab"]
const PLAYER_TQ := 12.0
const FOE_TQ := 30.0

var cfg: BoutConfig
var sim: CombatSim
var rigs: Array[CritterRig] = []
var holders: Array[Node3D] = []
var providers: Array[InputProvider] = []
var player: PlayerInput = null
var cam: BoutCamera
var hud: Hud
var entities: EntityView
var arena_def: ArenaDef
var phase := "setup"                 # setup intro fight outro done
var phase_t := 0.0
var time_scale := 1.0
var scale_target := 1.0
var scale_hold := 0.0
var player_idx := 0                  # which fighter the HUD / touch controls belong to (-1 = spectating)
var stats := {"ticks": 0, "frames": 0, "max_ticks_frame": 0, "events": 0}
var low_vit_offered := false
var min_ratio: Array = [1.0, 1.0]       # lowest Vitality ratio each fighter reached (near-death check for the career)
var on_tick: Callable = Callable()      # optional (sim) -> void after every tick (tests, replays)

var _acc := 0.0
var _pos_prev: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _pos_cur: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var _fall: Array[float] = [0.0, 0.0]
var _fall_y: Array[float] = [0.0, 0.0]
var _yaw: Array[float] = [0.0, 0.0]
var _extra_af: Array[int] = [0, 0]
var _shadows: Array[MeshInstance3D] = []
var _invert: CanvasLayer
var _invert_frames := 0
var _result: Dictionary = {}
var _finished_sent := false

func start(config: BoutConfig) -> void:
	cfg = config
	arena_def = CombatData.arena(cfg.arena_id)
	if arena_def == null:
		arena_def = CombatData.arena("ring")
	var da := CombatData.critter(cfg.a_id)
	var db := CombatData.critter(cfg.b_id)
	if cfg.mods.has("hazard") and arena_def.hazards.is_empty():
		arena_def = arena_def.with_hazards([CombatData.rules()["hazard_default"]])   # the zone is part of the arena, so the floor shows it
	sim = CombatSim.new(da, db, arena_def, cfg.stakes(), cfg.seed_value)
	sim.apply_modifiers(cfg.mods)
	sim.fighters[0].vit = maxf(1.0, sim.fighters[0].max_vit * clampf(cfg.a_vit, 0.01, 1.0))
	sim.fighters[1].vit = maxf(1.0, sim.fighters[1].max_vit * clampf(cfg.b_vit, 0.01, 1.0))
	if cfg.timeout_ticks > 0:
		sim.R = sim.R.duplicate()
		sim.R["timeout_ticks"] = cfg.timeout_ticks
	get_viewport().scaling_3d_scale = Settings.render_scale()       # quality Low/Medium/High (HUD stays full resolution)
	ArenaBuilder.build(self, arena_def, Settings.shadows_enabled())
	for i in 2:
		var holder := Node3D.new()
		holder.name = "Fighter%d" % i
		add_child(holder)
		var rid: String = cfg.a_id if i == 0 else cfg.b_id
		var rig: CritterRig = SkinnedRig.new() if SkinnedRig.available(rid) else CritterRig.new()   # skinned skeleton when the critter has one
		holder.add_child(rig)
		rig.setup(cfg.a_id if i == 0 else cfg.b_id)
		if Settings.shadows_enabled():
			if rig.has_method("enable_shadows"): rig.enable_shadows()
		holders.append(holder)
		rigs.append(rig)
		var sh := Stage.blob_shadow(self, 0.95)
		_shadows.append(sh)
	entities = EntityView.new()
	add_child(entities)
	var pal_a: Dictionary = rigs[0].palette
	var pal_b: Dictionary = rigs[1].palette
	entities.colors = [pal_a.get("glow", Color.WHITE), pal_b.get("glow", Color.WHITE)]
	cam = BoutCamera.new()
	add_child(cam)
	cam.current = true
	cam.reach = (arena_def.radius if arena_def.shape == "circle" else maxf(arena_def.half.x, arena_def.half.y)) * 1.45 + 3.0
	cam.intro = 1.0 if cfg.intro else 0.0
	_make_providers()
	var bonus := Settings.parry_window_bonus_frames(cfg.stakes())
	if bonus > 0 and player_idx >= 0:                                  # assist: wider parry for the human, Practice / Contest only
		var pt: Dictionary = sim.fighters[player_idx].T.duplicate()
		pt["parry_window"] = int(pt["parry_window"]) + bonus
		sim.fighters[player_idx].T = pt
	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.setup(self)
	var _audio := BoutAudio.new()
	_audio.name = "BoutAudio"
	add_child(_audio)
	_audio.bind(self)
	var _vfx := BoutVfx.new()
	_vfx.bind(self)
	if player != null:
		player.attach_touch(hud.touch)
	_invert = FxCtl.make_invert_overlay()
	add_child(_invert)
	var s0 := sim.state()
	for i in 2:
		_pos_prev[i] = s0["fighters"][i]["pos"]
		_pos_cur[i] = _pos_prev[i]
		_yaw[i] = atan2(-float(s0["fighters"][i]["facing"].y), float(s0["fighters"][i]["facing"].x))
	_sync(0.0, 0.0)
	cam.update(0.0, _w(0), _w(1))
	cam.snap()
	cam.update(0.0, _w(0), _w(1))
	Perf.context = "play"
	_set_phase("intro" if cfg.intro else "fight")
	Events.bout_started.emit(cfg.a_id, cfg.b_id, cfg.stakes())

func _make_providers() -> void:
	player_idx = -1
	for i in 2:
		var human: bool = cfg.human_a if i == 0 else false
		if human:
			player = PlayerInput.new()
			providers.append(player)
			player_idx = i
		else:
			providers.append(AIProvider.new(i, cfg.profile_a if i == 0 else cfg.profile_b, cfg.seed_value * 31 + i, not cfg.training))

func _w(i: int) -> Vector3:
	return holders[i].position

func _set_phase(p: String) -> void:
	phase = p
	phase_t = 0.0
	phase_changed.emit(p)

# ------------------------------------------------------------------ main loop
func _process(delta: float) -> void:
	if sim == null:
		return
	stats["frames"] += 1
	for p in providers:
		p.frame_update(delta)
	phase_t += delta
	_update_time_scale(delta)
	var step_dt := minf(delta, MAX_FRAME) * time_scale
	var ticks := 0
	match phase:
		"intro":
			if phase_t >= INTRO_SEC:
				_set_phase("fight")
		"fight":
			_acc += step_dt
			while _acc >= TICK and not sim.is_over() and ticks < 8:
				_acc -= TICK
				_tick()
				ticks += 1
			if sim.is_over():
				_begin_outro()
		"outro", "done":
			_acc += step_dt
			while _acc >= TICK:
				_acc -= TICK
				_extra_af[0] += 1
				_extra_af[1] += 1
			if phase == "outro" and phase_t >= OUTRO_SEC:
				_set_phase("done")
				_finished_sent = true
				finished.emit(_result)
			if phase == "done":
				cam.outro_yaw += delta * 0.10
	stats["max_ticks_frame"] = maxi(stats["max_ticks_frame"], ticks)
	var alpha := clampf(_acc / TICK, 0.0, 1.0) if phase == "fight" else 0.0
	var rig_dt := 0.0 if (sim.hitstop > 0 and phase == "fight") else minf(delta * time_scale, 0.034)   # rig springs are only stable for dt <~ 1/30
	_sync(rig_dt, alpha)
	if player != null:
		player.set_view(cam.right2(), cam.forward2())
	if cam.intro > 0.0 and rigs.size() > 1 and rigs[1].has_method("socket") and rigs[1].socket("head") != null:
		cam.face_target = rigs[1].socket("head").global_position
	cam.update(delta, _w(0), _w(1))
	entities.show_entities(sim.state()["entities"], delta)
	hud.refresh(delta)
	if _invert_frames > 0:
		_invert_frames -= 1
		if _invert_frames == 0:
			_invert.visible = false

func _update_time_scale(delta: float) -> void:
	if scale_hold > 0.0:
		scale_hold -= delta
		if scale_hold <= 0.0:
			scale_target = 1.0
	time_scale = lerpf(time_scale, scale_target, 1.0 - exp(-10.0 * delta))
	if absf(time_scale - scale_target) < 0.01:
		time_scale = scale_target

func slow_motion(scale: float, seconds: float) -> void:
	scale_target = scale
	scale_hold = seconds

func _tick() -> void:
	var inps: Array[CombatInput] = []
	for i in 2:
		inps.append(providers[i].tick(sim, i))
	sim.step(inps[0], inps[1])
	stats["ticks"] += 1
	var evs := sim.take_events()
	var st := sim.state()
	for i in 2:
		_pos_prev[i] = _pos_cur[i]
		_pos_cur[i] = st["fighters"][i]["pos"]
	for ev in evs:
		stats["events"] += 1
		_on_event(ev, st)
	_check_moment(st)
	if on_tick.is_valid():
		on_tick.call(sim)

# ------------------------------------------------------------------ sim state -> rigs
func _sync(dt: float, alpha: float) -> void:
	var st := sim.state()
	var cam_p := cam.global_position
	for i in 2:
		var f: Dictionary = st["fighters"][i]
		var pos: Vector2 = _pos_prev[i].lerp(_pos_cur[i], alpha)
		var holder := holders[i]
		var y := 0.0
		if not f["alive"] and arena_def.depth(f["pos"]) > 0.3 and arena_def.edge_type(f["pos"]) == "drop":
			_fall[i] += 22.0 * dt
			_fall_y[i] -= _fall[i] * dt
			y = _fall_y[i]
		holder.position = Vector3(pos.x, y, pos.y)
		var fv: Vector2 = f["facing"]
		_yaw[i] = lerp_angle(_yaw[i], atan2(-fv.y, fv.x), 1.0 - exp(-20.0 * maxf(dt, 1.0 / 60.0)))
		holder.rotation.y = _yaw[i]
		var to_cam := Vector3(cam_p.x - holder.position.x, 0, cam_p.z - holder.position.z).normalized()
		var local_z := Vector3(sin(_yaw[i]), 0, cos(_yaw[i]))
		var tq := PLAYER_TQ if i == player_idx else FOE_TQ
		var facing_cam := clampf(-Vector3(fv.x, 0, fv.y).dot(to_cam) * 0.5 + 0.7, 0.2, 1.0)
		rigs[i].three_quarter = signf(local_z.dot(to_cam)) * tq * facing_cam
		var maxv: float = maxf(1.0, float(f["vitality_max"]))
		var fs := {
			"action": f["action"], "action_frame": int(f["action_frame"]) + _extra_af[i], "move_id": f["move_id"],
			"vitality_ratio": float(f["vitality"]) / maxv, "facing": 1.0, "stun": f["stun"],
			"rage": clampf(float(f["rage"]) / maxf(1.0, float(sim.fighters[i].T["rage_max"])), 0.0, 1.0)
		}
		var vel: Vector2 = f.get("velocity", Vector2.ZERO)                  # gait: how fast, and forwards or backwards relative to the facing
		var wsp := maxf(0.5, float(sim.fighters[i].T["walk_speed"]))
		fs["speed"] = vel.length() / wsp
		fs["fwd"] = vel.dot(fv) / wsp
		var rmax := float(sim.fighters[i].T["plate_pool"])
		if rmax > 0.0:
			var total := ceili(rmax / float(sim.R["plate_size"]))
			fs["plates"] = clampi(total - int(f["plates"]), 0, 3)
		rigs[i].apply_fighter_state(fs, dt)
		var sh := _shadows[i]
		sh.position = Vector3(pos.x, 0.015, pos.y)
		sh.visible = y > -0.5

func fighter_name(i: int) -> String:
	var n: String = cfg.a_name if i == 0 else cfg.b_name
	return n if n != "" else sim.fighters[i].def.display_name

# ------------------------------------------------------------------ sim events -> presentation
func _on_event(ev: Dictionary, st: Dictionary) -> void:
	var idx := int(ev.get("fighter", 0))
	var t := str(ev["type"])
	var att := int(ev.get("attacker", 1 - idx))
	var hp := Vector3(ev["pos"].x, 1.1, ev["pos"].y) if ev.get("pos") is Vector2 else holders[idx].position
	var blow := (holders[idx].position - holders[att].position)
	blow.y = 0.0
	var heavy := false
	if t == "hit" or t == "block" or t == "parry" or t == "grab":
		var m: MoveDef = sim.fighters[att].def.move(str(ev.get("move_id", "")))
		heavy = (m != null and m.kind in HEAVY_KINDS) or bool(ev.get("counter", false))
		if Settings.get_value("reduce_flashing"):
			heavy = false
	var rev := {"type": t, "heavy": heavy, "world_pos": hp}
	match t:
		"hit":
			rigs[idx].play_event(rev)
			var dmg := float(ev.get("damage", 0.0))
			cam.add_shake(blow, clampf(0.05 + dmg * 0.0055, 0.05, 0.4) * (1.4 if heavy else 1.0))
			cam.add_punch(0.5 + (0.8 if heavy else 0.0))
			if heavy and int(ev.get("hitstop", 0)) >= 6:
				_flash_invert()
		"block":
			rigs[idx].play_event(rev)
			cam.add_shake(blow, 0.05)
		"parry":
			rigs[idx].play_event(rev)
			cam.add_punch(1.4)
			cam.add_shake(blow, 0.1)
			_flash_invert()
		"clash":
			rigs[idx].play_event(rev)
			cam.add_shake(Vector3.RIGHT, 0.08)
			cam.add_punch(0.6)
		"grab":
			rigs[idx].play_event(rev)
			cam.add_shake(blow, 0.18)
			cam.add_punch(0.8)
		"stagger", "dodge", "tell", "ringout", "yield":
			rigs[idx].play_event(rev)
		"ko":
			rigs[idx].play_event({"type": "ko", "world_pos": hp})
			cam.add_shake(blow, 0.35)
			cam.add_punch(2.0)
			_flash_invert()
		"laststand":
			rigs[idx].play_event(rev)
			cam.add_punch(1.6)
			cam.add_shake(Vector3.UP, 0.12)
			slow_motion(0.5, 0.5)
		"compel":
			var src := holders[int(ev.get("attacker", 1 - idx))].position + Vector3(0, 1.4, 0)
			rigs[idx].play_event({"type": "compel", "source_pos": src})
		"ghost":
			var em: MoveDef = sim.fighters[1 - idx].def.move(str(ev.get("move_id", "")))
			var ga := {"light": "strike_light", "heavy": "strike_heavy", "grab": "grab"}.get(em.kind if em != null else "heavy", "ability1") as String
			rigs[1 - idx].play_event({"type": "premonition", "ghost_action": ga, "ghost_frame": int(em.startup) if em != null else 8})
	fight_event.emit(ev)

func _flash_invert() -> void:
	if Settings.get_value("reduce_flashing"):
		return
	_invert.visible = true
	_invert_frames = 2

## The 'Yield or fight on' beat: the first time the human's Vitality drops under the Last Stand line, the world slows and the HUD asks.
func _check_moment(st: Dictionary) -> void:
	for i in 2:
		var fi: Dictionary = st["fighters"][i]
		min_ratio[i] = minf(float(min_ratio[i]), float(fi["vitality"]) / maxf(1.0, float(fi["vitality_max"])))
	if low_vit_offered or player_idx < 0 or phase != "fight":
		return
	var f: Dictionary = st["fighters"][player_idx]
	if f["alive"] and float(f["vitality"]) / maxf(1.0, float(f["vitality_max"])) < float(sim.R["last_stand_ratio"]):
		low_vit_offered = true
		slow_motion(0.35, 1.1)
		Events.yield_offered.emit(cfg.a_id if player_idx == 0 else cfg.b_id)
		hud.offer_yield()

func _begin_outro() -> void:
	_result = sim.result().duplicate(true)
	_result["a_id"] = cfg.a_id
	_result["b_id"] = cfg.b_id
	_result["player_idx"] = player_idx
	_result["training"] = cfg.training
	_result["stats"] = stats.duplicate()
	_result["min_ratio"] = min_ratio.duplicate()
	_result["profile"] = cfg.profile_b if player_idx == 0 else cfg.profile_a
	var loser := int(_result.get("loser", -1))
	if loser >= 0:
		cam.outro_focus = holders[loser].position
	for p in providers:
		p.clear()
	slow_motion(0.35, 1.3)
	cam.outro_blend = 0.0
	var tw := create_tween()
	tw.tween_property(cam, "outro_blend", 1.0, 1.2)
	Events.bout_ended.emit(_result)
	_set_phase("outro")

func is_over() -> bool:
	return phase == "outro" or phase == "done"

func fighter_state(i: int) -> Dictionary:
	return sim.state()["fighters"][i]

## World position of fighter i's chest for HUD projection.
func chest(i: int, h := 1.2) -> Vector3:
	return holders[i].position + Vector3(0, h, 0)

func _exit_tree() -> void:
	if is_inside_tree():
		get_viewport().scaling_3d_scale = 1.0
	if is_instance_valid(Perf):
		Perf.context = "menu"
