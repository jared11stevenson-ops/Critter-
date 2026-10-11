extends RefCounted
## SESSA - "The Gentle Edge": tall thin chartreuse mantis, black blade forearms with magenta edge-glow, oversized glossy
## eyes, tiny magenta scarf. V-shaped blades, thin waist. (ROSTER.md 2)

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _blade(m: Prim, z: float, dark: Color, glow: Color, green: Color, splay: float) -> void:
	# upper arm + elbow joint, then a sickle forearm: black blade, glowing cutting edge on the concave (upper) side
	var xf := T(Vector3.ZERO, Vector3(0, splay, 0))
	m.tube(xf, [Vector3(0, 0, 0), Vector3(0.12, -0.14, z * 0.5), Vector3(0.26, -0.2, z)],
			[Vector2(0.075, 0.075), Vector2(0.065, 0.065), Vector2(0.06, 0.06)], green, 0.0, Vector3(0, 0, 1), 6)
	m.blob(xf * T(Vector3(0.26, -0.2, z)), Vector3(0.09, 0.09, 0.09), green.darkened(0.15), 0.0, 1.0, 6, 4)
	var pts := [Vector3(0.26, -0.2, z), Vector3(0.58, -0.14, z), Vector3(0.88, 0.1, z), Vector3(1.06, 0.46, z), Vector3(1.1, 0.9, z)]
	var wr := [0.07, 0.13, 0.12, 0.09, 0.0]
	m.tube(xf, pts, [Vector2(wr[0], 0.03), Vector2(wr[1], 0.035), Vector2(wr[2], 0.032), Vector2(wr[3], 0.026), Vector2(0, 0)],
			dark, 0.0, Vector3(0, 0, 0) + Vector3(-1, 1, 0).normalized() * 0.0 + Vector3(0, 1, 0), 8, false, false)
	var edge: Array = []
	for i in range(pts.size()):
		var tg: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var nrm := Vector3(-tg.y, tg.x, 0.0)
		edge.append(pts[i] + nrm * (wr[i] * 0.85))
	m.tube(xf, edge, [Vector2(0.02, 0.026), Vector2(0.022, 0.028), Vector2(0.02, 0.026), Vector2(0.016, 0.022), Vector2(0, 0)],
			glow, 1.0, Vector3(0, 1, 0), 4, false, false)

