extends RefCounted
## CIGARRA - "The Oracle Hopper": psychic witch (165 cm). Crown of branching black twigs with six black spheres, spiky pale leaf-tipped
## hair, yellow-green ringed eyes with dark markings and three forehead dots, dark oversized hood/collar with green drip trim,
## cropped top, puffy purple sleeves, bandaged forearms, baggy cuffed purple trousers, orange rope belt with skull/egg charms,
## striped socks, leafy boots, and the translucent green treehopper-wing cloak with black oval spots.
## Reference: tools/source_art/cigarra_sheet.jpg.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _wing(m: Prim, z: float, c: Vector3, len: float, wid: float, tilt: float, sweep: float, col: Color, spot: Color, vein: Color) -> void:
	# leaf-veined cloak wing: 3 overlapping scalloped lobes fanning down from the shoulder, each with a vein spine and black oval spots
	var side := signf(z)
	for k in range(3):
		var fan := (k - 1) * 17.0
		var xf := T(c, Vector3(tilt * side, 0, sweep + fan))
		var l := len * (0.82 + 0.18 * (1 - absf(k - 1)))
		var ctr := Vector3(0.012 * (k - 1), -l * 0.5, 0)
		m.blob(xf * T(ctr), Vector3(0.012, l * 0.5, wid * 0.34), col if k != 1 else col.lightened(0.05), 0.0, 1.0, 8, 5)
		m.lim(xf, [Vector3(0.014, -0.02, 0), Vector3(0.014, -l * 0.5, 0), Vector3(0.014, -l * 0.98, 0)], 0.014, 0.008, vein, 1.0, 3, false, false)
		for q in range(2):
			m.lim(xf, [Vector3(0.014, -l * (0.3 + q * 0.25), 0), Vector3(0.014, -l * (0.4 + q * 0.25), wid * 0.22), Vector3(0.014, -l * (0.5 + q * 0.25), wid * 0.3)], 0.008, 0.005, vein, 1.0, 3, false, false)
		m.blob(xf * T(Vector3(0.015, -l * 0.42, wid * 0.1 * side)), Vector3(0.01, l * 0.1, wid * 0.07), spot, 0.0, 1.0, 6, 3)

