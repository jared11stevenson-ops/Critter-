class_name AruunKit
extends Kit
## Aruun — The Reacher. Morrow combo, Reaching Strike, Gravity Pull, Beetle Rage (Strain).
## Bible §23: "Greater strength therefore means greater self-damage."

var combo_i := 0
var swinging := false
var buffered := false
var _buffer_at := -10.0
var _chain_until := -1.0
var rage_t := 0.0
var strain_spent := 0.0
var _strain_tick := 0.0
var _rage_fx: Node = null
var _q: Array = []

func _setup() -> void:
	ability_ids = ["reaching_strike", "gravity_pull", "beetle_rage"]
	cd_max = [Balance.f("aruun.reaching_strike.cd", 6.0), Balance.f("aruun.gravity_pull.cd", 10.0), Balance.f("aruun.beetle_rage.cd", 18.0)]

func cost_hint(i: int) -> String:
	return "STRAIN" if i == 2 else ""

func knack_value() -> float:
	return strain_spent

func knack_max() -> float:
	return c.max_hp * Balance.f("aruun.beetle_rage.strain_per_s", 0.04) * Balance.f("aruun.beetle_rage.duration", 8.0)

func raging() -> bool:
	return rage_t > 0.0

# ---------------- combo ----------------
func basic_pressed() -> void:
	if swinging:
		buffered = true
		_buffer_at = clock
		return
	if not c.can_act():
		return
	var i := combo_i if clock <= _chain_until else 0
	_swing(i)

func _swing(i: int) -> void:
	swinging = true
	buffered = false
	var windup := Balance.arr("aruun.combo.windup", i, 0.1)
	var active := Balance.arr("aruun.combo.active", i, 0.08)
	var recover := Balance.arr("aruun.combo.recover", i, 0.25)
	var tok := c.begin_action(windup + active + recover, 0.2)
	var a := c.aim(Balance.arr("aruun.combo.range", i, 3.0) + 2.5, true)
	var dir: Vector3 = a[0]
	c.face_toward(dir)
	var heavy := i == 2
	c.vis("play_attack", "heavy" if heavy else "light")
	Audio.sfx_at("swing_heavy" if heavy else "swing_light", c.global_position)
	# small forward lunge for weight
	var lunge := Balance.arr("aruun.combo.lunge", i, 1.0)
	c.knock += dir * lunge * 3.2
	await wait(windup)
	if not c.action_valid(tok):
		swinging = false
		return
	var rng := Balance.arr("aruun.combo.range", i, 3.0)
	var arc := Balance.arr("aruun.combo.arc_deg", i, 150.0)
	var dmg := Balance.arr("aruun.combo.damage", i, 22.0)
	var kb := Balance.arr("aruun.combo.knockback", i, 2.5)
	var stg := Balance.arr("aruun.combo.stagger", i, 0.2)
	var kind := "heavy" if heavy else "light"
	var rage_stagger := raging()
	var origin := c.global_position
	var n := hit_arc(origin, dir, rng, arc, func(_e): return c.make_hit(dmg, kind, "aruun_combo", {"knockback": kb, "stagger": stg, "force_stagger": rage_stagger}), _q)
	if Field.current:
		Field.current.vfx("mace_arc", origin + Vector3(0, 1.1, 0) + dir * 0.8, {"angle": arc, "radius": rng, "dir": dir, "heavy": heavy})
		if heavy:
			Field.current.vfx("dust_puff", origin + dir * rng * 0.7)
	if n == 0 and heavy:
		Field.current.shake(0.12)
	await wait(active + recover * 0.45)
	if not c.action_valid(tok):
		swinging = false
		return
	if buffered and clock - _buffer_at < 0.6 and i < 2:
		c.action_lock = 0.0
		_swing(i + 1)
		return
	await wait(recover * 0.55)
	swinging = false
	if not c.action_valid(tok):
		return
	if buffered and clock - _buffer_at < 0.6:
		buffered = false
		_swing(0 if i >= 2 else i + 1)
		return
	combo_i = 0 if i >= 2 else i + 1
	_chain_until = clock + Balance.f("aruun.combo.chain_window", 0.45)

