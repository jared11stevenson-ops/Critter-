extends RefCounted
## ARUUN - "The Reacher": tall, elongated giraffe-beetle barbarian (240 cm). Dark charcoal carapace with deep-red patches, cream/bone wraps and
## charms, tattered olive hooded cloak and feathers, long red-orange spotted neck, small long mask-like head with red eye-patch markings and
## two long branching antlers arcing back, big red ladybug-spotted shoulder domes, red armor plates, digitigrade clawed legs, and the
## psionically bonded mace Morrow (studded dark sphere with a red core). Reference: tools/source_art/aruun_nerit_sheet.jpg (left half).
## Rig features: Morrow is a detachable part (throw / hover / recall), shell plates crack in 3 tiers (vertex-alpha 0.01/0.02/0.03).

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

## crack: glowing fracture lines on a plate, one set per tier (alpha 0.01 / 0.02 / 0.03 = shown at crack_level >= tier)
static func _cracks(m: Prim, c: Vector3, r: float, side: float) -> void:
	var tiers := [[0.01, [Vector3(0.1, 0.8, 0.6), Vector3(0.0, 0.4, 0.9), Vector3(0.15, 0.1, 0.95)]],
			[0.02, [Vector3(-0.5, 0.6, 0.6), Vector3(-0.2, 0.2, 0.95), Vector3(-0.45, -0.2, 0.85)]],
			[0.03, [Vector3(0.6, -0.1, 0.8), Vector3(0.35, -0.5, 0.85), Vector3(0.1, -0.85, 0.5)]]]
	for t in tiers:
		var pts: Array = []
		for d in t[1]:
			pts.append(c + Vector3(d.x, d.y, d.z * side).normalized() * r * 1.01)
		m.lim(T(), pts, 0.028, 0.02, Color.html("ffb070"), t[0], 3, false, false)

static func _dome(m: Prim, c: Vector3, r: float, red: Color, dark: Color, side: float) -> void:
	m.blob(T(c), Vector3(r, r * 0.88, r), red, 0.0, 1.0, 9, 6)
	for sp in [Vector3(0.1, 0.5, 0.82), Vector3(-0.5, 0.1, 0.8), Vector3(0.45, -0.25, 0.85)]:
		var d := Vector3(sp.x, sp.y, sp.z * side).normalized()
		m.blob(T(c + d * r * 0.97), Vector3(r * 0.3, r * 0.3, r * 0.12), dark, 0.0, 1.0, 6, 3)
	_cracks(m, c, r, side)

