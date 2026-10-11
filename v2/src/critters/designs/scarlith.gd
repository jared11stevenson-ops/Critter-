extends RefCounted
## SCARLITH - "The Fermented Kingpin" (Velvet Warrens). Brief: round plush red-velvet-mite body (fuzz layer), eight short legs, a pirate kit built
## from cheese rind and cloth (tricorn, eyepatch, wine coat), a barrel + bottle rack on the back, coin purse, gold tooth.
## Palette: crimson velvet, cheese-gold, wine purple, rind orange; warm gold glow.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _fuzz(m: Prim, c: Vector3, r: Vector3, col: Color, n: int, ln: float, seed_off: float = 0.0) -> void:
	for i in range(n):
		var a := float(i) * 2.399 + seed_off
		var y := 1.0 - 2.0 * (float(i) + 0.5) / n
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var d := Vector3(cos(a) * rr, y, sin(a) * rr)
		var p := c + Vector3(d.x * r.x, d.y * r.y, d.z * r.z)
		m.lim(T(), [p, p + d * ln], 0.06, 0.0, col, 0.0, 4, true, false)

static func build(b) -> void:
	b.quality = 0.62
	var P: Dictionary = b.pal
	var red: Color = P["main"]; var gold: Color = P["accent"]; var glow: Color = P["glow"]; var rind: Color = P["belly"]
	var wine := Color.html("4f1a36"); var black := Color.html("171012"); var wood := Color.html("7a4a2a"); var iron := Color.html("4a4852"); var dred := red.darkened(0.25)
	# ---- eight short fuzzy legs: 4 per leg group (two each side)
	for leg in [["leg_f", 0.35], ["leg_b", -0.4]]:
		var dx: float = leg[1]
		var l: Prim = b.part(leg[0], Vector3(dx, 0.55, 0.0))
		for z in [0.5, -0.5]:
			for k in range(2):
				var xo := dx * 0.0 + (k - 0.5) * 0.5 * signf(dx)
				var col := red if z > 0 else dred
				l.lim(T(), [Vector3(xo, 0.1, z * 0.5), Vector3(xo + dx * 0.4, 0.1, z * 1.1), Vector3(xo + dx * 0.55, -0.55, z * 1.5)], 0.15, 0.09, col, 0.0, 5)
				_fuzz(l, Vector3(xo + dx * 0.4, 0.1, z * 1.1), Vector3(0.1, 0.1, 0.1), col, 4, 0.1)
				l.blob(T(Vector3(xo + dx * 0.6, -0.57, z * 1.55)), Vector3(0.13, 0.05, 0.1), gold.darkened(0.3), 0.0, 1.0, 5, 3)
	# ---- torso: round plush body, wine coat panels, gold buttons, belt + coin purse
	var t: Prim = b.part("torso", Vector3(0, 0.55, 0))
	t.blob(T(Vector3(0, 0.45, 0)), Vector3(0.85, 0.7, 0.8), red, 0.0, 0.95, 12, 8)
	_fuzz(t, Vector3(0, 0.45, 0), Vector3(0.83, 0.68, 0.78), red, 16, 0.12)
	t.blob(T(Vector3(0.38, 0.35, 0)), Vector3(0.5, 0.58, 0.62), wine, 0.0, 0.8, 10, 6)             # coat front
	for z in [-0.4, -0.2, 0.2, 0.4]:
		t.flat(T(), [Vector3(0.78, 0.7, z), Vector3(0.86, 0.2, z), Vector3(0.8, -0.2, z * 1.1)], 0.1, 0.06, 0.02, wine.lightened(0.05) if z < 0 else wine, Vector3(0, 0, 1), 0.0, 0.0, true)
	for k in range(3):
		t.blob(T(Vector3(0.86, 0.55 - k * 0.22, 0.0), Vector3(0, 90, 0)), Vector3(0.06, 0.06, 0.03), gold, 0.3, 1.0, 6, 3)
	t.ring(T(Vector3(0.0, 0.18, 0), Vector3(90, 0, 0)), 0.8, 0.05, black, 0.0, 14, 4)
	t.blob(T(Vector3(0.78, 0.18, 0.0), Vector3(0, 90, 0)), Vector3(0.1, 0.1, 0.03), gold, 0.3, 1.0, 7, 3)         # buckle
	t.blob(T(Vector3(0.55, 0.05, 0.6)), Vector3(0.14, 0.17, 0.12), wood, 0.0, 0.9, 7, 5)                          # coin purse
	t.blob(T(Vector3(0.55, 0.22, 0.6)), Vector3(0.1, 0.06, 0.09), gold, 0.0, 0.9, 6, 3)
	for k in range(6):   # cheese-rind trim tatters on the coat hem
		var z := -0.45 + k * 0.18
		t.flat(T(), [Vector3(0.7, -0.05, z), Vector3(0.78, -0.3, z), Vector3(0.74, -0.55 - 0.08 * (k % 2), z)], 0.09, 0.06, 0.015, rind if k % 2 == 0 else gold.darkened(0.2), Vector3(0, 0, 1), 0.0, 0.0, true)
	# ---- head: big fuzzy red head, gold-ringed eyes, eyepatch, gold tooth, tricorn with a gold wheel
	var h: Prim = b.part("head", Vector3(0.75, 1.55, 0))
	h.blob(T(Vector3(0.05, 0.1, 0)), Vector3(0.55, 0.45, 0.52), red.lightened(0.04), 0.0, 0.9, 11, 7)
	_fuzz(h, Vector3(0.05, 0.1, 0), Vector3(0.53, 0.43, 0.5), red.lightened(0.08), 14, 0.11, 1.0)
	h.blob(T(Vector3(0.5, -0.15, 0), Vector3(0, 0, -10)), Vector3(0.14, 0.1, 0.2), dred, 0.0, 0.9, 6, 4)          # mouth parts
	h.blob(T(Vector3(0.6, -0.2, 0.06)), Vector3(0.025, 0.04, 0.02), gold, 0.5, 1.0, 4, 3)                         # gold tooth
	h.blob(T(Vector3(0.0, 0.5, 0)), Vector3(0.42, 0.28, 0.42), black, 0.0, 0.8, 10, 5)
	h.blob(T(Vector3(0.0, 0.4, 0), Vector3(0, 0, 3)), Vector3(0.88, 0.06, 0.84), black, 0.0, 0.7, 12, 3)
	for s in [-1.0, 1.0]:
		h.blob(T(Vector3(0.0, 0.52, 0.84 * s), Vector3(0, 0, 40)), Vector3(0.26, 0.06, 0.2), black, 0.0, 0.7, 7, 3)
	h.ring(T(Vector3(0.0, 0.5, 0.0), Vector3(90, 0, 0)), 0.44, 0.04, wine, 0.0, 14, 3)
	h.ring(T(Vector3(0.0, 0.52, 0.45), Vector3(0, 0, 0)), 0.11, 0.025, gold, 0.4, 10, 3)
	h.lim(T(), [Vector3(0.3, 0.2, 0.3), Vector3(0.4, 0.05, 0.0), Vector3(0.3, 0.2, -0.3)], 0.02, 0.02, black, 0.0, 3, false, false)   # eyepatch strap
	h.blob(T(Vector3(0.47, 0.06, 0.2), Vector3(0, 20, 0)), Vector3(0.05, 0.12, 0.12), black, 0.0, 1.0, 6, 4)       # eyepatch (viewer side)
	b.sock("head", "head", Vector3(0.05, 0.1, 0))
	b.set_face(Vector3(0.05, 0.1, 0), Vector3(0.55, 0.45, 0.52),
			{"eye_sep": 0.38, "eye_y": 0.06, "eye_size": Vector2(0.001, 0.2), "eye_white": 1.0, "sclera": Color.html("120a0a"), "eye_col": Color.html("f4bc3c"),
			"mouth_y": -0.4, "mouth_w": 0.16, "mouth_base": -0.1, "brow_off": 0.1, "brow_len": 0.16, "brow_thick": 0.04, "accent": gold}, 1.0, 0.75, -0.15, 0.9)
	# ---- arms: fuzzy red forelegs; front one holds a boarding-hook polearm
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var col := red if side > 0 else dred
		var a: Prim = b.part(nm, Vector3(0.4, 1.0, 0.82 * side))
		a.lim(T(), [Vector3(0, 0, 0), Vector3(0.12, -0.4, 0.1 * side), Vector3(0.4, -0.55, 0.14 * side)], 0.14, 0.09, col, 0.0, 5)
		_fuzz(a, Vector3(0.12, -0.4, 0.1 * side), Vector3(0.12, 0.12, 0.12), col, 5, 0.1)
		a.blob(T(Vector3(0.16, -0.45, 0.1 * side), Vector3(0, 0, 20)), Vector3(0.12, 0.17, 0.14), rind, 0.0, 0.8, 6, 4)    # cuff
		a.blob(T(Vector3(0.42, -0.58, 0.14 * side)), Vector3(0.1, 0.09, 0.09), col.lightened(0.05), 0.0, 1.0, 6, 3)
	var hand := Vector3(0.42, -0.58, 0.14)
	var dir := Vector3(0.5, 0.86, 0).normalized()
	var af: Prim = b.parts["arm_f"]["mb"]
	af.tube(T(), [hand - dir * 0.6, hand + dir * 1.2, hand + dir * 2.4], [Vector2(0.05, 0.05), Vector2(0.055, 0.055), Vector2(0.06, 0.06)], iron.lightened(0.1), 0.0, Vector3(0, 0, 1), 6)
	for k in [0.0, 0.9]:
		af.ring(T(hand + dir * k, Vector3(0, 90, 0) + Vector3(0, 0, 25)), 0.08, 0.025, gold, 0.0, 8, 3)
	var tip := hand + dir * 2.4
	af.flat(T(), [tip, tip + Vector3(0.2, 0.25, 0), tip + Vector3(0.45, 0.2, 0), tip + Vector3(0.5, -0.05, 0)], 0.16, 0.08, 0.03, iron, Vector3(-0.5, 0.5, 0).normalized(), 0.0, 0.25, true, 6)
	b.sock("weapon_tip", "arm_f", tip + Vector3(0.45, 0.1, 0))
	b.sock("weapon_base", "arm_f", hand + dir * 0.5)
	b.sock("hand", "arm_f", hand)
	# ---- lantern hung from the hat side + chain (lag): warm glow
	var w: Prim = b.part("weapon", Vector3(0.75, 2.2, 0.62))
	w.lim(T(), [Vector3(0, 0, 0), Vector3(0.0, -0.3, 0.0)], 0.015, 0.015, gold, 0.0, 3, false, false)
	w.blob(T(Vector3(0, -0.5, 0)), Vector3(0.11, 0.17, 0.11), glow, 1.0, 0.8, 7, 5)
	w.ring(T(Vector3(0, -0.34, 0), Vector3(90, 0, 0)), 0.08, 0.025, black, 0.0, 8, 3)
	# ---- back: barrel with gold hoops + a bottle rack (the "treasure cache"), cheese-rind lid
	var e: Prim = b.part("extra", Vector3(-0.65, 1.1, 0))
	e.tube(T(), [Vector3(0, -0.1, 0), Vector3(0, 0.0, 0), Vector3(0, 0.8, 0)], [Vector2(0.4, 0.4), Vector2(0.5, 0.5), Vector2(0.42, 0.42)], wood, 0.0, Vector3(0, 0, 1), 9)
	for hy in [0.0, 0.35, 0.7]:
		e.ring(T(Vector3(0, hy, 0), Vector3(90, 0, 0)), 0.5 - 0.05 * absf(hy - 0.35) * 2.0, 0.035, gold.darkened(0.15), 0.0, 12, 3)
	e.blob(T(Vector3(0, 0.82, 0)), Vector3(0.4, 0.07, 0.4), rind, 0.0, 0.8, 9, 3)
	for z in [-0.3, 0.0, 0.3]:   # bottles
		e.lim(T(), [Vector3(-0.45, 0.1, z), Vector3(-0.45, 0.5, z)], 0.1, 0.1, Color.html("4a7a3a"), 0.0, 6)
		e.lim(T(), [Vector3(-0.45, 0.5, z), Vector3(-0.45, 0.8, z)], 0.045, 0.045, Color.html("4a7a3a"), 0.0, 5, false, true)
		e.blob(T(Vector3(-0.45, 0.85, z)), Vector3(0.055, 0.04, 0.055), rind, 0.0, 1.0, 5, 3)
	b.cfg = {
		"scale": 1.0, "wa": 55.0, "sway": 1.4, "stride": 1.3, "bob": 0.4, "waddle": 0.9, "lag_weapon": 0.04, "lag_extra": 0.012, "lag_extra_x": 1.5,
		"armb_gain": 0.4, "guard_th": 40.0, "parry_th": 10.0, "blink_scale": 0.9,
		"style": {"strike_light": "hook", "strike_heavy": "chop", "ability1": "stance", "ability2": "hook", "laststand": "roar", "grab": "hook"},
		"amp": {"strike_light": 0.8, "strike_heavy": 0.9, "laststand": 1.1},
		"fidget": {"head": PL.K(0, 0, -10, 0.0, 0.0), "arm_b": PL.K(0, 0, 30, 0.05, 0.0)},
	}
