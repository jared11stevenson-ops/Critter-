extends RefCounted
## ARUUN - "The Reacher": giraffe-beetle barbarian (240 cm). Long orange neck with dark spots, small horse-like head with two barbed
## curved horns and a pale leaf-mane, dark plum carapace, big red ladybug-spotted shoulder domes, red-and-cream armored forearms,
## cream bandage wraps, brass belt medallion, olive tattered skirt, digitigrade clawed legs, and Morrow: the huge black spiked
## mace with a red dome-eye and a thorny handle. Reference: tools/source_art/aruun_nerit_sheet.jpg (left half).

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _dome(m: Prim, c: Vector3, r: float, red: Color, dark: Color, side: float) -> void:
	m.blob(T(c), Vector3(r, r * 0.88, r), red, 0.0, 1.0, 9, 6)
	for sp in [Vector3(0.1, 0.5, 0.82), Vector3(-0.5, 0.1, 0.8), Vector3(0.45, -0.25, 0.85)]:
		var d := Vector3(sp.x, sp.y, sp.z * side).normalized()
		m.blob(T(c + d * r * 0.97), Vector3(r * 0.3, r * 0.3, r * 0.12), dark, 0.0, 1.0, 6, 3)

static func build(b) -> void:
	var P: Dictionary = b.pal
	var plum: Color = P["main"]; var red: Color = P["accent"]; var orange: Color = P["glow"]; var tan: Color = P["belly"]
	var cream := Color.html("dcc9a4"); var olive := Color.html("737a3a"); var brass := Color.html("c9a24a"); var brown := Color.html("6b4a36")
	var gold_eye := Color.html("f2c230")
	# ---- digitigrade legs, armored in red-orange over plum
	for leg in [["leg_f", 0.08, 0.3], ["leg_b", -0.08, -0.3]]:
		var z: float = leg[2]
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.9, z))
		l.lim(T(), [Vector3(0, 0, 0), Vector3(0.2, -0.4, 0), Vector3(-0.04, -0.78, 0)], 0.23, 0.14, plum)
		l.blob(T(Vector3(0.25, -0.4, 0), Vector3(0, 0, 20)), Vector3(0.17, 0.24, 0.2), red, 0.0, 0.8, 8, 5)       # knee armor
		l.blob(T(Vector3(0.0, -0.58, 0.0), Vector3(0, 0, 8)), Vector3(0.1, 0.22, 0.13), orange, 0.0, 0.8, 7, 4)   # greave
		l.blob(T(Vector3(0.16, -0.88, 0)), Vector3(0.34, 0.1, 0.22), plum.lightened(0.05), 0.0, 0.8, 8, 4)      # foot
		for dz in [-0.08, 0.0, 0.08]:
			l.lim(T(), [Vector3(0.36, -0.88, dz), Vector3(0.55, -0.9, dz * 1.4)], 0.045, 0.0, cream, 0.0, 4, false, false)
	# ---- torso: plum carapace, tan belly, cream wraps, belt + brass medallion, loincloth tassels, long spotted neck
	var t: Prim = b.part("torso", Vector3(0, 0.9, 0))
	t.blob(T(Vector3(0, 0.08, 0)), Vector3(0.44, 0.28, 0.44), plum, 0.0, 0.85, 9, 5)
	t.blob(T(Vector3(0.05, 0.42, 0)), Vector3(0.34, 0.3, 0.32), tan.darkened(0.15), 0.0, 0.9, 9, 5)
	t.blob(T(Vector3(-0.02, 0.78, 0)), Vector3(0.52, 0.36, 0.5), plum, 0.0, 0.85, 10, 6)
	t.lim(T(), [Vector3(0.2, 1.0, 0.2), Vector3(0.28, 0.72, 0.0), Vector3(0.2, 0.5, -0.24)], 0.045, 0.045, cream, 0.0, 4, false, false)   # chest wrap
	t.lim(T(), [Vector3(0.2, 1.0, -0.2), Vector3(0.3, 0.7, 0.0), Vector3(0.2, 0.48, 0.24)], 0.045, 0.045, cream, 0.0, 4, false, false)
	t.ring(T(Vector3(0.02, 0.2, 0), Vector3(90, 0, 0)), 0.33, 0.05, red, 0.0, 12, 4)
	t.blob(T(Vector3(0.36, 0.18, 0), Vector3(0, 90, 0)), Vector3(0.15, 0.15, 0.04), brass, 0.0, 1.0, 9, 3)   # medallion
	t.blob(T(Vector3(0.4, 0.18, 0), Vector3(0, 90, 0)), Vector3(0.07, 0.07, 0.03), red, 0.0, 1.0, 7, 3)
	for dz in [-0.14, 0.0, 0.14]:
		t.flat(T(), [Vector3(0.34, 0.1, dz), Vector3(0.36, -0.15, dz), Vector3(0.34, -0.42, dz * 1.1)], 0.07, 0.04, 0.015, cream, Vector3(0, 0, 1), 0.0, 0.0, true)
	t.lim(T(), [Vector3(0.0, 0.98, 0), Vector3(0.1, 1.22, 0), Vector3(0.28, 1.5, 0), Vector3(0.38, 1.75, 0)], 0.17, 0.11, orange, 0.0, 8)  # neck
	for k in range(3):
		var f := 0.2 + k * 0.28
		t.blob(T(Vector3(0.1 + 0.28 * f * 1.1, 1.02 + f * 0.7, 0.11)), Vector3(0.06, 0.07, 0.03), plum, 0.0, 1.0, 5, 3)
		t.blob(T(Vector3(0.1 + 0.28 * f * 1.1, 1.02 + f * 0.7, -0.11)), Vector3(0.06, 0.07, 0.03), plum, 0.0, 1.0, 5, 3)
	# ---- head: long muzzle, yellow eye, barbed horns, pale leaf mane
	var h: Prim = b.part("head", Vector3(0.38, 2.7, 0))
	h.blob(T(Vector3(0.12, 0.05, 0)), Vector3(0.36, 0.26, 0.28), orange.darkened(0.05), 0.0, 0.9, 11, 7)
	h.blob(T(Vector3(0.4, -0.1, 0), Vector3(0, 0, -12)), Vector3(0.28, 0.15, 0.2), plum.lightened(0.12), 0.0, 0.9, 9, 5)   # snout
	h.blob(T(Vector3(-0.12, 0.12, 0), Vector3(0, 0, 20)), Vector3(0.2, 0.2, 0.3), plum, 0.0, 0.9, 8, 5)
	for s in [-1.0, 1.0]:
		h.lim(T(), [Vector3(-0.02, 0.2, 0.14 * s), Vector3(-0.2, 0.6, 0.3 * s), Vector3(-0.05, 0.98, 0.42 * s), Vector3(0.38, 1.12, 0.4 * s)], 0.12, 0.035, red, 0.0, 6, true, false)
		h.lim(T(), [Vector3(-0.12, 0.55, 0.28 * s), Vector3(-0.32, 0.72, 0.36 * s)], 0.06, 0.0, red, 0.0, 4, false, false)       # barb
		h.lim(T(), [Vector3(-0.12, 0.78, 0.4 * s), Vector3(-0.14, 1.08, 0.5 * s)], 0.05, 0.0, red, 0.0, 4, false, false)
		h.flat(T(), [Vector3(-0.1, 0.0, 0.22 * s), Vector3(-0.38, -0.08, 0.34 * s), Vector3(-0.66, -0.4, 0.3 * s)], 0.16, 0.06, 0.015, cream.lightened(0.1), Vector3(0, 1, 0), 0.0, 0.2, true)  # leaf mane
		h.flat(T(), [Vector3(-0.1, 0.14, 0.2 * s), Vector3(-0.34, 0.2, 0.3 * s), Vector3(-0.5, 0.1, 0.28 * s)], 0.09, 0.04, 0.015, olive.lightened(0.15), Vector3(0, 1, 0), 0.0, 0.2, true)
	b.sock("head", "head", Vector3(0.12, 0.05, 0))
	b.set_face(Vector3(0.12, 0.05, 0), Vector3(0.36, 0.26, 0.28),
			{"eye_sep": 0.55, "eye_y": 0.12, "eye_size": Vector2(0.15, 0.15), "eye_white": 1.0, "sclera": gold_eye, "eye_col": Color.html("1a1012"),
			"lid_bias": 0.25, "mouth_y": -0.42, "mouth_w": 0.3, "mouth_base": -0.1, "brow_off": 0.0, "brow_len": 0.16, "brow_thick": 0.04,
			"no_brow": 0.0}, 1.2, 0.85, 0.0, 0.9)
	# ---- arms: long, red-cream armored, domed ladybug shoulders; front arm drags Morrow
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.0, 1.62, 0.5 * side))
		_dome(a, Vector3(0.0, 0.08, 0.1 * side), 0.3, red, plum, side)
		a.lim(T(), [Vector3(0, 0, 0), Vector3(0.05, -0.5, 0.04 * side), Vector3(0.2, -0.95, 0.06 * side)], 0.16, 0.13, plum.lightened(0.04), 0.0, 7)
		a.blob(T(Vector3(0.1, -0.76, 0.06 * side), Vector3(0, 0, 14)), Vector3(0.16, 0.29, 0.18), red, 0.0, 0.7, 8, 5)       # forearm plate
		a.blob(T(Vector3(0.06, -0.62, 0.06 * side), Vector3(0, 0, 14)), Vector3(0.06, 0.12, 0.17), cream, 0.0, 0.8, 6, 4)    # wrap
		a.blob(T(Vector3(0.22, -1.02, 0.06 * side)), Vector3(0.15, 0.13, 0.13), plum.lightened(0.08), 0.0, 0.9, 7, 4)       # hand
		for dz in [-0.06, 0.0, 0.06]:
			a.lim(T(), [Vector3(0.3, -1.06, 0.06 * side + dz), Vector3(0.4, -1.14, 0.06 * side + dz * 1.4)], 0.035, 0.0, cream, 0.0, 4, false, false)
	b.sock("hand", "arm_f", Vector3(0.22, -1.02, 0.06))
	# ---- Morrow: spiked black mace, red dome-eye, thorny handle (parented to the front arm, swings and lags)
	var w: Prim = b.part("weapon", Vector3(0.22, 0.88, 0.56), "arm_f")
	w.lim(T(), [Vector3(-0.15, 0.3, 0), Vector3(0.3, 0.1, 0), Vector3(0.9, -0.15, 0)], 0.075, 0.06, brown, 0.0, 6)
	for k in range(4):
		var f := 0.15 + k * 0.2
		w.lim(T(), [Vector3(-0.15 + 1.05 * f, 0.3 - 0.45 * f, 0.06), Vector3(-0.15 + 1.05 * f + 0.04, 0.3 - 0.45 * f + 0.14, 0.14)], 0.03, 0.0, brown.darkened(0.2), 0.0, 4, false, false)
	var mc := Vector3(1.4, -0.34, 0)
	w.blob(T(mc), Vector3(0.62, 0.62, 0.62), plum.darkened(0.1), 0.0, 1.0, 11, 8)
	for sp in [Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(1, 0.3, 0.5), Vector3(-1, 0.4, 0.5), Vector3(0.3, 0.2, -1), Vector3(-0.4, -0.2, -1), Vector3(0.9, -0.5, -0.4),
			Vector3(-0.9, -0.5, 0.2), Vector3(0.4, 0.9, 0.5), Vector3(-0.4, 0.9, -0.5), Vector3(0.5, -0.9, 0.4), Vector3(-0.6, 0.5, -0.8), Vector3(0.9, 0.5, -0.3), Vector3(-0.2, -0.5, 0.9), Vector3(0.1, 0.2, 1), Vector3(-1, -0.2, -0.3)]:
		var d: Vector3 = sp.normalized()
		var base := mc + d * 0.58
		w.lim(T(), [base, base + d * 0.3], 0.11, 0.0, tan.darkened(0.1), 0.0, 5, true, false)
	w.blob(T(mc + Vector3(0.0, 0.0, 0.58)), Vector3(0.28, 0.28, 0.1), red, 1.0, 1.0, 9, 5)           # the red dome-eye
	w.blob(T(mc + Vector3(0.06, 0.06, 0.66)), Vector3(0.08, 0.08, 0.04), Color.html("ffd9c8"), 1.0, 1.0, 5, 3)
	b.sock("weapon_tip", "weapon", mc + Vector3(0.5, 0.0, 0.0))
	b.sock("weapon_base", "weapon", Vector3(0.3, 0.1, 0))
	# ---- olive tattered skirt/cape flaps at the back (lag)
	var e: Prim = b.part("extra", Vector3(-0.2, 1.0, 0))
	for k in range(5):
		var z := -0.3 + k * 0.15
		var ln := 0.9 - absf(z) * 0.5
		e.flat(T(), [Vector3(0, 0, z), Vector3(-0.1, -ln * 0.5, z), Vector3(-0.2, -ln, z)], 0.1, 0.07, 0.015, olive if k % 2 == 0 else olive.darkened(0.2), Vector3(1, 0, 0), 0.0, 0.0, true)
	e.flat(T(), [Vector3(0.02, 0.5, 0), Vector3(-0.2, 0.6, 0.0), Vector3(-0.5, 0.5, 0)], 0.3, 0.2, 0.02, plum.lightened(0.04), Vector3(0, 0, 1), 0.0, 0.0, true)   # hooded mantle
	b.cfg = {
		"scale": 1.0, "wa": -22.0, "sway": 1.2, "stride": 0.8, "bob": 0.5, "waddle": 0.6, "lag_weapon": 0.012, "lag_extra": 0.025,
		"armb_gain": 0.35, "guard_th": 35.0, "parry_th": 5.0,
		"style": {"strike_light": "chop", "strike_heavy": "overhead", "ability1": "overhead", "ability2": "spin", "laststand": "overhead", "grab": "charge"},
		"amp": {"strike_light": 0.8, "ability1": 1.1, "laststand": 1.25, "grab": 0.7},
		"fidget": {"head": PL.K(0, 0, 12, 0.03, 0.0), "arm_b": PL.K(0, 0, 18, 0.0, 0.03)},
	}
