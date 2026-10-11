extends RefCounted
## ZEPHYR - "The Nectar Seeker": hummingbird-hawk-moth / old-folklore fairy (165 cm). Pale bird-skull mask with a long thin curved beak and
## big red-ringed black eyes, a crest of red-brown leaf feathers, curled antennae with red tassels and flowers, gaunt brown body, red scarf,
## layered tattered leaf-strip skirt, large pink-gem nectar vials, four long petal-like wings (pink, red, olive), bird legs with talons,
## and a thin proboscis-needle lance. Reference: tools/source_art/zephyr_sheet.png.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _petal(m: Prim, c: Vector3, ln: float, wid: float, tilt: float, sweep: float, col: Color, spot: Color, z: float) -> void:
	var xf := T(c, Vector3(tilt * signf(z), 0, sweep))
	m.blob(xf, Vector3(0.012, ln, wid), col, 0.0, 1.0, 8, 6)
	for k in range(3):
		m.blob(xf * T(Vector3(0.012, (-0.4 + k * 0.35) * ln, (0.3 - 0.2 * k) * wid * signf(z))), Vector3(0.01, 0.07 * ln, 0.08 * wid), spot, 0.0, 1.0, 5, 3)
	m.lim(xf, [Vector3(0.012, ln * 0.9, 0), Vector3(0.012, -ln * 0.9, 0)], 0.012, 0.01, col.lightened(0.3), 1.0, 3, false, false)

