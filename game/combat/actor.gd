class_name CritterActor
extends CharacterBody3D
## Shared body for party members, enemies and destructible objects.
## Damage pipeline: receive_hit(hit) where hit = {
##   amount, source, dir (Vector3), knockback, stagger, kind ("light"|"heavy"), ability (String),
##   crit (bool, forced), can_crit (bool), stun, slow:[mult,dur], feel (bool) }

signal died(actor)
signal hp_changed(hp, max_hp)

var team := "enemy"
var passive := false      # never auto-aimed (keystone wildlife)
var is_object := false    # destructible prop (pylon)
var wild := false         # non-sapient wildlife: containable under threshold
var species_id := ""
var display_name := ""
var body_radius := 0.5
var height := 1.0
var max_hp := 100.0
var hp := 100.0
var alive := true
var downed := false
var poise := 0.0
var mass := 1.0
var visual: Node3D = null
var facing := Vector3.FORWARD

var invuln_t := 0.0
var stun_t := 0.0
var stagger_t := 0.0
var slow_t := 0.0
var slow_mult := 1.0
var pull_t := 0.0
var pull_point := Vector3.ZERO
var pull_speed := 5.0
var soaked_t := 0.0        # hook for future elemental states
var knock := Vector3.ZERO
var gravity := 24.0
var _flash_cd := 0.0

func _actor_ready() -> void:
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 24.0))
	floor_max_angle = deg_to_rad(46.0)
	floor_snap_length = 0.6
	safe_margin = 0.04

# ---------------- queries ----------------
func is_targetable() -> bool:
	return alive and not downed and is_inside_tree()

func hostile_now() -> bool:
	return false

func aim_height() -> float:
	return height * 0.5

func vis(method: String, a: Variant = null, b: Variant = null) -> Variant:
	if visual == null or not visual.has_method(method):
		return null
	if b != null:
		return visual.call(method, a, b)
	if a != null:
		return visual.call(method, a)
	return visual.call(method)

func is_stunned() -> bool:
	return stun_t > 0.0 or stagger_t > 0.0

func speed_mult() -> float:
	return slow_mult if slow_t > 0.0 else 1.0

# ---------------- damage ----------------
func receive_hit(hit: Dictionary) -> float:
	if not is_targetable():
		return 0.0
	if invuln_t > 0.0 and not hit.get("ignore_invuln", false):
		return 0.0
	var s0: Variant = hit.get("source", null)
	if typeof(s0) == TYPE_OBJECT and not is_instance_valid(s0):
		hit["source"] = null
	var amount := float(hit.get("amount", 0.0))
	var crit := bool(hit.get("crit", false))
	if not crit and hit.get("can_crit", true) and team != "party":
		crit = randf() < Balance.f("global.crit_chance", 0.08)
		if crit:
			amount *= Balance.f("global.crit_mult", 1.6)
	amount = _modify_incoming(amount, hit)
	if amount < 0.0:
		# negative = deflected (armor)
		if Field.current:
			Field.current.damage_number(global_position + Vector3(0, height + 0.3, 0), 0, "armor")
			Field.current.vfx("hit_spark", global_position + Vector3(0, aim_height(), 0))
		Audio.sfx_at("hit_metal", global_position, -6.0)
		return 0.0
	hp = maxf(0.0, hp - amount)
	hp_changed.emit(hp, max_hp)
	var src: Node = hit.get("source", null)
	Events.actor_damaged.emit(self, amount, src)
	var f := Field.current
	var top := global_position + Vector3(0, height + 0.3, 0)
	if f:
		var kind := "party" if team == "party" else ("crit" if crit else "normal")
		f.damage_number(top, amount, kind)
		if hit.get("feel", true):
			if crit:
				f.impact("crit")
			elif hit.get("kind", "light") == "heavy":
				f.impact("heavy")
			else:
				f.impact("light")
		var spot := global_position + Vector3(0, aim_height(), 0)
		f.vfx("heavy_impact" if hit.get("kind", "light") == "heavy" or crit else "hit_spark", spot)
	vis("flash_hit")
	_play_hit_sfx(hit)
	# knockback / stagger (poise resists)
	var dir: Vector3 = hit.get("dir", Vector3.ZERO)
	dir.y = 0
	if dir.length_squared() < 0.001 and src is Node3D:
		dir = global_position - (src as Node3D).global_position
		dir.y = 0
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
	var kb := float(hit.get("knockback", 0.0))
	if kb > 0.0:
		var resist := clampf(1.0 - poise / 160.0, 0.15, 1.0)
		knock += dir * kb * resist * 2.2 / maxf(0.5, mass)
	var stg := float(hit.get("stagger", 0.0))
	if stg > 0.0 and (hit.get("kind", "light") == "heavy" or poise < 30.0 or hit.get("force_stagger", false)):
		stagger_t = maxf(stagger_t, stg * clampf(1.0 - poise / 200.0, 0.3, 1.0))
		_on_staggered()
	if hit.has("stun"):
		apply_stun(float(hit["stun"]))
	if hit.has("slow"):
		var s: Array = hit["slow"]
		apply_slow(float(s[0]), float(s[1]))
	_on_hit(hit, amount)
	if hp <= 0.0:
		_on_zero_hp(hit)
	return amount

