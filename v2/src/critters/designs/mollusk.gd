extends RefCounted
## MOLLUSK - "The Weight of Tomorrow": giant African snail warrior (220 cm). Upright peach body with orange mottling, two long eye-stalks, a
## giant spiral shell (maroon/brown with cream bands) overgrown with ferns and a red hibiscus, a trailing slug tail, muscular armored
## arms with mauve bracers, a round pale shoulder shell, red cloth strips, beaded belts and hanging charms, and a huge moss-covered stone mace.
## Reference: tools/source_art/mollusk_sheet.png.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _fern(m: Prim, base: Vector3, ang: float, ln: float, col: Color) -> void:
	for k in range(5):
		var f := 0.2 + k * 0.18
		var a := deg_to_rad(ang)
		var p := base + Vector3(sin(a), cos(a), 0) * ln * f
		for sd in [-1.0, 1.0]:
			m.flat(T(), [p, p + Vector3(sin(a) * 0.1, cos(a) * 0.08, 0.14 * sd), p + Vector3(sin(a) * 0.16, cos(a) * 0.1 - 0.04, 0.3 * sd)], 0.05, 0.02, 0.01, col, Vector3(0, 1, 0), 0.0, 0.1, true, 3)
	m.lim(T(), [base, base + Vector3(sin(deg_to_rad(ang)), cos(deg_to_rad(ang)), 0) * ln], 0.025, 0.012, col.darkened(0.2), 0.0, 3, false, false)

