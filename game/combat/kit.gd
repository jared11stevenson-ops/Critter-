class_name Kit
extends Node
## Base ability kit for a playable partner. Slots 0..2 map to ability_1..3.
## Subclasses: AruunKit, CigarraKit. Timings use scaled time so slow-mo and hit-stop stay consistent.

var c: PlayableCritter = null
var ability_ids: Array = ["", "", ""]
var cd: Array = [0.0, 0.0, 0.0]
var cd_max: Array = [1.0, 1.0, 1.0]
var clock := 0.0

func bind(critter: PlayableCritter) -> void:
	c = critter
	_setup()

func _setup() -> void:
	pass

func tick(delta: float) -> void:
	clock += delta
	for i in 3:
		if cd[i] > 0.0:
			cd[i] = maxf(0.0, cd[i] - delta)
	_tick(delta)

func _tick(_delta: float) -> void:
	pass

func wait(t: float) -> Signal:
	return c.get_tree().create_timer(maxf(0.0, t), false).timeout

func basic_pressed() -> void:
	pass

func cast(i: int) -> void:
	if i < 0 or i > 2:
		return
	if cd[i] > 0.0:
		_deny("Not ready")
		return
	var why := blocked_reason(i)
	if why != "":
		_deny(why)
		return
	if _cast(i):
		cd[i] = cd_max[i]
		Events.ability_used.emit(c.char_id, ability_ids[i])

func _deny(text: String) -> void:
	if c.controlled and Field.current:
		Field.current.float_text(c.global_position + Vector3(0, c.height + 0.5, 0), text, Color(1, 0.8, 0.7), 32)
		Audio.sfx("ui_back", -8.0)

func _cast(_i: int) -> bool:
	return false

func blocked_reason(_i: int) -> String:
	return ""

func cd_frac(i: int) -> float:
	return clampf(cd[i] / maxf(0.01, cd_max[i]), 0.0, 1.0)

func cost_hint(_i: int) -> String:
	return ""

func move_mult() -> float:
	return 1.0

func modify_incoming(amount: float, _hit: Dictionary) -> float:
	return amount

func on_interrupted() -> void:
	pass

func on_downed() -> void:
	pass

func knack_value() -> float:
	return 0.0

func knack_max() -> float:
	return 1.0

## AI: returns ability slot to use against target, or -1.
func ai_choose(_target: Node, _enemies_near: int) -> int:
	return -1

func is_busy() -> bool:
	return c.action_lock > 0.0

## Melee arc query helper.
func hit_arc(origin: Vector3, dir: Vector3, reach: float, arc_deg: float, make: Callable, out: Array) -> int:
	var f := Field.current
	if f == null:
		return 0
	f.enemies_in_radius(origin, reach, out)
	var half := deg_to_rad(arc_deg * 0.5)
	var n := 0
	for e in out:
		var to: Vector3 = e.global_position - origin
		to.y = 0
		if to.length() > 0.8 and dir.angle_to(to.normalized()) > half:
			continue
		var h: Dictionary = make.call(e)
		if to.length() > 0.01:
			h["dir"] = to.normalized()
		else:
			h["dir"] = dir
		e.receive_hit(h)
		n += 1
	return n

## Line query helper (Reaching Strike etc.).
func hit_line(origin: Vector3, dir: Vector3, length: float, width: float, make: Callable, out: Array) -> int:
	var f := Field.current
	if f == null:
		return 0
	out.clear()
	var n := 0
	for e in f.enemies:
		if not is_instance_valid(e) or not e.is_targetable():
			continue
		var to: Vector3 = e.global_position - origin
		to.y = 0
		var along := to.dot(dir)
		if along < -0.5 or along > length + e.body_radius:
			continue
		var perp := (to - dir * along).length()
		if perp > width * 0.5 + e.body_radius:
			continue
		out.append(e)
	for e in out:
		var h: Dictionary = make.call(e)
		h["dir"] = dir
		e.receive_hit(h)
		n += 1
	return n
