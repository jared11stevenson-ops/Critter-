extends RefCounted
## KRAGG - "Main Event": massive mahogany stag beetle, huge bone-white mandibles, moss patch on the back, cape of tattered banner,
## heavy chain with a hook around the waist, showman's grin and an eyebrow ring. (ROSTER.md 7)

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func build(b) -> void:
	var P: Dictionary = b.pal
	var mah: Color = P["main"]; var bone: Color = P["accent"]; var moss: Color = P["glow"]; var pale: Color = P["belly"]
	var deep := mah.darkened(0.3)
	for leg in [["leg_f", 0.22, 0.4], ["leg_b", -0.2, -0.4]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.5, leg[2]))
		l.tube(T(), [Vector3(0, 0.04, 0), Vector3(0, -0.28, 0)], [Vector2(0.2, 0.2), Vector2(0.17, 0.17)], deep, 0.0, Vector3(0, 0, 1), 7)
		l.blob(T(Vector3(0.1, -0.38, 0)), Vector3(0.3, 0.13, 0.22), deep.darkened(0.2), 0.0, 0.7, 8, 4)
	# massive barrel torso, shell with moss, waist chain
	var t: Prim = b.part("torso", Vector3(0, 0.5, 0))
	t.blob(T(Vector3(0.12, 0.5, 0)), Vector3(0.72, 0.62, 0.76), mah, 0.0, 0.82, 12, 8)
	t.blob(T(Vector3(0.4, 0.28, 0)), Vector3(0.4, 0.36, 0.58), pale, 0.0, 0.95, 8, 5)
	t.blob(T(Vector3(-0.42, 0.66, 0)), Vector3(0.6, 0.52, 0.7), deep, 0.0, 0.85, 10, 6)
	t.tube(T(), [Vector3(-0.9, 0.5, 0), Vector3(-0.62, 1.0, 0), Vector3(-0.2, 1.2, 0)], [Vector2(0.03, 0.03), Vector2(0.03, 0.03), Vector2(0.03, 0.03)], bone, 0.0, Vector3(0, 0, 1), 4, false, false)
	for m in [Vector3(-0.55, 1.14, 0.1), Vector3(-0.4, 1.2, -0.12), Vector3(-0.7, 1.0, -0.2), Vector3(-0.3, 1.1, 0.3), Vector3(-0.65, 1.1, 0.34)]:
		t.blob(T(m), Vector3(0.14, 0.1, 0.14), moss, 0.25, 1.0, 6, 4)
	t.ring(T(Vector3(0.1, 0.22, 0), Vector3(90, 0, 0)), 0.7, 0.055, Color.html("7e8793"), 0.0, 16, 4)
	t.blob(T(Vector3(0.82, 0.22, 0)), Vector3(0.1, 0.14, 0.14), bone, 0.0, 0.8, 7, 4)
	# head: wide, grin, giant pincers
	var h: Prim = b.part("head", Vector3(0.4, 1.36, 0))
	h.blob(T(Vector3(0.1, 0.34, 0)), Vector3(0.56, 0.4, 0.62), mah.lightened(0.06), 0.0, 0.85, 12, 8)
	h.blob(T(Vector3(0.12, 0.62, 0), Vector3(0, 0, 4)), Vector3(0.46, 0.09, 0.56), deep, 0.0, 0.8, 9, 4)   # brow ridge
	for s in [-1.0, 1.0]:
		var mp := [Vector3(0.3, 0.1, 0.4 * s), Vector3(0.8, 0.02, 0.66 * s), Vector3(1.3, 0.16, 0.56 * s), Vector3(1.66, 0.48, 0.28 * s)]
		h.tube(T(), mp, [Vector2(0.17, 0.15), Vector2(0.15, 0.13), Vector2(0.11, 0.1), Vector2(0.0, 0.0)], bone, 0.0, Vector3(0, 1, 0), 7, true, false)
		for pair in [[1, 2, 0.35], [2, 3, 0.25]]:   # teeth on the inner edge of each pincer
			var tp: Vector3 = (mp[pair[0]] as Vector3).lerp(mp[pair[1]], pair[2]) + Vector3(0.0, 0.1, -0.14 * s)
			h.blob(T(tp, Vector3(0, 0, 20)), Vector3(0.06, 0.12, 0.06), bone.darkened(0.08), 0.0, 1.0, 5, 3)
	# arms: thick, bone wrist wraps
	var a: Prim = b.part("arm_f", Vector3(0.3, 1.1, 0.78))
	a.tube(T(), [Vector3(0, 0, 0), Vector3(0.12, -0.22, 0.05), Vector3(0.2, -0.42, 0.1)], [Vector2(0.21, 0.21), Vector2(0.18, 0.18), Vector2(0.16, 0.16)], mah, 0.0, Vector3(0, 0, 1), 7)
	a.blob(T(Vector3(0.22, -0.43, 0.1)), Vector3(0.12, 0.1, 0.2), bone, 0.0, 0.8, 7, 4)
	a.blob(T(Vector3(0.27, -0.6, 0.1)), Vector3(0.3, 0.27, 0.27), deep.lightened(0.08), 0.0, 0.9, 9, 6)
	b.sock("weapon_tip", "arm_f", Vector3(0.5, -0.6, 0.1))
	b.sock("weapon_base", "arm_f", Vector3(0.12, -0.22, 0.05))
	b.sock("hand", "arm_f", Vector3(0.27, -0.6, 0.1))
	var ab: Prim = b.part("arm_b", Vector3(0.3, 1.1, -0.78))
	ab.tube(T(), [Vector3(0, 0, 0), Vector3(0.12, -0.22, -0.05), Vector3(0.2, -0.42, -0.1)], [Vector2(0.21, 0.21), Vector2(0.18, 0.18), Vector2(0.16, 0.16)], mah.darkened(0.08), 0.0, Vector3(0, 0, 1), 7)
	ab.blob(T(Vector3(0.22, -0.43, -0.1)), Vector3(0.12, 0.1, 0.2), bone.darkened(0.1), 0.0, 0.8, 7, 4)
	ab.blob(T(Vector3(0.27, -0.6, -0.1)), Vector3(0.3, 0.27, 0.27), deep, 0.0, 0.9, 9, 6)
	# chain + hook swinging from the belt (near side)
	var w: Prim = b.part("weapon", Vector3(0.4, 0.74, 0.78))
	var yy := 0.0
	for k in range(7):
		w.blob(T(Vector3(0, -yy - 0.05, 0.0), Vector3(0, 90 * (k % 2), 0)), Vector3(0.045, 0.075, 0.03), Color.html("8a929c"), 0.0, 1.0, 6, 4)
		yy += 0.1
	w.tube(T(), [Vector3(0, -yy, 0), Vector3(0.0, -yy - 0.16, 0), Vector3(0.14, -yy - 0.3, 0), Vector3(0.1, -yy - 0.46, 0), Vector3(-0.06, -yy - 0.42, 0)],
			[Vector2(0.05, 0.05), Vector2(0.05, 0.05), Vector2(0.045, 0.045), Vector2(0.035, 0.035), Vector2(0.0, 0.0)], Color.html("b9c0c8"), 0.0, Vector3(0, 0, 1), 6, true, false)
	b.sock("hook", "weapon", Vector3(0.0, -yy - 0.3, 0))
	# tattered banner cape (streams back)
	var e: Prim = b.part("extra", Vector3(-0.2, 1.38, 0))
	var banner := [moss.darkened(0.3), mah.darkened(0.1), bone, mah.lightened(0.1)]
	for k in range(4):
		var z := -0.42 + k * 0.28
		var ln := 1.2 + (k % 2) * 0.5
		e.tube(T(), [Vector3(0, 0.0 - k * 0.03, z), Vector3(-ln * 0.4, -0.12 - k * 0.04, z), Vector3(-ln * 0.75, -0.42 - k * 0.04, z), Vector3(-ln, -0.78, z)],
				[Vector2(0.24, 0.02), Vector2(0.26, 0.02), Vector2(0.2, 0.016), Vector2(0.0, 0.0)], banner[k], 0.0, Vector3(0, 1, 0), 4, false, false)
	b.sock("head", "head", Vector3(0.1, 0.34, 0))
	b.set_face(Vector3(0.1, 0.34, 0), Vector3(0.56, 0.46, 0.6),
			{"eye_sep": 0.42, "eye_y": 0.08, "eye_size": Vector2(0.15, 0.15), "lid_bias": 0.12, "eye_white": 0.0, "mouth_y": -0.3, "mouth_w": 0.36,
			"mouth_base": 0.9, "ring": 1.0, "accent": bone, "brow_off": 0.07, "brow_len": 0.2, "brow_thick": 0.045}, 1.05, 0.75, -0.03, 0.88)
	b.cfg = {
		"scale": 1.18,
		"wa": -78.0, "sway": 1.5, "stride": 0.85, "bob": 0.5, "waddle": 1.0, "lag_weapon": 0.04, "lag_extra": 0.03, "lag_extra_x": 3.0,
		"guard_th": -20.0, "parry_th": -10.0, "armb_gain": 0.6,
		"style": {"strike_light": "punch", "strike_heavy": "chop", "ability1": "grab", "ability2": "hook", "laststand": "spin", "grab": "grab"},
		"amp": {"strike_light": 0.8, "strike_heavy": 0.85, "ability1": 0.8, "ability2": 0.8, "laststand": 1.1, "grab": 0.85},
		"fidget": {"torso": PL.K(0, 0, -6, 0, 0, 0, 1.05, 1.05, 1.05), "arm_f": PL.K(0, 0, 100), "arm_b": PL.K(0, 0, 100), "head": PL.K(0, 0, 8)},
	}
