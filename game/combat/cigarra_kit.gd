class_name CigarraKit
extends Kit
## Cigarra — The Oracle Hopper. Bad Thought, Premonition, False Memory, Brain Skip, Grasshopper Thought.
## Cost: Future-Noise (Bible §22 "Cost of Premonition"): she experiences prophecy as noise.

var noise := 0.0
var _since_cast := 10.0
var overwhelmed_t := 0.0
var _fire_cd := 0.0
var _fire_buffered := false
var premonition_t := 0.0
var _ghosts: Array = []         # [ghost_visual, enemy]
var _false_ghosts: Array = []
var _last_emit := -1.0
var _q: Array = []

func _setup() -> void:
	ability_ids = ["premonition", "false_memory", "brain_skip"]
	cd_max = [Balance.f("cigarra.premonition.cd", 12.0), Balance.f("cigarra.false_memory.cd", 14.0), Balance.f("cigarra.brain_skip.cd", 9.0)]

func cost_hint(i: int) -> String:
	var keys := ["premonition", "false_memory", "brain_skip"]
	return "+%d NOISE" % int(Balance.f("cigarra.%s.noise" % keys[i], 20.0))

func knack_value() -> float:
	return noise

func knack_max() -> float:
	return Balance.f("cigarra.noise.max", 100.0)

func move_mult() -> float:
	return Balance.f("cigarra.noise.overwhelm_slow", 0.5) if overwhelmed_t > 0.0 else 1.0

func blocked_reason(_i: int) -> String:
	if overwhelmed_t > 0.0:
		return "Overwhelmed!"
	return ""

func add_noise(v: float) -> void:
	noise = clampf(noise + v, 0.0, knack_max())
	_since_cast = 0.0
	if noise >= knack_max() and overwhelmed_t <= 0.0:
		overwhelmed_t = Balance.f("cigarra.noise.overwhelm_time", 3.0)
		Audio.sfx("noise_overload")
		if Field.current:
			Field.current.float_text(c.global_position + Vector3(0, c.height + 0.6, 0), "OVERWHELMED", Color(0.9, 0.5, 1.0), 50)
			Field.current.shake(0.3)
		Events.toast.emit("Cigarra is overwhelmed by future-noise", "warning")
	Events.knack_cost_changed.emit("cigarra", noise, knack_max())

func _tick(delta: float) -> void:
	_fire_cd = maxf(0.0, _fire_cd - delta)
	_since_cast += delta
	if overwhelmed_t > 0.0:
		overwhelmed_t -= delta
		if overwhelmed_t <= 0.0:
			noise = knack_max() * 0.4
			Events.knack_cost_changed.emit("cigarra", noise, knack_max())
	elif _since_cast > Balance.f("cigarra.noise.decay_delay", 0.8) and noise > 0.0:
		noise = maxf(0.0, noise - Balance.f("cigarra.noise.decay", 6.0) * delta)
		if clock - _last_emit > 0.1 or noise == 0.0:
			_last_emit = clock
			Events.knack_cost_changed.emit("cigarra", noise, knack_max())
	if _fire_buffered and _fire_cd <= 0.0:
		_fire_buffered = false
		basic_pressed()
	if premonition_t > 0.0:
		premonition_t -= delta
		_update_ghosts()
		if premonition_t <= 0.0:
			_end_premonition()

# ---------------- Bad Thought ----------------
func basic_pressed() -> void:
	if _fire_cd > 0.0:
		if _fire_cd < 0.15:
			_fire_buffered = true
		return
	if not c.can_act() and c.action_lock > 0.15:
		return
	var b := Balance.section("cigarra.bad_thought")
	_fire_cd = float(b.get("interval", 0.36))
	var rng := float(b.get("range", 14.0))
	var a := c.aim(rng, true)
	var dir: Vector3 = a[0]
	c.face_toward(dir)
	c.begin_action(0.12, 0.6)
	c.vis("play_attack", "cast")
	Audio.sfx_at("psychic_bolt", c.global_position, -3.0)
	var from := c.global_position + Vector3(0, c.height * 0.85, 0) + dir * 0.4
	var hit := c.make_hit(float(b.get("damage", 16)), "light", "bad_thought", {"knockback": float(b.get("knockback", 1.2)), "stagger": float(b.get("stagger", 0.12))})
	if Field.current:
		Field.current.spawn_projectile(from, dir, float(b.get("speed", 26.0)), rng + 2.0, hit, "party", a[1], "psychic")

# ---------------- abilities ----------------
func _cast(i: int) -> bool:
	match i:
		0: return _premonition()
		1: return _false_memory()
		2: return _brain_skip()
	return false

func _premonition() -> bool:
	var b := Balance.section("cigarra.premonition")
	var f := Field.current
	if f == null:
		return false
	premonition_t = float(b.get("duration", 5.0))
	f.premonition_active = true
	f.request_time_scale("premonition", float(b.get("time_scale", 0.7)))
	c.begin_action(0.25, 0.0)
	c.vis("play_attack", "cast")
	Audio.sfx("premonition")
	f.vfx("psychic_burst", c.global_position + Vector3(0, 1.2, 0))
	f.float_text(c.global_position + Vector3(0, c.height + 0.6, 0), "PREMONITION", Color(0.75, 0.95, 1.0), 48)
	add_noise(float(b.get("noise", 30.0)))
	_spawn_ghosts()
	return true

