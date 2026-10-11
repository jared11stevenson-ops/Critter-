extends RefCounted
## SCARLITH - "The Fermented Kingpin": red-velvet-mite pirate kingpin (12 cm). Crimson fuzzy mite body, big fuzzy head with gold-ringed black
## eyes (+ two small eyes above), black tricorn with red band and gold wheel emblem, long dark gold-trimmed coat with medallions and tatters,
## the huge Swiss-cheese carapace on his back with chains, a glowing lantern, and a boarding-hook polearm.
## Reference: tools/source_art/scarlith_sheet.jpg.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _fuzz(m: Prim, c: Vector3, r: Vector3, col: Color, n: int, ln: float, seed_off: float = 0.0) -> void:
	# short velvet tufts radiating from an ellipsoid (red-velvet-mite pile)
	for i in range(n):
		var a := float(i) * 2.399 + seed_off
		var y := 1.0 - 2.0 * (float(i) + 0.5) / n
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var d := Vector3(cos(a) * rr, y, sin(a) * rr)
		var p := c + Vector3(d.x * r.x, d.y * r.y, d.z * r.z)
		m.lim(T(), [p, p + d * ln], 0.05, 0.0, col, 0.0, 4, true, false)

static func build(b) -> void:
	b.quality = 0.55
	var P: Dictionary = b.pal
	var red: Color = P["main"]; var gold: Color = P["accent"]; var glow: Color = P["glow"]; var cheese: Color = Color.html("e0c27c")
	var coat := Color.html("2c1519"); var black := Color.html("171012"); var iron := Color.html("3c3a44"); var hole := Color.html("b8741f")
	var dred := red.darkened(0.25)
	# ---- 2+2 spidery fuzzy legs
	for leg in [["leg_f", 0.25], ["leg_b", -0.25]]:
		var dx: float = leg[1]
		var l: Prim = b.part(leg[0], Vector3(dx, 0.75, 0.0))
		for z in [0.5, -0.5]:
			var col := red if z > 0 else dred
			l.lim(T(), [Vector3(0, 0, z * 0.3), Vector3(dx * 1.3, 0.12, z * 0.9), Vector3(dx * 2.2, -0.35, z * 1.3), Vector3(dx * 2.5, -0.72, z * 1.5)], 0.17, 0.09, col, 0.0, 5)
			_fuzz(l, Vector3(dx * 1.3, 0.12, z * 0.9), Vector3(0.1, 0.1, 0.1), col, 5, 0.1)
			l.blob(T(Vector3(dx * 2.5, -0.74, z * 1.5)), Vector3(0.12, 0.05, 0.1), gold.darkened(0.3), 0.0, 1.0, 5, 3)
	# ---- torso: crimson fuzzy body under a long dark gold-trimmed coat with medallions and tatters
	var t: Prim = b.part("torso", Vector3(0, 0.75, 0))
	t.blob(T(Vector3(0, 0.2, 0)), Vector3(0.55, 0.45, 0.55), red, 0.0, 0.95, 11, 7)
	_fuzz(t, Vector3(0, 0.2, 0), Vector3(0.52, 0.42, 0.52), red, 18, 0.12)
	t.blob(T(Vector3(0.2, 0.0, 0)), Vector3(0.42, 0.55, 0.5), coat, 0.0, 0.8, 10, 6)
	for z in [-0.3, -0.15, 0.0, 0.15, 0.3]:
		t.flat(T(), [Vector3(0.52, 0.45, z), Vector3(0.58, 0.0, z), Vector3(0.55, -0.45 - 0.08 * absf(z) * 4.0, z)], 0.08, 0.05, 0.02, gold if int(z * 20) % 2 == 0 else red.darkened(0.1), Vector3(0, 0, 1), 0.0, 0.0, true)
	t.flat(T(), [Vector3(0.5, 0.5, 0), Vector3(0.58, 0.1, 0), Vector3(0.56, -0.3, 0)], 0.1, 0.07, 0.02, gold.lightened(0.1), Vector3(0, 0, 1), 0.3, 0.0, true)
	for pr in [Vector3(0.58, 0.0, 0.22), Vector3(0.58, -0.25, -0.2), Vector3(0.58, 0.2, -0.1)]:
		t.blob(T(pr, Vector3(0, 90, 0)), Vector3(0.09, 0.09, 0.03), gold, 0.3, 1.0, 7, 3)
	for k in range(6):
		var z := -0.4 + k * 0.16
		t.flat(T(), [Vector3(0.0, -0.1, z), Vector3(0.12, -0.4, z), Vector3(0.1, -0.7 - 0.1 * (k % 3), z)], 0.1, 0.07, 0.015, cheese.darkened(0.1) if k % 2 == 0 else Color.html("9a9a48"), Vector3(1, 0, 0), 0.0, 0.0, true)
	# ---- head: big fuzzy red head, gold-ringed eyes, tricorn pirate hat with a gold wheel
	var h: Prim = b.part("head", Vector3(0.45, 1.35, 0))
	h.blob(T(Vector3(0.05, 0.12, 0)), Vector3(0.5, 0.42, 0.5), red.lightened(0.04), 0.0, 0.9, 11, 7)
	_fuzz(h, Vector3(0.05, 0.12, 0), Vector3(0.48, 0.4, 0.48), red.lightened(0.08), 18, 0.11, 1.0)
	for pr in [Vector3(0.38, 0.38, 0.12), Vector3(0.38, 0.38, -0.12)]:
		h.blob(T(pr), Vector3(0.05, 0.05, 0.05), black, 0.0, 1.0, 5, 3)
	h.blob(T(Vector3(0.0, 0.5, 0)), Vector3(0.4, 0.3, 0.4), black, 0.0, 0.8, 10, 5)                         # hat crown
	h.blob(T(Vector3(0.0, 0.4, 0), Vector3(0, 0, 3)), Vector3(0.82, 0.06, 0.78), black, 0.0, 0.7, 12, 3)       # brim
	h.blob(T(Vector3(0.0, 0.66, 0.0), Vector3(0, 0, 3)), Vector3(0.62, 0.05, 0.12), black.lightened(0.04), 0.0, 0.7, 9, 3)
	for s in [-1.0, 1.0]:
		h.blob(T(Vector3(0.0, 0.52, 0.8 * s), Vector3(0, 0, 40)), Vector3(0.26, 0.06, 0.2), black, 0.0, 0.7, 7, 3)    # upturned corners
	h.ring(T(Vector3(0.0, 0.5, 0.0), Vector3(90, 0, 0)), 0.42, 0.04, red.darkened(0.1), 0.0, 14, 3)                  # red band
	h.ring(T(Vector3(0.0, 0.55, 0.43), Vector3(0, 0, 0)), 0.1, 0.025, gold, 0.4, 10, 3)                           # wheel emblem
	h.blob(T(Vector3(0.0, 0.55, 0.44)), Vector3(0.04, 0.04, 0.02), gold, 0.4, 1.0, 5, 3)
	h.blob(T(Vector3(0.0, 0.58, 0.0), Vector3(0, 0, 0)), Vector3(0.0001, 0.0001, 0.0001), black, 0.0, 1.0, 3, 2)
	b.sock("head", "head", Vector3(0.05, 0.12, 0))
	b.set_face(Vector3(0.05, 0.12, 0), Vector3(0.5, 0.42, 0.5),
			{"eye_sep": 0.38, "eye_y": 0.06, "eye_size": Vector2(0.2, 0.2), "eye_white": 1.0, "sclera": Color.html("120a0a"), "eye_col": Color.html("f4bc3c"),
			"lid_bias": 0.0, "mouth_y": -0.4, "mouth_w": 0.16, "mouth_base": -0.1, "brow_off": 0.1, "brow_len": 0.16, "brow_thick": 0.04, "accent": gold}, 1.0, 0.75, -0.15, 0.9)
	# ---- arms: fuzzy red forelegs; front one holds the boarding-hook polearm
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var col := red if side > 0 else dred
		var a: Prim = b.part(nm, Vector3(0.35, 1.0, 0.5 * side))
		a.lim(T(), [Vector3(0, 0, 0), Vector3(0.12, -0.35, 0.1 * side), Vector3(0.45, -0.5, 0.15 * side)], 0.12, 0.08, col, 0.0, 5)
		_fuzz(a, Vector3(0.12, -0.35, 0.1 * side), Vector3(0.1, 0.1, 0.1), col, 5, 0.1)
		a.blob(T(Vector3(0.18, -0.4, 0.1 * side), Vector3(0, 0, 20)), Vector3(0.1, 0.16, 0.14), cheese.darkened(0.05), 0.0, 0.8, 6, 4)   # cuff
		a.lim(T(), [Vector3(0.45, -0.5, 0.15 * side), Vector3(0.62, -0.58, 0.16 * side)], 0.05, 0.0, gold.darkened(0.3), 0.0, 4, true, false)
	var hand := Vector3(0.45, -0.5, 0.15)
	var dir := Vector3(0.7, -0.7, 0).normalized()
	var af: Prim = b.parts["arm_f"]["mb"]
	var pole := [hand - dir * 0.5 + Vector3(0, 0, 0), hand + dir * 1.2, hand + dir * 2.0]
	af.tube(T(), pole, [Vector2(0.05, 0.05), Vector2(0.055, 0.055), Vector2(0.06, 0.06)], iron.lightened(0.1), 0.0, Vector3(0, 0, 1), 6)
	for k in [0.2, 0.9]:
		af.ring(T(hand + dir * k, Vector3(0, 90, 0) + Vector3(0, 0, 45)), 0.075, 0.025, gold, 0.0, 8, 3)
	var tip := hand + dir * 2.0
	af.flat(T(), [tip, tip + Vector3(0.15, -0.25, 0), tip + Vector3(0.4, -0.35, 0), tip + Vector3(0.55, -0.15, 0.0), tip + Vector3(0.45, 0.1, 0)], 0.16, 0.09, 0.03, iron, Vector3(-0.5, -0.5, 0).normalized(), 0.0, 0.25, true, 6)   # boarding hook blade
	b.sock("weapon_tip", "arm_f", tip + Vector3(0.45, -0.2, 0))
	b.sock("weapon_base", "arm_f", hand + dir * 0.5)
	b.sock("hand", "arm_f", hand)
	# ---- lantern + chain + amulets on the hat side (lag)
	var w: Prim = b.part("weapon", Vector3(0.45, 1.8, 0.62))
	w.lim(T(), [Vector3(0, 0, 0), Vector3(0.0, -0.3, 0.0)], 0.015, 0.015, gold, 0.0, 3, false, false)
	w.blob(T(Vector3(0, -0.5, 0)), Vector3(0.11, 0.17, 0.11), glow, 1.0, 0.8, 7, 5)
	w.ring(T(Vector3(0, -0.34, 0), Vector3(90, 0, 0)), 0.08, 0.025, black, 0.0, 8, 3)
	w.ring(T(Vector3(0, -0.68, 0), Vector3(90, 0, 0)), 0.08, 0.025, black, 0.0, 8, 3)
	# ---- the cheese carapace: huge pale slab with holes, chains and a rope
	var e: Prim = b.part("extra", Vector3(-0.4, 1.4, 0))
	e.blob(T(Vector3(0, 0.1, 0), Vector3(0, 0, -14)), Vector3(0.95, 0.62, 0.8), cheese, 0.0, 0.8, 12, 8)
	e.blob(T(Vector3(-0.35, -0.15, 0), Vector3(0, 0, -30)), Vector3(0.6, 0.5, 0.78), cheese.darkened(0.08), 0.0, 0.8, 9, 6)
	for hp in [Vector3(0.25, 0.4, 0.62), Vector3(-0.2, 0.5, 0.55), Vector3(0.45, 0.05, 0.66), Vector3(-0.55, 0.1, 0.6), Vector3(0.1, 0.0, 0.78), Vector3(-0.4, -0.3, 0.7),
			Vector3(0.2, 0.45, -0.6), Vector3(-0.3, 0.45, -0.55), Vector3(0.45, 0.0, -0.66), Vector3(-0.5, 0.0, -0.64), Vector3(0.05, -0.05, -0.78)]:
		e.blob(T(hp, Vector3(0, 0, 0)), Vector3(0.11, 0.12, 0.05), hole, 0.15, 1.0, 6, 3)
	e.lim(T(), [Vector3(0.3, 0.7, 0.3), Vector3(0.0, 0.95, 0.0), Vector3(-0.3, 0.7, -0.3)], 0.03, 0.03, gold, 0.0, 4, false, false)   # carry loop
	e.lim(T(), [Vector3(0.6, 0.2, 0.4), Vector3(0.6, -0.2, 0.5), Vector3(0.5, -0.5, 0.45)], 0.025, 0.025, gold.darkened(0.2), 0.0, 4, false, false)
	b.cfg = {
		"scale": 1.0, "wa": -45.0, "sway": 1.4, "stride": 1.3, "bob": 0.4, "waddle": 0.9, "lag_weapon": 0.04, "lag_extra": 0.012, "lag_extra_x": 1.5,
		"armb_gain": 0.4, "guard_th": 40.0, "parry_th": 10.0, "blink_scale": 0.9,
		"style": {"strike_light": "hook", "strike_heavy": "chop", "ability1": "stance", "ability2": "hook", "laststand": "roar", "grab": "hook"},
		"amp": {"strike_light": 0.8, "strike_heavy": 0.9, "laststand": 1.1},
		"fidget": {"head": PL.K(0, 0, -10, 0.0, 0.0), "arm_b": PL.K(0, 0, 30, 0.05, 0.0)},
	}