static func build(b) -> void:
	b.quality = 0.9
	var P: Dictionary = b.pal
	var olive: Color = P["main"]; var pink: Color = P["accent"]; var glow: Color = P["glow"]; var peach: Color = P["belly"]
	var brown := Color.html("6a4a3a"); var dark := Color.html("3a2a2a"); var cream := Color.html("e6d5ae"); var red := Color.html("a03a34"); var crest := Color.html("b04a3a")
	var gold := Color.html("d8b04a"); var talon := Color.html("33241f")
	b.glass = ["extra"]
	# ---- bird legs with talons
	for leg in [["leg_f", 0.1, 0.2], ["leg_b", -0.1, -0.2]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.95, leg[2]))
		l.lim(T(), [Vector3(0, 0, 0), Vector3(0.14, -0.4, 0), Vector3(-0.08, -0.8, 0)], 0.1, 0.05, brown, 0.0, 5)
		l.blob(T(Vector3(0.14, -0.4, 0)), Vector3(0.1, 0.1, 0.1), dark, 0.0, 1.0, 5, 3)
		for dz in [-0.06, 0.0, 0.06]:
			l.lim(T(), [Vector3(-0.06, -0.84, dz), Vector3(0.24, -0.9, dz * 1.6)], 0.035, 0.0, talon, 0.0, 4, true, false)
		l.lim(T(), [Vector3(-0.08, -0.82, 0), Vector3(-0.28, -0.9, 0)], 0.03, 0.0, talon, 0.0, 4, true, false)
	# ---- torso: gaunt brown body, red scarf, belt, layered leaf-strip skirt
	var t: Prim = b.part("torso", Vector3(0, 0.95, 0))
	t.blob(T(Vector3(0, 0.1, 0)), Vector3(0.28, 0.2, 0.26), dark, 0.0, 0.9, 8, 5)
	t.blob(T(Vector3(0.02, 0.5, 0)), Vector3(0.3, 0.42, 0.28), brown.lightened(0.04), 0.0, 0.9, 9, 6)
	t.ring(T(Vector3(0, 0.18, 0), Vector3(90, 0, 0)), 0.27, 0.05, red, 0.0, 10, 4)
	t.blob(T(Vector3(0.24, 0.18, 0), Vector3(0, 90, 0)), Vector3(0.07, 0.07, 0.03), gold, 0.0, 1.0, 6, 3)
	t.lim(T(), [Vector3(0.1, 0.95, 0.22), Vector3(0.24, 0.82, 0.0), Vector3(0.1, 0.95, -0.22)], 0.07, 0.07, red, 0.0, 5, true, true)      # scarf
	t.flat(T(), [Vector3(0.22, 0.85, 0.0), Vector3(0.3, 0.5, 0.0), Vector3(0.26, 0.2, 0.0)], 0.06, 0.05, 0.015, red, Vector3(0, 0, 1), 0.0, 0.0, true)
	var skirt := [olive, red.darkened(0.1), cream.darkened(0.15), dark, olive.lightened(0.1), pink.darkened(0.2)]
	for k in range(12):
		var a := float(k) / 12.0 * TAU
		var z := sin(a) * 0.3
		var x := cos(a) * 0.26
		var ln := 0.65 + 0.2 * absf(sin(k * 2.7))
		t.flat(T(), [Vector3(x, 0.05, z), Vector3(x * 1.15, -ln * 0.5, z * 1.15), Vector3(x * 1.2, -ln, z * 1.2)], 0.15, 0.07, 0.015, skirt[k % skirt.size()], Vector3(-sin(a), 0, cos(a)), 0.0, 0.0, true)
	# ---- head: pale bird-skull mask, long curved beak, black red-ringed eyes, leaf crest, curled antennae with tassels
	var h: Prim = b.part("head", Vector3(0.1, 1.9, 0))
	h.blob(T(Vector3(0.05, 0.2, 0)), Vector3(0.34, 0.36, 0.3), cream, 0.0, 0.9, 10, 7)
	h.lim(T(), [Vector3(0.3, 0.1, 0), Vector3(0.7, -0.05, 0), Vector3(1.0, -0.35, 0), Vector3(1.08, -0.7, 0)], 0.075, 0.0, cream.darkened(0.12), 0.0, 6, true, false)   # beak
	h.lim(T(), [Vector3(0.9, -0.25, 0), Vector3(1.08, -0.7, 0)], 0.04, 0.0, brown, 0.0, 4, false, false)
	h.blob(T(Vector3(-0.05, 0.1, 0)), Vector3(0.22, 0.3, 0.3), brown, 0.0, 0.9, 7, 5)
	for k in range(5):
		var f := float(k) / 4.0
		var base := Vector3(-0.05, 0.5, (f - 0.5) * 0.3)
		h.flat(T(), [base, base + Vector3(0.0 - 0.08 * k, 0.5, (f - 0.5) * 0.3), base + Vector3(-0.1 - 0.1 * k, 0.9 - 0.08 * absf(k - 2), (f - 0.5) * 0.5)], 0.13, 0.06, 0.015, crest if k % 2 == 0 else crest.lightened(0.1), Vector3(0, 0, 1), 0.0, 0.3, true)
	for s in [-1.0, 1.0]:
		var ant := [Vector3(0.1, 0.52, 0.12 * s), Vector3(0.2, 0.9, 0.3 * s), Vector3(0.0, 1.2, 0.5 * s), Vector3(-0.1, 0.95, 0.6 * s)]
		h.lim(T(), ant, 0.025, 0.015, gold.darkened(0.2), 0.0, 4, true, true)
		h.lim(T(), [Vector3(-0.1, 0.95, 0.6 * s), Vector3(-0.08, 0.5, 0.62 * s)], 0.02, 0.02, red, 0.0, 3, false, false)
		h.flat(T(), [Vector3(-0.08, 0.5, 0.62 * s), Vector3(-0.08, 0.3, 0.62 * s), Vector3(-0.06, 0.0, 0.62 * s)], 0.07, 0.05, 0.02, red, Vector3(0, 0, 1), 0.0, 0.2, true)
		h.blob(T(Vector3(-0.1, 1.0, 0.6 * s)), Vector3(0.07, 0.07, 0.07), Color.html("f0a0b0"), 0.3, 1.0, 5, 3)
	b.sock("head", "head", Vector3(0.05, 0.2, 0))
	b.set_face(Vector3(0.05, 0.2, 0), Vector3(0.34, 0.36, 0.3),
			{"eye_sep": 0.42, "eye_y": 0.08, "eye_size": Vector2(0.2, 0.2), "eye_white": 1.0, "sclera": Color.html("140808"), "eye_col": Color.html("ff3a2a"),
			"mouth_y": -0.6, "mouth_w": 0.0001, "mouth_base": 0.0, "brow_off": 0.08, "brow_len": 0.17, "brow_thick": 0.035, "accent": pink}, 0.95, 0.72, -0.05, 0.9)
	# ---- arms: thin brown, clawed; front hand holds the proboscis needle
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.0, 1.78, 0.34 * side))
		a.blob(T(Vector3(0, 0, 0)), Vector3(0.13, 0.12, 0.13), red, 0.0, 1.0, 6, 4)
		a.lim(T(), [Vector3(0, 0, 0), Vector3(-0.08, -0.45, 0.05 * side), Vector3(0.2, -0.7, 0.08 * side)], 0.075, 0.055, brown, 0.0, 5)
		a.blob(T(Vector3(0.22, -0.74, 0.08 * side)), Vector3(0.09, 0.09, 0.08), dark, 0.0, 1.0, 5, 3)
		for dz in [-0.04, 0.0, 0.04]:
			a.lim(T(), [Vector3(0.26, -0.78, 0.08 * side + dz), Vector3(0.36, -0.9, 0.09 * side + dz * 1.5)], 0.022, 0.0, talon, 0.0, 4, false, false)
	var hand := Vector3(0.22, -0.74, 0.08)
	var af: Prim = b.parts["arm_f"]["mb"]
	var dir := Vector3(0.45, -0.89, 0).normalized()
	af.lim(T(), [hand - dir * 0.5, hand + dir * 0.4, hand + dir * 1.7], 0.035, 0.0, pink.darkened(0.25), 0.0, 5, true, false)
	af.lim(T(), [hand + dir * 1.0, hand + dir * 1.15], 0.05, 0.05, gold, 0.0, 5)
	b.sock("weapon_tip", "arm_f", hand + dir * 1.7)
	b.sock("weapon_base", "arm_f", hand + dir * 0.4)
	b.sock("hand", "arm_f", hand)
	# ---- hanging nectar vials (big pink gems) and leaf tassels (lag)
	var w: Prim = b.part("weapon", Vector3(0.18, 1.2, 0.2))
	var gems := [[Vector3(0.0, 0.0, 0.1), 0.13, pink], [Vector3(0.05, -0.15, -0.2), 0.09, Color.html("a8d04a")], [Vector3(-0.05, -0.5, 0.05), 0.08, glow]]
	for g in gems:
		w.lim(T(), [g[0] + Vector3(0, 0.2, 0), g[0]], 0.012, 0.012, gold, 0.0, 3, false, false)
		w.blob(T(g[0] - Vector3(0, g[1] * 0.9, 0)), Vector3(g[1] * 0.8, g[1] * 1.25, g[1] * 0.8), g[2], 0.55, 1.0, 7, 5)
		w.ring(T(g[0] - Vector3(0, g[1] * 0.1, 0), Vector3(90, 0, 0)), g[1] * 0.6, 0.02, gold, 0.0, 8, 3)
	# ---- four petal wings: olive-pink pair up behind, long pink-red pair hanging
	var e: Prim = b.part("extra", Vector3(-0.22, 1.6, 0))
	var oliv := Color.html("8d9a50"); var pk := Color.html("d6788e"); var rd := Color.html("b4504e"); var spot := Color.html("f3d9c4")
	for z in [0.1, -0.1]:
		_petal(e, Vector3(-0.35, 0.35, z * 4.0), 0.95, 0.3, 40.0, 38.0, oliv, spot, z)
		_petal(e, Vector3(-0.1, -0.5, z * 4.5), 1.2, 0.3, 25.0, -8.0, pk, spot, z)
		_petal(e, Vector3(-0.3, -0.5, z * 2.6), 1.0, 0.26, 10.0, -16.0, rd, spot, z)
	b.cfg = {
		"scale": 1.0, "wa": -63.0, "sway": 2.0, "stride": 1.2, "bob": 0.5, "waddle": 0.3, "lag_weapon": 0.05, "lag_extra": 0.012, "flap": 5.0, "flap_hz": 9.0,
		"armb_gain": 0.5, "guard_th": 40.0, "parry_th": 5.0, "blink_scale": 0.8, "hover": 0.12,
		"style": {"strike_light": "thrust", "strike_heavy": "leap", "ability1": "leap", "ability2": "stance", "laststand": "spin", "grab": "grab"},
		"amp": {"strike_light": 0.85, "strike_heavy": 0.9, "laststand": 1.2},
		"fidget": {"head": PL.K(0, 0, 14, 0.02, 0.0), "arm_b": PL.K(0, 0, 40, 0.0, 0.03)},
	}
