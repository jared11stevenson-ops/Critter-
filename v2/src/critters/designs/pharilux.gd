extends RefCounted
## PHARILUX - "The Watcher Below" (approved concept sheet = visual canon). Tall hunched ghost prey-mantis, weathered teal body with barnacle
## crust, an antique diving / lighthouse lantern for a head (glowing amber lens, no human face), long arcing antennae that hang chains and
## lanterns over him like a lamp post, two huge rust-bronze raptorial scythe arms, a chain + anchor at the hip, and long tattered pale
## yellow-green membranes hanging behind like a cloak. Palette: teal, rust bronze, amber, tide-mist cream.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _lantern(m: Prim, c: Vector3, sz: float, brass: Color, amber: Color) -> void:
	m.lim(T(), [c + Vector3(0, sz * 1.7, 0), c + Vector3(0, sz * 1.25, 0)], sz * 0.3, sz * 0.3, brass, 0.0, 4)
	m.blob(T(c), Vector3(sz * 0.75, sz * 1.0, sz * 0.75), amber, 1.0, 1.0, 7, 5)                              # glass + flame

static func _anchor(m: Prim, c: Vector3, sz: float, col: Color) -> void:
	m.lim(T(), [c + Vector3(0, sz, 0), c + Vector3(0, -sz, 0)], sz * 0.15, sz * 0.15, col, 0.0, 5)
	m.lim(T(), [c + Vector3(-sz * 0.55, sz * 0.55, 0), c + Vector3(sz * 0.55, sz * 0.55, 0)], sz * 0.12, sz * 0.12, col, 0.0, 4)
	m.ring(T(c + Vector3(0, sz * 1.15, 0)), sz * 0.2, sz * 0.07, col, 0.0, 8, 4)
	m.lim(T(), [c + Vector3(-sz * 0.9, -sz * 0.35, 0), c + Vector3(-sz * 0.55, -sz * 0.9, 0), c + Vector3(0, -sz, 0), c + Vector3(sz * 0.55, -sz * 0.9, 0), c + Vector3(sz * 0.9, -sz * 0.35, 0)], sz * 0.13, sz * 0.09, col, 0.0, 4)

static func _chain(m: Prim, pts: Array, col: Color, rad: float) -> void:
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var steps := maxi(2, int(a.distance_to(b) / (rad * 10.0)))
		for k in range(steps):
			var p := a.lerp(b, (float(k) + 0.5) / steps)
			m.ring(T(p, Vector3(90.0 * (k % 2), 0, 0)), rad * 1.4, rad * 0.45, col, 0.0, 6, 3)

static func _barnacles(m: Prim, c: Vector3, r: float, n: int, col: Color) -> void:
	for i in range(n):
		var a := float(i) * 2.39
		m.blob(T(c + Vector3(cos(a) * r, sin(a * 1.7) * r * 0.8, sin(a) * r * 0.6)), Vector3(0.045, 0.04, 0.045), col, 0.0, 1.0, 5, 3)

