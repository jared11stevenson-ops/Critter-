extends RefCounted
## HALDOR - "The Quarry-Hammer": barrel-chested charcoal rhino beetle, gold-capped horn, dented hard hat,
## shed-shell maul resting on the shoulder, chisel on a cord. (ROSTER.md 1)

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func build(b) -> void:
	var P: Dictionary = b.pal
	var main: Color = P["main"]; var gold: Color = P["accent"]; var ember: Color = P["glow"]
	var belly: Color = P["belly"]; var deep: Color = main.darkened(0.3)
	var stone := Color.html("cdbfa4"); var stone_d := Color.html("a99a80")
	var wood := Color.html("7a5236"); var hat := gold.darkened(0.12)
	# legs (tiny, stubby)
	for leg in [["leg_f", 0.24, 0.34], ["leg_b", -0.22, -0.34]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.46, leg[2]))
		l.tube(T(), [Vector3(0, 0.04, 0), Vector3(0, -0.3, 0)], [Vector2(0.15, 0.15), Vector2(0.125, 0.125)], main)
		l.blob(T(Vector3(0.1, -0.37, 0)), Vector3(0.24, 0.1, 0.17), deep, 0.0, 0.8, 9, 5)
	# torso: round barrel chest + shell
	var t: Prim = b.part("torso", Vector3(0, 0.46, 0))
	t.blob(T(Vector3(0.1, 0.42, 0)), Vector3(0.58, 0.5, 0.64), main, 0.0, 0.8, 11, 7)
	t.blob(T(Vector3(0.3, 0.2, 0)), Vector3(0.42, 0.34, 0.52), belly, 0.0, 0.9, 9, 6)
	t.blob(T(Vector3(-0.34, 0.5, 0)), Vector3(0.5, 0.46, 0.58), deep, 0.0, 0.85, 10, 6)
	t.tube(T(), [Vector3(-0.82, 0.38, 0), Vector3(-0.66, 0.78, 0), Vector3(-0.34, 0.99, 0), Vector3(0.0, 0.96, 0)],
			[Vector2(0.03, 0.03), Vector2(0.03, 0.03), Vector2(0.03, 0.03), Vector2(0.03, 0.03)], gold, 0.0, Vector3(0, 0, 1), 5, false, false)
	for s in [-1.0, 1.0]:
		t.blob(T(Vector3(0.12, 0.82, 0.62 * s)), Vector3(0.11, 0.11, 0.08), gold, 0.0, 1.0, 6, 4)
	# cracked eye-spot on the shell (viewer side)
	t.blob(T(Vector3(-0.36, 0.52, 0.575)), Vector3(0.17, 0.17, 0.035), Color.html("f1e6c8"), 0.0, 1.0, 10, 4)
	t.blob(T(Vector3(-0.34, 0.52, 0.605)), Vector3(0.075, 0.075, 0.02), P["ink"], 0.0, 1.0, 8, 4)
	t.tube(T(), [Vector3(-0.2, 0.69, 0.58), Vector3(-0.32, 0.55, 0.61), Vector3(-0.28, 0.44, 0.61), Vector3(-0.42, 0.33, 0.58)],
			[Vector2(0.014, 0.014), Vector2(0.014, 0.014), Vector2(0.014, 0.014), Vector2(0.004, 0.004)], P["ink"], 0.0, Vector3(0, 0, 1), 4, false, false)
	# head: huge, sleepy
	var h: Prim = b.part("head", Vector3(0.2, 1.3, 0))
	h.blob(T(Vector3(0.12, 0.4, 0)), Vector3(0.54, 0.47, 0.5), main.lightened(0.06), 0.0, 0.9, 12, 8)
	h.blob(T(Vector3(0.1, 0.78, 0)), Vector3(0.44, 0.22, 0.47), hat, 0.0, 0.85, 10, 5)             # hat dome
	h.blob(T(Vector3(0.0, 0.67, 0), Vector3(0, 0, -6)), Vector3(0.54, 0.05, 0.56), hat.darkened(0.15), 0.0, 0.8, 12, 3)  # brim
	h.blob(T(Vector3(0.14, 0.93, 0.12), Vector3(0, 0, -8)), Vector3(0.2, 0.07, 0.22), hat.darkened(0.3), 0.0, 1.0, 8, 4)  # dent
	h.tube(T(), [Vector3(0.38, 0.62, 0), Vector3(0.66, 0.7, 0), Vector3(0.95, 0.84, 0), Vector3(1.14, 1.04, 0)],
			[Vector2(0.15, 0.15), Vector2(0.125, 0.125), Vector2(0.095, 0.095), Vector2(0.075, 0.075)], main.lightened(0.18), 0.0, Vector3(0, 0, 1), 8)
	h.tube(T(), [Vector3(1.08, 0.97, 0), Vector3(1.24, 1.17, 0)], [Vector2(0.095, 0.095), Vector2(0.0, 0.0)], gold, 0.0, Vector3(0, 0, 1), 8, false, true)
	# front arm carries the maul
	var a: Prim = b.part("arm_f", Vector3(0.18, 1.02, 0.62))
	a.tube(T(), [Vector3(0, 0, 0), Vector3(0.14, -0.2, 0.04), Vector3(0.3, -0.2, 0.07)],
			[Vector2(0.15, 0.15), Vector2(0.125, 0.125), Vector2(0.115, 0.115)], main)
	a.blob(T(Vector3(0.32, -0.2, 0.08)), Vector3(0.16, 0.15, 0.15), gold.darkened(0.1), 0.0, 1.0, 8, 5)
	var dir := Vector2(-0.55, 0.83).normalized()
	var hand := Vector2(0.32, -0.2)
	a.tube(T(), [Vector3(hand.x - dir.x * 0.35, hand.y - dir.y * 0.35, 0.08), Vector3(hand.x + dir.x * 1.45, hand.y + dir.y * 1.45, 0.08)],
			[Vector2(0.06, 0.06), Vector2(0.06, 0.06)], wood, 0.0, Vector3(0, 0, 1), 6)
	var hc := hand + dir * 1.62
	var hxf := T(Vector3(hc.x, hc.y, 0.08), Vector3(0, 0, 33.4))
	a.blob(hxf, Vector3(0.36, 0.26, 0.27), stone, 0.0, 0.5, 10, 6)
	a.blob(T(Vector3(hc.x, hc.y, 0.08), Vector3(0, 0, 33.4)) * T(Vector3(0.0, 0.0, 0.0), Vector3.ZERO, Vector3.ONE), Vector3(0.37, 0.1, 0.285), stone_d, 0.0, 0.5, 8, 3)
	for s in [-1.0, 1.0]:
		a.blob(hxf * T(Vector3(0.3 * s, 0, 0)), Vector3(0.08, 0.28, 0.29), gold.darkened(0.2), 0.0, 0.7, 8, 4)  # bands
	a.tube(hxf * T(Vector3(0, 0, 0.275)), [Vector3(-0.26, 0.12, 0), Vector3(-0.08, -0.02, 0), Vector3(0.08, 0.1, 0), Vector3(0.24, -0.08, 0)],
			[Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02), Vector2(0.02, 0.02)], ember, 1.0, Vector3(0, 0, 1), 4, false, false)
	b.sock("weapon_tip", "arm_f", Vector3(hc.x + 0.28, hc.y + 0.18, 0.08))
	b.sock("weapon_base", "arm_f", Vector3(hand.x, hand.y, 0.08))
	b.sock("hand", "arm_f", Vector3(0.32, -0.2, 0.08))
	# far arm grips the same haft
	var ab: Prim = b.part("arm_b", Vector3(0.18, 1.02, -0.62))
	ab.tube(T(), [Vector3(0, 0, 0), Vector3(0.14, -0.2, -0.04), Vector3(0.3, -0.2, -0.07)],
			[Vector2(0.15, 0.15), Vector2(0.125, 0.125), Vector2(0.115, 0.115)], main.darkened(0.08))
	ab.blob(T(Vector3(0.32, -0.2, -0.08)), Vector3(0.16, 0.15, 0.15), gold.darkened(0.2), 0.0, 1.0, 8, 5)
	# chisel on a cord (dangles, lags)
	var w: Prim = b.part("weapon", Vector3(0.3, 0.74, 0.58))
	w.tube(T(), [Vector3(0, 0, 0), Vector3(0.02, -0.16, 0.02)], [Vector2(0.018, 0.018), Vector2(0.018, 0.018)], wood, 0.0, Vector3(0, 0, 1), 4, false, false)
	w.tube(T(), [Vector3(0.02, -0.14, 0.02), Vector3(0.02, -0.3, 0.02), Vector3(0.02, -0.42, 0.02)],
			[Vector2(0.05, 0.03), Vector2(0.045, 0.03), Vector2(0.0, 0.0)], Color.html("b8c2cc"), 0.0, Vector3(1, 0, 0), 6, true, true)
	b.sock("chisel", "weapon", Vector3(0.02, -0.42, 0.02))
	b.sock("head", "head", Vector3(0.12, 0.4, 0))
	b.set_face(Vector3(0.12, 0.4, 0), Vector3(0.54, 0.47, 0.5),
			{"eye_sep": 0.4, "eye_y": 0.06, "eye_size": Vector2(0.21, 0.21), "lid_bias": 0.45, "mouth_y": -0.3,
			"mouth_w": 0.2, "mouth_base": 0.14, "brow_off": 0.08, "brow_len": 0.2, "brow_thick": 0.04}, 0.95, 0.74, -0.05, 0.9)
	b.cfg = {
		"height": 2.25, "wa": 123.5, "arm_b_follow": true, "sway": 1.4, "stride": 0.8, "bob": 0.7, "waddle": 1.4,
		"lag_weapon": 0.035, "guard_th": 45.0, "parry_th": 10.0,
		"style": {"strike_light": "chop", "strike_heavy": "overhead", "ability1": "overhead", "ability2": "charge",
				"laststand": "overhead", "grab": "charge"},
		"amp": {"ability1": 1.25, "laststand": 1.35, "grab": 0.7, "strike_light": 0.9},
		"fidget": {"head": PL.K(0, 0, -16, 0, -0.02), "torso": PL.K(0, 0, -5), "weapon": PL.K(0, 0, 28)},
	}