func _spawn_ghosts() -> void:
	_clear_ghosts()
	var f := Field.current
	for e in f.enemies:
		if not is_instance_valid(e) or not e.is_targetable() or e.passive or e.is_object:
			continue
		if e.global_position.distance_to(c.global_position) > 28.0:
			continue
		if not e.has_method("make_ghost_visual"):
			continue
		var g: Node3D = e.make_ghost_visual()
		if g == null:
			continue
		f.add_child(g)
		g.global_position = e.global_position
		_ghosts.append([g, e])
		f.future_ghosts.append(g)
	if noise >= Balance.f("cigarra.noise.distort_at", 60.0):
		# False ghosts: noise corrupts the vision. They look the same but grant no counter.
		for k in 2:
			if _ghosts.is_empty():
				break
			var src: Array = _ghosts[randi() % _ghosts.size()]
			var e2: Node = src[1]
			var fg: Node3D = e2.make_ghost_visual()
			if fg:
				f.add_child(fg)
				fg.global_position = e2.global_position + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
				fg.set_meta("false_ghost", true)
				_false_ghosts.append(fg)

func _update_ghosts() -> void:
	var lead := Balance.f("cigarra.premonition.ghost_lead", 0.9)
	for pair in _ghosts:
		var g: Node3D = pair[0]
		var e: Node = pair[1]
		if not is_instance_valid(g):
			continue
		if not is_instance_valid(e) or not e.is_targetable():
			g.visible = false
			continue
		var p: Vector3 = e.future_point(lead) if e.has_method("future_point") else e.global_position
		g.global_position = g.global_position.lerp(p, 0.25)
		if e.has_method("future_facing"):
			VisualFactory.call_v(g, "set_facing", [e.future_facing()])
	for fg in _false_ghosts:
		if is_instance_valid(fg):
			fg.global_position += Vector3(sin(clock * 3.0 + fg.get_instance_id()), 0, cos(clock * 2.0)) * 0.02

func _clear_ghosts() -> void:
	var f := Field.current
	for pair in _ghosts:
		if is_instance_valid(pair[0]):
			if f:
				f.future_ghosts.erase(pair[0])
			pair[0].queue_free()
	for fg in _false_ghosts:
		if is_instance_valid(fg):
			fg.queue_free()
	_ghosts.clear()
	_false_ghosts.clear()

func _end_premonition() -> void:
	premonition_t = 0.0
	_clear_ghosts()
	var f := Field.current
	if f:
		f.premonition_active = false
		f.clear_time_scale("premonition")

func _false_memory() -> bool:
	var b := Balance.section("cigarra.false_memory")
	var a := c.aim(10.0, true)
	var dir: Vector3 = a[0]
	var p := c.global_position + dir * 3.0
	if Field.current:
		p.y = Field.current.height_at(p.x, p.z)
	c.begin_action(0.2, 0.0)
	c.vis("play_attack", "cast")
	Audio.sfx_at("false_memory", p)
	var d := Decoy.new()
	c.get_parent().add_child(d)
	d.global_position = p
	d.setup("cigarra", float(b.get("duration", 5.0)))
	if Field.current:
		Field.current.vfx("false_memory_echo", p)
	add_noise(float(b.get("noise", 25.0)))
	return true

func _brain_skip() -> bool:
	var b := Balance.section("cigarra.brain_skip")
	var a := c.aim(float(b.get("range", 12.0)), true)
	var t: Node = a[1]
	if t == null or t.is_object:
		_deny("No target")
		return false
	c.face_toward(a[0])
	c.begin_action(0.25, 0.0)
	c.vis("play_attack", "cast")
	Audio.sfx_at("brain_skip", t.global_position)
	if t.has_method("skip_action"):
		t.skip_action()
	var h := c.make_hit(float(b.get("damage", 30)), "heavy", "brain_skip", {"stun": float(b.get("stun", 1.6)), "knockback": 0.5})
	h["feel"] = true
	t.receive_hit(h)
	if Field.current:
		Field.current.vfx("brain_skip_glitch", t.global_position + Vector3(0, t.aim_height(), 0))
		Field.current.float_text(t.global_position + Vector3(0, t.height + 0.9, 0), "SKIPPED", Color(0.6, 1.0, 0.9), 44)
	add_noise(float(b.get("noise", 20.0)))
	return true

## Grasshopper Thought (contextual: leap points).
func grasshopper(to: Vector3, cb: Callable) -> void:
	var b := Balance.section("cigarra.grasshopper_thought")
	add_noise(float(b.get("noise", 10.0)))
	Events.ability_used.emit("cigarra", "grasshopper_thought")
	c.start_leap(to, float(b.get("time", 1.15)), float(b.get("height", 6.0)), cb)

func on_downed() -> void:
	if premonition_t > 0.0:
		_end_premonition()

func _exit_tree() -> void:
	_end_premonition()

func ai_choose(target: Node, enemies_near: int) -> int:
	if target == null or noise > 45.0 or overwhelmed_t > 0.0:
		return -1
	var d: float = target.global_position.distance_to(c.global_position)
	if cd[2] <= 0.0 and d < 11.0 and target.has_method("is_winding_up") and target.is_winding_up():
		return 2
	if cd[1] <= 0.0 and enemies_near >= 3:
		return 1
	return -1
