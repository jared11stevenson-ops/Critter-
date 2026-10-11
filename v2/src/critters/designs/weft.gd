extends RefCounted
## WEFT - "The Thread Between": violet orb-weaver, big round abdomen with a silver web, eight limbs (four graceful walkers,
## four tool-like), teal lantern on her back, thick spiral-lens glasses, a long thread-lance. (ROSTER.md 3)

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _web(m: Prim, c: Vector3, rx: float, ry: float, rz: float, side: float, col: Color) -> void:
	# spiral thread + spokes laid on the abdomen's side surface (z follows the ellipsoid)
	var pts: Array = []
	var rad: Array = []
	for i in range(0, 25):
		var a := float(i) / 24.0
		var ang := a * TAU * 2.0
		var r := 0.06 + a * 0.9
		var x := cos(ang) * r * rx
		var y := sin(ang) * r * ry
		var zz := rz * sqrt(maxf(0.0, 1.0 - r * r)) + 0.012
		pts.append(c + Vector3(x, y, zz * side))
		rad.append(Vector2(0.014, 0.014))
	m.tube(T(), pts, rad, col, 0.15, Vector3(0, 0, 1), 3, false, false)
	for k in range(5):
		var ang2 := float(k) / 5.0 * TAU + 0.3
		var q: Array = []
		for j in range(3):
			var r2 := 0.06 + float(j) / 2.0 * 0.9
			q.append(c + Vector3(cos(ang2) * r2 * rx, sin(ang2) * r2 * ry, (rz * sqrt(maxf(0.0, 1.0 - r2 * r2)) + 0.012) * side))
		m.tube(T(), q, [Vector2(0.012, 0.012), Vector2(0.012, 0.012), Vector2(0.012, 0.012)], col, 0.15, Vector3(0, 0, 1), 3, false, false)

static func _leg(m: Prim, dx: float, z: float, vio: Color, silver: Color) -> void:
	# graceful long leg: hip -> high knee -> foot, thin
	m.tube(T(), [Vector3(0, 0, 0), Vector3(dx * 0.85, 0.5, z * 0.6), Vector3(dx * 1.45, 0.0, z * 0.9), Vector3(dx * 1.7, -0.92, z * 1.05)],
			[Vector2(0.07, 0.07), Vector2(0.055, 0.055), Vector2(0.045, 0.045), Vector2(0.03, 0.03)], vio, 0.0, Vector3(0, 0, 1), 5)
	m.blob(T(Vector3(dx * 0.85, 0.5, z * 0.6)), Vector3(0.075, 0.075, 0.075), silver, 0.0, 1.0, 6, 4)

