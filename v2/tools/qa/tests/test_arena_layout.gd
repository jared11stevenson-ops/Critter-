extends RefCounted
## Touch layout geometry (>= 96 px buttons, no overlap, on screen, every aspect, safe areas, left-handed) and TouchControls gestures.

func _touch(index: int, pos: Vector2, down: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = down
	return e

func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	return e

func run() -> Array:
	var fails: Array = []
	# viewport sizes after canvas_items/expand stretch: 16:9, 20:9 (2400x1080), 21:9, 16:10, 4:3
	var sizes := [Vector2(1280, 720), Vector2(1600, 720), Vector2(1680, 720), Vector2(1280, 800), Vector2(1280, 960)]
	var margin_sets := [Vector4(24, 16, 24, 16), Vector4(60, 20, 60, 28)]    # plain and notch / gesture-bar phone
	for layout in ["A", "B"]:
		for sz in sizes:
			for m in margin_sets:
				for lefty in [false, true]:
					var bad := TouchLayout.problems(layout, sz, m, lefty)
					QaCheck.is_true(fails, bad.is_empty(), "layout %s %s lefty=%s: %s" % [layout, sz, lefty, str(bad)])
	# stick zone and gesture zone never contain a button center
	for sz in sizes:
		for lefty in [false, true]:
			var bt := TouchLayout.buttons("A", sz, Vector4(24, 16, 24, 16), lefty)
			var zone := TouchLayout.stick_zone(sz, Vector4(24, 16, 24, 16), lefty)
			for id in bt:
				QaCheck.is_true(fails, not zone.has_point(bt[id]["center"]), "stick zone free of %s (%s lefty=%s)" % [id, sz, lefty])
	# --- TouchControls: layout A events
	var tc := TouchControls.new()
	tc.size = Vector2(1280, 720)
	tc.configure("A", false)
	var pressed: Array = []
	tc.pressed.connect(func(id): pressed.append(id))
	var bt := tc.button_rects()
	tc._input(_touch(0, bt["strike"]["center"], true))
	QaCheck.is_true(fails, tc.strike_down, "strike button down")
	tc._input(_touch(1, bt["guard"]["center"], true))
	QaCheck.is_true(fails, not tc.strike_down and tc.guard_down and pressed == ["grab"], "strike while guarding = grab, not a strike")
	pressed.clear()
	tc._input(_touch(0, bt["strike"]["center"], false))
	QaCheck.is_true(fails, tc.guard_down, "strike released, guard still held")
	tc._input(_touch(1, bt["guard"]["center"], false))
	QaCheck.is_true(fails, not tc.guard_down, "guard released")
	tc._input(_touch(2, bt["ab1"]["center"], true))
	tc._input(_touch(2, bt["ab1"]["center"], false))
	tc._input(_touch(3, bt["dodge"]["center"], true))
	tc._input(_touch(3, bt["dodge"]["center"], false))
	QaCheck.eq(fails, pressed, ["a1", "dodge"], "button presses emitted")
	# floating stick: anywhere in the zone, output relative to the touch-down point
	tc._input(_touch(4, Vector2(300, 500), true))
	tc._input(_drag(4, Vector2(300 + 96, 500)))
	QaCheck.near(fails, tc.stick.x, 1.0, "stick full right")
	tc._input(_drag(4, Vector2(300, 500 - 48)))
	QaCheck.near(fails, tc.stick.y, -0.5, "stick half up")
	tc._input(_touch(5, bt["strike"]["center"], true))
	QaCheck.is_true(fails, tc.strike_down and tc.stick.length() > 0.3, "stick and strike at the same time")
	tc._input(_touch(4, Vector2(300, 452), false))
	QaCheck.eq(fails, tc.stick, Vector2.ZERO, "stick released")
	tc.release_all()
	# Guard + Strike together = grab (either order), no strike
	pressed.clear()
	tc._input(_touch(20, bt["guard"]["center"], true))
	tc._input(_touch(21, bt["strike"]["center"], true))
	QaCheck.is_true(fails, pressed == ["grab"] and not tc.strike_down, "guard then strike = grab")
	tc.release_all()
	pressed.clear()
	tc._input(_touch(22, bt["strike"]["center"], true))
	tc._input(_touch(23, bt["guard"]["center"], true))
	QaCheck.is_true(fails, pressed == ["grab"] and not tc.strike_down, "strike then guard = grab")
	tc.release_all()
	pressed.clear()
	tc._input(_touch(24, bt["ab3"]["center"], true))
	QaCheck.eq(fails, pressed, ["a3"], "third ability button")
	tc.release_all()
	# last stand button is only hittable when offered
	pressed.clear()
	tc._input(_touch(6, bt["ls"]["center"], true))
	tc._input(_touch(6, bt["ls"]["center"], false))
	QaCheck.eq(fails, pressed.size(), 0, "hidden Last Stand button ignores touches")
	tc.can_ls = true
	tc._input(_touch(6, bt["ls"]["center"], true))
	QaCheck.eq(fails, pressed, ["ls"], "Last Stand button when available")
	tc.release_all()
	# long press on pause = yield, short press = pause
	pressed.clear()
	var paused := [0]
	tc.pause_pressed.connect(func(): paused[0] += 1)
	tc._input(_touch(7, bt["pause"]["center"], true))
	tc._process(0.2)
	tc._input(_touch(7, bt["pause"]["center"], false))
	QaCheck.eq(fails, paused[0], 1, "short press opens pause")
	QaCheck.eq(fails, pressed.size(), 0, "short press does not yield")
	tc._input(_touch(8, bt["pause"]["center"], true))
	for i in 12:
		tc._process(0.1)
	QaCheck.eq(fails, pressed, ["yield"], "long press yields")
	tc._input(_touch(8, bt["pause"]["center"], false))
	QaCheck.eq(fails, paused[0], 1, "long press does not also pause")
	# --- layout B gestures
	tc.configure("B", false)
	pressed.clear()
	var g := Vector2(900, 400)
	tc._input(_touch(0, g, true))
	tc._input(_touch(0, g, false))
	QaCheck.is_true(fails, tc.strike_down, "tap in the gesture zone strikes")
	tc._process(0.016); tc._process(0.016); tc._process(0.016)
	QaCheck.is_true(fails, not tc.strike_down, "tap pulse ends")
	tc._input(_touch(1, g, true))
	tc._input(_drag(1, g + Vector2(90, 0)))
	QaCheck.is_true(fails, pressed == ["dodge"] and tc.dodge_dir.x > 0.9, "sideways swipe = dodge")
	tc._input(_touch(1, g + Vector2(90, 0), false))
	pressed.clear()
	tc._input(_touch(9, g, true))
	tc._input(_drag(9, g + Vector2(0, -90)))
	QaCheck.eq(fails, pressed, ["grab"], "forward swipe = grab")
	tc._input(_touch(9, g + Vector2(0, -90), false))
	tc._input(_touch(2, g, true))
	tc._process(0.3)
	QaCheck.is_true(fails, tc.guard_down, "hold in the gesture zone guards")
	tc._input(_touch(2, g, false))
	QaCheck.is_true(fails, not tc.guard_down, "guard ends on release")
	tc._input(_touch(3, tc.button_rects()["heavy"]["center"], true))
	QaCheck.is_true(fails, tc.heavy_down, "heavy button (layout B)")
	tc.free()
	return fails