static func build(b) -> void:
	b.quality = 0.66
	var P: Dictionary = b.pal
	var char: Color = P["main"]; var red: Color = P["accent"]; var ember: Color = P["glow"]; var tan: Color = P["belly"]
	var cream := Color.html("dcc9a4"); var olive := Color.html("6f7a3c"); var brass := Color.html("c9a24a"); var brown := Color.html("5b4030")
	var neckc := Color.html("b4452a"); var horn := Color.html("c0482a"); var gold := Color.html("f2c230")
	# ---- legs: tall digitigrade, red armor over charcoal, cream wraps, clawed feet
	for leg in [["leg_f", 0.1, 0.3], ["leg_b", -0.12, -0.3]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 1.4, leg[2]))
		l.lim(T(), [Vector3(0, 0, 0), Vector3(0.3, -0.55, 0), Vector3(-0.05, -1.06, 0), Vector3(0.05, -1.34, 0)], 0.19, 0.08, char)
		l.blob(T(Vector3(0.12, -0.28, 0), Vector3(0, 0, 25)), Vector3(0.12, 0.34, 0.2), red, 0.0, 0.7, 8, 5)       # thigh plate
		l.blob(T(Vector3(0.3, -0.58, 0)), Vector3(0.15, 0.18, 0.18), red.darkened(0.1), 0.0, 0.8, 7, 4)            # knee
		l.ring(T(Vector3(0.0, -0.95, 0), Vector3(90, 0, 0)), 0.12, 0.035, cream, 0.0, 8, 3)
		l.blob(T(Vector3(0.18, -1.38, 0)), Vector3(0.3, 0.07, 0.17), char.lightened(0.05), 0.0, 0.8, 8, 4)
		for dz in [-0.08, 0.0, 0.08]:
			l.lim(T(), [Vector3(0.4, -1.38, dz), Vector3(0.62, -1.4, dz * 1.5)], 0.05, 0.0, cream, 0.0, 4, false, false)
	# ---- torso: charcoal carapace, red patches, cream wraps and charms, belt + brass medallion, long spotted neck
	var t: Prim = b.part("torso", Vector3(0, 1.4, 0))
	t.blob(T(Vector3(0, 0.12, 0)), Vector3(0.36, 0.26, 0.36), char, 0.0, 0.85, 9, 5)
	t.blob(T(Vector3(0.04, 0.55, 0)), Vector3(0.34, 0.36, 0.32), tan.darkened(0.2), 0.0, 0.9, 9, 5)
	t.blob(T(Vector3(-0.04, 0.95, 0)), Vector3(0.42, 0.32, 0.42), char, 0.0, 0.85, 10, 6)
	t.blob(T(Vector3(0.22, 0.9, 0.2), Vector3(0, 0, 15)), Vector3(0.1, 0.22, 0.12), red, 0.0, 0.8, 6, 4)          # breast plates
	t.blob(T(Vector3(0.22, 0.9, -0.2), Vector3(0, 0, 15)), Vector3(0.1, 0.22, 0.12), red, 0.0, 0.8, 6, 4)
	_cracks(t, Vector3(0.1, 0.88, 0.0), 0.3, 1.0)
	t.lim(T(), [Vector3(0.25, 1.15, 0.2), Vector3(0.32, 0.8, 0.0), Vector3(0.22, 0.5, -0.26)], 0.045, 0.045, cream, 0.0, 4, false, false)
	t.lim(T(), [Vector3(0.25, 1.15, -0.2), Vector3(0.34, 0.78, 0.0), Vector3(0.22, 0.48, 0.26)], 0.045, 0.045, cream, 0.0, 4, false, false)
	t.ring(T(Vector3(0.02, 0.28, 0), Vector3(90, 0, 0)), 0.35, 0.055, red, 0.0, 12, 4)
	t.blob(T(Vector3(0.4, 0.26, 0), Vector3(0, 90, 0)), Vector3(0.15, 0.15, 0.04), brass, 0.0, 1.0, 9, 3)
	t.blob(T(Vector3(0.44, 0.26, 0), Vector3(0, 90, 0)), Vector3(0.07, 0.07, 0.03), red, 0.3, 1.0, 7, 3)
	for dz in [-0.16, 0.0, 0.16]:
		t.flat(T(), [Vector3(0.38, 0.18, dz), Vector3(0.4, -0.15, dz), Vector3(0.38, -0.5, dz * 1.1)], 0.07, 0.04, 0.015, cream, Vector3(0, 0, 1), 0.0, 0.0, true)
	t.blob(T(Vector3(0.38, 0.0, 0.2)), Vector3(0.05, 0.08, 0.04), cream, 0.0, 1.0, 5, 3)                          # bone charm
	t.lim(T(), [Vector3(0.0, 1.15, 0), Vector3(0.12, 1.5, 0), Vector3(0.3, 1.95, 0), Vector3(0.45, 2.3, 0)], 0.17, 0.11, neckc, 0.0, 8)   # neck
	for k in range(4):
		var f := 0.15 + k * 0.22
		for sd in [-1.0, 1.0]:
			t.blob(T(Vector3(0.12 + 0.33 * f * 1.6, 1.15 + f * 1.1, 0.12 * sd)), Vector3(0.055, 0.08, 0.03), char, 0.0, 1.0, 5, 3)
	# ---- head: small, long mask-like beetle face, red eye-patches (face shader), pale leaf mane, long antlers arcing back
	var h: Prim = b.part("head", Vector3(0.5, 3.75, 0))
	h.blob(T(Vector3(0.12, 0.05, 0)), Vector3(0.28, 0.2, 0.2), char.lightened(0.06), 0.0, 0.9, 10, 6)
	h.blob(T(Vector3(0.44, -0.07, 0), Vector3(0, 0, -10)), Vector3(0.32, 0.13, 0.14), char.lightened(0.1), 0.0, 0.9, 9, 5)
	for s in [-1.0, 1.0]:
		var ant := [Vector3(0.0, 0.17, 0.1 * s), Vector3(-0.14, 0.45, 0.25 * s), Vector3(-0.42, 0.7, 0.42 * s), Vector3(-0.85, 0.78, 0.5 * s)]
		h.lim(T(), ant, 0.1, 0.03, horn, 0.0, 5, true, false)
		h.lim(T(), [ant[1], Vector3(0.05, 0.7, 0.4 * s), Vector3(0.18, 0.92, 0.5 * s)], 0.045, 0.012, horn, 0.0, 4, false, false)
		h.lim(T(), [ant[2], Vector3(-0.4, 1.05, 0.52 * s), Vector3(-0.3, 1.3, 0.56 * s)], 0.04, 0.012, horn, 0.0, 4, false, false)
		h.lim(T(), [ant[2], Vector3(-0.8, 0.5, 0.5 * s)], 0.04, 0.0, horn, 0.0, 4, false, false)
		h.flat(T(), [Vector3(-0.12, 0.0, 0.16 * s), Vector3(-0.4, -0.05, 0.3 * s), Vector3(-0.72, -0.28, 0.26 * s)], 0.12, 0.05, 0.015, cream.lightened(0.1), Vector3(0, 1, 0), 0.0, 0.2, true)
		h.flat(T(), [Vector3(-0.1, 0.12, 0.14 * s), Vector3(-0.36, 0.2, 0.26 * s), Vector3(-0.6, 0.1, 0.24 * s)], 0.09, 0.04, 0.015, olive.lightened(0.18), Vector3(0, 1, 0), 0.0, 0.2, true)
	b.sock("head", "head", Vector3(0.12, 0.05, 0) * 1.5)
	b.set_face(Vector3(0.12, 0.05, 0) * 1.5, Vector3(0.28, 0.2, 0.2) * 1.5,
			{"eye_sep": 0.55, "eye_y": 0.16, "eye_size": Vector2(0.13, 0.13), "eye_white": 1.0, "sclera": gold, "eye_col": Color.html("140a0c"),
			"lid_bias": 0.3, "mark": 1.0, "mark_col": Color.html("a82a22"), "accent": gold, "mouth_y": -0.5, "mouth_w": 0.34, "mouth_base": -0.15,
			"brow_off": 0.0, "brow_len": 0.14, "brow_thick": 0.045}, 1.25, 0.95, 0.0, 0.9)
	# ---- arms: long, wrapped, red-plated, domed ladybug shoulders (cracking)
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.0, 2.3, 0.56 * side))
		_dome(a, Vector3(0.0, 0.06, 0.08 * side), 0.32, red, char, side)
		a.lim(T(), [Vector3(0, 0, 0), Vector3(0.04, -0.55, 0.04 * side), Vector3(0.18, -1.05, 0.06 * side)], 0.14, 0.11, char.lightened(0.04), 0.0, 7)
		a.blob(T(Vector3(0.1, -0.82, 0.06 * side), Vector3(0, 0, 12)), Vector3(0.14, 0.3, 0.17), red, 0.0, 0.7, 8, 5)
		a.ring(T(Vector3(0.05, -0.55, 0.05 * side), Vector3(90, 0, 10)), 0.13, 0.04, cream, 0.0, 8, 3)
		a.ring(T(Vector3(0.09, -0.45, 0.05 * side), Vector3(90, 0, 10)), 0.13, 0.04, cream, 0.0, 8, 3)
		a.blob(T(Vector3(0.2, -1.12, 0.06 * side)), Vector3(0.15, 0.13, 0.13), char.lightened(0.1), 0.0, 0.9, 7, 4)
		for dz in [-0.06, 0.0, 0.06]:
			a.lim(T(), [Vector3(0.28, -1.16, 0.06 * side + dz), Vector3(0.4, -1.26, 0.06 * side + dz * 1.4)], 0.035, 0.0, cream, 0.0, 4, false, false)
	b.sock("hand", "arm_f", Vector3(0.2, -0.9, 0.06))
	# ---- Morrow (detachable): studded charcoal sphere with a red core eye on a thorny haft
	var w: Prim = b.part("weapon", Vector3(0.2, 1.18, 0.62), "arm_f")
	var dir := Vector3(0.78, -0.3, 0).normalized()
	w.lim(T(), [dir * -0.35, dir * 0.6, dir * 1.35], 0.07, 0.055, brown, 0.0, 6)
	for k in range(4):
		var f := 0.3 + k * 0.28
		var up := Vector3(0.3, 0.95, 0).normalized()
		w.lim(T(), [dir * f + up * 0.04, dir * f + up * 0.15 + Vector3(0, 0, 0.06)], 0.03, 0.0, brown.darkened(0.2), 0.0, 4, false, false)
	var mc := dir * 1.65
	w.blob(T(mc), Vector3(0.4, 0.4, 0.4), char.darkened(0.05), 0.0, 1.0, 10, 7)
	var sp_dirs := [Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(1, 0.2, 0.5), Vector3(-1, 0.4, 0.5), Vector3(0.3, 0.2, -1), Vector3(-0.4, -0.2, -1), Vector3(0.9, -0.5, -0.4),
			Vector3(-0.9, -0.5, 0.2), Vector3(0.4, 0.9, 0.5), Vector3(-0.4, 0.9, -0.5), Vector3(0.5, -0.9, 0.4), Vector3(-0.6, 0.5, -0.8), Vector3(0.9, 0.5, -0.3), Vector3(0.1, 0.2, 1)]
	for sp in sp_dirs:
		var d: Vector3 = sp.normalized()
		var base := mc + d * 0.38
		w.lim(T(), [base, base + d * 0.2], 0.075, 0.0, tan.darkened(0.05), 0.0, 5, true, false)
		w.blob(T(base), Vector3(0.05, 0.05, 0.05), brown, 0.0, 1.0, 4, 3)
	w.blob(T(mc + Vector3(0.0, 0.0, 0.37)), Vector3(0.2, 0.2, 0.08), red, 1.0, 1.0, 9, 5)           # psionic red core (emissive)
	w.blob(T(mc + Vector3(0.04, 0.04, 0.43)), Vector3(0.06, 0.06, 0.03), Color.html("ffd9c8"), 1.0, 1.0, 5, 3)
	w.blob(T(mc + Vector3(0.0, 0.0, -0.37)), Vector3(0.2, 0.2, 0.08), red, 1.0, 1.0, 9, 5)
	b.sock("weapon_tip", "weapon", mc + Vector3(0.4, 0.0, 0.0))
	b.sock("weapon_base", "weapon", dir * 0.3)
	# ---- hooded tattered olive cloak + feathers on the back (lags)
	var e: Prim = b.part("extra", Vector3(-0.1, 2.5, 0))
	e.blob(T(Vector3(-0.12, 0.1, 0), Vector3(0, 0, 10)), Vector3(0.34, 0.3, 0.52), char.darkened(0.05), 0.0, 0.8, 9, 5)       # hood behind the neck
	e.blob(T(Vector3(-0.2, -0.3, 0), Vector3(0, 0, 8)), Vector3(0.22, 0.6, 0.55), olive.darkened(0.15), 0.0, 0.8, 9, 5)
	for k in range(9):
		var z := -0.48 + k * 0.12
		var ln := 1.2 - absf(z) * 0.5 + 0.2 * (k % 2)
		e.flat(T(), [Vector3(-0.2, -0.2, z), Vector3(-0.3, -0.2 - ln * 0.5, z), Vector3(-0.38, -0.2 - ln, z)], 0.1, 0.07, 0.015, olive if k % 2 == 0 else olive.lightened(0.12), Vector3(1, 0, 0), 0.0, 0.0, true)
	for k in range(3):
		e.flat(T(), [Vector3(-0.3, -0.1, -0.2 + k * 0.2), Vector3(-0.5, -0.5 - k * 0.1, -0.2 + k * 0.2), Vector3(-0.55, -1.0, -0.2 + k * 0.2)], 0.07, 0.04, 0.015, cream, Vector3(1, 0, 0), 0.0, 0.0, true)
	# ---- proportion pass (brief: broad-shouldered hero, long neck, small beetle head, ~4.5 heads): shorter legs/arms, larger head
	var sc := {"leg_f": Vector3(1.35, 0.72, 1.35), "leg_b": Vector3(1.35, 0.72, 1.35), "torso": Vector3(1.25, 0.8, 1.3), "head": Vector3.ONE * 1.5,
			"arm_f": Vector3(1.25, 0.8, 1.25), "arm_b": Vector3(1.25, 0.8, 1.25), "extra": Vector3(1.2, 0.8, 1.2)}
	for pn in sc:
		(b.parts[pn]["mb"] as Prim).scale_all(sc[pn])
	b.parts["leg_f"]["pos"] = Vector3(0.1, 1.0, 0.3); b.parts["leg_b"]["pos"] = Vector3(-0.12, 1.0, -0.3)
	b.parts["torso"]["pos"] = Vector3(0, 1.0, 0)
	b.parts["head"]["pos"] = Vector3(0.5, 2.95, 0)
	b.parts["arm_f"]["pos"] = Vector3(0.0, 1.78, 0.74); b.parts["arm_b"]["pos"] = Vector3(0.0, 1.78, -0.74)
	b.parts["weapon"]["pos"] = Vector3(0.25, 0.9, 0.8)
	b.parts["extra"]["pos"] = Vector3(-0.1, 2.0, 0)
	b.cfg = {
		"scale": 1.0, "wa": -17.0, "sway": 1.2, "stride": 0.8, "bob": 0.5, "waddle": 0.5, "lag_weapon": 0.01, "lag_extra": 0.025,
		"armb_gain": 0.35, "guard_th": 35.0, "parry_th": 5.0, "detach": ["weapon"],
		"detach_act": {"ability1": {"part": "weapon", "mode": "goto", "out": Vector3(4.0, 1.4, 0.5), "spin": 540.0, "hold": 8},
				"ability2": {"part": "weapon", "mode": "goto", "out": Vector3(2.2, 3.4, 0.5), "spin": 120.0, "hold": 24}},
		"style": {"strike_light": "chop", "strike_heavy": "overhead", "ability1": "thrust", "ability2": "overhead", "laststand": "roar", "grab": "charge"},
		"amp": {"strike_light": 0.8, "ability1": 1.0, "laststand": 1.0, "grab": 0.7},
		"fidget": {"head": PL.K(0, 0, 12, 0.03, 0.0), "arm_b": PL.K(0, 0, 18, 0.0, 0.03)},
	}
