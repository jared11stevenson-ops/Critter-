extends RefCounted
## PlayerInput: tap = light on release, hold = heavy, latched presses survive between ticks, Last Stand chord, stick mapped through the camera.

func _make() -> PlayerInput:
	var p := PlayerInput.new()
	p.use_keyboard = false
	p.attach_touch(TouchControls.new())
	return p

func _frame(p: PlayerInput) -> void:
	p.frame_update(1.0 / 60.0)

func run() -> Array:
	var fails: Array = []
	var sim: CombatSim = null
	# --- tap -> exactly one strike_tap, no hold
	var p := _make()
	var t: TouchControls = p.touch
	t.strike_down = true
	_frame(p)
	var taps := 0
	var holds := 0
	for i in 3:
		var o := p.tick(sim, 0)
		taps += int(o.strike_tap)
		holds += int(o.strike_hold)
	t.strike_down = false
	_frame(p)
	for i in 3:
		var o := p.tick(sim, 0)
		taps += int(o.strike_tap)
		holds += int(o.strike_hold)
	QaCheck.eq(fails, taps, 1, "tap fires one light")
	QaCheck.eq(fails, holds, 0, "tap never raises heavy")
	# --- fast tap fully between two ticks is not lost
	p = _make()
	t = p.touch
	t.strike_down = true
	_frame(p)
	t.strike_down = false
	_frame(p)
	var o2 := p.tick(sim, 0)
	QaCheck.is_true(fails, o2.strike_tap, "press+release between ticks still yields a tap")
	# --- hold -> heavy from tick HOLD_TICKS, no tap on release
	p = _make()
	t = p.touch
	t.strike_down = true
	_frame(p)
	var first_hold := -1
	var tap_seen := false
	for i in 20:
		var o := p.tick(sim, 0)
		if o.strike_hold and first_hold < 0:
			first_hold = i + 1
		tap_seen = tap_seen or o.strike_tap
	QaCheck.eq(fails, first_hold, PlayerInput.HOLD_TICKS, "heavy raised at the hold threshold")
	t.strike_down = false
	_frame(p)
	var o3 := p.tick(sim, 0)
	QaCheck.is_true(fails, not o3.strike_tap and not tap_seen, "releasing a hold does not also tap")
	# --- guard is a level; dodge/grab/abilities are single presses
	p = _make()
	t = p.touch
	t.guard_down = true
	_frame(p)
	QaCheck.is_true(fails, p.tick(sim, 0).guard and p.tick(sim, 0).guard, "guard level stays")
	t.guard_down = false
	_frame(p)
	QaCheck.is_true(fails, not p.tick(sim, 0).guard, "guard released")
	p.press("dodge"); p.press("grab"); p.press("a1"); p.press("a2")
	var o4 := p.tick(sim, 0)
	QaCheck.is_true(fails, o4.dodge and o4.grab and o4.ability1 and o4.ability2, "latched presses delivered")
	var o5 := p.tick(sim, 0)
	QaCheck.is_true(fails, not (o5.dodge or o5.grab or o5.ability1 or o5.ability2), "presses consumed once")
	# --- Last Stand: the last_stand flag (or both ability buttons on an older sim) for two ticks
	p.press("ls")
	var ls := 0
	for i in 4:
		var o := p.tick(sim, 0)
		if bool(o.get("last_stand")) or (o.ability1 and o.ability2):
			ls += 1
	QaCheck.eq(fails, ls, PlayerInput.LS_TICKS, "last stand chord lasts LS_TICKS")
	p.press("yield")
	QaCheck.is_true(fails, p.tick(sim, 0).yield_pressed, "yield press")
	# --- stick through the camera: up = camera forward, right = camera right
	p = _make()
	t = p.touch
	p.set_view(Vector2(0, 1), Vector2(1, 0))      # camera looks along +x, its right is +z
	t.stick = Vector2(0, -1)
	_frame(p)
	var mv := p.tick(sim, 0).move
	QaCheck.near(fails, mv.x, 1.0, "stick up moves along the camera forward x")
	QaCheck.near(fails, mv.y, 0.0, "stick up has no sideways part")
	t.stick = Vector2(1, 0)
	_frame(p)
	mv = p.tick(sim, 0).move
	QaCheck.near(fails, mv.y, 1.0, "stick right moves along the camera right")
	# --- swipe dodge steers by the swipe direction for a few ticks
	t.stick = Vector2.ZERO
	t.dodge_dir = Vector2(0, -1)
	_frame(p)
	p.press("dodge")
	var od := p.tick(sim, 0)
	QaCheck.is_true(fails, od.dodge and od.move.x > 0.9, "swipe dodge steers forward")
	QaCheck.is_true(fails, p.tick(sim, 0).move.x > 0.9, "dodge steering persists a few ticks")
	return fails