func _play_hit_sfx(hit: Dictionary) -> void:
	Audio.sfx_at("hit_flesh", global_position)

func _modify_incoming(amount: float, _hit: Dictionary) -> float:
	return amount

func _on_hit(_hit: Dictionary, _amount: float) -> void:
	pass

func _on_staggered() -> void:
	pass

func _on_zero_hp(_hit: Dictionary) -> void:
	alive = false
	died.emit(self)
	Events.actor_died.emit(self)

func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)

# ---------------- statuses ----------------
func apply_stun(dur: float) -> void:
	stun_t = maxf(stun_t, dur)
	_on_staggered()

func apply_slow(mult: float, dur: float) -> void:
	slow_mult = mult
	slow_t = maxf(slow_t, dur)

func apply_pull(point: Vector3, dur: float, spd: float) -> void:
	pull_point = point
	pull_t = dur
	pull_speed = spd

func apply_status(status_name: String, dur: float, data: Dictionary = {}) -> void:
	match status_name:
		"stun": apply_stun(dur)
		"slow": apply_slow(float(data.get("mult", 0.5)), dur)
		"pulled": apply_pull(data.get("point", global_position), dur, float(data.get("speed", 5.0)))
		"soaked": soaked_t = maxf(soaked_t, dur)

func tick_statuses(delta: float) -> void:
	invuln_t = maxf(0.0, invuln_t - delta)
	stun_t = maxf(0.0, stun_t - delta)
	stagger_t = maxf(0.0, stagger_t - delta)
	soaked_t = maxf(0.0, soaked_t - delta)
	if slow_t > 0.0:
		slow_t -= delta
		if slow_t <= 0.0:
			slow_mult = 1.0
	if pull_t > 0.0:
		pull_t -= delta

## Horizontal steering + knockback + pull + gravity, then move_and_slide.
var _knock_applied := Vector3.ZERO   # knock added to velocity last frame (removed before steering)

func body_move(desired: Vector3, accel: float, friction: float, delta: float, fly_height: float = -1.0) -> void:
	# Steer the actor's own velocity only — last frame's knockback is taken back out first, otherwise it
	# feeds back into velocity every frame and a 6 m/s knock snowballs into 80 m/s launches.
	var hv := Vector3(velocity.x - _knock_applied.x, 0, velocity.z - _knock_applied.z)
	if desired.length_squared() > 0.0001:
		hv = hv.move_toward(desired, accel * delta)
	else:
		hv = hv.move_toward(Vector3.ZERO, friction * delta)
	if pull_t > 0.0:
		var to := pull_point - global_position
		to.y = 0
		if to.length() > 0.6:
			hv = to.normalized() * pull_speed
		else:
			hv = Vector3.ZERO
	var k := knock
	knock = knock.move_toward(Vector3.ZERO, 30.0 * delta)
	_knock_applied = Vector3(k.x, 0, k.z)
	velocity.x = hv.x + k.x
	velocity.z = hv.z + k.z
	if fly_height >= 0.0:
		var ground := Field.current.height_at(global_position.x, global_position.z) if Field.current else 0.0
		var target_y := ground + fly_height
		velocity.y = (target_y - global_position.y) * 4.0
	elif is_on_floor() and velocity.y <= 0.0:
		velocity.y = -0.5
	else:
		velocity.y -= gravity * delta
	move_and_slide()
	# keep facing current horizontal velocity when not overridden
	if fly_height < 0.0 and hv.length_squared() > 0.25:
		pass

func face_toward(dir: Vector3) -> void:
	var d := Vector3(dir.x, 0, dir.z)
	if d.length_squared() > 0.0001:
		facing = d.normalized()
		vis("set_facing", facing)
