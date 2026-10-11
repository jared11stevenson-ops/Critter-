extends RefCounted
## ZEPHYR - "The Nectar Seeker" (Briarwild). Brief: small quick hovering silhouette, fuzzy moth thorax, long coiled proboscis worn like a scarf,
## feathered antenna flags, pointed leaf ears, courier satchel + message tubes, petal skirt, flower crown, four fast-looking wings.
## Palette: olive-brown fuzz, orange underwing, nectar-magenta accent, pollen-gold glow.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _fuzz(m: Prim, c: Vector3, r: Vector3, col: Color, n: int, ln: float, seed_off: float = 0.0) -> void:
	for i in range(n):
		var a := float(i) * 2.399 + seed_off
		var y := 1.0 - 2.0 * (float(i) + 0.5) / n
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var d := Vector3(cos(a) * rr, y, sin(a) * rr)
		var p := c + Vector3(d.x * r.x, d.y * r.y, d.z * r.z)
		m.lim(T(), [p, p + d * ln], 0.05, 0.0, col, 0.0, 4, true, false)

static func _wing(m: Prim, c: Vector3, ln: float, wid: float, tilt: float, sweep: float, top: Color, under: Color, spot: Color, z: float) -> void:
	var xf := T(c, Vector3(tilt * signf(z), 0, sweep))
	m.blob(xf, Vector3(0.012, ln, wid), top, 0.0, 1.0, 8, 6)
	m.blob(xf * T(Vector3(-0.012, -ln * 0.25, 0)), Vector3(0.008, ln * 0.7, wid * 0.8), under, 0.0, 1.0, 7, 5)    # orange underwing showing through
	for k in range(3):
		m.blob(xf * T(Vector3(0.015, (-0.4 + k * 0.35) * ln, (0.35 - 0.25 * k) * wid * signf(z))), Vector3(0.01, 0.07 * ln, 0.08 * wid), spot, 0.0, 1.0, 5, 3)
	m.lim(xf, [Vector3(0.014, ln * 0.95, 0), Vector3(0.014, -ln * 0.95, 0)], 0.012, 0.008, under.lightened(0.2), 1.0, 3, false, false)