static func build(b) -> void:
	b.quality = 0.7
	var P: Dictionary = b.pal
	var purple: Color = P["main"]; var green: Color = P["accent"]; var lime: Color = P["glow"]; var cream: Color = P["belly"]
	var skin := Color.html("e2b58a"); var hair := Color.html("ece6d2"); var boot := Color.html("3b3a1f"); var orange := Color.html("e0873a")
	var black := Color.html("15111a"); var olive := Color.html("8a9a3a")
	b.glass = ["extra"]
	# ---- legs: baggy cuffed trousers, striped socks, leafy boots
	for leg in [["leg_f", 0.1, 0.2], ["leg_b", -0.08, -0.2]]:
		var z: float = leg[2]
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.62, z))
		l.blob(T(Vector3(0, -0.2, 0)), Vector3(0.24, 0.3, 0.24), purple, 0.0, 0.9, 9, 6)
		l.ring(T(Vector3(0, -0.4, 0), Vector3(90, 0, 0)), 0.2, 0.04, purple.lightened(0.1), 0.0, 10, 4)
		l.lim(T(), [Vector3(0, -0.4, 0), Vector3(0, -0.5, 0)], 0.1, 0.1, cream, 0.0, 6)
		l.lim(T(), [Vector3(0.0, -0.43, 0), Vector3(0.0, -0.48, 0)], 0.115, 0.115, olive, 0.0, 6)
		l.blob(T(Vector3(0.1, -0.56, 0)), Vector3(0.26, 0.11, 0.18), boot, 0.0, 0.8, 8, 4)
		l.flat(T(), [Vector3(0.0, -0.5, z * 0.3), Vector3(-0.12, -0.55, z * 0.5), Vector3(-0.2, -0.64, z * 0.6)], 0.07, 0.04, 0.012, olive, Vector3(0, 0, 1), 0.0, 0.1, true)
	# ---- torso: cropped top, hood collar, rope belt, charms are a separate lagging part
	var t: Prim = b.part("torso", Vector3(0, 0.62, 0))
	t.blob(T(Vector3(0.0, 0.22, 0)), Vector3(0.32, 0.3, 0.3), purple.lightened(0.04), 0.0, 0.9, 9, 6)
	t.blob(T(Vector3(0.04, 0.42, 0)), Vector3(0.3, 0.22, 0.28), cream.darkened(0.12), 0.0, 0.9, 9, 5)
	t.blob(T(Vector3(0.18, 0.28, 0)), Vector3(0.1, 0.08, 0.2), skin, 0.0, 1.0, 6, 3)   # bare midriff
	t.ring(T(Vector3(0.0, 0.1, 0), Vector3(90, 0, 0)), 0.3, 0.045, orange, 0.0, 12, 4)
	t.blob(T(Vector3(-0.2, 0.7, 0)), Vector3(0.34, 0.36, 0.56), purple.darkened(0.12), 0.0, 0.75, 11, 6)   # oversized collar / hood
	for dz in [-0.34, -0.17, 0.0, 0.17, 0.34]:
		t.flat(T(), [Vector3(0.1, 0.62, dz), Vector3(0.16, 0.5, dz), Vector3(0.14, 0.4, dz)], 0.06, 0.03, 0.012, lime, Vector3(0, 0, 1), 0.0, 0.0, true)  # green drip trim
	# ---- head: tan face, ringed yellow eyes, spiky pale hair with leaf tips, forehead dots, branching crown of black spheres
	var h: Prim = b.part("head", Vector3(0.05, 1.3, 0))
	h.blob(T(Vector3(0.1, 0.38, 0)), Vector3(0.44, 0.42, 0.42), skin, 0.0, 0.92, 12, 8)
	h.blob(T(Vector3(-0.02, 0.66, 0), Vector3(0, 0, 14)), Vector3(0.42, 0.2, 0.44), hair, 0.0, 0.8, 10, 5)      # hair cap, pushed back off the forehead
	for k in range(16):
		var az := float(k) / 16.0 * TAU
		var dirv := Vector3(cos(az) * 0.8 - 0.3, 0.7 + 0.5 * sin(k * 2.3), sin(az) * 1.0).normalized()
		var base := Vector3(-0.02, 0.62, 0.0) + Vector3(dirv.x * 0.3, 0.0, dirv.z * 0.34)
		if cos(az) > 0.7:
			continue
		var ln := 0.5 + 0.2 * absf(sin(k * 1.9))
		h.lim(T(), [base, base + dirv * ln * 0.55, base + dirv * ln + Vector3(-0.08, -0.05, 0)], 0.1, 0.0, hair, 0.0, 5, true, false)
		h.lim(T(), [base + dirv * ln * 0.7, base + dirv * ln + Vector3(-0.08, -0.05, 0)], 0.045, 0.0, lime, 0.0, 4, false, false)
	for s in [-1.0, 1.0]:
		h.flat(T(), [Vector3(0.28, 0.42, 0.42 * s), Vector3(0.2, 0.18, 0.5 * s), Vector3(0.1, -0.05, 0.5 * s)], 0.08, 0.04, 0.015, hair, Vector3(1, 0, 0), 0.0, 0.1, true)   # side locks
		h.flat(T(), [Vector3(0.1, 0.9, 0.16 * s), Vector3(0.2, 1.04, 0.22 * s), Vector3(0.24, 1.18, 0.3 * s)], 0.07, 0.03, 0.012, lime, Vector3(0, 0, 1), 0.0, 0.0, true)
	for pr in [Vector3(0.5, 0.64, 0.0), Vector3(0.47, 0.54, 0.07), Vector3(0.47, 0.54, -0.07)]:
		h.blob(T(pr), Vector3(0.04, 0.04, 0.04), black, 0.0, 1.0, 5, 3)
	# crown: branching black twig with six spheres
	var tw := Vector3(0.1, 0.9, 0)
	var orbs: Prim = b.part("weapon", Vector3(0.05, 1.3, 0) + tw, "head")   # crown spheres: DETACHABLE (orbit / flick / recall)
	h.lim(T(), [tw, tw + Vector3(0.0, 0.25, 0.0)], 0.06, 0.04, black, 0.0, 5)
	var branches := [[Vector3(0.0, 0.25, 0.0), Vector3(0.1, 0.5, 0.3), Vector3(0.2, 0.62, 0.55), 0.17], [Vector3(0.0, 0.25, 0.0), Vector3(-0.05, 0.55, 0.12), Vector3(0.0, 0.8, 0.1), 0.19],
			[Vector3(0.0, 0.25, 0.0), Vector3(0.1, 0.5, -0.3), Vector3(0.2, 0.66, -0.58), 0.17], [Vector3(0.0, 0.25, 0.0), Vector3(-0.2, 0.42, 0.28), Vector3(-0.36, 0.5, 0.45), 0.15],
			[Vector3(0.0, 0.25, 0.0), Vector3(-0.2, 0.42, -0.28), Vector3(-0.36, 0.54, -0.5), 0.15], [Vector3(0.1, 0.5, 0.3), Vector3(0.3, 0.8, 0.3), Vector3(0.35, 0.98, 0.22), 0.14]]
	for br in branches:
		h.lim(T(), [tw + br[0], tw + br[1], tw + br[2]], 0.035, 0.022, black, 0.0, 4, false, false)
		orbs.blob(T(br[2]), Vector3(br[3], br[3], br[3]), black.lightened(0.04), 0.0, 1.0, 8, 5)
		orbs.blob(T(br[2] + Vector3(br[3] * 0.35, br[3] * 0.45, br[3] * 0.5)), Vector3(br[3] * 0.22, br[3] * 0.22, br[3] * 0.1), Color.html("e8e4f0"), 0.6, 1.0, 5, 3)  # shine
		orbs.blob(T(br[2]), Vector3(br[3] * 0.45, br[3] * 0.45, br[3] * 1.06), Color.html("c9e04a"), 0.35, 1.0, 5, 3)   # gold-green core glow (flares as the tell)
	b.sock("head", "head", Vector3(0.1, 0.38, 0))
	b.set_face(Vector3(0.1, 0.38, 0), Vector3(0.44, 0.42, 0.42),
			{"eye_sep": 0.38, "eye_y": 0.0, "eye_size": Vector2(0.2, 0.2), "eye_white": 1.0, "sclera": Color.html("e8ee7a"), "eye_col": Color.html("141008"),
			"lid_bias": 0.1, "mouth_y": -0.34, "mouth_w": 0.14, "mouth_base": 0.0, "brow_off": 0.06, "brow_len": 0.18, "brow_thick": 0.03, "glasses": 0.0}, 0.95, 0.75, -0.12, 0.92)
	# ---- arms: puffy sleeves, bandaged forearms, long pale hands (front arm = casting hand)
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.0, 1.0, 0.4 * side))
		a.blob(T(Vector3(0.0, -0.18, 0.02 * side)), Vector3(0.2, 0.26, 0.2), purple.lightened(0.06), 0.0, 0.9, 8, 5)
		a.lim(T(), [Vector3(0.04, -0.38, 0.03 * side), Vector3(0.12, -0.6, 0.05 * side)], 0.1, 0.08, cream, 0.0, 6)
		a.ring(T(Vector3(0.05, -0.4, 0.03 * side), Vector3(80, 0, 12)), 0.1, 0.03, purple.lightened(0.15), 0.0, 8, 3)
		a.blob(T(Vector3(0.16, -0.7, 0.06 * side)), Vector3(0.1, 0.12, 0.08), skin, 0.0, 0.9, 6, 4)
		for dz in [-0.04, 0.0, 0.04]:
			a.lim(T(), [Vector3(0.2, -0.76, 0.06 * side + dz), Vector3(0.28, -0.88, 0.07 * side + dz * 1.4)], 0.025, 0.0, skin.darkened(0.1), 0.0, 4, false, false)
	b.sock("hand", "arm_f", Vector3(0.16, -0.7, 0.06))
	b.sock("weapon_base", "arm_f", Vector3(0.16, -0.7, 0.06))
	b.sock("weapon_tip", "arm_f", Vector3(0.32, -0.9, 0.07))
	# ---- belt charms (static on the torso): skull-egg, orange egg, olive pod on cords
	var t2: Prim = b.parts["torso"]["mb"]
	for ch in [[Vector3(0.27, 0.05, 0.22), cream, 0.1, 0.13], [Vector3(0.22, 0.02, -0.24), orange.lightened(0.15), 0.09, 0.12], [Vector3(0.1, 0.03, 0.3), olive, 0.07, 0.09]]:
		t2.lim(T(), [ch[0] + Vector3(0, 0.12, 0), ch[0]], 0.012, 0.012, orange, 0.0, 3, false, false)
		t2.blob(T(ch[0] + Vector3(0, -ch[3] * 0.9, 0)), Vector3(ch[2], ch[3], ch[2] * 0.8), ch[1], 0.0, 1.0, 7, 5)
	t2.blob(T(Vector3(0.3, -0.07, 0.23)), Vector3(0.03, 0.035, 0.02), black, 0.0, 1.0, 4, 3)
	t2.blob(T(Vector3(0.24, -0.07, 0.23)), Vector3(0.03, 0.035, 0.02), black, 0.0, 1.0, 4, 3)
	# ---- treehopper wing cloak (translucent green, black oval spots, purple edge): two big drooping sheets + two lower ones
	var e: Prim = b.part("extra", Vector3(-0.2, 1.1, 0))
	var spot := Color.html("2a2236"); var wg := Color.html("a8c93e"); var vein := Color.html("e2f08a")
	for z in [0.14, -0.14]:
		_wing(e, z, Vector3(-0.05, -0.1, z * 3.2), 1.0, 0.8, 30.0, -8.0, wg, spot, vein)
		_wing(e, z, Vector3(-0.2, -0.2, z * 1.8), 0.85, 0.65, 14.0, -12.0, wg.darkened(0.1), spot, vein)
	e.flat(T(), [Vector3(0.05, 0.12, 0), Vector3(-0.05, -0.3, 0), Vector3(-0.12, -0.7, 0)], 0.26, 0.24, 0.02, purple, Vector3(0, 0, 1), 0.0, 0.0, true)
	b.cfg = {
		"scale": 1.0, "wa": -50.0, "sway": 3.0, "stride": 1.1, "bob": 0.6, "waddle": 0.5, "lag_weapon": 0.05, "lag_extra": 0.02, "flap": 3.0, "flap_hz": 6.0,
		"blink_scale": 1.0, "armb_gain": 0.5, "guard_th": 40.0, "parry_th": 10.0, "hover": 0.0, "detach": ["weapon"],
		"detach_act": {"strike_light": {"part": "weapon", "mode": "goto", "out": Vector3(3.0, 2.3, 0.0), "spin": 360.0, "hold": 4},
				"ability1": {"part": "weapon", "mode": "orbit", "out": Vector3(0.2, 2.6, 0.0), "radius": 1.7, "hz": 1.1, "hold": 30},
				"laststand": {"part": "weapon", "mode": "orbit", "out": Vector3(0.2, 2.6, 0.0), "radius": 2.0, "hz": 1.6, "hold": 30}},
		"ghost_act": {"ability1": {"as": "strike_heavy", "frame": 12, "offset": Vector3(1.3, 0, 0), "count": 2, "life": 1.0}},
		"style": {"strike_light": "punch", "strike_heavy": "slash_up", "ability1": "stance", "ability2": "hook", "laststand": "roar", "grab": "hook"},
		"amp": {"strike_light": 0.7, "strike_heavy": 0.9, "laststand": 1.2},
		"fidget": {"head": PL.K(14, 0, -6), "arm_f": PL.K(0, 0, 40, 0.05, 0.0)},
	}