static func build(b) -> void:
	var P: Dictionary = b.pal
	var green: Color = P["main"]; var dark: Color = P["accent"]; var mag: Color = P["glow"]; var pale: Color = P["belly"]
	# legs: tall thin stilts with a back-bent knee
	for leg in [["leg_f", 0.1, 0.18], ["leg_b", -0.12, -0.18]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 1.02, leg[2]))
		l.tube(T(), [Vector3(0, 0.02, 0), Vector3(-0.12, -0.5, 0), Vector3(0.04, -0.96, 0)],
				[Vector2(0.07, 0.07), Vector2(0.055, 0.055), Vector2(0.045, 0.045)], green.darkened(0.1), 0.0, Vector3(0, 0, 1), 6)
		l.blob(T(Vector3(0.1, -0.99, 0)), Vector3(0.17, 0.05, 0.09), dark, 0.0, 0.9, 7, 4)
	# torso: thin waist, long folded-wing abdomen trailing back
	var t: Prim = b.part("torso", Vector3(0, 1.02, 0))
	t.blob(T(Vector3(0.02, 0.4, 0)), Vector3(0.26, 0.46, 0.24), green, 0.0, 0.95, 9, 6)
	t.blob(T(Vector3(0.12, 0.3, 0)), Vector3(0.14, 0.3, 0.2), pale, 0.0, 1.0, 7, 5)
	t.tube(T(), [Vector3(-0.1, 0.55, 0), Vector3(-0.5, 0.52, 0), Vector3(-0.92, 0.7, 0), Vector3(-1.2, 1.0, 0)],
			[Vector2(0.2, 0.2), Vector2(0.19, 0.17), Vector2(0.13, 0.1), Vector2(0.0, 0.0)], green.darkened(0.12), 0.0, Vector3(0, 0, 1), 8, true, false)
	t.tube(T(), [Vector3(-0.15, 0.7, 0.12), Vector3(-0.55, 0.66, 0.13), Vector3(-0.95, 0.82, 0.1)],
			[Vector2(0.05, 0.03), Vector2(0.06, 0.03), Vector2(0.03, 0.02)], pale, 0.0, Vector3(0, 1, 0), 4, false, false)
	# head: wide triangular dome with huge glossy eyes (drawn by the face shader) + antennae
	var h: Prim = b.part("head", Vector3(0.05, 1.56, 0))
	h.blob(T(Vector3(0.1, 0.28, 0)), Vector3(0.36, 0.34, 0.56), green.lightened(0.04), 0.0, 0.82, 12, 7)
	h.blob(T(Vector3(0.12, 0.06, 0)), Vector3(0.22, 0.16, 0.3), green.darkened(0.06), 0.0, 1.0, 8, 4)   # chin wedge
	for s in [-1.0, 1.0]:
		h.tube(T(), [Vector3(0.06, 0.55, 0.16 * s), Vector3(0.0, 0.85, 0.28 * s), Vector3(-0.2, 1.08, 0.4 * s), Vector3(-0.4, 1.14, 0.48 * s)],
				[Vector2(0.03, 0.03), Vector2(0.024, 0.024), Vector2(0.02, 0.02), Vector2(0.018, 0.018)], dark, 0.0, Vector3(0, 0, 1), 5, false, true)
		h.blob(T(Vector3(-0.42, 1.14, 0.49 * s)), Vector3(0.05, 0.05, 0.05), mag, 1.0, 1.0, 6, 4)
	# blade forearms (two V-shaped sickles)
	var a: Prim = b.part("arm_f", Vector3(0.1, 1.38, 0.3))
	_blade(a, 0.04, dark, mag, green, -9.0)
	b.sock("weapon_tip", "arm_f", Vector3(1.1, 0.9, 0.04))
	b.sock("weapon_base", "arm_f", Vector3(0.3, -0.16, 0.04))
	b.sock("hand", "arm_f", Vector3(0.26, -0.2, 0.04))
	var ab: Prim = b.part("arm_b", Vector3(0.1, 1.38, -0.3))
	_blade(ab, -0.04, dark.lightened(0.05), mag, green.darkened(0.12), 9.0)
	# tiny scarf (lags behind)
	var e: Prim = b.part("extra", Vector3(0.0, 1.52, 0))
	e.ring(T(Vector3.ZERO, Vector3(90, 0, 0)), 0.2, 0.055, mag, 0.35, 12, 5)
	e.tube(T(), [Vector3(-0.12, 0.0, 0.12), Vector3(-0.35, -0.06, 0.14), Vector3(-0.58, -0.22, 0.1), Vector3(-0.7, -0.42, 0.1)],
			[Vector2(0.06, 0.02), Vector2(0.075, 0.02), Vector2(0.065, 0.02), Vector2(0.0, 0.0)], mag, 0.25, Vector3(0, 1, 0), 4, true, false)
	b.sock("head", "head", Vector3(0.1, 0.28, 0))
	b.set_face(Vector3(0.1, 0.28, 0), Vector3(0.36, 0.34, 0.56),
			{"eye_sep": 0.5, "eye_y": 0.08, "eye_size": Vector2(0.3, 0.3), "eye_white": 1.0, "eye_col": mag.darkened(0.2), "sclera": Color.html("f4ffd6"),
			"mouth_y": -0.34, "mouth_w": 0.22, "mouth_base": 0.7, "brow_off": 0.02, "brow_len": 0.14, "brow_thick": 0.03},
			1.15, 0.86, 0.0, 0.82)
	b.cfg = {
		"wa": 42.0, "sway": 3.0, "stride": 1.35, "bob": 0.5, "waddle": 0.35, "blink_scale": 1.3,
		"lag_extra": 0.03, "guard_th": 78.0, "parry_th": 30.0,
		"style": {"strike_light": "slash_up", "strike_heavy": "slash_back", "ability1": "stance", "ability2": "leap",
				"laststand": "spin", "grab": "hook"},
		"amp": {"laststand": 1.35, "strike_light": 0.85},
		"poses": {"guard": {"ant": {"arm_b": PL.K(0, 0, 60, 0.04, 0, 0)}}},
		"fidget": {"head": PL.K(20, 0, -5), "arm_f": PL.K(0, 0, -38, 0.05, 0, 0)},
	}
