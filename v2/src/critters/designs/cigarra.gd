extends RefCounted
## CIGARRA - "The Oracle Hopper" (Canopy Fold). Treehopper-witch: springy ~3.5-head build, big ringed yellow-green eyes, forehead gem + marks,
## pale LEAF-strand hair and leaf ears, oversized dark hood-collar, puffy sleeves, baggy cuffed trousers, belt charms, a draped scalloped
## translucent leaf-veined wing cloak, and the crown: a black branching twig carrying SIX individual glossy spheres (a MultiMesh swarm:
## each sphere orbits / flicks / returns on its own thread). Brief: design/v2/REDESIGN_BRIEFS.md.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

## One cloak panel: a long scalloped petal hanging from the shoulder line around the back, with a vein spine, side veins and black spots.
static func _panel(m: Prim, phi_deg: float, top_y: float, len: float, wid: float, flare: float, col: Color, spot: Color, vein: Color) -> void:
	var phi := deg_to_rad(phi_deg)
	var R := 0.4
	var ctr := Vector3(-0.12 - cos(phi) * R, top_y - len * 0.5 * cos(deg_to_rad(flare)), sin(phi) * R)
	var xf := T(ctr, Vector3(0, 180.0 + phi_deg, flare))
	m.blob(xf, Vector3(0.012, len * 0.5, wid), col, 0.0, 1.0, 8, 6)
	m.lim(xf, [Vector3(0.014, len * 0.46, 0), Vector3(0.014, 0.0, 0), Vector3(0.014, -len * 0.48, 0)], 0.012, 0.007, vein, 1.0, 3, false, false)
	for q in range(3):
		var y0 := len * (0.3 - q * 0.22)
		for sd in [-1.0, 1.0]:
			m.lim(xf, [Vector3(0.014, y0, 0), Vector3(0.014, y0 - len * 0.1, wid * 0.55 * sd), Vector3(0.014, y0 - len * 0.2, wid * 0.8 * sd)], 0.007, 0.005, vein, 1.0, 3, false, false)
	m.blob(xf * T(Vector3(0.015, len * 0.12, wid * 0.25)), Vector3(0.01, len * 0.07, wid * 0.14), spot, 0.0, 1.0, 6, 3)
	m.blob(xf * T(Vector3(0.015, -len * 0.18, -wid * 0.3)), Vector3(0.01, len * 0.06, wid * 0.12), spot, 0.0, 1.0, 6, 3)

