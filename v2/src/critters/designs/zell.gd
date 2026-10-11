extends RefCounted
## ZELL - "Short Summer": sleek cyan dragonfly, four transparent glass wings (an X in profile), white racing stripes, slim
## glaive with a wing-shaped blade, huge goggle eyes (one bigger), scarf tail, hovers. (ROSTER.md 6)

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _wing(m: Prim, z: float, ang_deg: float, length: float, width: float, tint: Color) -> void:
	var a := deg_to_rad(ang_deg)
	var d := Vector3(cos(a), sin(a), 0)
	var hint := Vector3(-sin(a), cos(a), 0)
	var pts := [d * 0.0 + Vector3(0, 0, z), d * length * 0.3 + Vector3(0, 0, z), d * length * 0.65 + Vector3(0, 0, z), d * length + Vector3(0, 0, z)]
	m.tube(T(), pts, [Vector2(0.05, 0.012), Vector2(width, 0.012), Vector2(width * 0.85, 0.01), Vector2(0.0, 0.0)], tint, 0.0, hint, 6, false, false)
	for off in [-0.45, 0.35]:   # veins
		var vp := []
		for k in range(4):
			var f: float = [0.1, 0.4, 0.7, 0.95][k]
			var w: float = [0.0, 1.0, 0.8, 0.2][k]
			vp.append(d * length * f + hint * width * off * w + Vector3(0, 0, z))
		m.tube(T(), vp, [Vector2(0.01, 0.014), Vector2(0.01, 0.014), Vector2(0.01, 0.014), Vector2(0.006, 0.01)], Color.WHITE, 1.0, hint, 3, false, false)