func on_interrupted() -> void:
	swinging = false
	buffered = false

# ---------------- abilities ----------------
func _cast(i: int) -> bool:
	match i:
		0: _reaching_strike()
		1: _gravity_pull()
		2: _beetle_rage()
	return true

func _reaching_strike() -> void:
	var b := Balance.section("aruun.reaching_strike")
	var length := float(b.get("length", 9.0))
	var a := c.aim(length + 1.0, true)
	var dir: Vector3 = a[0]
	# If no enemy target, prefer an interactable breakable in front (e.g. cracked Thoughtstone)
	if a[1] == null and Field.current and Field.current.level and Field.current.level.has_method("breakable_dir"):
		var bd: Variant = Field.current.level.breakable_dir(c.global_position, dir, length + 2.0)
		if bd is Vector3:
			dir = bd
	c.face_toward(dir)
	var windup := float(b.get("windup", 0.26))
	var tok := c.begin_action(windup + 0.3, 0.0)
	c.vis("play_attack", "heavy")
	Audio.sfx_at("mace_extend", c.global_position)
	if Field.current:
		Field.current.telegraph_rect(c.global_position, dir, length, float(b.get("width", 1.8)), windup, Color(1.0, 0.65, 0.3, 0.8))
	await wait(windup)
	if not c.action_valid(tok):
		return
	var origin := c.global_position
	var dmg := float(b.get("damage", 60))
	hit_line(origin, dir, length, float(b.get("width", 1.8)), func(_e): return c.make_hit(dmg, "heavy", "reaching_strike", {"knockback": float(b.get("knockback", 6.0)), "stagger": float(b.get("stagger", 0.6)), "force_stagger": true}), _q)
	var f := Field.current
	if f:
		f.vfx("reach_line", origin + Vector3(0, 1.2, 0), {"length": length, "dir": dir})
		f.vfx("heavy_impact", origin + dir * length + Vector3(0, 0.8, 0))
		f.shake(0.3)
		if f.level and f.level.has_method("on_line_strike"):
			f.level.on_line_strike(origin, dir, length, "reaching_strike")

func _gravity_pull() -> void:
	var b := Balance.section("aruun.gravity_pull")
	var dist := float(b.get("dist", 6.0))
	var a := c.aim(dist + 4.0, true)
	var dir: Vector3 = a[0]
	var point := c.global_position + dir * dist
	if a[1] != null:
		var tp: Vector3 = a[1].global_position
		if tp.distance_to(c.global_position) < dist + 3.0:
			point = tp
	if Field.current:
		point.y = Field.current.height_at(point.x, point.z)
	c.face_toward(dir)
	var tok := c.begin_action(0.35, 0.3)
	c.vis("play_attack", "cast")
	Audio.sfx_at("gravity_hum", point)
	var pull_time := float(b.get("pull_time", 2.0))
	var radius := float(b.get("radius", 6.0))
	var f := Field.current
	var well: Node = null
	if f:
		well = f.vfx("gravity_well", point + Vector3(0, 1.5, 0), {"radius": radius, "duration": pull_time})
		f.telegraph_circle(point, radius, pull_time, Color(0.62, 0.45, 1.0, 0.7))
	var t := 0.0
	while t < pull_time:
		if f == null or not is_instance_valid(c) or c.downed:
			return
		f.enemies_in_radius(point, radius, _q)
		for e in _q:
			if not e.is_object:
				e.apply_pull(point, 0.3, float(b.get("pull_speed", 5.5)))
		await wait(0.25)
		t += 0.25
	if not is_instance_valid(c) or c.downed:
		return
	# Slam — Probable Impact when Cigarra's Premonition is active and the combo is unlocked.
	var combo: bool = bool(GameState.get_flag("combo_unlocked", false)) and f != null and f.premonition_active
	var dmg := float(b.get("slam_damage", 45))
	var extra := {"knockback": 3.0, "stagger": 0.5}
	if combo:
		dmg *= float(b.get("combo_mult", 2.0))
		extra["stun"] = float(b.get("combo_stun", 2.0))
	f.enemies_in_radius(point, float(b.get("slam_radius", 4.2)), _q)
	for e in _q:
		var h := c.make_hit(dmg, "heavy", "gravity_pull", extra)
		h["feel"] = true
		h["dir"] = (e.global_position - point).normalized() if e.global_position.distance_to(point) > 0.2 else Vector3.FORWARD
		e.receive_hit(h)
	Audio.sfx_at("slam", point)
	f.vfx("heavy_impact", point + Vector3(0, 0.4, 0))
	f.vfx("dust_puff", point)
	f.impact("boss" if combo else "heavy")
	if combo:
		f.float_text(point + Vector3(0, 2.6, 0), "PROBABLE IMPACT!", Color(0.85, 0.95, 0.4), 60)
		Events.ability_used.emit("combo", "probable_impact")
	if well and is_instance_valid(well) and well.has_method("stop"):
		well.stop()