static func build(b) -> void:
	b.quality = 0.55
	var P: Dictionary = b.pal
	var purple: Color = P["main"]; var green: Color = P["accent"]; var lime: Color = P["glow"]; var cream: Color = P["belly"]
	var skin := Color.html("e2b58a"); var hair := Color.html("efe9d8"); var boot := Color.html("3b3a1f"); var orange := Color.html("e0873a")
	var black := Color.html("15111a"); var olive := Color.html("8a9a3a"); var gold := Color.html("e8d04a")
	b.glass = ["extra"]
	# ---- legs: baggy cuffed trousers, striped socks, leafy boots
	for leg in [["leg_f", 0.1, 0.2], ["leg_b", -0.08, -0.2]]:
		var z: float = leg[2]
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.62, z))
		l.blob(T(Vector3(0, -0.2, 0)), Vector3(0.26, 0.31, 0.26), purple, 0.0, 0.9, 9, 6)
		l.blob(T(Vector3(0.1, -0.12, 0.0)), Vector3(0.12, 0.14, 0.2), purple.darkened(0.2), 0.0, 0.9, 6, 4)   # cargo patch
		l.ring(T(Vector3(0, -0.4, 0), Vector3(90, 0, 0)), 0.2, 0.045, purple.lightened(0.1), 0.0, 10, 4)
		l.lim(T(), [Vector3(0, -0.4, 0), Vector3(0, -0.5, 0)], 0.1, 0.1, cream, 0.0, 6)
		l.lim(T(), [Vector3(0.0, -0.43, 0), Vector3(0.0, -0.48, 0)], 0.115, 0.115, olive, 0.0, 6)
		l.blob(T(Vector3(0.1, -0.56, 0)), Vector3(0.27, 0.11, 0.18), boot, 0.0, 0.8, 8, 4)
		l.flat(T(), [Vector3(0.0, -0.5, z * 0.3), Vector3(-0.12, -0.55, z * 0.5), Vector3(-0.22, -0.64, z * 0.6)], 0.08, 0.04, 0.012, olive, Vector3(0, 0, 1), 0.0, 0.2, true)
	# ---- torso: cropped top, belt, charms
	var t: Prim = b.part("torso", Vector3(0, 0.62, 0))
	t.blob(T(Vector3(0.0, 0.22, 0)), Vector3(0.29, 0.3, 0.27), purple.lightened(0.04), 0.0, 0.9, 9, 6)
	t.blob(T(Vector3(0.04, 0.42, 0)), Vector3(0.28, 0.2, 0.26), cream.darkened(0.12), 0.0, 0.9, 9, 5)
	t.blob(T(Vector3(0.17, 0.28, 0)), Vector3(0.09, 0.07, 0.19), skin, 0.0, 1.0, 6, 3)
	t.ring(T(Vector3(0.0, 0.1, 0), Vector3(90, 0, 0)), 0.28, 0.045, orange, 0.0, 12, 4)
	for ch in [[Vector3(0.26, 0.05, 0.22), cream, 0.1, 0.13], [Vector3(0.22, 0.02, -0.24), orange.lightened(0.15), 0.09, 0.12], [Vector3(0.1, 0.03, 0.3), olive, 0.07, 0.09]]:
		t.lim(T(), [ch[0] + Vector3(0, 0.12, 0), ch[0]], 0.012, 0.012, orange, 0.0, 3, false, false)
		t.blob(T(ch[0] + Vector3(0, -ch[3] * 0.9, 0)), Vector3(ch[2], ch[3], ch[2] * 0.8), ch[1], 0.0, 1.0, 7, 5)
	t.blob(T(Vector3(0.3, -0.07, 0.23)), Vector3(0.03, 0.035, 0.02), black, 0.0, 1.0, 4, 3)
	t.blob(T(Vector3(0.24, -0.07, 0.23)), Vector3(0.03, 0.035, 0.02), black, 0.0, 1.0, 4, 3)
	# oversized dark hood-collar: wraps the neck, rises behind the head, lime-trimmed
	t.blob(T(Vector3(-0.05, 0.64, 0)), Vector3(0.42, 0.24, 0.5), purple.darkened(0.15), 0.0, 0.75, 11, 6)
	t.blob(T(Vector3(-0.3, 0.9, 0), Vector3(0, 0, 14)), Vector3(0.1, 0.38, 0.5), purple.darkened(0.25), 0.0, 0.8, 8, 6)    # hood back rising behind the head
	for sd in [-1.0, 1.0]:
		t.blob(T(Vector3(0.0, 0.84, 0.46 * sd), Vector3(0, 0, 0)), Vector3(0.3, 0.22, 0.08), purple.darkened(0.1), 0.0, 0.8, 7, 4)   # side wings of the hood
	for dz in [-0.36, -0.18, 0.0, 0.18, 0.36]:
		t.flat(T(), [Vector3(0.28, 0.66, dz), Vector3(0.32, 0.56, dz), Vector3(0.3, 0.46, dz)], 0.07, 0.03, 0.012, lime, Vector3(0, 0, 1), 0.0, 0.0, true)
	# ---- head: tan face, ringed yellow-green eyes (shader), forehead gem + marks, leaf-strand hair and leaf ears
	var h: Prim = b.part("head", Vector3(0.05, 1.3, 0))
	h.blob(T(Vector3(0.1, 0.38, 0)), Vector3(0.44, 0.42, 0.42), skin, 0.0, 0.92, 12, 8)
	h.blob(T(Vector3(0.52, 0.58, 0.0), Vector3(0, 0, 20)), Vector3(0.05, 0.1, 0.07), gold, 0.7, 1.0, 6, 4)             # forehead gem
	for pr in [Vector3(0.5, 0.5, 0.12), Vector3(0.5, 0.5, -0.12), Vector3(0.38, 0.14, 0.34), Vector3(0.38, 0.14, -0.34)]:
		h.blob(T(pr), Vector3(0.03, 0.03, 0.03), black, 0.0, 1.0, 5, 3)                                            # marks
	h.blob(T(Vector3(0.0, 0.62, 0), Vector3(0, 0, 14)), Vector3(0.42, 0.2, 0.44), hair, 0.0, 0.8, 10, 5)          # hair mass
	for k in range(10):   # leaf strands sweeping back and down
		var az := lerpf(-1.25, 1.25, float(k) / 9.0)
		var base := Vector3(0.0, 0.72, 0.38 * sin(az))
		var drop := 0.3 + 0.18 * absf(sin(k * 1.9))
		h.flat(T(), [base, base + Vector3(-0.2, 0.12, 0.2 * sin(az)), base + Vector3(-0.38 - 0.1 * cos(az), -drop * 0.4, 0.38 * sin(az)), base + Vector3(-0.45, -drop, 0.42 * sin(az))],
				0.1, 0.05, 0.015, hair if k % 3 != 1 else lime.lightened(0.35), Vector3(0, 0, 1) if k % 2 == 0 else Vector3(1, 0, 0), 0.0, 0.5, true, 4)
	for k in range(4):    # fringe leaves over the forehead
		var z := (k - 1.5) * 0.15
		h.flat(T(), [Vector3(0.38, 0.7, z), Vector3(0.48, 0.66, z * 1.2), Vector3(0.52, 0.52, z * 1.4)], 0.07, 0.03, 0.012, hair if k % 2 == 0 else lime, Vector3(0, 0, 1), 0.0, 0.4, true)
	for sd in [-1.0, 1.0]:
		h.flat(T(), [Vector3(0.05, 0.4, 0.4 * sd), Vector3(-0.05, 0.5, 0.65 * sd), Vector3(-0.2, 0.62, 0.9 * sd)], 0.1, 0.05, 0.015, lime, Vector3(0, 1, 0), 0.0, 0.5, true, 4)   # leaf ears
		h.flat(T(), [Vector3(0.1, 0.12, 0.42 * sd), Vector3(0.0, 0.0, 0.5 * sd), Vector3(-0.1, -0.12, 0.5 * sd)], 0.06, 0.03, 0.012, hair, Vector3(1, 0, 0), 0.0, 0.2, true)
	# crown: black branching twig on the head; the spheres are the swarm
	var tw := Vector3(0.1, 0.9, 0)
	h.lim(T(), [tw, tw + Vector3(0.0, 0.25, 0.0)], 0.06, 0.04, black, 0.0, 5)
	var branches := [[Vector3(0.1, 0.5, 0.3), Vector3(0.2, 0.62, 0.55), 0.17], [Vector3(-0.05, 0.55, 0.12), Vector3(0.0, 0.8, 0.1), 0.19],
			[Vector3(0.1, 0.5, -0.3), Vector3(0.2, 0.66, -0.58), 0.17], [Vector3(-0.2, 0.42, 0.28), Vector3(-0.36, 0.5, 0.45), 0.15],
			[Vector3(-0.2, 0.42, -0.28), Vector3(-0.36, 0.54, -0.5), 0.15], [Vector3(0.3, 0.8, 0.3), Vector3(0.35, 0.98, 0.22), 0.14]]
	var rest: Array = []
	for br in branches:
		h.lim(T(), [tw + Vector3(0, 0.25, 0), tw + br[0], tw + br[1]], 0.035, 0.022, black, 0.0, 4, false, false)
		rest.append(br[1])
	var orb := Prim.new()
	orb.quality = b.quality
	orb.blob(T(), Vector3(0.17, 0.17, 0.17), black.lightened(0.04), 0.0, 1.0, 8, 5)
	orb.blob(T(Vector3(0.06, 0.08, 0.09)), Vector3(0.04, 0.04, 0.02), Color.html("e8e4f0"), 0.6, 1.0, 5, 3)
	orb.blob(T(), Vector3(0.08, 0.08, 0.18), gold, 0.4, 1.0, 5, 3)        # core glow (flares as the tell)
	b.swarm = {"mb": orb, "rest": rest, "parent": "head", "pos": Vector3(0.05, 1.3, 0) + tw}
	b.sock("head", "head", Vector3(0.1, 0.38, 0))
	b.sock("crown", "head", tw)
	b.set_face(Vector3(0.1, 0.38, 0), Vector3(0.44, 0.42, 0.42),
			{"eye_sep": 0.38, "eye_y": 0.0, "eye_size": Vector2(0.21, 0.21), "eye_white": 1.0, "sclera": Color.html("e8ee7a"), "eye_col": Color.html("141008"),
			"ringed": 1.0, "accent": Color.html("5a7a1a"), "lid_bias": 0.1, "mouth_y": -0.36, "mouth_w": 0.15, "mouth_base": 0.1, "brow_off": 0.08, "brow_len": 0.18, "brow_thick": 0.03}, 0.95, 0.75, -0.12, 0.92)
	# ---- arms: puffy sleeves, bandaged forearms, long pale hands
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.0, 1.0, 0.42 * side))
		a.blob(T(Vector3(0.0, -0.18, 0.02 * side)), Vector3(0.21, 0.27, 0.21), purple.lightened(0.06), 0.0, 0.9, 8, 5)
		a.lim(T(), [Vector3(0.04, -0.38, 0.03 * side), Vector3(0.12, -0.6, 0.05 * side)], 0.1, 0.08, cream, 0.0, 6)
		a.ring(T(Vector3(0.05, -0.4, 0.03 * side), Vector3(80, 0, 12)), 0.1, 0.03, purple.lightened(0.15), 0.0, 8, 3)
		a.blob(T(Vector3(0.16, -0.7, 0.06 * side)), Vector3(0.1, 0.12, 0.08), skin, 0.0, 0.9, 6, 4)
		for dz in [-0.04, 0.0, 0.04]:
			a.lim(T(), [Vector3(0.2, -0.76, 0.06 * side + dz), Vector3(0.28, -0.88, 0.07 * side + dz * 1.4)], 0.025, 0.0, skin.darkened(0.1), 0.0, 4, false, false)
	b.sock("hand", "arm_f", Vector3(0.16, -0.7, 0.06))
	b.sock("weapon_base", "arm_f", Vector3(0.16, -0.7, 0.06))
	b.sock("weapon_tip", "arm_f", Vector3(0.32, -0.9, 0.07))
	# ---- draped scalloped translucent leaf-veined cloak (attached at the hood/shoulders): overlapping petals around the back, two layers
	var e: Prim = b.part("extra", Vector3(-0.05, 1.5, 0))
	var wg := Color.html("a8c93e"); var spot := Color.html("2a2236"); var vein := Color.html("e2f08a")
	for k in range(7):    # upper layer, shoulder line
		var phi := lerpf(-105.0, 105.0, float(k) / 6.0)
		_panel(e, phi, 0.0, 0.95 + 0.25 * cos(deg_to_rad(phi)) - 0.18 * (k % 2), 0.17, 10.0 + 6.0 * absf(phi) / 105.0, wg, spot, vein)
	for k in range(5):    # lower overlapping layer, longer, offset
		var phi := lerpf(-95.0, 95.0, float(k) / 4.0)
		_panel(e, phi, -0.12, 1.0 + 0.3 * cos(deg_to_rad(phi)) - 0.2 * (k % 2), 0.19, 18.0 + 8.0 * absf(phi) / 95.0, wg.darkened(0.12), spot, vein)
	e.flat(T(), [Vector3(0.0, 0.05, 0.4), Vector3(-0.35, 0.02, 0.0), Vector3(0.0, 0.05, -0.4)], 0.18, 0.18, 0.02, purple, Vector3(0, 1, 0), 0.0, 0.0, false)   # purple yoke edge
	b.cfg = {
		"scale": 1.0, "wa": -50.0, "sway": 3.0, "stride": 1.1, "bob": 0.6, "waddle": 0.5, "lag_extra": 0.015, "flap": 4.0, "flap_hz": 5.0,
		"blink_scale": 1.0, "armb_gain": 0.5, "guard_th": 40.0, "parry_th": 10.0,
		"swarm_rest": rest,
		"swarm_act": {"strike_light": {"mode": "flick", "dir": Vector3(1, 0.1, 0), "dist": 3.2, "hold": 4},
				"strike_heavy": {"mode": "volley", "dir": Vector3(1, 0.1, 0), "dist": 3.6, "fan": 1.3, "hold": 6},
				"ability1": {"mode": "orbit", "center": Vector3(0, 0.2, 0), "radius": 1.5, "hz": 1.1, "hold": 36},
				"laststand": {"mode": "orbit", "center": Vector3(0, 0.2, 0), "radius": 1.9, "hz": 1.7, "hold": 36}},
		"ghost_act": {"ability1": {"as": "strike_heavy", "frame": 12, "offset": Vector3(1.3, 0, 0), "count": 2, "life": 1.0}},
		"style": {"strike_light": "punch", "strike_heavy": "slash_up", "ability1": "stance", "ability2": "hook", "laststand": "roar", "grab": "hook"},
		"amp": {"strike_light": 0.7, "strike_heavy": 0.9, "laststand": 1.2},
		"fidget": {"head": PL.K(14, 0, -6), "arm_f": PL.K(0, 0, 40, 0.05, 0.0)},
	}
