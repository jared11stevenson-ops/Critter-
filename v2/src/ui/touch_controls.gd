class_name TouchControls extends Control
## On-screen controls. Layout A = buttons (Strike tap/hold, Guard hold, Dodge, Grab, two abilities); layout B = gestures
## (tap strike, swipe dodge, hold guard) plus Heavy / Grab / ability buttons. Floating left stick, left-handed mirroring,
## safe-area aware, multi-touch. Reads ScreenTouch / ScreenDrag only (the project emulates touch from the mouse on desktop).
## PlayerInput polls the public levels and listens to `pressed`. The HUD pushes cooldowns and the Last Stand state in.

signal pressed(id: String)           # grab dodge a1 a2 a3 ls yield
signal pause_pressed

const HOLD_GUARD_SEC := 0.24
const TAP_MAX_TRAVEL := 28.0
const SWIPE_MIN := 58.0
const SWIPE_MAX_SEC := 0.40
const YIELD_HOLD_SEC := 1.0

var layout := "A"
var left_handed := false
var stick := Vector2.ZERO
var strike_down := false
var guard_down := false
var heavy_down := false
var dodge_dir := Vector2.ZERO
var can_ls := false
var lock_on := true                                  # lock-on shown on the LOCK button (PlayerInput owns the state)
var cooldowns := {"ab1": 0.0, "ab2": 0.0, "ab3": 0.0}           # remaining ratio 0..1
var ab_names := {"ab1": "", "ab2": "", "ab3": ""}
var ab_colors := {"ab1": UiStyle.TEAL_LT, "ab2": UiStyle.GOLD, "ab3": UiStyle.PAPER}
var ab_icons: Dictionary = {}                       # button id -> Texture2D (ability icons from res://art/icons)
var basic_icons: Dictionary = {}                    # strike/heavy/guard/dodge/grab/ls -> Texture2D
var ab_known := false                               # HUD set the names: ability buttons without a move are hidden
var yield_progress := 0.0
var blocker: Callable = Callable()                  # (Vector2) -> bool: true where a menu / prompt sits on top (touches there are not gameplay)

var _btns: Dictionary = {}
var _fingers: Dictionary = {}                       # index -> {role, id, origin, pos, t}
var _stick_origin := Vector2.ZERO
var _stick_finger := -1
var _pulse := 0
var _pressed_ids: Dictionary = {}
var _margins := Vector4(24, 16, 24, 16)
var _t := 0.0
var _ink: Ink

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(relayout)
	relayout()

func configure(layout_id: String, lefty: bool) -> void:
	layout = layout_id if layout_id in ["A", "B"] else "A"
	left_handed = lefty
	release_all()
	relayout()

func relayout() -> void:
	_margins = UiStyle.safe_margins(get_viewport()) if is_inside_tree() else Vector4(24, 16, 24, 16)
	_btns = TouchLayout.buttons(layout, size, _margins, left_handed)
	_stick_origin = TouchLayout.stick_home(size, _margins, left_handed)
	queue_redraw()

func button_rects() -> Dictionary:
	return _btns

func release_all() -> void:
	_fingers.clear()
	stick = Vector2.ZERO
	strike_down = false
	guard_down = false
	heavy_down = false
	_stick_finger = -1
	_pressed_ids.clear()
	yield_progress = 0.0
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		release_all()

func _hidden(id: String) -> bool:
	return (id == "ls" and not can_ls) or (ab_known and id.begins_with("ab") and str(ab_names.get(id, "")) == "")

func _hit_button(p: Vector2) -> String:
	var best := ""
	var best_d := 1e9
	for id in _btns:
		if _hidden(id):
			continue
		var b: Dictionary = _btns[id]
		var d := p.distance_to(b["center"])
		if d <= float(b["r"]) * 1.12 and d < best_d:
			best = id
			best_d = d
	return best

func _input(ev: InputEvent) -> void:
	if not visible:
		return
	if ev is InputEventScreenTouch:
		var e := ev as InputEventScreenTouch
		if e.pressed:
			_down(e.index, e.position)
		else:
			_up(e.index)
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		_drag(d.index, d.position)

func _down(idx: int, p: Vector2) -> void:
	if blocker.is_valid() and blocker.call(p):
		return
	var id := _hit_button(p)
	if id != "":
		_fingers[idx] = {"role": "button", "id": id, "t": _t, "pos": p, "origin": p}
		match id:
			"strike":
				if guard_down:
					pressed.emit("grab")          # Guard + Strike together = universal throw
					_fingers[idx]["role"] = "button"
				else:
					strike_down = true
			"guard":
				guard_down = true
				if strike_down:
					strike_down = false
					pressed.emit("grab")
			"heavy": heavy_down = true
			"pause": pass
			"ab1": pressed.emit("a1")
			"ab2": pressed.emit("a2")
			"ab3": pressed.emit("a3")
			_: pressed.emit(id)
		_pressed_ids[id] = true
	elif _stick_finger < 0 and TouchLayout.stick_zone(size, _margins, left_handed).has_point(p):
		_stick_finger = idx
		_stick_origin = _clamp_origin(p)
		_fingers[idx] = {"role": "stick", "id": "stick", "t": _t, "pos": p, "origin": p}
		stick = Vector2.ZERO
	elif layout == "B" and TouchLayout.gesture_zone(size, left_handed).has_point(p):
		_fingers[idx] = {"role": "gesture", "id": "gesture", "t": _t, "pos": p, "origin": p, "done": false}
	queue_redraw()