static func build(b) -> void:
	b.cfg = {}
	var P: Dictionary = b.pal
	var vio: Color = P["main"]; var silver: Color = P["accent"]; var teal: Color = P["glow"]; var pale: Color = P["belly"]
	var deep := vio.darkened(0.3)
	# walkers: front pair + back pair, each pair = near + far leg merged
	var lf: Prim = b.part("leg_f", Vector3(0.3, 0.98, 0.0))
	_leg(lf, 1.0, 0.7, vio, silver); _leg(lf, 0.85, -0.7, deep, silver)
	var lb: Prim = b.part("leg_b", Vector3(-0.3, 0.98, 0.0))
	_leg(lb, -1.0, 0.7, vio, silver); _leg(lb, -0.85, -0.7, deep, silver)
	# torso: cephalothorax + HUGE abdomen with the web, lantern on a stalk
	var t: Prim = b.part("torso", Vector3(0, 0.98, 0))
	t.blob(T(Vector3(0.18, 0.12, 0)), Vector3(0.42, 0.34, 0.4), vio.lightened(0.05), 0.0, 0.95, 9, 6)
	t.blob(T(Vector3(-0.62, 0.42, 0)), Vector3(0.78, 0.74, 0.72), vio, 0.0, 0.95, 12, 8)
	_web(t, Vector3(-0.62, 0.42, 0), 0.74, 0.7, 0.72, 1.0, silver)
	_web(t, Vector3(-0.62, 0.42, 0), 0.74, 0.7, 0.72, -1.0, silver.darkened(0.2))
	t.blob(T(Vector3(-0.3, 0.0, 0)), Vector3(0.22, 0.2, 0.3), pale, 0.0, 1.0, 7, 4)
	t.tube(T(), [Vector3(-0.72, 1.05, 0), Vector3(-0.6, 1.4, 0), Vector3(-0.42, 1.62, 0)],
			[Vector2(0.035, 0.035), Vector2(0.03, 0.03), Vector2(0.03, 0.03)], silver, 0.0, Vector3(0, 0, 1), 5, false, true)
	t.blob(T(Vector3(-0.38, 1.76, 0)), Vector3(0.2, 0.22, 0.2), teal, 1.0, 1.0, 9, 6)
	t.ring(T(Vector3(-0.38, 1.6, 0), Vector3(90, 0, 0)), 0.15, 0.03, silver, 0.0, 10, 4)
	# head: round, huge, glasses drawn by the face shader
	var h: Prim = b.part("head", Vector3(0.52, 1.18, 0))
	h.blob(T(Vector3(0.1, 0.3, 0)), Vector3(0.46, 0.42, 0.5), vio.lightened(0.08), 0.0, 0.92, 12, 8)
	h.blob(T(Vector3(0.0, 0.64, 0), Vector3(0, 0, 10)), Vector3(0.3, 0.14, 0.34), deep, 0.0, 1.0, 8, 4)     # fringe tuft
	for s in [-1.0, 1.0]:
		h.tube(T(), [Vector3(0.42, 0.03, 0.12 * s), Vector3(0.52, -0.1, 0.1 * s)], [Vector2(0.05, 0.05), Vector2(0.02, 0.02)], silver, 0.0, Vector3(0, 0, 1), 5, true, false)
	# thread-lance arm (needle with a teal thread through the eye)
	var a: Prim = b.part("arm_f", Vector3(0.52, 0.98, 0.34))
	a.tube(T(), [Vector3(0, 0, 0), Vector3(0.18, -0.12, 0.08), Vector3(0.34, 0.0, 0.1)],
			[Vector2(0.075, 0.075), Vector2(0.065, 0.065), Vector2(0.06, 0.06)], vio, 0.0, Vector3(0, 0, 1), 6)
	a.blob(T(Vector3(0.36, 0.0, 0.1)), Vector3(0.1, 0.1, 0.1), silver.darkened(0.2), 0.0, 1.0, 7, 4)
	var dir := Vector3(0.82, 0.57, 0).normalized()
	a.tube(T(), [Vector3(0.36, 0.0, 0.1) - dir * 0.55, Vector3(0.36, 0.0, 0.1) + dir * 0.4, Vector3(0.36, 0.0, 0.1) + dir * 1.9],
			[Vector2(0.05, 0.05), Vector2(0.04, 0.04), Vector2(0.0, 0.0)], silver, 0.0, Vector3(0, 0, 1), 6, true, false)
	a.ring(T(Vector3(0.36, 0.0, 0.1) - dir * 0.42, Vector3(0, 90, 32)), 0.06, 0.016, teal, 1.0, 8, 4)
	b.sock("weapon_tip", "arm_f", Vector3(0.36, 0.0, 0.1) + dir * 1.9)
	b.sock("weapon_base", "arm_f", Vector3(0.36, 0.0, 0.1) + dir * 0.4)
	b.sock("hand", "arm_f", Vector3(0.36, 0.0, 0.1))
	# off-hand: silk spool
	var ab: Prim = b.part("arm_b", Vector3(0.5, 0.98, -0.34))
	ab.tube(T(), [Vector3(0, 0, 0), Vector3(0.16, -0.16, -0.08), Vector3(0.3, -0.1, -0.1)],
			[Vector2(0.075, 0.075), Vector2(0.065, 0.065), Vector2(0.06, 0.06)], deep, 0.0, Vector3(0, 0, 1), 6)
	ab.blob(T(Vector3(0.34, -0.1, -0.1), Vector3(90, 0, 0)), Vector3(0.14, 0.09, 0.14), silver, 0.0, 0.7, 8, 4)
	ab.blob(T(Vector3(0.34, -0.1, -0.1), Vector3(90, 0, 0)), Vector3(0.15, 0.06, 0.15), teal, 0.8, 0.9, 8, 4)
	# silk line trailing from the spool (lags)
	var w: Prim = b.part("weapon", Vector3(0.84, 0.88, -0.1), "arm_b")
	w.tube(T(), [Vector3(0, 0, 0), Vector3(0.15, -0.12, 0), Vector3(0.1, -0.35, 0), Vector3(0.22, -0.6, 0), Vector3(0.12, -0.85, 0)],
			[Vector2(0.018, 0.018), Vector2(0.018, 0.018), Vector2(0.016, 0.016), Vector2(0.016, 0.016), Vector2(0.0, 0.0)], teal, 0.9, Vector3(0, 0, 1), 4, false, false)
	# two rear tool-limbs (hook + needle) swaying behind
	var e: Prim = b.part("extra", Vector3(-0.35, 1.5, 0))
	for s in [-1.0, 1.0]:
		e.tube(T(), [Vector3(0, 0, 0.1 * s), Vector3(-0.35, 0.3, 0.3 * s), Vector3(-0.7, 0.2, 0.42 * s), Vector3(-0.9, -0.1, 0.45 * s)],
				[Vector2(0.06, 0.06), Vector2(0.05, 0.05), Vector2(0.04, 0.04), Vector2(0.0, 0.0)], vio, 0.0, Vector3(0, 0, 1), 5, true, false)
		e.blob(T(Vector3(-0.35, 0.3, 0.3 * s)), Vector3(0.07, 0.07, 0.07), silver, 0.0, 1.0, 6, 4)
	b.sock("head", "head", Vector3(0.1, 0.3, 0))
	b.set_face(Vector3(0.1, 0.3, 0), Vector3(0.46, 0.42, 0.5),
			{"eye_sep": 0.42, "eye_y": 0.06, "eye_size": Vector2(0.2, 0.2), "eye_white": 1.0, "eye_col": teal.darkened(0.55),
			"sclera": Color.html("f2fbff"), "glasses": 1.0, "accent": teal, "mouth_y": -0.34, "mouth_w": 0.16, "mouth_base": 0.4,
			"mouth_skew": 0.5, "brow_off": 0.26, "brow_len": 0.17, "brow_thick": 0.03},
			1.05, 0.8, 0.0, 0.92)
	b.cfg = {
		"scale": 1.0,
		"wa": 35.0, "sway": 3.0, "stride": 1.1, "bob": 0.6, "waddle": 0.2, "flap": 4.0, "flap_hz": 3.0, "blink_scale": 1.2,
		"lag_weapon": 0.04, "lag_extra": 0.012, "guard_th": 75.0, "parry_th": 30.0, "armb_gain": 0.15,
		"style": {"strike_light": "thrust", "strike_heavy": "thrust", "ability1": "hook", "ability2": "stance",
				"laststand": "roar", "grab": "hook"},
		"amp": {"strike_heavy": 1.45, "laststand": 1.2},
		"fidget": {"head": PL.K(0, 0, -14, 0.02, -0.02), "arm_b": PL.K(0, 0, 35, 0.04, 0.04)},
	}
