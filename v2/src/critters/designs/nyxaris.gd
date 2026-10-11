extends RefCounted
## NYXARIS - "The Frostbloom Weaver": yeti-crab / black-widow / dragon-fruit-flower sentinel (200 cm). Black chitin body with glowing
## pink/orange veins, white fluffy fur ruffs, a furry cream face with pink eyes and fangs under a pink crest, a fan of icy blue-pink crystal
## spikes on her back, two huge black furred claws with icy blades, six spidery black legs, long arching antennae with dangling pink
## teardrop gems and silk strands. Reference: tools/source_art/nyxaris_sheet.png (concept sheet, immutable).

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _fur(m: Prim, c: Vector3, r: Vector3, col: Color, n: int, ln: float, bias: Vector3 = Vector3(0, -0.3, 0), seed_off: float = 0.0) -> void:
	for i in range(n):
		var a := float(i) * 2.399 + seed_off
		var y := 1.0 - 2.0 * (float(i) + 0.5) / n
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var d := Vector3(cos(a) * rr, y, sin(a) * rr)
		var p := c + Vector3(d.x * r.x, d.y * r.y, d.z * r.z)
		m.lim(T(), [p, p + (d + bias).normalized() * ln], 0.07, 0.0, col, 0.0, 4, true, false)

static func _gem(m: Prim, top: Vector3, drop: float, size: float, col: Color) -> void:
	m.lim(T(), [top, top + Vector3(0, -drop, 0)], 0.012, 0.012, col.darkened(0.35), 0.0, 3, false, false)
	m.blob(T(top + Vector3(0, -drop - size * 1.1, 0)), Vector3(size * 0.75, size * 1.25, size * 0.75), col, 0.7, 1.0, 7, 5)