func _clamp_origin(p: Vector2) -> Vector2:
	var r := TouchLayout.STICK_R + 8.0
	return Vector2(clampf(p.x, r, size.x - r), clampf(p.y, r, size.y - r))

func _drag(idx: int, p: Vector2) -> void:
	if not _fingers.has(idx):
		return
	var f: Dictionary = _fingers[idx]
	f["pos"] = p
	match f["role"]:
		"stick":
			var v := (p - _stick_origin) / TouchLayout.STICK_R
			if v.length() < 0.06:
				v = Vector2.ZERO
			stick = v.limit_length(1.0)
			var over := (p - _stick_origin).length() - TouchLayout.STICK_R * 1.4     # floating: the base follows a thumb that runs far
			if over > 0.0:
				_stick_origin += (p - _stick_origin).normalized() * over
		"gesture":
			var dv: Vector2 = p - f["origin"]
			if not f["done"] and dv.length() >= SWIPE_MIN and _t - float(f["t"]) <= SWIPE_MAX_SEC:
				f["done"] = true
				dodge_dir = dv.normalized()
				pressed.emit("grab" if dodge_dir.y < -0.8 else "dodge")        # forward swipe = grab, any other swipe = dodge
	queue_redraw()

func _up(idx: int) -> void:
	if not _fingers.has(idx):
		return
	var f: Dictionary = _fingers[idx]
	_fingers.erase(idx)
	match f["role"]:
		"stick":
			_stick_finger = -1
			stick = Vector2.ZERO
			_stick_origin = TouchLayout.stick_home(size, _margins, left_handed)
		"button":
			match f["id"]:
				"strike": strike_down = false
				"guard": guard_down = false
				"heavy": heavy_down = false
				"pause":
					if yield_progress < 1.0 and _t - float(f["t"]) < YIELD_HOLD_SEC:
						pause_pressed.emit()
			_pressed_ids.erase(f["id"])
			yield_progress = 0.0 if f["id"] == "pause" else yield_progress
		"gesture":
			if f["done"]:
				pass
			elif guard_down:
				guard_down = false
			elif (f["pos"] - f["origin"]).length() <= TAP_MAX_TRAVEL and _t - float(f["t"]) < HOLD_GUARD_SEC:
				strike_down = true
				_pulse = 2
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _pulse > 0:
		_pulse -= 1
		if _pulse == 0:
			strike_down = false
	for idx in _fingers:
		var f: Dictionary = _fingers[idx]
		if f["role"] == "gesture" and not f["done"] and not guard_down and _t - float(f["t"]) >= HOLD_GUARD_SEC \
				and (f["pos"] - f["origin"]).length() <= TAP_MAX_TRAVEL:
			guard_down = true
			f["done"] = false
		elif f["role"] == "button" and f["id"] == "pause":
			yield_progress = clampf((_t - float(f["t"])) / YIELD_HOLD_SEC, 0.0, 1.0)
			if yield_progress >= 1.0 and not f.get("fired", false):
				f["fired"] = true
				pressed.emit("yield")
	if visible:
		queue_redraw()

# ------------------------------------------------------------------ drawing
func _col_for(id: String) -> Color:
	match id:
		"strike", "heavy": return UiStyle.GOLD
		"guard": return UiStyle.TEAL_LT
		"dodge": return UiStyle.GREEN
		"grab": return Color(0.86, 0.45, 0.30)
		"ab1", "ab2", "ab3": return ab_colors[id]
		"ls": return Color(0.95, 0.35, 0.30)
		"lock": return UiStyle.TEAL if lock_on else UiStyle.PAPER_DK
	return UiStyle.PAPER

