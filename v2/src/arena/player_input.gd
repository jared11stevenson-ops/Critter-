class_name PlayerInput extends InputProvider
## Human input: keyboard / gamepad through the InputActions autoload actions plus the on-screen TouchControls.
## Strike: tap = light (fires on release), hold >= HOLD_TICKS = heavy (level stays up while held, for charged heavies).
## Guard is a level (the sim reads the press timing as a parry). Grab / dodge / abilities are latched presses.
## Last Stand = ability1 + ability2 raised together for two ticks. Yield is the 'yield' key or the long press in the HUD.

const HOLD_TICKS := 8        # shorter hold = light fires on release sooner (<= ~130 ms); trade-off: heavies need a firmer hold
const LS_TICKS := 2
const DODGE_STEER_TICKS := 6

var locked := true                 # lock-on toggle (button / key): free movement when off
var cam_right := Vector2.RIGHT
var cam_forward := Vector2(0, -1)
var touch: Object = null           # TouchControls (duck typed: stick, strike_down, guard_down, signal pressed(name))
var use_keyboard := true
# levels written by sources
var stick := Vector2.ZERO          # screen space: x right, y down
var strike_level := false
var guard_level := false
var heavy_level := false          # touch Heavy button (layout B): holds strike_hold up while pressed
# latches
var _latch := {}
var _strike_prev := false
var _sp := false
var _sr := false
var _holding := false
var _held_ticks := 0
var _ls_left := 0
var _steer := Vector2.ZERO
var _steer_left := 0

func attach_touch(t: Object) -> void:
	touch = t
	if t != null and t.has_signal("pressed"):
		t.connect("pressed", press)

func set_view(right: Vector2, forward: Vector2) -> void:
	cam_right = right
	cam_forward = forward

func press(action: String) -> void:
	_latch[action] = true

func frame_update(_delta: float) -> void:
	var s := Vector2.ZERO
	var strike := false
	var guard := false
	if use_keyboard:
		s = InputActions.move_vector()
		strike = Input.is_action_pressed("strike")
		guard = Input.is_action_pressed("guard")
		for a in ["grab", "dodge", "ability1", "ability2", "ability3", "last_stand", "yield"]:
			if Input.is_action_just_pressed(a):
				_latch[{"ability1": "a1", "ability2": "a2", "ability3": "a3", "last_stand": "ls"}.get(a, a)] = true
		if Input.is_action_just_pressed("lock"):
			_latch["lock"] = true
	if touch != null:
		if touch.stick.length() > s.length():
			s = touch.stick
		strike = strike or touch.strike_down
		guard = guard or touch.guard_down
		heavy_level = touch.heavy_down
	stick = s
	guard_level = guard
	strike_level = strike
	if strike and not _strike_prev:
		if guard:
			_latch["grab"] = true      # Guard + Strike together = grab
		else:
			_sp = true
	if _strike_prev and not strike:
		_sr = true
	_strike_prev = strike

func world_move() -> Vector2:
	var m := cam_right * stick.x + cam_forward * (-stick.y)
	return m.limit_length(1.0)

func tick(_sim: CombatSim, _idx: int) -> CombatInput:
	var o := CombatInput.new()
	if _take("lock"):
		locked = not locked
		if touch != null and "lock_on" in touch:
			touch.set("lock_on", locked)
	o.lock = locked
	o.move = world_move()
	o.guard = guard_level
	if heavy_level:
		o.strike_hold = true
	if _sp:
		_sp = false
		_holding = true
		_held_ticks = 0
	if _holding:
		_held_ticks += 1
		if _held_ticks >= HOLD_TICKS and (strike_level or not _sr):
			o.strike_hold = true
	if _sr:
		_sr = false
		if _holding and _held_ticks < HOLD_TICKS:
			o.strike_tap = true
		_holding = false
	if not strike_level and not _sp:
		_holding = false
	o.grab = _take("grab")
	if _take("dodge"):
		o.dodge = true
		var dd: Vector2 = touch.dodge_dir if (touch != null and "dodge_dir" in touch) else Vector2.ZERO
		if dd != Vector2.ZERO:
			_steer = (cam_right * dd.x + cam_forward * (-dd.y)).limit_length(1.0)
			_steer_left = DODGE_STEER_TICKS
	if _steer_left > 0:
		_steer_left -= 1
		o.move = _steer
	o.ability1 = _take("a1")
	o.ability2 = _take("a2")
	if "ability3" in o:
		o.set("ability3", _take("a3"))
	else:
		_take("a3")
	if _take("ls"):
		_ls_left = LS_TICKS
	if _ls_left > 0:
		_ls_left -= 1
		if "last_stand" in o:
			o.set("last_stand", true)
		else:
			o.ability1 = true
			o.ability2 = true
	o.yield_pressed = _take("yield")
	return o

func _take(k: String) -> bool:
	if _latch.get(k, false):
		_latch[k] = false
		return true
	return false

func clear() -> void:
	_latch.clear()
	_sp = false; _sr = false; _holding = false; _ls_left = 0; _steer_left = 0
