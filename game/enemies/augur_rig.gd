class_name AugurRig
extends EnemyBase
## Boss: AUGUR-7 Deepcore Rig (GDD beat 8).
## Phase 1: drill slams + drone waves. Phase 2: vents open (only damageable at vents) + Thoughtstone
## shard eruptions. Phase 3: overdrive drill beam sweep (dash through or hide behind shards).

signal phase_changed(p)
signal defeated

var phase := 1
var active := false
var vents: Array = []
var vents_open := false
var _vent_t := 0.0
var _slam_t := 2.0
var _drone_t := 4.0
var _shard_t := 3.0
var _beam_t := 4.0
var _beam_state := ""        # "" | "tele" | "sweep"
var _beam_a := 0.0
var _beam_from := 0.0
var _beam_to := 0.0
var _beam_dmg_acc: Dictionary = {}
var _transition_t := 0.0
var drones: Array = []
var shards: Array = []
var _ray_q: PhysicsRayQueryParameters3D

func _enemy_ready() -> void:
	is_object = false
	wild = false
	poise = 9999.0
	mass = 1000.0
	collision_layer = 4
	collision_mask = 0
	_ray_q = PhysicsRayQueryParameters3D.new()
	_ray_q.collision_mask = 1
	for i in 3:
		var v := VentWeakpoint.new()
		v.rig = self
		v.name = "VentWP%d" % (i + 1)
		get_parent().add_child.call_deferred(v)
		vents.append(v)
	_bind_vent_markers.call_deferred()

func _bind_vent_markers() -> void:
	for i in 3:
		var m: Node3D = null
		if visual and visual.has_method("get_vent"):
			m = visual.get_vent(i + 1) as Node3D
		if m == null:
			m = VisualFactory.marker(visual, "Vent%d" % (i + 1))
		if m == null:
			m = Marker3D.new()
			add_child(m)
			m.position = Vector3(-body_radius * 0.7, 2.5, (i - 1) * 2.6)
		vents[i].marker = m

func activate() -> void:
	active = true
	aggro = true
	if Field.current:
		Field.current.boss_active = true
	Events.boss_phase_changed.emit(1)

func hostile_now() -> bool:
	return active and alive

func aim_height() -> float:
	return 2.0

func _modify_incoming(amount: float, hit: Dictionary) -> float:
	if not active or _transition_t > 0.0:
		return -1.0
	if phase >= 2 and not hit.get("via_vent", false):
		return -1.0
	return amount

func make_ghost_visual() -> Node3D:
	return null

func future_point(_lead: float) -> Vector3:
	return _attack_point

func _physics_process(delta: float) -> void:
	if not alive:
		return
	tick_statuses(delta)
	knock = Vector3.ZERO
	stun_t = 0.0
	stagger_t = 0.0
	if not active:
		return
	if _transition_t > 0.0:
		_transition_t -= delta
		return
	_check_phase()
	var c := cfg
	# --- drill slams ---
	_slam_t -= delta
	if _slam_t <= 0.0 and _beam_state == "":
		_slam_t = float(c.get("slam_interval", 3.2)) * (1.0 if phase == 1 else 1.35)
		_drill_slam()
	# --- drone waves (phase 1-2) ---
	if phase <= 2:
		_drone_t -= delta
		if _drone_t <= 0.0:
			_drone_t = float(c.get("drone_wave_interval", 14.0))
			_spawn_drones()
	# --- vents + shards (phase 2+) ---
	if phase >= 2:
		_vent_t -= delta
		if _vent_t <= 0.0:
			_set_vents(not vents_open)
			_vent_t = float(c.get("vent_open_time", 6.0)) if vents_open else float(c.get("vent_closed_time", 4.0))
		_shard_t -= delta
		if _shard_t <= 0.0:
			_shard_t = float(c.get("shard_interval", 7.0))
			_shard_eruption()
	# --- beam (phase 3) ---
	if phase >= 3:
		_beam_tick(delta)

func _check_phase() -> void:
	var frac := hp / max_hp
	var want := 1
	if frac <= float(cfg.get("phase3_at", 0.33)):
		want = 3
	elif frac <= float(cfg.get("phase2_at", 0.66)):
		want = 2
	if want > phase:
		phase = want
		_transition_t = 1.6
		vis("set_phase", phase)
		Audio.sfx_at("vent", global_position)
		if Field.current:
			Field.current.impact("boss")
			Field.current.vfx("coolant_vent", global_position + Vector3(0, 3, 0))
		passive = true   # body is armoured now: auto-aim goes to the vents
		if phase == 2:
			_set_vents(true)
			_vent_t = float(cfg.get("vent_open_time", 6.0))
			_shard_t = 2.0
		if phase == 3:
			_beam_t = 2.5
		phase_changed.emit(phase)
		Events.boss_phase_changed.emit(phase)