func _beetle_rage() -> void:
	var b := Balance.section("aruun.beetle_rage")
	rage_t = float(b.get("duration", 8.0))
	strain_spent = 0.0
	c.dmg_mult = float(b.get("dmg_mult", 1.5))
	c.speed_buff = float(b.get("speed_mult", 1.25))
	c.begin_action(0.35, 0.0)
	c.vis("play_attack", "heavy")
	Audio.sfx_at("rage_roar", c.global_position)
	if Field.current:
		Field.current.shake(0.35)
		Field.current.float_text(c.global_position + Vector3(0, c.height + 0.7, 0), "BEETLE RAGE", Color(1.0, 0.45, 0.25), 52)
		_rage_fx = Field.current.vfx("rage_aura", c.global_position, {}, c)
	c.vis("set_highlight", Color(1.0, 0.3, 0.1), true)

func _tick(delta: float) -> void:
	if rage_t > 0.0:
		rage_t -= delta
		_strain_tick -= delta
		if _strain_tick <= 0.0:
			_strain_tick = 0.5
			var dmg := c.max_hp * Balance.f("aruun.beetle_rage.strain_per_s", 0.04) * 0.5
			dmg = minf(dmg, c.hp - 1.0)
			if dmg > 0.0:
				c.hp -= dmg
				strain_spent += dmg
				c.hp_changed.emit(c.hp, c.max_hp)
				if Field.current:
					Field.current.damage_number(c.global_position + Vector3(0, c.height + 0.2, 0), dmg, "strain")
			Events.knack_cost_changed.emit("aruun", strain_spent, knack_max())
		if rage_t <= 0.0:
			_end_rage()

func _end_rage() -> void:
	rage_t = 0.0
	c.dmg_mult = 1.0
	c.speed_buff = 1.0
	c.vis("set_highlight", Color(1.0, 0.3, 0.1), false)
	if _rage_fx and is_instance_valid(_rage_fx):
		if _rage_fx.has_method("stop"):
			_rage_fx.stop()
		else:
			_rage_fx.queue_free()
	_rage_fx = null
	strain_spent = 0.0
	Events.knack_cost_changed.emit("aruun", 0.0, knack_max())

func on_downed() -> void:
	if rage_t > 0.0:
		_end_rage()

func ai_choose(target: Node, enemies_near: int) -> int:
	if target == null:
		return -1
	var d: float = target.global_position.distance_to(c.global_position)
	if cd[1] <= 0.0 and enemies_near >= 3 and d < 9.0:
		return 1
	if cd[0] <= 0.0 and d < 8.5 and d > 3.0:
		return 0
	if cd[2] <= 0.0 and enemies_near >= 3 and c.hp > c.max_hp * 0.7:
		return 2
	return -1
