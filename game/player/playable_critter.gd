class_name PlayableCritter
extends CritterActor
## A playable partner (Aruun / Cigarra). Driven by intents written each frame either by the
## PartyController (player input) or the partner AI. Collision: layer 2, mask 1|3|4.

signal downed_changed(member, is_downed)

var char_id := "aruun"
var controlled := false
var kit: Kit = null

# intents (written by controller / AI each frame)
var in_move := Vector3.ZERO      # world-space, length 0..1
var in_aim := Vector3.ZERO       # stick direction if held (abilities aim along it)

var base_speed := 4.6
var accel := 38.0
var friction := 30.0
var speed_buff := 1.0
var dmg_mult := 1.0

var state := "normal"            # normal | dash | downed | channel | leap | burden | scripted
var action_lock := 0.0
var action_move_mult := 1.0
var _action_token := 0

var dash_cd := 0.0
var _dash_t := 0.0
var _dash_dir := Vector3.FORWARD
var _dash_speed := 14.0
var _dash_ghost_hit := false
var counter_ready := false       # Premonition counter: next hit = guaranteed crit x2.5

var revive_progress := 0.0
var _safe_ring: Array = []
var _safe_t := 0.0
var _scripted_pts: Array = []
var _scripted_cb: Callable
var _leap_from := Vector3.ZERO
var _leap_to := Vector3.ZERO
var _leap_t := 0.0
var _leap_dur := 1.0
var _leap_h := 6.0
var _leap_cb: Callable
var _step_t := 0.0

func setup(id: String) -> void:
	char_id = id
	team = "party"
	display_name = Canon.display_name(id)
	species_id = id
	var b := Balance.section(id)
	max_hp = float(b.get("hp", 300))
	hp = max_hp
	base_speed = float(b.get("speed", 4.6))
	accel = float(b.get("accel", 38.0))
	friction = float(b.get("friction", 30.0))
	height = float(b.get("height", 1.8))
	body_radius = float(b.get("radius", 0.5))
	poise = float(b.get("poise", 20))
	mass = 2.0 if id == "aruun" else 1.0
	name = id.capitalize()

func _ready() -> void:
	_actor_ready()
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = body_radius
	cap.height = maxf(height * 0.8, body_radius * 2.0 + 0.1)
	cs.shape = cap
	cs.position.y = cap.height * 0.5
	add_child(cs)
	visual = VisualFactory.character(char_id)
	add_child(visual)
	if char_id == "aruun":
		kit = AruunKit.new()
	else:
		kit = CigarraKit.new()
	kit.name = "Kit"
	add_child(kit)
	kit.bind(self)
	if Field.current:
		Field.current.register_party(self)
	face_toward(Vector3.FORWARD)

# ---------------- actions ----------------
func can_act() -> bool:
	return state == "normal" and action_lock <= 0.0 and not is_stunned() and alive and not downed

func begin_action(lock: float, move_mult: float = 0.0) -> int:
	_action_token += 1
	action_lock = lock
	action_move_mult = move_mult
	return _action_token

func action_valid(tok: int) -> bool:
	return tok == _action_token and alive and not downed and state != "downed"

func interrupt_action() -> void:
	_action_token += 1
	action_lock = 0.0
	if kit:
		kit.on_interrupted()

func request_attack() -> void:
	if kit and not downed and state == "normal" and not is_stunned():
		kit.basic_pressed()

func request_ability(i: int) -> void:
	if kit and can_act():
		kit.cast(i)

func request_dash() -> void:
	if downed or state != "normal" or dash_cd > 0.0 or stun_t > 0.0:
		return
	if kit and kit.has_method("dash_blocked") and kit.dash_blocked():
		return
	var b := Balance.section(char_id)
	var dir := in_move
	if dir.length_squared() < 0.04:
		dir = facing
	dir.y = 0
	_dash_dir = dir.normalized()
	var dt := float(b.get("dash_time", 0.22))
	_dash_t = dt
	_dash_speed = float(b.get("dash_dist", 4.0)) / dt
	invuln_t = maxf(invuln_t, float(b.get("dash_iframes", 0.25)))
	dash_cd = float(b.get("dash_cd", 1.2))
	_dash_ghost_hit = false
	interrupt_action()
	stagger_t = 0.0
	state = "dash"
	face_toward(_dash_dir)
	vis("play_attack", "leap" if char_id == "cigarra" else "light")
	Audio.sfx_at("leap" if char_id == "cigarra" else "swing_light", global_position, -4.0)
	if Field.current:
		Field.current.vfx("dust_puff", global_position)

