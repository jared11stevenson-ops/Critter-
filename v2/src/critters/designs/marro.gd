extends RefCounted
## MARRO - "We Are One": brick-red army ant, three-segment body with cream stripes, tall brass coin-shield, straight bone pike,
## tiny brass helmet with a plume of colony thread. Silhouette: shield rectangle plus pike line. (ROSTER.md 5)

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func build(b) -> void:
	var P: Dictionary = b.pal
	var red: Color = P["main"]; var brass: Color = P["accent"]; var cream: Color = P["glow"]; var pale: Color = P["belly"]
	var deep := red.darkened(0.28)
	for leg in [["leg_f", 0.16, 0.26], ["leg_b", -0.14, -0.26]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.5, leg[2]))
		l.tube(T(), [Vector3(0, 0.02, 0), Vector3(0.1, -0.18, 0.04 * signf(leg[2])), Vector3(0.0, -0.46, 0)],
				[Vector2(0.1, 0.1), Vector2(0.085, 0.085), Vector2(0.07, 0.07)], deep, 0.0, Vector3(0, 0, 1), 6)
		l.blob(T(Vector3(0.08, -0.49, 0)), Vector3(0.2, 0.07, 0.13), deep.darkened(0.2), 0.0, 0.8, 7, 4)
	# three segments: thorax (torso), gaster (striped, behind), head (above)
	var t: Prim = b.part("torso", Vector3(0, 0.5, 0))
	t.blob(T(Vector3(0.05, 0.44, 0)), Vector3(0.4, 0.46, 0.4), red, 0.0, 0.88, 10, 7)
	t.blob(T(Vector3(0.22, 0.34, 0)), Vector3(0.22, 0.3, 0.3), pale, 0.0, 1.0, 7, 5)
	t.blob(T(Vector3(-0.58, 0.26, 0)), Vector3(0.52, 0.42, 0.42), deep, 0.0, 0.95, 11, 7)
	for dx in [-0.35, -0.55, -0.75]:
		var rr := 0.42 * sqrt(maxf(0.0, 1.0 - pow((dx + 0.58) / 0.52, 2.0)))
		t.ring(T(Vector3(dx, 0.26, 0), Vector3(0, 90, 0)), rr, 0.035, cream, 0.0, 12, 4)
	t.tube(T(), [Vector3(-0.3, 0.6, 0), Vector3(-0.05, 0.72, 0)], [Vector2(0.06, 0.06), Vector2(0.06, 0.06)], brass, 0.0, Vector3(0, 0, 1), 4, true, true)   # strap
	var h: Prim = b.part("head", Vector3(0.14, 1.0, 0))
	h.blob(T(Vector3(0.08, 0.38, 0)), Vector3(0.44, 0.4, 0.46), red.lightened(0.05), 0.0, 0.88, 12, 8)
	h.blob(T(Vector3(0.0, 0.62, 0), Vector3(0, 0, 4)), Vector3(0.48, 0.3, 0.5), brass, 0.0, 0.9, 12, 6, -0.25)    # helmet
	h.blob(T(Vector3(0.0, 0.5, 0), Vector3(0, 0, 4)), Vector3(0.52, 0.045, 0.54), brass.darkened(0.2), 0.0, 0.8, 12, 3)   # brim
	for s in [-1.0, 1.0]:
		h.tube(T(), [Vector3(0.4, 0.14, 0.14 * s), Vector3(0.6, 0.0, 0.08 * s)], [Vector2(0.05, 0.05), Vector2(0.018, 0.018)], cream, 0.0, Vector3(0, 0, 1), 5, true, false)
		h.tube(T(), [Vector3(0.2, 0.62, 0.34 * s), Vector3(0.42, 1.0, 0.5 * s), Vector3(0.62, 1.2, 0.56 * s)],
				[Vector2(0.028, 0.028), Vector2(0.024, 0.024), Vector2(0.02, 0.02)], deep, 0.0, Vector3(0, 0, 1), 4, false, true)
	# pike arm (far side), straight bone shaft + brass leaf head
	var a: Prim = b.part("arm_f", Vector3(0.12, 0.98, -0.5))
	a.tube(T(), [Vector3(0, 0, 0), Vector3(0.14, -0.15, -0.04), Vector3(0.3, -0.1, -0.06)], [Vector2(0.09, 0.09), Vector2(0.08, 0.08), Vector2(0.075, 0.075)], red, 0.0, Vector3(0, 0, 1), 6)
	a.blob(T(Vector3(0.32, -0.1, -0.06)), Vector3(0.1, 0.1, 0.1), brass.darkened(0.1), 0.0, 1.0, 7, 4)
	a.tube(T(), [Vector3(-0.5, -0.1, -0.06), Vector3(0.9, -0.08, -0.06), Vector3(2.0, -0.03, -0.06)], [Vector2(0.045, 0.045), Vector2(0.04, 0.04), Vector2(0.035, 0.035)], cream, 0.0, Vector3(0, 0, 1), 6)
	a.tube(T(), [Vector3(1.9, -0.03, -0.06), Vector3(2.1, -0.02, -0.06), Vector3(2.38, 0.0, -0.06), Vector3(2.62, 0.01, -0.06)],
			[Vector2(0.05, 0.03), Vector2(0.13, 0.03), Vector2(0.1, 0.025), Vector2(0.0, 0.0)], brass.lightened(0.1), 0.0, Vector3(0, 1, 0), 6, false, false)
	b.sock("weapon_tip", "arm_f", Vector3(2.62, 0.01, -0.06))
	b.sock("weapon_base", "arm_f", Vector3(0.9, -0.08, -0.06))
	b.sock("hand", "arm_f", Vector3(0.32, -0.1, -0.06))
	# colony pennant on the pike (flutters)
	var w: Prim = b.part("weapon", Vector3(2.0, 1.0, -0.56), "arm_f")
	w.tube(T(), [Vector3(0, 0, 0), Vector3(-0.18, -0.06, 0), Vector3(-0.34, -0.2, 0), Vector3(-0.44, -0.32, 0)],
			[Vector2(0.08, 0.015), Vector2(0.075, 0.015), Vector2(0.06, 0.012), Vector2(0.0, 0.0)], red.lightened(0.05), 0.0, Vector3(0, 1, 0), 4, true, false)
	# shield arm (near side): tall brass coin, stripes of rivets
	var ab: Prim = b.part("arm_b", Vector3(0.12, 0.98, 0.5))
	ab.tube(T(), [Vector3(0, 0, 0), Vector3(0.12, -0.14, 0.04), Vector3(0.24, -0.2, 0.08)], [Vector2(0.09, 0.09), Vector2(0.08, 0.08), Vector2(0.075, 0.075)], red.darkened(0.05), 0.0, Vector3(0, 0, 1), 6)
	ab.blob(T(Vector3(0.36, -0.22, 0.2)), Vector3(0.34, 0.58, 0.07), brass, 0.0, 0.38, 10, 7)
	ab.ring(T(Vector3(0.36, -0.22, 0.26)), 0.22, 0.03, cream, 0.0, 14, 4)
	ab.blob(T(Vector3(0.36, -0.22, 0.27)), Vector3(0.09, 0.09, 0.03), cream, 0.0, 1.0, 8, 4)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			ab.blob(T(Vector3(0.36 + 0.24 * sx, -0.22 + 0.42 * sy, 0.27)), Vector3(0.04, 0.04, 0.03), brass.darkened(0.3), 0.0, 1.0, 5, 3)
	ab.blob(T(Vector3(0.18, -0.2, 0.12)), Vector3(0.11, 0.11, 0.11), brass.darkened(0.25), 0.0, 1.0, 7, 4)
	# plume of colony thread
	var e: Prim = b.part("extra", Vector3(0.14, 1.66, 0))
	for k in [0.0, 1.0]:
		e.tube(T(Vector3(0, 0, 0.06 * (k * 2.0 - 1.0))), [Vector3(0, 0, 0), Vector3(-0.12, 0.32 + k * 0.08, 0), Vector3(-0.42, 0.46, 0), Vector3(-0.72, 0.28 - k * 0.1, 0), Vector3(-0.86, 0.0 - k * 0.15, 0)],
				[Vector2(0.11, 0.09), Vector2(0.15, 0.12), Vector2(0.13, 0.1), Vector2(0.09, 0.07), Vector2(0.0, 0.0)], red if k == 0.0 else cream, 0.0, Vector3(0, 0, 1), 5, true, false)
	b.sock("head", "head", Vector3(0.08, 0.38, 0))
	b.set_face(Vector3(0.08, 0.38, 0), Vector3(0.44, 0.4, 0.46),
			{"eye_sep": 0.36, "eye_y": 0.0, "eye_size": Vector2(0.11, 0.11), "eye_white": 0.0, "mouth_y": -0.3, "mouth_w": 0.12,
			"mouth_base": -0.25, "brow_off": 0.1, "brow_len": 0.17, "brow_thick": 0.035}, 1.0, 0.78, -0.12, 0.88)
	b.cfg = {
		"scale": 1.0,
		"wa": 3.0, "sway": 1.2, "stride": 1.0, "bob": 0.7, "waddle": 0.6, "lag_weapon": 0.05, "lag_extra": 0.03, "armb_gain": 0.06,
		"guard_th": 6.0, "parry_th": 3.0,
		"style": {"strike_light": "thrust", "strike_heavy": "thrust", "ability1": "stance", "ability2": "thrust", "laststand": "roar", "grab": "stance"},
		"amp": {"strike_light": 0.8, "strike_heavy": 1.2, "ability2": 1.7, "laststand": 1.1},
		"poses": {
			"guard": {"ant": {"arm_b": PL.K(0, 82, 4, 0.5, 0.2, -0.5)}},
			"ability1": {"ant": {"arm_b": PL.K(0, 82, 4, 0.5, 0.2, -0.5)}, "strike": {"arm_b": PL.K(0, 82, 4, 0.55, 0.2, -0.5)}, "rec": {"arm_b": PL.K(0, 60, 2, 0.3, 0.1, -0.3)}},
			"parry": {"ant": {"arm_b": PL.K(0, 82, 4, 0.5, 0.2, -0.5)}, "strike": {"arm_b": PL.K(0, 82, 4, 0.7, 0.2, -0.5)}, "rec": {"arm_b": PL.K(0, 82, 4, 0.5, 0.2, -0.5)}},
			"grab": {"ant": {"arm_b": PL.K(0, 70, 4, 0.1, 0.15, -0.4)}, "strike": {"arm_b": PL.K(0, 84, 4, 0.95, 0.2, -0.55)}, "rec": {"arm_b": PL.K(0, 70, 4, 0.4, 0.15, -0.4)}},
		},
		"fidget": {"head": PL.K(0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0), "arm_b": PL.K(0, 0, 8, 0, 0.03, 0), "extra": PL.K(0, 0, 18)},
	}