func _set_vents(on: bool) -> void:
	vents_open = on
	for v in vents:
		v.open = on
	vis("open_vents", on)
	Audio.sfx_at("vent", global_position)
	if on and Field.current:
		for v in vents:
			if v.marker:
				Field.current.vfx("coolant_vent", v.marker.global_position)
		Events.toast.emit("Vents open — strike them!", "info")

func _nearest_party() -> Node:
	var f := Field.current
	if f == null:
		return null
	return f.enemy_pick_target(global_position, 60.0)

func _drill_slam() -> void:
	var t := _nearest_party()
	if t == null:
		return
	var p: Vector3 = t.global_position
	var to := flat_to(p)
	var reach := 22.0
	if to.length() > reach:
		p = global_position + to.normalized() * reach
	var dur := float(cfg.get("slam_telegraph", 1.1))
	_attack_point = p
	vis("play_telegraph", dur)
	vis("play_drill_slam")
	Audio.sfx_at("drill", global_position)
	var rad := float(cfg.get("slam_radius", 4.2))
	if Field.current:
		Field.current.telegraph_circle(p, rad, dur)
	await get_tree().create_timer(dur, false).timeout
	if not alive or not is_inside_tree():
		return
	hit_party_in_radius(p, rad, make_hit(float(cfg.get("slam_damage", 48)), "heavy", {"knockback": 9.0, "stagger": 0.6}))
	Audio.sfx_at("slam", p)
	if Field.current:
		Field.current.vfx("heavy_impact", p + Vector3(0, 0.3, 0))
		Field.current.vfx("drill_sparks", p + Vector3(0, 0.5, 0))
		Field.current.vfx("dust_puff", p)
		Field.current.shake(0.45)

func _spawn_drones() -> void:
	var alive_n := 0
	for d in drones:
		if is_instance_valid(d) and d.alive:
			alive_n += 1
	var f := Field.current
	if f == null or f.level == null or not f.level.has_method("spawn_enemy"):
		return
	var n := mini(int(cfg.get("drone_wave", 2)), int(cfg.get("max_drones", 3)) - alive_n)
	for i in n:
		var p := global_position + Vector3(-8.0, 0, (i * 2 - 1) * 7.0)
		var d: Node = f.level.spawn_enemy("dominion_drone", p)
		if d:
			d.aggro = true
			drones.append(d)
	if n > 0:
		Events.toast.emit("Survey drones deployed", "warning")

func _shard_eruption() -> void:
	var f := Field.current
	if f == null:
		return
	var n := int(cfg.get("shard_count", 3))
	var rad := float(cfg.get("shard_radius", 2.2))
	var dur := float(cfg.get("shard_telegraph", 1.1))
	var pts: Array = []
	var t := _nearest_party()
	var center: Vector3 = t.global_position if t else global_position + Vector3(-12, 0, 0)
	for i in n:
		var a := TAU * float(i) / float(n) + randf() * 0.8
		var r := 3.5 if i > 0 else 0.0
		var p := center + Vector3(cos(a) * r, 0, sin(a) * r)
		# keep shards in the arena, between rig and player for phase-3 cover
		var rel := p - global_position
		rel.y = 0
		if rel.length() < body_radius + 3.0:
			p = global_position + rel.normalized() * (body_radius + 3.0)
		pts.append(p)
		f.telegraph_circle(p, rad, dur, Color(0.55, 0.85, 1.0, 1.0), true)
	await get_tree().create_timer(dur, false).timeout
	if not alive or not is_inside_tree():
		return
	for p in pts:
		hit_party_in_radius(p, rad, make_hit(float(cfg.get("shard_damage", 30)), "heavy", {"knockback": 7.0, "stagger": 0.4}))
		_spawn_shard(p)
		f.vfx("thoughtstone_shards", p)
	f.shake(0.3)
	Audio.sfx_at("boulder_break", center)