static func build(b) -> void:
	var P: Dictionary = b.pal
	var cyan: Color = P["main"]; var white: Color = P["accent"]; var blue: Color = P["glow"]; var pale: Color = P["belly"]
	var deep := cyan.darkened(0.28)
	# tiny dangling legs
	for leg in [["leg_f", 0.12, 0.16], ["leg_b", -0.1, -0.16]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.95, leg[2]))
		l.tube(T(), [Vector3(0, 0, 0), Vector3(0.06, -0.3, 0), Vector3(-0.04, -0.58, 0)], [Vector2(0.055, 0.055), Vector2(0.045, 0.045), Vector2(0.04, 0.04)], deep, 0.0, Vector3(0, 0, 1), 5)
		l.blob(T(Vector3(0.0, -0.6, 0)), Vector3(0.12, 0.04, 0.07), white, 0.0, 0.9, 6, 3)
	# slim thorax + long tail abdomen with racing stripes
	var t: Prim = b.part("torso", Vector3(0, 0.95, 0))
	t.blob(T(Vector3(0.0, 0.36, 0)), Vector3(0.3, 0.46, 0.28), cyan, 0.0, 0.95, 9, 6)
	t.blob(T(Vector3(0.14, 0.3, 0)), Vector3(0.14, 0.28, 0.22), pale, 0.0, 1.0, 7, 5)
	for s in [-1.0, 1.0]:
		t.tube(T(), [Vector3(0.0, 0.76, 0.14 * s), Vector3(0.02, 0.4, 0.27 * s), Vector3(0.0, 0.0, 0.2 * s)], [Vector2(0.025, 0.025), Vector2(0.025, 0.025), Vector2(0.025, 0.025)], white, 0.0, Vector3(0, 0, 1), 4, false, false)
	t.tube(T(), [Vector3(-0.15, 0.1, 0), Vector3(-0.7, 0.0, 0), Vector3(-1.3, -0.12, 0), Vector3(-1.8, -0.26, 0)],
			[Vector2(0.15, 0.15), Vector2(0.11, 0.11), Vector2(0.085, 0.085), Vector2(0.0, 0.0)], cyan, 0.0, Vector3(0, 0, 1), 7, true, false)
	for k in range(3):
		var px := -0.55 - k * 0.42
		t.ring(T(Vector3(px, 0.0 - k * 0.04, 0), Vector3(0, 90, 0)), 0.125 - k * 0.012, 0.025, white, 0.0, 9, 4)
	t.blob(T(Vector3(-1.82, -0.27, 0)), Vector3(0.09, 0.07, 0.07), blue, 1.0, 1.0, 6, 4)
	# head: huge goggle eyes
	var h: Prim = b.part("head", Vector3(0.16, 1.5, 0))
	h.blob(T(Vector3(0.1, 0.3, 0)), Vector3(0.42, 0.37, 0.52), cyan.lightened(0.05), 0.0, 0.85, 12, 7)
	for s in [-1.0, 1.0]:
		h.tube(T(), [Vector3(0.1, 0.62, 0.18 * s), Vector3(0.2, 0.9, 0.3 * s), Vector3(0.1, 1.05, 0.36 * s)], [Vector2(0.025, 0.025), Vector2(0.02, 0.02), Vector2(0.02, 0.02)], white, 0.0, Vector3(0, 0, 1), 4, false, true)
		h.blob(T(Vector3(-0.34, 0.3, 0.46 * s), Vector3(0, 0, 0)), Vector3(0.1, 0.08, 0.06), blue, 0.8, 1.0, 6, 3)   # goggle strap buckles
	# glaive: pole + wing blade (two-handed)
	var a: Prim = b.part("arm_f", Vector3(0.2, 1.3, 0.3))
	a.tube(T(), [Vector3(0, 0, 0), Vector3(0.16, -0.14, 0.04), Vector3(0.3, -0.12, 0.06)], [Vector2(0.065, 0.065), Vector2(0.055, 0.055), Vector2(0.05, 0.05)], cyan, 0.0, Vector3(0, 0, 1), 5)
	a.blob(T(Vector3(0.32, -0.12, 0.06)), Vector3(0.08, 0.08, 0.08), white, 0.0, 1.0, 6, 4)
	var dir := Vector3(0.9, 0.43, 0)
	var hand := Vector3(0.32, -0.12, 0.06)
	a.tube(T(), [hand - dir * 0.8, hand + dir * 1.0, hand + dir * 1.7], [Vector2(0.04, 0.04), Vector2(0.036, 0.036), Vector2(0.034, 0.034)], white, 0.0, Vector3(0, 0, 1), 5)
	a.blob(T(hand + dir * 0.35, Vector3(0, 0, 40), Vector3(1, 1, 1)), Vector3(0.07, 0.12, 0.07), blue, 0.7, 0.8, 6, 3)   # grip wrap
	var hn := Vector3(-dir.y, dir.x, 0)
	var bl := [hand + dir * 1.65, hand + dir * 1.9 + hn * 0.02, hand + dir * 2.2 + hn * 0.1, hand + dir * 2.5 + hn * 0.08, hand + dir * 2.7 - hn * 0.02]
	a.tube(T(), bl, [Vector2(0.05, 0.025), Vector2(0.15, 0.03), Vector2(0.17, 0.028), Vector2(0.1, 0.02), Vector2(0.0, 0.0)], Color.html("e9fbff"), 0.0, hn, 8, false, false)
	var ed := []
	for i in range(bl.size()):
		ed.append(bl[i] + hn * [0.05, 0.14, 0.16, 0.09, 0.0][i])
	a.tube(T(), ed, [Vector2(0.014, 0.02), Vector2(0.016, 0.022), Vector2(0.016, 0.022), Vector2(0.012, 0.018), Vector2(0.0, 0.0)], blue, 1.0, hn, 4, false, false)
	b.sock("weapon_tip", "arm_f", hand + dir * 2.7)
	b.sock("weapon_base", "arm_f", hand + dir * 1.0)
	b.sock("hand", "arm_f", hand)
	var ab: Prim = b.part("arm_b", Vector3(0.2, 1.3, -0.3))
	ab.tube(T(), [Vector3(0, 0, 0), Vector3(0.16, -0.14, -0.04), Vector3(0.3, -0.12, -0.06)], [Vector2(0.065, 0.065), Vector2(0.055, 0.055), Vector2(0.05, 0.05)], deep, 0.0, Vector3(0, 0, 1), 5)
	ab.blob(T(Vector3(0.32, -0.12, -0.06)), Vector3(0.08, 0.08, 0.08), white.darkened(0.1), 0.0, 1.0, 6, 4)
	# scarf tail (lags hard)
	var w: Prim = b.part("weapon", Vector3(0.1, 1.42, 0.0))
	w.ring(T(Vector3.ZERO, Vector3(90, 0, 0)), 0.2, 0.05, blue, 0.4, 10, 4)
	w.tube(T(), [Vector3(-0.12, 0, 0.1), Vector3(-0.5, -0.04, 0.12), Vector3(-0.95, -0.2, 0.1), Vector3(-1.3, -0.1, 0.1), Vector3(-1.55, -0.28, 0.1)],
			[Vector2(0.07, 0.015), Vector2(0.1, 0.015), Vector2(0.1, 0.015), Vector2(0.08, 0.015), Vector2(0.0, 0.0)], blue, 0.35, Vector3(0, 1, 0), 4, true, false)
	# four glass wings: fore pair up-front, hind pair up-back (an X seen from the side)
	b.glass = ["extra"]
	var e: Prim = b.part("extra", Vector3(-0.12, 1.5, 0))
	var wt := cyan.lerp(Color.WHITE, 0.55)
	for z in [0.16, -0.16]:
		_wing(e, z, 48.0, 1.7, 0.4, wt)
		_wing(e, z * 1.3, 132.0, 1.6, 0.36, wt.darkened(0.05))
	b.sock("head", "head", Vector3(0.1, 0.3, 0))
	b.set_face(Vector3(0.1, 0.3, 0), Vector3(0.42, 0.37, 0.52),
			{"eye_sep": 0.5, "eye_y": 0.06, "eye_size": Vector2(0.3, 0.24), "eye_white": 1.0, "eye_col": blue.darkened(0.3), "sclera": Color.html("f6ffff"),
			"goggle": 1.0, "accent": blue, "mouth_y": -0.34, "mouth_w": 0.2, "mouth_base": 0.5, "mouth_skew": 0.8, "brow_bias": Vector2(0.0, 0.35),
			"brow_off": 0.34, "brow_len": 0.2, "brow_thick": 0.035}, 1.1, 0.8, 0.0, 0.85)
	b.cfg = {
		"scale": 0.95,
		"wa": 25.0, "arm_b_follow": true, "sway": 3.0, "stride": 1.5, "bob": 0.3, "waddle": 0.2, "hover": 0.28, "flap": 9.0, "flap_hz": 24.0,
		"lag_weapon": 0.06, "lag_extra": 0.01, "guard_th": 85.0, "parry_th": 40.0, "blink_scale": 0.8,
		"style": {"strike_light": "slash_back", "strike_heavy": "leap", "ability1": "leap", "ability2": "slash_up", "laststand": "spin", "grab": "grab"},
		"amp": {"strike_light": 0.9, "ability1": 1.2, "laststand": 1.3, "grab": 1.1},
		"fidget": {"head": PL.K(0, 0, 8, 0.02, 0.0), "arm_f": PL.K(0, 0, -60, -0.05, 0.06), "torso": PL.K(0, 0, -4)},
	}