static func build(b) -> void:
	b.quality = 0.5
	var P: Dictionary = b.pal
	var black: Color = P["main"]; var pink: Color = P["accent"]; var ice: Color = P["glow"]; var fur: Color = P["belly"]
	var crystal := Color.html("9fcde8"); var rose := Color.html("e87cb8"); var orange := Color.html("ff8a3a"); var plum := Color.html("4a2d5a")
	# ---- legs: black segmented spider legs with icy tips; front group (4) and rear group (2)
	var spec := [["leg_f", [[0.55, 0.8], [0.55, -0.8], [0.1, 1.0], [0.1, -1.0]], 0.35], ["leg_b", [[-0.5, 0.8], [-0.5, -0.8]], -0.3]]
	for sp in spec:
		var l: Prim = b.part(sp[0], Vector3(sp[2], 0.95, 0.0))
		for ld in sp[1]:
			var dx: float = ld[0]; var dz: float = ld[1]
			l.lim(T(), [Vector3(0, 0, dz * 0.2), Vector3(dx * 0.7, 0.35, dz * 0.7), Vector3(dx * 1.1 + 0.1, 0.05, dz * 1.05), Vector3(dx * 1.4 + 0.2, -0.9, dz * 1.15)], 0.15, 0.05, black, 0.0, 5)
			l.blob(T(Vector3(dx * 0.7, 0.35, dz * 0.7)), Vector3(0.14, 0.14, 0.14), plum, 0.0, 1.0, 5, 3)
			l.lim(T(), [Vector3(dx * 1.4 + 0.2, -0.75, dz * 1.15), Vector3(dx * 1.45 + 0.2, -0.95, dz * 1.18)], 0.04, 0.0, ice, 0.4, 4, true, false)
			_fur(l, Vector3(dx * 1.0, 0.2, dz * 0.95), Vector3(0.12, 0.12, 0.12), fur, 3, 0.14)
	# ---- torso: big black carapace with glowing veins, fur ruffs, crystal fan, a pendant at the chest
	var t: Prim = b.part("torso", Vector3(0, 0.95, 0))
	t.blob(T(Vector3(-0.1, 0.1, 0)), Vector3(0.95, 0.62, 0.82), black, 0.0, 0.9, 12, 8)
	t.blob(T(Vector3(-0.75, 0.2, 0)), Vector3(0.6, 0.5, 0.55), black.lightened(0.04), 0.0, 0.9, 9, 6)    # abdomen
	for vz in [-1.0, 1.0]:
		t.lim(T(), [Vector3(0.4, 0.4, 0.55 * vz), Vector3(0.0, 0.58, 0.6 * vz), Vector3(-0.5, 0.5, 0.62 * vz)], 0.03, 0.03, pink, 1.0, 3, false, false)
		t.lim(T(), [Vector3(0.45, 0.1, 0.72 * vz), Vector3(0.0, 0.2, 0.8 * vz), Vector3(-0.6, 0.15, 0.7 * vz)], 0.025, 0.025, orange, 1.0, 3, false, false)
	t.lim(T(), [Vector3(0.15, 0.62, 0.0), Vector3(-0.3, 0.7, 0.0), Vector3(-0.9, 0.55, 0.0)], 0.035, 0.035, pink, 1.0, 3, false, false)
	_fur(t, Vector3(0.35, 0.35, 0), Vector3(0.45, 0.4, 0.8), fur, 14, 0.3, Vector3(0.3, -0.1, 0))
	_fur(t, Vector3(-0.2, 0.55, 0), Vector3(0.55, 0.2, 0.7), fur.darkened(0.05), 9, 0.28, Vector3(0, 0.2, 0), 2.0)
	t.lim(T(), [Vector3(0.7, 0.2, 0.0), Vector3(0.78, -0.05, 0.0)], 0.02, 0.02, black, 0.0, 3, false, false)
	_gem(t, Vector3(0.74, 0.2, 0.0), 0.06, 0.12, pink)
	for i in range(9):   # crystal fan on the back
		var f := float(i) / 8.0
		var ang := lerpf(-70.0, 70.0, f)
		var ln := 0.85 + 0.35 * sin(f * PI)
		var base := Vector3(-0.2, 0.62, (f - 0.5) * 0.9)
		var dirv := Vector3(-0.35 - 0.1 * absf(f - 0.5), 1.0, (f - 0.5) * 0.9).normalized()
		var col := crystal if i % 2 == 0 else rose
		t.flat(T(), [base, base + dirv * ln * 0.55, base + dirv * ln], 0.2, 0.12, 0.02, col, Vector3(0, 0, 1) if i % 2 == 0 else Vector3(1, 0, 0), 0.25, 0.1, true, 4)
	# ---- head: furry cream face, pink eyes, fangs, pink crest horns
	var h: Prim = b.part("head", Vector3(0.7, 1.15, 0))
	h.blob(T(Vector3(0.1, 0.1, 0)), Vector3(0.5, 0.42, 0.52), fur, 0.0, 0.9, 11, 7)
	_fur(h, Vector3(0.1, 0.1, 0), Vector3(0.48, 0.4, 0.5), fur, 12, 0.12, Vector3(0.1, -0.2, 0))
	for s in [-1.0, 1.0]:
		h.lim(T(), [Vector3(0.38, -0.2, 0.12 * s), Vector3(0.5, -0.45, 0.1 * s)], 0.06, 0.0, Color.html("efe6d0"), 0.0, 5, true, false)   # fang
		h.lim(T(), [Vector3(0.0, 0.42, 0.18 * s), Vector3(-0.1, 0.8, 0.3 * s), Vector3(0.05, 1.05, 0.38 * s)], 0.07, 0.015, pink, 0.5, 5, true, false)
		h.lim(T(), [Vector3(0.28, -0.2, 0.3 * s), Vector3(0.5, -0.38, 0.42 * s)], 0.07, 0.02, black, 0.0, 4, true, false)   # mandible
	h.flat(T(), [Vector3(0.1, 0.45, 0), Vector3(0.0, 0.85, 0), Vector3(-0.05, 1.2, 0)], 0.1, 0.05, 0.02, rose, Vector3(0, 0, 1), 0.5, 0.2, true, 4)
	b.sock("head", "head", Vector3(0.1, 0.1, 0))
	b.set_face(Vector3(0.1, 0.1, 0), Vector3(0.5, 0.42, 0.52),
			{"eye_sep": 0.4, "eye_y": 0.1, "eye_size": Vector2(0.17, 0.17), "eye_white": 1.0, "sclera": Color.html("e0568e"), "eye_col": Color.html("2a0a1c"),
			"mouth_y": -0.42, "mouth_w": 0.2, "mouth_base": -0.2, "brow_off": 0.08, "brow_len": 0.2, "brow_thick": 0.04, "accent": pink}, 1.0, 0.7, -0.08, 0.9)
	# ---- claws: black furred pincers with icy blades (front arms)
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.55, 1.15, 0.85 * side))
		a.lim(T(), [Vector3(0, 0, 0), Vector3(0.2, -0.3, 0.1 * side), Vector3(0.5, -0.4, 0.2 * side)], 0.2, 0.15, black, 0.0, 6)
		_fur(a, Vector3(0.25, -0.3, 0.12 * side), Vector3(0.2, 0.18, 0.2), fur, 8, 0.2, Vector3(0.2, -0.3, 0))
		a.blob(T(Vector3(0.62, -0.42, 0.22 * side)), Vector3(0.28, 0.2, 0.22), black.lightened(0.05), 0.0, 0.9, 8, 5)
		var pts := [Vector3(0.7, -0.4, 0.2 * side), Vector3(1.05, -0.3, 0.22 * side), Vector3(1.3, -0.5, 0.2 * side), Vector3(1.4, -0.85, 0.2 * side)]
		a.flat(T(), pts, 0.2, 0.1, 0.05, black, Vector3(0, 1, 0), 0.0, 0.2, true, 6)
		a.flat(T(), [pts[1] + Vector3(0.1, -0.05, 0), pts[2] + Vector3(0.05, -0.1, 0), pts[3] + Vector3(-0.02, -0.12, 0)], 0.1, 0.05, 0.03, crystal, Vector3(0, 1, 0), 0.4, 0.2, true, 4)
		a.flat(T(), [Vector3(0.7, -0.6, 0.2 * side), Vector3(0.95, -0.8, 0.2 * side), Vector3(1.0, -1.05, 0.2 * side)], 0.16, 0.06, 0.04, black.lightened(0.04), Vector3(1, 0, 0), 0.0, 0.2, true, 4)   # lower pincer
	b.sock("hand", "arm_f", Vector3(0.62, -0.42, 0.22))
	b.sock("weapon_base", "arm_f", Vector3(0.7, -0.4, 0.2))
	b.sock("weapon_tip", "arm_f", Vector3(1.4, -0.9, 0.2))
	# ---- hanging pink pendants and silk strands from the claws (lag)
	var w: Prim = b.part("weapon", Vector3(0.6, 0.65, 1.0))
	_gem(w, Vector3(0, 0, 0), 0.2, 0.1, pink)
	w.lim(T(), [Vector3(0.1, 0.0, -0.15), Vector3(0.14, -0.5, -0.2), Vector3(0.05, -0.9, -0.25)], 0.012, 0.01, rose, 0.8, 3, false, false)
	# ---- antennae with dangling pink teardrops (sway)
	var e: Prim = b.part("extra", Vector3(0.75, 2.1, 0))
	for s in [-1.0, 1.0]:
		var an := [Vector3(0, 0, 0.12 * s), Vector3(-0.2, 0.7, 0.3 * s), Vector3(-0.1, 1.1, 0.55 * s), Vector3(0.2, 1.15, 0.75 * s), Vector3(0.38, 0.85, 0.8 * s)]
		e.lim(T(), an, 0.04, 0.02, black.lightened(0.05), 0.0, 4, true, true)
		for k in range(4):
			e.lim(T(), [an[k], an[k] + Vector3(0.0, 0.0, 0.0)], 0.001, 0.001, pink, 0.0, 3, false, false)
		e.lim(T(), [an[1], an[1] + Vector3(0.0, 0.0, 0.0)], 0.001, 0.001, pink, 0.0, 3, false, false)
		_gem(e, an[4], 0.2, 0.09, pink)
		_gem(e, an[3] + Vector3(0, 0, 0.03 * s), 0.12, 0.07, rose)
	b.cfg = {
		"scale": 1.1, "wa": -35.0, "sway": 1.2, "stride": 1.1, "bob": 0.35, "waddle": 0.7, "lag_weapon": 0.04, "lag_extra": 0.02, "lag_extra_x": 2.0,
		"armb_gain": 0.5, "guard_th": 30.0, "parry_th": 0.0, "blink_scale": 1.3,
		"style": {"strike_light": "punch", "strike_heavy": "chop", "ability1": "grab", "ability2": "hook", "laststand": "roar", "grab": "grab"},
		"amp": {"strike_light": 0.8, "strike_heavy": 0.85, "ability1": 0.8, "grab": 0.8},
		"fidget": {"head": PL.K(10, 0, -8, 0.0, 0.0), "extra": PL.K(0, 0, 14)},
	}