func _spawn_shard(p: Vector3) -> void:
	var f := Field.current
	if shards.size() >= 6:
		var old: Node = shards.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.9
	cyl.height = 3.2
	cs.shape = cyl
	cs.position.y = 1.6
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(1.8, 3.4, 1.8)
	mi.mesh = pm
	mi.position.y = 1.7
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.78, 0.92)
	m.emission_enabled = true
	m.emission = Color(0.2, 0.5, 0.7)
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mi.material_override = m
	sb.add_child(mi)
	get_parent().add_child(sb)
	var gy := f.height_at(p.x, p.z) if f else p.y
	sb.global_position = Vector3(p.x, gy - 3.4, p.z)
	sb.rotation.y = randf() * TAU
	var tw := sb.create_tween()
	tw.tween_property(sb, "global_position:y", gy, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(float(cfg.get("shard_life", 18.0)))
	tw.tween_property(sb, "global_position:y", gy - 3.6, 0.6)
	tw.tween_callback(sb.queue_free)
	shards.append(sb)

func _beam_tick(delta: float) -> void:
	var f := Field.current
	match _beam_state:
		"":
			_beam_t -= delta
			if _beam_t <= 0.0:
				_beam_state = "tele"
				var arc := deg_to_rad(float(cfg.get("beam_arc_deg", 150.0)))
				# arena is toward -X of the rig: angle PI
				var dir := 1.0 if randf() < 0.5 else -1.0
				_beam_from = PI - arc * 0.5 * dir
				_beam_to = PI + arc * 0.5 * dir
				var dur := float(cfg.get("beam_telegraph", 1.4))
				_beam_t = dur
				vis("play_telegraph", dur)
				Audio.sfx_at("drill", global_position, 3.0)
				if f:
					f.telegraph_arc(global_position, minf(_beam_from, _beam_to), maxf(_beam_from, _beam_to), float(cfg.get("beam_length", 34.0)), dur)
					Events.toast.emit("Drill beam! Dash through or hide behind a shard", "warning")
		"tele":
			_beam_t -= delta
			if _beam_t <= 0.0:
				_beam_state = "sweep"
				_beam_t = 0.0
				_beam_dmg_acc.clear()
		"sweep":
			_beam_t += delta
			var dur2 := float(cfg.get("beam_sweep_time", 2.6))
			var k := clampf(_beam_t / dur2, 0.0, 1.0)
			_beam_a = lerpf(_beam_from, _beam_to, k)
			_beam_visual(true)
			_beam_damage(delta)
			if f and int(_beam_t * 10.0) % 2 == 0:
				f.shake(0.06)
			if k >= 1.0:
				_beam_state = ""
				_beam_t = float(cfg.get("beam_interval", 9.0))
				_beam_visual(false)

func _beam_visual(on: bool) -> void:
	if visual and visual.has_method("set_beam"):
		visual.set_beam(on, _beam_angle_for_visual())

## Gameplay keeps the beam as a world-space angle a (direction (cos a, 0, sin a)). Agent 1's rig wants
## yaw relative to its facing (its "Beam" node points down local -Z of its parent); the fallback
## visual takes the world angle as-is.
func _beam_angle_for_visual() -> float:
	var bn := visual.find_child("Beam", true, false) as Node3D
	if bn == null or not (bn.get_parent() is Node3D):
		return _beam_a
	var pb: Basis = (bn.get_parent() as Node3D).global_basis.orthonormalized()
	var parent_yaw := atan2(pb.z.x, pb.z.z)
	var want := atan2(-cos(_beam_a), -sin(_beam_a))
	return wrapf(want - parent_yaw, -PI, PI)

func _beam_damage(delta: float) -> void:
	var f := Field.current
	if f == null:
		return
	var origin := global_position + Vector3(0, 1.2, 0)
	var length := float(cfg.get("beam_length", 34.0))
	for p in f.party_members:
		if not p.is_targetable():
			continue
		var to: Vector3 = p.global_position - global_position
		to.y = 0
		if to.length() > length:
			continue
		var ang := atan2(to.z, to.x)
		var diff := absf(wrapf(ang - _beam_a, -PI, PI))
		var tol := 0.09 + 1.0 / maxf(4.0, to.length())
		if diff > tol:
			continue
		# behind a Thoughtstone shard?
		_ray_q.from = origin
		_ray_q.to = p.global_position + Vector3(0, 1.0, 0)
		_ray_q.exclude = [get_rid()]
		var res := get_world_3d().direct_space_state.intersect_ray(_ray_q)
		if not res.is_empty():
			var col: Object = res.get("collider")
			if col is StaticBody3D and shards.has(col):
				continue
		var acc: float = float(_beam_dmg_acc.get(p.get_instance_id(), 0.0)) + float(cfg.get("beam_damage_per_s", 70)) * delta
		if acc >= 10.0:
			p.receive_hit(make_hit(acc, "heavy", {"knockback": 2.0}))
			acc = 0.0
		_beam_dmg_acc[p.get_instance_id()] = acc

func _on_zero_hp(hit: Dictionary) -> void:
	_beam_visual(false)
	_set_vents(false)
	for d in drones:
		if is_instance_valid(d) and d.alive:
			d.receive_hit({"amount": 9999.0, "source": self, "can_crit": false, "feel": false, "ignore_invuln": true})
	alive = false
	collision_layer = 4
	died.emit(self)
	Events.actor_died.emit(self)
	if Field.current:
		Field.current.boss_active = false
		Field.current.impact("boss")
		Field.current.vfx("boss_explosion", global_position + Vector3(0, 4, 0))
		Field.current.request_time_scale("boss_kill", 0.3, 0.9)
	Audio.sfx_at("explosion", global_position, 4.0)
	vis("play_die")
	defeated.emit()