static func build(b) -> void:
	b.quality = 0.75
	var P: Dictionary = b.pal
	var tan: Color = P["main"]; var brown: Color = P["accent"]; var glow: Color = P["glow"]; var pale: Color = P["belly"]
	var maroon := Color.html("5a2a2e"); var shell_b := Color.html("8a5530"); var cream := Color.html("e2c99c"); var leaf := Color.html("4f8030")
	var cloth := Color.html("a8322c"); var mauve := Color.html("5d4766"); var stone := Color.html("5e5468"); var moss := Color.html("6f9a36"); var flower := Color.html("e8493a")
	var gold := Color.html("d5a443")
	# ---- two stubby feet
	for leg in [["leg_f", 0.18, 0.28], ["leg_b", -0.12, -0.28]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.5, leg[2]))
		l.blob(T(Vector3(0.06, -0.3, 0)), Vector3(0.3, 0.2, 0.22), tan.darkened(0.05), 0.0, 0.85, 8, 5)
		l.blob(T(Vector3(0.28, -0.4, 0)), Vector3(0.14, 0.08, 0.16), brown, 0.0, 0.8, 6, 3)
	# ---- torso: tall peach body, cream belly, belts, red strips, pendants; the long slug tail trails behind
	var t: Prim = b.part("torso", Vector3(0, 0.5, 0))
	t.blob(T(Vector3(-0.05, 0.4, 0)), Vector3(0.58, 0.62, 0.52), tan, 0.0, 0.88, 11, 8)
	t.blob(T(Vector3(0.2, 0.55, 0)), Vector3(0.3, 0.5, 0.4), pale, 0.0, 0.9, 8, 6)
	t.blob(T(Vector3(-0.4, -0.05, 0)), Vector3(0.8, 0.22, 0.4), tan.darkened(0.08), 0.0, 0.9, 10, 5)
	t.lim(T(), [Vector3(-0.6, -0.05, 0), Vector3(-1.2, -0.12, 0), Vector3(-1.9, -0.2, 0)], 0.3, 0.0, tan.darkened(0.12), 0.0, 8, false, false)   # tail
	for k in range(5):
		var z := -0.3 + k * 0.15
		t.flat(T(), [Vector3(0.32, 0.4, z), Vector3(0.36, 0.0, z), Vector3(0.32, -0.38 - 0.06 * (k % 2), z)], 0.07, 0.05, 0.015, cloth if k % 2 == 0 else cream.darkened(0.1), Vector3(0, 0, 1), 0.0, 0.0, true)
	t.ring(T(Vector3(0, 0.25, 0), Vector3(90, 0, 0)), 0.52, 0.06, mauve, 0.0, 12, 4)
	for z in [-0.28, -0.1, 0.08, 0.26]:
		t.blob(T(Vector3(0.5, 0.15, z)), Vector3(0.05, 0.08, 0.05), gold if int(z * 10) % 2 == 0 else glow, 0.3, 1.0, 5, 3)
	t.lim(T(), [Vector3(0.28, 1.0, 0.25), Vector3(0.4, 0.7, 0.0), Vector3(0.28, 0.45, -0.25)], 0.03, 0.03, brown, 0.0, 4, false, false)
	t.blob(T(Vector3(0.42, 0.7, 0.0)), Vector3(0.09, 0.11, 0.06), glow, 0.4, 1.0, 6, 4)
	# ---- head with two long eye-stalks (eyes are geometry), downturned mouth drawn by the face shader
	var h: Prim = b.part("head", Vector3(0.25, 1.65, 0))
	h.blob(T(Vector3(0.1, 0.1, 0)), Vector3(0.36, 0.34, 0.32), tan.lightened(0.04), 0.0, 0.9, 10, 7)
	h.blob(T(Vector3(0.2, -0.22, 0), Vector3(0, 0, -10)), Vector3(0.14, 0.08, 0.16), pale, 0.0, 0.9, 7, 4)
	for s in [-1.0, 1.0]:
		var st := [Vector3(0.05, 0.3, 0.1 * s), Vector3(0.1, 0.7, 0.16 * s), Vector3(0.18, 1.1, 0.2 * s), Vector3(0.24, 1.4, 0.22 * s)]
		h.lim(T(), st, 0.075, 0.055, tan.lightened(0.05), 0.0, 6)
		h.blob(T(Vector3(0.26, 1.46, 0.22 * s)), Vector3(0.13, 0.13, 0.13), Color.html("f6efe0"), 0.0, 1.0, 8, 5)
		h.blob(T(Vector3(0.36, 1.46, 0.22 * s)), Vector3(0.05, 0.06, 0.06), Color.html("140c0a"), 0.0, 1.0, 5, 3)
		h.lim(T(), [Vector3(0.3, -0.18, 0.2 * s), Vector3(0.4, -0.34, 0.24 * s)], 0.03, 0.015, tan, 0.0, 4, true, true)          # lower tentacles
	h.blob(T(Vector3(-0.1, 0.4, 0.0)), Vector3(0.14, 0.1, 0.2), leaf, 0.0, 0.9, 6, 3)
	b.sock("head", "head", Vector3(0.1, 0.1, 0))
	b.set_face(Vector3(0.1, 0.1, 0), Vector3(0.36, 0.34, 0.32),
			{"eye_size": Vector2(0.001, 0.001), "eye_sep": 0.38, "eye_y": 0.18, "no_brow": 0.0, "brow_off": 0.0, "brow_len": 0.22, "brow_thick": 0.04, "mouth_y": -0.15, "mouth_w": 0.3, "mouth_base": -0.35, "accent": cloth}, 0.95, 0.7, -0.1, 0.9)
	# ---- arms: big, mottled, mauve bracers; front fist carries the mossy stone mace; back arm has the round pale shoulder shell
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.1, 1.45, 0.58 * side))
		a.blob(T(Vector3(0, 0.0, 0.04 * side)), Vector3(0.24, 0.22, 0.24), mauve, 0.0, 0.9, 8, 5)
		a.lim(T(), [Vector3(0, -0.05, 0), Vector3(0.1, -0.5, 0.06 * side), Vector3(0.3, -0.85, 0.1 * side)], 0.2, 0.16, tan.darkened(0.08), 0.0, 7)
		a.blob(T(Vector3(0.22, -0.74, 0.1 * side), Vector3(0, 0, 18)), Vector3(0.19, 0.22, 0.2), mauve, 0.0, 0.8, 8, 5)         # bracer
		a.blob(T(Vector3(0.34, -0.98, 0.1 * side)), Vector3(0.2, 0.17, 0.18), tan.darkened(0.12), 0.0, 0.9, 7, 4)
		if side < 0:
			a.blob(T(Vector3(0.05, 0.14, -0.2)), Vector3(0.22, 0.22, 0.12), cream.lightened(0.1), 0.0, 1.0, 8, 5)
			a.blob(T(Vector3(0.05, 0.14, -0.31)), Vector3(0.08, 0.08, 0.03), flower, 0.0, 1.0, 6, 3)
	var hand := Vector3(0.34, -0.98, 0.1)
	var af: Prim = b.parts["arm_f"]["mb"]
	af.lim(T(), [hand + Vector3(-0.1, 0.25, 0), hand + Vector3(0.45, -0.1, 0)], 0.07, 0.065, brown, 0.0, 5)
	var sc := hand + Vector3(0.85, -0.2, 0)
	af.blob(T(sc), Vector3(0.52, 0.5, 0.5), stone, 0.0, 0.8, 9, 6)
	for mp in [Vector3(0.1, 0.4, 0.3), Vector3(-0.2, 0.3, -0.35), Vector3(0.3, -0.2, 0.4), Vector3(-0.35, -0.1, 0.2), Vector3(0.0, 0.46, -0.1)]:
		af.blob(T(sc + mp), Vector3(0.17, 0.12, 0.17), moss, 0.0, 1.0, 6, 3)
	af.ring(T(sc + Vector3(0, 0, 0), Vector3(0, 90, 0)), 0.5, 0.025, brown, 0.0, 12, 3)
	b.sock("weapon_tip", "arm_f", sc + Vector3(0.45, 0.0, 0.0))
	b.sock("weapon_base", "arm_f", hand)
	b.sock("hand", "arm_f", hand)
	# ---- hanging charms and time relics (lag)
	var w: Prim = b.part("weapon", Vector3(0.35, 1.0, 0.5))
	for k in range(4):
		var z := -0.1 + k * 0.12
		w.lim(T(), [Vector3(0, 0, z), Vector3(0, -0.18 - 0.05 * k, z)], 0.012, 0.012, brown, 0.0, 3, false, false)
		w.blob(T(Vector3(0, -0.3 - 0.05 * k, z)), Vector3(0.06, 0.1, 0.05), [glow, gold, mauve, moss][k], 0.3, 1.0, 6, 4)
	# ---- the giant spiral shell: maroon/brown with cream bands, ferns and a red hibiscus
	var e: Prim = b.part("extra", Vector3(-0.45, 1.1, 0))
	e.blob(T(Vector3(0, 0.1, 0), Vector3(0, 0, -10)), Vector3(0.95, 0.95, 0.72), shell_b, 0.0, 0.95, 14, 10)
	e.blob(T(Vector3(0.12, 0.05, 0), Vector3(0, 0, -10)), Vector3(0.7, 0.72, 0.76), maroon, 0.0, 0.95, 12, 8)
	for sdz in [-1.0, 1.0]:
		for rr in [0.28, 0.5, 0.72]:
			var zz: float = 0.72 * sqrt(maxf(0.0, 1.0 - pow(rr / 0.95, 2.0))) * 0.98 * sdz
			e.ring(T(Vector3(0, 0.1, zz), Vector3(0, 0, 0)), rr, 0.045, cream if rr != 0.5 else brown, 0.0, 14, 3, 0.6)
		e.blob(T(Vector3(0, 0.1, 0.7 * sdz)), Vector3(0.12, 0.12, 0.07), cream, 0.0, 1.0, 6, 3)
	_fern(e, Vector3(0.2, 0.85, 0.1), -20.0, 0.7, leaf)
	_fern(e, Vector3(-0.1, 0.9, -0.1), -55.0, 0.6, leaf.darkened(0.1))
	for i in range(5):
		var a2 := float(i) / 5.0 * TAU
		e.blob(T(Vector3(0.2 + cos(a2) * 0.1, 1.0 + 0.0, sin(a2) * 0.1), Vector3(0, 0, 0)), Vector3(0.07, 0.13, 0.05), flower, 0.0, 1.0, 5, 3)
	e.blob(T(Vector3(0.2, 1.0, 0.0)), Vector3(0.04, 0.04, 0.04), Color.html("f4d24a"), 0.4, 1.0, 5, 3)
	b.cfg = {
		"scale": 1.0, "wa": -50.0, "sway": 1.0, "stride": 0.55, "bob": 0.3, "waddle": 0.8, "lag_weapon": 0.03, "lag_extra": 0.006, "lag_extra_x": 0.5,
		"armb_gain": 0.3, "guard_th": 20.0, "parry_th": 0.0, "blink_scale": 1.0,
		"style": {"strike_light": "chop", "strike_heavy": "overhead", "ability1": "overhead", "ability2": "stance", "laststand": "roar", "grab": "charge"},
		"amp": {"strike_light": 0.7, "strike_heavy": 0.9, "ability1": 1.1, "grab": 0.6},
		"fidget": {"head": PL.K(0, 0, 8, 0.0, 0.0), "torso": PL.K(0, 0, 0, 0, 0, 0, 1.03, 1.03, 1.03)},
	}
