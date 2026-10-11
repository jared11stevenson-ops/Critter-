extends RefCounted
## MOLLUSK - "The Weight of Tomorrow" (Rainward). Brief: huge calm giant-African-snail rescue hero: thick banded shell carrying carved journey marks
## and rescue-crew patches, soft heavy body on a strong trailing foot, stalk eyes with kind tired faces, a high-vis orange rescue vest/harness with
## straps, a small forklift-fork prop on the harness. Palette: shell amber/brown bands, soft olive-grey body, high-vis orange accent.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func build(b) -> void:
	b.quality = 0.7
	var P: Dictionary = b.pal
	var body: Color = P["main"]; var orange: Color = P["accent"]; var glow: Color = P["glow"]; var pale: Color = P["belly"]
	var amber := Color.html("94623a"); var brown := Color.html("4a2616"); var cream := Color.html("e8d3a2"); var dark := Color.html("3a2a22"); var steel := Color.html("8b929b")
	# ---- two stubby legs under the heavy front (the rest of the weight rides on the foot)
	for leg in [["leg_f", 0.25, 0.3], ["leg_b", -0.05, -0.3]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.5, leg[2]))
		l.blob(T(Vector3(0.05, -0.28, 0)), Vector3(0.34, 0.24, 0.26), body.darkened(0.08), 0.0, 0.85, 8, 5)
		l.blob(T(Vector3(0.3, -0.38, 0)), Vector3(0.18, 0.1, 0.2), body.darkened(0.2), 0.0, 0.8, 6, 3)
	# ---- torso: heavy soft body leaning forward, long strong foot trailing behind, vest + harness
	var t: Prim = b.part("torso", Vector3(0, 0.5, 0))
	t.blob(T(Vector3(0.05, 0.5, 0)), Vector3(0.6, 0.66, 0.54), body, 0.0, 0.88, 11, 8)
	t.blob(T(Vector3(0.28, 0.55, 0)), Vector3(0.34, 0.5, 0.42), pale, 0.0, 0.9, 8, 6)
	t.blob(T(Vector3(-0.8, 0.0, 0)), Vector3(1.0, 0.26, 0.5), body.darkened(0.06), 0.0, 0.85, 11, 5)                 # the foot slab
	t.lim(T(), [Vector3(-1.4, 0.0, 0), Vector3(-2.1, -0.02, 0), Vector3(-2.7, -0.06, 0)], 0.38, 0.0, body.darkened(0.1), 0.0, 8, false, false)   # tapering tail
	t.blob(T(Vector3(0.15, 0.62, 0), Vector3(0, 0, 4)), Vector3(0.52, 0.5, 0.58), orange, 0.0, 0.8, 10, 6)           # high-vis vest
	for k in range(2):
		t.ring(T(Vector3(0.12, 0.45 + k * 0.28, 0), Vector3(90, 0, 0)), 0.58, 0.035, Color.html("f4f0e0"), 0.15, 12, 3)   # reflective stripes
	t.lim(T(), [Vector3(0.1, 1.1, 0.35), Vector3(0.45, 0.65, 0.0), Vector3(0.2, 0.2, -0.4)], 0.045, 0.045, dark, 0.0, 4, false, false)  # harness straps
	t.lim(T(), [Vector3(0.1, 1.1, -0.35), Vector3(0.45, 0.6, 0.0), Vector3(0.2, 0.2, 0.4)], 0.045, 0.045, dark, 0.0, 4, false, false)
	t.blob(T(Vector3(0.46, 0.65, 0.0), Vector3(0, 90, 0)), Vector3(0.1, 0.1, 0.03), steel, 0.0, 1.0, 7, 3)           # buckle
	t.blob(T(Vector3(0.55, 0.45, 0.25)), Vector3(0.07, 0.1, 0.06), glow, 0.5, 1.0, 6, 4)                              # rescue light
	# ---- head: gentle peaked head, two long stalk eyes (tired lids), small downturned mouth on the face plate
	var h: Prim = b.part("head", Vector3(0.4, 1.75, 0))
	h.blob(T(Vector3(0.1, 0.1, 0)), Vector3(0.36, 0.34, 0.32), body.lightened(0.04), 0.0, 0.9, 10, 7)
	h.blob(T(Vector3(0.24, -0.2, 0), Vector3(0, 0, -10)), Vector3(0.16, 0.09, 0.18), pale, 0.0, 0.9, 7, 4)
	for s in [-1.0, 1.0]:
		var st := [Vector3(0.05, 0.3, 0.1 * s), Vector3(0.1, 0.7, 0.16 * s), Vector3(0.18, 1.1, 0.2 * s), Vector3(0.24, 1.4, 0.22 * s)]
		h.lim(T(), st, 0.075, 0.055, body.lightened(0.06), 0.0, 6)
		h.blob(T(Vector3(0.26, 1.46, 0.22 * s)), Vector3(0.14, 0.14, 0.14), Color.html("f6efe0"), 0.0, 1.0, 8, 5)
		h.blob(T(Vector3(0.37, 1.44, 0.22 * s)), Vector3(0.06, 0.07, 0.07), Color.html("140c0a"), 0.0, 1.0, 5, 3)
		h.blob(T(Vector3(0.27, 1.53, 0.22 * s), Vector3(0, 0, -12)), Vector3(0.16, 0.08, 0.16), body.darkened(0.12), 0.0, 0.9, 7, 3)    # heavy tired eyelid
		h.lim(T(), [Vector3(0.3, -0.18, 0.2 * s), Vector3(0.4, -0.34, 0.24 * s)], 0.03, 0.015, body, 0.0, 4, true, true)
	b.sock("head", "head", Vector3(0.1, 0.1, 0))
	b.set_face(Vector3(0.1, 0.1, 0), Vector3(0.36, 0.34, 0.32),
			{"eye_size": Vector2(0.001, 0.001), "eye_sep": 0.38, "eye_y": 0.18, "brow_off": 0.0, "brow_len": 0.22, "brow_thick": 0.04, "mouth_y": -0.15, "mouth_w": 0.3, "mouth_base": -0.35}, 0.95, 0.7, -0.1, 0.9)
	# ---- arms: big stout, orange vest straps; fists
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.15, 1.5, 0.62 * side))
		a.blob(T(Vector3(0, 0.0, 0.04 * side)), Vector3(0.25, 0.23, 0.25), orange.darkened(0.05), 0.0, 0.9, 8, 5)
		a.lim(T(), [Vector3(0, -0.05, 0), Vector3(0.1, -0.5, 0.06 * side), Vector3(0.3, -0.85, 0.1 * side)], 0.2, 0.16, body.darkened(0.04), 0.0, 7)
		a.ring(T(Vector3(0.12, -0.45, 0.06 * side), Vector3(90, 0, 14)), 0.18, 0.04, steel, 0.0, 8, 3)
		a.blob(T(Vector3(0.34, -0.98, 0.1 * side)), Vector3(0.22, 0.19, 0.2), body.darkened(0.12), 0.0, 0.9, 7, 4)
	var hand := Vector3(0.34, -0.98, 0.1)
	b.sock("weapon_tip", "arm_f", hand + Vector3(0.3, 0, 0))
	b.sock("weapon_base", "arm_f", hand)
	b.sock("hand", "arm_f", hand)
	# ---- forklift-fork prop + hanging rescue tags on the harness (lag)
	var w: Prim = b.part("weapon", Vector3(0.35, 1.05, 0.5))
	w.lim(T(), [Vector3(0, 0, 0), Vector3(0.0, -0.15, 0.02)], 0.02, 0.02, dark, 0.0, 3, false, false)
	w.blob(T(Vector3(0.0, -0.2, 0.02)), Vector3(0.12, 0.04, 0.09), steel, 0.0, 0.7, 6, 3)
	for z in [-0.06, 0.06]:
		w.lim(T(), [Vector3(0.0, -0.2, 0.02 + z), Vector3(0.0, -0.75, 0.02 + z)], 0.035, 0.012, steel, 0.0, 4, false, true)    # fork tines
	for k in range(2):
		w.blob(T(Vector3(0.14, -0.15 - k * 0.2, -0.1)), Vector3(0.05, 0.08, 0.04), [glow, orange][k], 0.3, 1.0, 5, 3)
	# ---- the giant banded shell: amber/brown bands, spiral crown, carved journey marks, rescue-crew patches
	var e: Prim = b.part("extra", Vector3(-0.6, 1.25, 0))
	e.blob(T(Vector3(0, 0.2, 0), Vector3(0, 0, -10)), Vector3(1.05, 1.0, 0.76), amber, 0.0, 0.95, 14, 10)
	for sdz in [-1.0, 1.0]:
		for rr in [0.3, 0.52, 0.74, 0.92]:
			var zz: float = 0.76 * sqrt(maxf(0.0, 1.0 - pow(rr / 1.05, 2.0))) * 0.99 * sdz
			e.ring(T(Vector3(0, 0.2, zz)), rr, 0.05, brown if int(rr * 10) % 2 == 0 else cream, 0.0, 14, 3, 0.6)   # growth bands
		e.blob(T(Vector3(0, 0.2, 0.76 * sdz)), Vector3(0.12, 0.12, 0.07), brown, 0.0, 1.0, 6, 3)                   # spiral apex
		for k in range(5):   # carved journey tick marks
			var a := 0.5 + k * 0.5
			e.lim(T(), [Vector3(cos(a) * 0.55, 0.2 + sin(a) * 0.55, 0.77 * sdz), Vector3(cos(a) * 0.7, 0.2 + sin(a) * 0.7, 0.75 * sdz)], 0.022, 0.022, dark, 0.0, 3, false, false)
		e.blob(T(Vector3(0.45, -0.25, 0.74 * sdz)), Vector3(0.14, 0.12, 0.03), orange, 0.15, 1.0, 5, 3)             # rescue-crew patch
		e.blob(T(Vector3(0.45, -0.25, 0.765 * sdz)), Vector3(0.07, 0.015, 0.02), Color.html("f4f0e0"), 0.2, 1.0, 4, 3)
	b.cfg = {
		"scale": 1.0, "wa": -40.0, "sway": 1.0, "stride": 0.55, "bob": 0.3, "waddle": 0.8, "lag_weapon": 0.03, "lag_extra": 0.006, "lag_extra_x": 0.5,
		"armb_gain": 0.3, "guard_th": 20.0, "parry_th": 0.0, "blink_scale": 1.0,
		"style": {"strike_light": "punch", "strike_heavy": "overhead", "ability1": "stance", "ability2": "stance", "laststand": "roar", "grab": "charge"},
		"amp": {"strike_light": 0.7, "strike_heavy": 0.9, "grab": 0.6},
		"fidget": {"head": PL.K(0, 0, 8, 0.0, 0.0), "torso": PL.K(0, 0, 0, 0, 0, 0, 1.03, 1.03, 1.03)},
	}