## Aim helper: returns [dir, target]. Abilities aim along the stick if held, else auto-aim.
func aim(max_range: float, use_stick: bool = true) -> Array:
	var f := Field.current
	var base := facing
	if use_stick and in_aim.length_squared() > 0.09:
		base = in_aim.normalized()
	var t: Node = null
	if f:
		var cone := Balance.f("global.autoaim_cone_deg", 70.0)
		if use_stick and in_aim.length_squared() > 0.09:
			cone = 40.0
		t = f.find_target(global_position, base, max_range, cone)
	if t:
		var d: Vector3 = t.global_position - global_position
		d.y = 0
		if d.length_squared() > 0.01:
			return [d.normalized(), t]
	return [base, null]

# ---------------- physics ----------------
func _physics_process(delta: float) -> void:
	tick_statuses(delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	action_lock = maxf(0.0, action_lock - delta)
	if kit:
		kit.tick(delta)
	match state:
		"downed":
			body_move(Vector3.ZERO, accel, friction * 2.0, delta)
			vis("set_move_amount", 0.0)
		"dash":
			_dash_t -= delta
			velocity.x = _dash_dir.x * _dash_speed
			velocity.z = _dash_dir.z * _dash_speed
			_knock_applied = Vector3.ZERO
			velocity.y = -2.0 if is_on_floor() else velocity.y - gravity * delta
			move_and_slide()
			_check_ghost_dash()
			if _dash_t <= 0.0:
				state = "normal"
				velocity.x *= 0.3
				velocity.z *= 0.3
		"leap":
			_leap_t += delta
			var k := clampf(_leap_t / _leap_dur, 0.0, 1.0)
			var p := _leap_from.lerp(_leap_to, k)
			p.y += sin(k * PI) * _leap_h
			global_position = p
			velocity = Vector3.ZERO
			_knock_applied = Vector3.ZERO
			if k >= 1.0:
				state = "normal"
				Audio.sfx_at("land", global_position)
				if Field.current:
					Field.current.vfx("dust_puff", global_position)
					Field.current.shake(0.2)
				if _leap_cb.is_valid():
					_leap_cb.call()
		"scripted":
			_scripted_step(delta)
		"burden", "channel":
			body_move(Vector3.ZERO, accel, friction, delta)
			vis("set_move_amount", 0.0)
		_:
			var desired := Vector3.ZERO
			var mv := in_move
			if mv.length() > 1.0:
				mv = mv.normalized()
			if not is_stunned():
				var mult := speed_buff * speed_mult()
				if kit:
					mult *= kit.move_mult()
				if action_lock > 0.0:
					mult *= action_move_mult
				desired = mv * base_speed * mult
				if mv.length_squared() > 0.01 and action_lock <= 0.0:
					face_toward(mv)
			body_move(desired, accel, friction, delta)
			var hs := Vector2(velocity.x, velocity.z).length()
			vis("set_move_amount", clampf(hs / base_speed, 0.0, 1.0))
			if hs > 1.0 and is_on_floor():
				_step_t -= delta * hs
				if _step_t <= 0.0:
					_step_t = 2.2
					if controlled:
						Audio.sfx_at("footstep_dirt", global_position, -12.0)
	_track_safe(delta)

func _check_ghost_dash() -> void:
	if _dash_ghost_hit or Field.current == null:
		return
	var ghosts: Array = Field.current.future_ghosts
	var r := Balance.f("cigarra.premonition.ghost_radius", 1.6)
	for g in ghosts:
		if is_instance_valid(g) and g.visible and not g.has_meta("false_ghost"):
			var gp: Vector3 = g.global_position
			if Vector2(gp.x - global_position.x, gp.z - global_position.z).length() < r:
				_dash_ghost_hit = true
				counter_ready = true
				var f := Field.current
				f.request_time_scale("counter", Balance.f("cigarra.premonition.counter_slowmo_scale", 0.25), Balance.f("cigarra.premonition.counter_slowmo", 0.35))
				f.float_text(global_position + Vector3(0, height + 0.6, 0), "COUNTER!", Color(0.7, 0.95, 1.0), 54)
				f.shake(0.25)
				f.vfx("psychic_burst", global_position + Vector3(0, 1, 0))
				Audio.sfx("premonition", 2.0)
				Events.toast.emit("Counter ready: next hit is a critical", "info")
				return

func _track_safe(delta: float) -> void:
	if global_position.y < -14.0 and state != "leap":
		_fall_recover()
		return
	_safe_t -= delta
	if _safe_t <= 0.0 and is_on_floor() and state == "normal":
		_safe_t = 0.4
		_safe_ring.append(global_position)
		if _safe_ring.size() > 8:
			_safe_ring.pop_front()

func _fall_recover() -> void:
	var p: Vector3 = _safe_ring[0] if _safe_ring.size() > 0 else global_position + Vector3(0, 20, 0)
	if Field.current and Field.current.level and Field.current.level.has_method("safe_point_near"):
		p = Field.current.level.safe_point_near(p, self)
	global_position = p + Vector3(0, 0.6, 0)
	velocity = Vector3.ZERO
	_knock_applied = Vector3.ZERO
	knock = Vector3.ZERO
	state = "normal"
	if alive and not downed:
		var dmg := max_hp * Balance.f("global.fall_damage_frac", 0.08)
		hp = maxf(1.0, hp - dmg)
		hp_changed.emit(hp, max_hp)
		if Field.current:
			Field.current.damage_number(global_position + Vector3(0, height, 0), dmg, "party")
	_safe_ring.clear()

func teleport(p: Vector3) -> void:
	global_position = p
	velocity = Vector3.ZERO
	_knock_applied = Vector3.ZERO
	knock = Vector3.ZERO
	_safe_ring.clear()
	if state == "dash" or state == "leap" or state == "scripted":
		state = "normal"

# ---------------- leap / scripted ----------------
func start_leap(to: Vector3, dur: float, h: float, cb: Callable = Callable()) -> void:
	interrupt_action()
	_leap_from = global_position
	_leap_to = to
	_leap_t = 0.0
	_leap_dur = dur
	_leap_h = h
	_leap_cb = cb
	state = "leap"
	face_toward(to - global_position)
	vis("play_attack", "leap")
	Audio.sfx_at("leap", global_position)
	if Field.current:
		Field.current.vfx("leap_trail", global_position, {"to": to}, null)

func scripted_move(points: Array, cb: Callable = Callable()) -> void:
	interrupt_action()
	_scripted_pts = points.duplicate()
	_scripted_cb = cb
	state = "scripted"

func _scripted_step(delta: float) -> void:
	if _scripted_pts.is_empty():
		state = "normal"
		vis("set_move_amount", 0.0)
		if _scripted_cb.is_valid():
			var cb := _scripted_cb
			_scripted_cb = Callable()
			cb.call()
		return
	var target: Vector3 = _scripted_pts[0]
	var to := target - global_position
	to.y = 0
	if to.length() < 0.5:
		_scripted_pts.pop_front()
		return
	face_toward(to)
	body_move(to.normalized() * base_speed * 0.9, accel, friction, delta)
	vis("set_move_amount", 0.9)

# ---------------- damage ----------------
func receive_hit(hit: Dictionary) -> float:
	if state == "leap" or state == "scripted":
		return 0.0
	var dealt := super.receive_hit(hit)
	if dealt > 0.0:
		invuln_t = maxf(invuln_t, Balance.f("global.invuln_after_hit", 0.3))
		if controlled and Field.current:
			Field.current.shake(0.18 if dealt < 25 else 0.4)
	return dealt

func _modify_incoming(amount: float, hit: Dictionary) -> float:
	if kit:
		return kit.modify_incoming(amount, hit)
	return amount

func _on_staggered() -> void:
	if state == "normal":
		interrupt_action()

func _play_hit_sfx(_hit: Dictionary) -> void:
	Audio.sfx_at("hit_shell" if char_id == "aruun" else "hit_flesh", global_position)

func _on_zero_hp(_hit: Dictionary) -> void:
	set_downed(true)

func set_downed(on: bool) -> void:
	if downed == on:
		return
	downed = on
	revive_progress = 0.0
	if on:
		interrupt_action()
		if kit:
			kit.on_downed()
		state = "downed"
		hp = 0.0
		Audio.sfx("downed")
	else:
		state = "normal"
		invuln_t = 1.2
	vis("set_downed", on)
	hp_changed.emit(hp, max_hp)
	downed_changed.emit(self, on)

func revive(frac: float) -> void:
	hp = max_hp * frac
	set_downed(false)
	if Field.current:
		Field.current.vfx("heal_motes", global_position)
		Field.current.damage_number(global_position + Vector3(0, height, 0), hp, "heal")

## Outgoing hit helper: applies buffs, counter crit, routes feel only for the controlled member.
func make_hit(amount: float, kind: String, ability: String, extra: Dictionary = {}) -> Dictionary:
	var h := {"amount": amount * dmg_mult, "source": self, "kind": kind, "ability": ability, "feel": controlled or kind == "heavy"}
	if counter_ready:
		counter_ready = false
		h["amount"] = float(h["amount"]) * Balance.f("cigarra.premonition.counter_mult", 2.5)
		h["crit"] = true
	for k in extra:
		h[k] = extra[k]
	return h

func is_targetable() -> bool:
	return alive and not downed and is_inside_tree() and state != "leap"