static func build(b) -> void:
	b.quality = 0.8
	var P: Dictionary = b.pal
	var fuzz: Color = P["main"]; var mag: Color = P["accent"]; var pollen: Color = P["glow"]; var cream: Color = P["belly"]
	var orange := Color.html("e8873a"); var dark := Color.html("3a2a22"); var olive := Color.html("6e6a3a"); var wood := Color.html("6a4a30"); var brass := Color.html("c9a24a")
	b.glass = ["extra"]
	# ---- legs: tiny dangling bird-like legs (it hovers)
	for leg in [["leg_f", 0.1, 0.14], ["leg_b", -0.08, -0.14]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.8, leg[2]))
		l.lim(T(), [Vector3(0, 0, 0), Vector3(0.1, -0.3, 0), Vector3(-0.02, -0.62, 0)], 0.06, 0.035, dark, 0.0, 5)
		for dz in [-0.04, 0.0, 0.04]:
			l.lim(T(), [Vector3(-0.02, -0.64, dz), Vector3(0.14, -0.7, dz * 1.6)], 0.022, 0.0, dark, 0.0, 4, true, false)
	# ---- torso: fuzzy round moth thorax, banded abdomen, magenta petal skirt, courier harness
	var t: Prim = b.part("torso", Vector3(0, 0.8, 0))
	t.blob(T(Vector3(0.05, 0.35, 0)), Vector3(0.38, 0.38, 0.34), fuzz, 0.0, 0.95, 10, 7)
	_fuzz(t, Vector3(0.05, 0.35, 0), Vector3(0.36, 0.36, 0.32), fuzz.lightened(0.08), 16, 0.12)
	t.blob(T(Vector3(0.12, 0.3, 0)), Vector3(0.22, 0.26, 0.28), cream, 0.0, 0.9, 8, 5)
	t.lim(T(), [Vector3(-0.2, 0.15, 0), Vector3(-0.6, 0.0, 0), Vector3(-0.95, -0.12, 0)], 0.2, 0.1, olive, 0.0, 7)       # abdomen
	for k in range(3):
		t.ring(T(Vector3(-0.35 - 0.2 * k, 0.07 - 0.04 * k, 0), Vector3(0, 90, 0)), 0.16 - 0.02 * k, 0.03, orange, 0.0, 9, 3)
	for k in range(3):   # fan tail tuft
		t.flat(T(), [Vector3(-0.95, -0.12, 0), Vector3(-1.15, -0.1 + 0.05 * k, (k - 1) * 0.12), Vector3(-1.3, -0.05 + 0.1 * k, (k - 1) * 0.2)], 0.07, 0.04, 0.015, fuzz.lightened(0.15), Vector3(0, 1, 0), 0.0, 0.3, true)
	for k in range(9):   # petal skirt
		var a := float(k) / 9.0 * TAU
		var x := cos(a) * 0.3
		var z := sin(a) * 0.3
		t.flat(T(), [Vector3(x, 0.05, z), Vector3(x * 1.3, -0.12, z * 1.3), Vector3(x * 1.5, -0.3, z * 1.5)], 0.13, 0.08, 0.015, mag if k % 2 == 0 else mag.lightened(0.2), Vector3(-sin(a), 0, cos(a)), 0.0, 0.4, true)
	t.lim(T(), [Vector3(0.15, 0.7, 0.28), Vector3(0.32, 0.35, 0.0), Vector3(0.15, 0.0, -0.28)], 0.035, 0.035, wood, 0.0, 4, false, false)    # bandolier
	for k in range(3):   # message tubes in the bandolier
		t.lim(T(), [Vector3(0.3 - 0.02 * k, 0.5 - k * 0.14, 0.08 - 0.06 * k), Vector3(0.3 - 0.02 * k, 0.4 - k * 0.14, 0.08 - 0.06 * k)], 0.045, 0.045, brass, 0.0, 6)
	# proboscis worn as a scarf: coiled rings around the neck + a free curled tip
	for k in range(4):
		t.ring(T(Vector3(0.12 + 0.01 * k, 0.74 + k * 0.05, 0), Vector3(80, 0, 0)), 0.22 - 0.01 * k, 0.05, orange if k % 2 == 0 else mag, 0.0, 12, 4)
	t.lim(T(), [Vector3(0.3, 0.8, 0.1), Vector3(0.42, 0.55, 0.12), Vector3(0.46, 0.25, 0.1), Vector3(0.38, 0.1, 0.12)], 0.05, 0.015, orange, 0.0, 5, false, true)
	# ---- head: round, huge dark compound eyes (face plate), feathered antenna flags, leaf ears, flower crown
	var h: Prim = b.part("head", Vector3(0.12, 1.65, 0))
	h.blob(T(Vector3(0.08, 0.2, 0)), Vector3(0.36, 0.34, 0.34), fuzz.lightened(0.05), 0.0, 0.9, 10, 7)
	_fuzz(h, Vector3(0.08, 0.2, 0), Vector3(0.34, 0.32, 0.32), fuzz.lightened(0.1), 10, 0.1)
	for s in [-1.0, 1.0]:
		var ant := [Vector3(0.1, 0.5, 0.1 * s), Vector3(0.0, 0.9, 0.22 * s), Vector3(-0.1, 1.25, 0.3 * s)]
		h.lim(T(), ant, 0.025, 0.015, dark, 0.0, 4, true, false)
		h.flat(T(), [ant[0], ant[1], ant[2] + Vector3(-0.05, 0.1, 0.05 * s)], 0.14, 0.05, 0.012, mag, Vector3(0, 0, 1), 0.2, 0.5, true, 4)      # feathered flag vane
		h.flat(T(), [ant[1], ant[1] + Vector3(-0.15, 0.1, 0.1 * s)], 0.07, 0.03, 0.012, pollen, Vector3(0, 0, 1), 0.3, 0.2, true, 3)
		h.flat(T(), [Vector3(0.0, 0.25, 0.3 * s), Vector3(-0.12, 0.35, 0.55 * s), Vector3(-0.25, 0.5, 0.75 * s)], 0.1, 0.05, 0.012, olive.lightened(0.1), Vector3(0, 1, 0), 0.0, 0.5, true, 4)   # pointed leaf ears
	for k in range(6):   # flower crown
		var a := float(k) / 6.0 * TAU
		h.blob(T(Vector3(0.0 + cos(a) * 0.3, 0.52, sin(a) * 0.3), Vector3(0, 0, 0)), Vector3(0.07, 0.06, 0.07), mag if k % 2 == 0 else cream, 0.15, 1.0, 5, 3)
	b.sock("head", "head", Vector3(0.08, 0.2, 0))
	b.set_face(Vector3(0.08, 0.2, 0), Vector3(0.36, 0.34, 0.34),
			{"eye_sep": 0.42, "eye_y": 0.05, "eye_size": Vector2(0.24, 0.24), "eye_white": 1.0, "sclera": Color.html("140a0c"), "eye_col": mag,
			"mouth_y": -0.5, "mouth_w": 0.1, "mouth_base": 0.3, "brow_off": 0.1, "brow_len": 0.17, "brow_thick": 0.03, "accent": pollen, "ringed": 1.0}, 1.1, 0.75, 0.0, 0.9)
	# ---- arms: thin; front hand holds a short pollen wand
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.05, 1.45, 0.34 * side))
		a.blob(T(), Vector3(0.11, 0.1, 0.11), fuzz, 0.0, 1.0, 6, 4)
		a.lim(T(), [Vector3(0, 0, 0), Vector3(-0.06, -0.4, 0.04 * side), Vector3(0.14, -0.78, 0.06 * side)], 0.06, 0.045, dark, 0.0, 5)
		a.blob(T(Vector3(0.16, -0.84, 0.07 * side)), Vector3(0.08, 0.09, 0.07), dark.lightened(0.05), 0.0, 1.0, 6, 3)
		for dz in [-0.03, 0.0, 0.03]:
			a.lim(T(), [Vector3(0.2, -0.88, 0.07 * side + dz), Vector3(0.28, -0.98, 0.08 * side + dz * 1.4)], 0.018, 0.0, dark, 0.0, 4, false, false)
	var hand := Vector3(0.16, -0.84, 0.07)
	var dir := Vector3(0.5, 0.86, 0).normalized()
	var af: Prim = b.parts["arm_f"]["mb"]
	af.lim(T(), [hand - dir * 0.4, hand + dir * 0.6, hand + dir * 1.3], 0.03, 0.0, wood, 0.0, 5, true, false)
	af.blob(T(hand + dir * 1.2), Vector3(0.07, 0.07, 0.07), pollen, 0.9, 1.0, 6, 4)
	b.sock("weapon_tip", "arm_f", hand + dir * 1.3)
	b.sock("weapon_base", "arm_f", hand + dir * 0.3)
	b.sock("hand", "arm_f", hand)
	# ---- courier satchel + tubes on the hip (lag)
	var w: Prim = b.part("weapon", Vector3(-0.1, 0.95, 0.38))
	w.blob(T(Vector3(0, -0.15, 0.02)), Vector3(0.22, 0.2, 0.1), wood, 0.0, 0.7, 8, 5)
	w.blob(T(Vector3(0.0, -0.05, 0.1)), Vector3(0.2, 0.09, 0.03), mag, 0.0, 0.7, 6, 3)
	w.blob(T(Vector3(0.0, -0.05, 0.13)), Vector3(0.045, 0.045, 0.02), brass, 0.0, 1.0, 5, 3)
	for k in range(3):
		w.lim(T(), [Vector3(-0.12 + k * 0.08, -0.3, -0.03), Vector3(-0.1 + k * 0.08, -0.55, -0.03)], 0.035, 0.035, brass, 0.0, 6)
	# ---- four wings: big olive-brown forewings with orange underwing, smaller hindwings; fast flap
	var e: Prim = b.part("extra", Vector3(-0.2, 1.4, 0))
	var wt := Color.html("8a7a46"); var spot := Color.html("f3d9a0")
	for z in [0.1, -0.1]:
		_wing(e, Vector3(-0.15, 0.25, z * 4.0), 0.85, 0.34, 40.0, 38.0, wt, orange, spot, z)
		_wing(e, Vector3(-0.2, -0.45, z * 4.5), 0.65, 0.26, 20.0, -14.0, wt.darkened(0.08), orange.lightened(0.1), spot, z)
	b.cfg = {
		"scale": 1.0, "wa": -63.0, "sway": 2.0, "stride": 1.2, "bob": 0.5, "waddle": 0.3, "lag_weapon": 0.05, "lag_extra": 0.012, "flap": 9.0, "flap_hz": 22.0,
		"armb_gain": 0.5, "guard_th": 40.0, "parry_th": 5.0, "blink_scale": 0.8, "hover": 0.3,
		"style": {"strike_light": "thrust", "strike_heavy": "leap", "ability1": "leap", "ability2": "stance", "laststand": "spin", "grab": "grab"},
		"amp": {"strike_light": 0.85, "strike_heavy": 0.9, "laststand": 1.2},
		"fidget": {"head": PL.K(0, 0, 14, 0.02, 0.0), "arm_b": PL.K(0, 0, 40, 0.0, 0.03)},
	}