func _draw() -> void:
	if _ink == null:
		_ink = Ink.new(self)
	# stick: idle hint ring or the live base + knob
	var sc := _stick_origin
	var active := _stick_finger >= 0
	_ink.disc(sc, TouchLayout.STICK_R, Color(0.09, 0.07, 0.07, 0.30 if active else 0.16))
	_ink.ring(sc, TouchLayout.STICK_R, Color(0.95, 0.88, 0.72, 0.55 if active else 0.3))
	var knob := sc + stick * TouchLayout.STICK_R
	_ink.disc(knob, 44.0, UiStyle.INK)
	_ink.disc(knob, 40.0, Color(0.95, 0.88, 0.72, 0.85 if active else 0.35))
	if layout == "B":
		var gz := TouchLayout.gesture_zone(size, left_handed)
		_ink.text(Vector2(gz.position.x + gz.size.x * 0.5 - 200, size.y * 0.30), "tap strike  hold guard  swipe dodge  swipe up grab", 18, Color(0.95, 0.88, 0.72, 0.5), HORIZONTAL_ALIGNMENT_CENTER, 400)
	var washes: Array = []
	for id in _btns:
		if _hidden(id):
			continue
		_draw_button(id, _btns[id], washes)
	for w in washes:
		_ink_wash(w[0], w[1], w[2])
	_ink.flush()

func _draw_button(id: String, b: Dictionary, washes: Array) -> void:
	var c: Vector2 = b["center"]
	var r: float = b["r"]
	var down: bool = _pressed_ids.has(id) or (id == "strike" and strike_down) or (id == "guard" and guard_down)
	if id == "pause":
		_ink.disc(c, r, Color(0.09, 0.07, 0.07, 0.55))
		_ink.ring(c, r, UiStyle.PAPER, true)
		_ink.rect(Rect2(c + Vector2(-12, -16), Vector2(8, 32)), UiStyle.PAPER)
		_ink.rect(Rect2(c + Vector2(4, -16), Vector2(8, 32)), UiStyle.PAPER)
		if yield_progress > 0.0:
			draw_arc(c, r + 6, -PI * 0.5, -PI * 0.5 + TAU * yield_progress, 32, UiStyle.RUST, 7.0, true)
			_ink.text(c + Vector2(-70, r + 34), "keep holding to YIELD", 18, UiStyle.RUST, HORIZONTAL_ALIGNMENT_CENTER, 140)
		return
	var col := _col_for(id)
	var rr := r * (0.92 if down else 1.0)
	if id == "ls":
		rr += sin(_t * 9.0) * 3.0
	_ink.disc(c + Vector2(4, 5), rr, Color(0, 0, 0, 0.5))
	_ink.disc(c, rr + 3.0, UiStyle.INK)
	_ink.disc(c, rr - 1.0, col.darkened(0.25) if down else col)
	_ink.ring(c, rr - 8.0, Color(1, 1, 1, 0.22))
	var cd := float(cooldowns.get(id, 0.0))
	if cd > 0.0:
		washes.append([c, rr - 1.0, cd])
	var label := str(b["label"])
	if id == "lock":
		label = "LOCK" if lock_on else "FREE"
	var fsize := 18
	var icon: Texture2D = ab_icons.get(id, basic_icons.get(id, null))
	if icon != null:
		var isz := (rr - 3.0) * 2.0
		draw_texture_rect(icon, Rect2(c - Vector2(isz, isz) * 0.5, Vector2(isz, isz)), false, Color(1, 1, 1, 0.78 if down else 1.0))
	if id in ["ab1", "ab2", "ab3"]:
		var nm := str(ab_names.get(id, ""))
		label = nm if nm != "" else label
		fsize = 18
	elif id == "strike" or id == "heavy":
		fsize = 34
	elif id == "ls":
		fsize = 18
	var lines := label.split(" ", false)
	if lines.size() > 2:
		lines = PackedStringArray([lines[0], " ".join(lines.slice(1))])
	var y0 := c.y + float(fsize) * 0.33 - float(lines.size() - 1) * float(fsize) * 0.55
	if icon != null:
		# with an icon the name sits small along the bottom edge so it never hides the emblem
		fsize = 14
		lines = PackedStringArray([label.replace(" ", "\n")]) if false else PackedStringArray([label])
		y0 = c.y + rr * 0.62
	for i in lines.size():
		_ink.text(Vector2(c.x - rr, y0 + float(i) * float(fsize) * 1.1), lines[i], fsize, UiStyle.PAPER, HORIZONTAL_ALIGNMENT_CENTER, rr * 2.0, 7)

## Ink wash: dark ink covers the button from the bottom and drains as the cooldown runs out.
func _ink_wash(c: Vector2, r: float, ratio: float) -> void:
	var cut := c.y - r + 2.0 * r * (1.0 - clampf(ratio, 0.0, 1.0))
	var pts := PackedVector2Array()
	var n := 40
	for i in n + 1:
		var a := TAU * float(i) / float(n)
		var p := c + Vector2(cos(a), sin(a)) * r
		if p.y >= cut:
			pts.append(p)
	if pts.size() >= 3:
		var cols := PackedColorArray()
		cols.resize(pts.size())
		cols.fill(Color(0.07, 0.06, 0.09, 0.82))
		draw_polygon(pts, cols)