static func build(b) -> void:
	b.quality = 0.4
	var P: Dictionary = b.pal
	var teal: Color = P["main"]; var rust: Color = P["accent"]; var amber: Color = P["glow"]; var mist: Color = P["belly"]
	var brass := Color.html("a9803a"); var iron := Color.html("2c3234"); var dark := Color.html("1f2a2c")
	var membrane := Color.html("c4cf94"); var mem2 := Color.html("8fb89a"); var barn := Color.html("cdd1b8")
	b.glass = ["extra"]
	# ---- legs: long digitigrade stilts, barnacled knees, hooked feet
	for leg in [["leg_f", 0.12, 0.2], ["leg_b", -0.18, -0.2]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 1.35, leg[2]))
		l.lim(T(), [Vector3(0, 0, 0), Vector3(0.28, -0.45, 0), Vector3(0.2, -0.62, 0)], 0.1, 0.075, teal, 0.0, 6)
		l.lim(T(), [Vector3(0.2, -0.62, 0), Vector3(-0.1, -1.0, 0), Vector3(-0.02, -1.33, 0)], 0.075, 0.045, teal.darkened(0.1), 0.0, 6)
		l.blob(T(Vector3(0.24, -0.55, 0)), Vector3(0.12, 0.1, 0.1), rust, 0.0, 1.0, 6, 4)
		l.lim(T(), [Vector3(-0.02, -1.33, 0), Vector3(0.28, -1.37, 0.05)], 0.05, 0.015, rust, 0.0, 4, true, false)
		l.lim(T(), [Vector3(-0.02, -1.33, 0), Vector3(0.22, -1.4, -0.06)], 0.045, 0.012, rust, 0.0, 4, true, false)
		l.lim(T(), [Vector3(-0.02, -1.33, 0), Vector3(-0.25, -1.37, 0)], 0.04, 0.012, rust, 0.0, 4, true, false)
	# ---- torso: hunched thorax leaning forward, pale chest plates, banded abdomen, chain harness, mantle cloak
	var t: Prim = b.part("torso", Vector3(0, 1.4, 0))
	t.lim(T(), [Vector3(-0.05, 0.0, 0), Vector3(0.2, 0.45, 0), Vector3(0.42, 0.95, 0)], 0.3, 0.22, teal, 0.0, 8)
	t.lim(T(), [Vector3(0.06, 0.1, 0), Vector3(0.28, 0.5, 0), Vector3(0.45, 0.88, 0)], 0.27, 0.19, mist, 0.0, 7)
	t.blob(T(Vector3(0.38, 0.95, 0)), Vector3(0.26, 0.2, 0.34), rust, 0.0, 0.9, 8, 5)                     # shoulder yoke
	t.lim(T(), [Vector3(-0.25, 0.0, 0), Vector3(-0.65, -0.18, 0), Vector3(-1.05, -0.55, 0)], 0.2, 0.06, teal.darkened(0.15), 0.0, 7)   # abdomen
	for k in range(4):
		t.ring(T(Vector3(-0.4 - 0.18 * k, -0.06 - 0.1 * k, 0), Vector3(0, 90, -25)), 0.17 - 0.03 * k, 0.025, rust, 0.0, 9, 3)
	_barnacles(t, Vector3(0.38, 1.0, 0.18), 0.2, 4, barn)
	_barnacles(t, Vector3(0.0, 0.2, 0.2), 0.2, 3, barn)
	_chain(t, [Vector3(0.5, 1.05, 0.28), Vector3(0.3, 0.55, 0.3), Vector3(0.1, 0.1, 0.22), Vector3(-0.05, -0.3, 0.12)], iron, 0.03)
	_chain(t, [Vector3(0.5, 1.05, -0.28), Vector3(0.3, 0.55, -0.3), Vector3(0.1, 0.1, -0.22)], iron, 0.03)
	_lantern(t, Vector3(0.2, 0.0, 0.3), 0.07, brass, amber)
	for k in range(5):   # tattered mantle hanging from the shoulders (a cloak of membrane)
		var z: float = (float(k) - 2.0) * 0.17
		var len: float = 1.5 + 0.35 * float((k * 3) % 4)
		t.flat(T(), [Vector3(0.25, 0.9, z), Vector3(-0.15, 0.2, z * 1.4), Vector3(-0.3, -0.5, z * 1.8), Vector3(-0.3, 0.9 - len, z * 2.0)], 0.12, 0.05, 0.012, mem2 if k % 2 == 0 else membrane, Vector3(0, 0, 1), 0.0, 0.2, true, 4)
	# ---- head: small insect skull inside a big brass lantern helmet; amber lens at the front, chimney cap, chain-hung antenna arcs
	var h: Prim = b.part("head", Vector3(0.62, 2.45, 0))
	h.blob(T(Vector3(0.0, 0.0, 0)), Vector3(0.2, 0.26, 0.2), teal.lightened(0.05), 0.0, 0.9, 8, 6)                  # skull / neck bulb
	h.blob(T(Vector3(0.1, 0.34, 0)), Vector3(0.36, 0.34, 0.34), brass.darkened(0.15), 0.0, 0.95, 10, 7)               # helmet dome
	h.ring(T(Vector3(0.1, 0.18, 0), Vector3(90, 0, 0)), 0.36, 0.05, rust, 0.0, 12, 4)                                # helmet rim
	h.blob(T(Vector3(0.3, 0.3, 0)), Vector3(0.24, 0.26, 0.26), amber, 1.0, 1.0, 9, 6)                              # the lantern lens
	h.ring(T(Vector3(0.44, 0.3, 0), Vector3(0, 90, 0)), 0.2, 0.035, brass, 0.0, 10, 4)                              # lens bezel
	h.lim(T(), [Vector3(0.05, 0.62, 0), Vector3(0.05, 0.8, 0)], 0.09, 0.05, brass, 0.0, 6)                           # chimney cap
	h.blob(T(Vector3(0.05, 0.86, 0)), Vector3(0.11, 0.05, 0.11), rust, 0.0, 1.0, 6, 3)
	for s in [-1.0, 1.0]:   # long arcing antennae, chains and lanterns hang from them
		var ant := [Vector3(-0.05, 0.6, 0.12 * s), Vector3(-0.2, 1.05, 0.28 * s), Vector3(0.15, 1.45, 0.42 * s), Vector3(0.65, 1.4, 0.52 * s), Vector3(0.95, 1.05, 0.58 * s)]
		h.lim(T(), ant, 0.04, 0.018, brass, 0.0, 5, true, false)
		_chain(h, [ant[4] + Vector3(0, -0.05, 0), ant[4] + Vector3(0.02, -0.4, 0)], iron, 0.018)
		_lantern(h, ant[4] + Vector3(0.02, -0.55, 0), 0.08, brass, amber)
		_chain(h, [ant[3] + Vector3(0, -0.03, 0), ant[3] + Vector3(0, -0.3, 0)], iron, 0.016)
		_lantern(h, ant[3] + Vector3(0, -0.42, 0), 0.06, brass, amber.lightened(0.1))
		_chain(h, [ant[1] + Vector3(0, -0.03, 0), ant[1] + Vector3(-0.04, -0.28, 0)], iron, 0.016)
		_lantern(h, ant[1] + Vector3(-0.04, -0.38, 0), 0.05, brass, amber)
	b.sock("head", "head", Vector3(0.3, 0.3, 0))
	b.set_face(Vector3(0.3, 0.3, 0), Vector3(0.24, 0.26, 0.26),
			{"eye_sep": 0.55, "eye_y": 0.0, "eye_size": Vector2(0.11, 0.05), "eye_white": 1.0, "sclera": Color.html("3a2308"), "eye_col": Color.html("fff0b0"),
			"mouth_y": -0.7, "mouth_w": 0.0, "mouth_base": 0.0, "brow_off": 0.1, "brow_len": 0.12, "brow_thick": 0.025, "accent": amber, "ringed": 0.0}, 0.9, 0.6, 0.0, 0.9)
	# ---- arms: huge raptorial scythes (rust bronze, serrated); the front one is the weapon arm, the back one is a lantern arm
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.45, 2.3, 0.4 * side))
		a.blob(T(), Vector3(0.14, 0.14, 0.14), rust, 0.0, 1.0, 6, 4)
		a.lim(T(), [Vector3(0, 0, 0), Vector3(0.25, -0.35, 0.03 * side), Vector3(0.45, -0.7, 0.05 * side)], 0.1, 0.085, teal, 0.0, 6)
		a.blob(T(Vector3(0.45, -0.7, 0.05 * side)), Vector3(0.13, 0.12, 0.12), rust, 0.0, 1.0, 6, 4)
		var blade := [Vector3(0.45, -0.7, 0.05 * side), Vector3(0.95, -0.55, 0.06 * side), Vector3(1.3, -0.95, 0.07 * side), Vector3(1.3, -1.5, 0.07 * side), Vector3(1.05, -1.95, 0.07 * side)]
		a.flat(T(), blade, 0.17, 0.0, 0.05, rust, Vector3(0, 0, 1), 0.0, 0.25, true, 6)
		a.lim(T(), blade, 0.07, 0.01, brass, 0.0, 5, false, false)
		for k in range(2):   # serrations along the inner edge
			var p: Vector3 = (blade[k + 1] as Vector3).lerp(blade[k + 1] + Vector3(-0.05, -0.05, 0), 0.5)
			a.lim(T(), [p + Vector3(-0.1, 0.0, 0.0), p + Vector3(-0.28, -0.1, 0.0)], 0.03, 0.0, brass, 0.0, 4, true, false)
	b.sock("weapon_tip", "arm_f", Vector3(1.05, -1.95, 0.07))
	b.sock("weapon_base", "arm_f", Vector3(0.55, -0.7, 0.05))
	b.sock("hand", "arm_f", Vector3(0.55, -0.7, 0.05))
	var ab: Prim = b.parts["arm_b"]["mb"]
	_chain(ab, [Vector3(1.2, -1.3, -0.07), Vector3(1.22, -1.75, -0.07)], iron, 0.02)
	_lantern(ab, Vector3(1.22, -1.95, -0.07), 0.07, brass, amber)
	# ---- weapon (lagging): a long rust chain and a big anchor swinging from the hip
	var w: Prim = b.part("weapon", Vector3(-0.15, 1.5, 0.42))
	_chain(w, [Vector3(0, 0, 0), Vector3(-0.08, -0.5, 0.02), Vector3(0.0, -1.0, 0.0)], rust, 0.035)
	_anchor(w, Vector3(0.0, -1.35, 0.0), 0.34, iron)
	# ---- membranes: long tattered translucent pale-gold/green wings behind him, holes and a frayed hem down to the ground
	var e: Prim = b.part("extra", Vector3(-0.1, 2.25, 0))
	for z in [0.16, -0.16]:
		var xf := T(Vector3(-0.2, -1.0, z * 2.4), Vector3(18.0 * signf(z), 0, 8.0))
		e.blob(xf, Vector3(0.012, 1.25, 0.55), membrane, 0.0, 1.0, 9, 7)
		e.blob(xf * T(Vector3(0.01, -0.2, 0)), Vector3(0.01, 0.9, 0.35), mem2, 0.0, 1.0, 8, 6)
		for k in range(4):
			e.blob(xf * T(Vector3(0.014, -0.9 + k * 0.32, (0.25 - 0.09 * (k % 4)) * signf(z))), Vector3(0.01, 0.06, 0.06), mist.lightened(0.2), 0.0, 1.0, 5, 3)
		for k in range(3):   # frayed hem tatters
			var zz: float = (float(k) - 1.0) * 0.3 * signf(z) + z * 2.4
			e.flat(T(), [Vector3(-0.25, -2.1, zz), Vector3(-0.32, -2.5 - 0.15 * (k % 3), zz * 1.05)], 0.1, 0.0, 0.01, mem2, Vector3(0, 0, 1), 0.0, 0.2, true, 3)
	b.cfg = {
		"scale": 1.28, "wa": -63.0, "sway": 1.4, "stride": 1.0, "bob": 0.3, "waddle": 0.2, "lag_weapon": 0.1, "lag_extra": 0.022, "flap": 3.0, "flap_hz": 2.0,
		"armb_gain": 0.4, "guard_th": 35.0, "parry_th": 5.0, "blink_scale": 0.5, "hover": 0.0,
		"style": {"strike_light": "slash_back", "strike_heavy": "overhead", "ability1": "roar", "ability2": "hook", "laststand": "leap", "grab": "grab"},
		"amp": {"strike_light": 0.9, "strike_heavy": 1.0, "laststand": 1.2},
		"fidget": {"head": PL.K(0, 0, 8, 0.02, 0.0), "arm_b": PL.K(0, 0, 25, 0.0, 0.03)},
	}
