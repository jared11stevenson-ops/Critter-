extends RefCounted
## CINDER - "Pressure Cooker": squat tangerine bombardier beetle, soot armor plates, yellow pressure gauges, brass-and-steel
## Boiler Gauntlet with a nozzle, goggles pushed up, always slightly smoking, one eyebrow raised. (ROSTER.md 4)

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func build(b) -> void:
	var P: Dictionary = b.pal
	var orange: Color = P["main"]; var soot: Color = P["accent"]; var yel: Color = P["glow"]; var pale: Color = P["belly"]
	var brass := Color.html("d9a441"); var steel := Color.html("9aa6b4")
	# stubby legs with big boots
	for leg in [["leg_f", 0.18, 0.3], ["leg_b", -0.2, -0.3]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 0.4, leg[2]))
		l.tube(T(), [Vector3(0, 0.03, 0), Vector3(0, -0.22, 0)], [Vector2(0.15, 0.15), Vector2(0.13, 0.13)], soot, 0.0, Vector3(0, 0, 1), 6)
		l.blob(T(Vector3(0.1, -0.29, 0)), Vector3(0.25, 0.12, 0.18), soot.lightened(0.12), 0.0, 0.7, 8, 4)
	# round, squat body with soot plates and gauges
	var t: Prim = b.part("torso", Vector3(0, 0.4, 0))
	t.blob(T(Vector3(0.0, 0.5, 0)), Vector3(0.7, 0.62, 0.66), orange, 0.0, 0.92, 12, 8)
	t.blob(T(Vector3(0.28, 0.3, 0)), Vector3(0.42, 0.34, 0.5), pale, 0.0, 1.0, 8, 5)
	for i in range(3):   # armor plates down the back
		var y := 0.82 - i * 0.28
		t.blob(T(Vector3(-0.5 + i * 0.03, y, 0), Vector3(0, 0, 18 - i * 6)), Vector3(0.2, 0.15, 0.62), soot, 0.0, 0.6, 8, 4)
	for s in [-1.0, 1.0]:   # pressure gauges on the chest
		t.blob(T(Vector3(0.45, 0.62, 0.34 * s), Vector3(0, 28 * s, 0)), Vector3(0.14, 0.14, 0.05), yel, 0.9, 1.0, 9, 4)
		t.ring(T(Vector3(0.45, 0.62, 0.35 * s), Vector3(0, 28 * s, 0)), 0.14, 0.03, brass, 0.0, 10, 4)
	# head: big, goggles pushed up
	var h: Prim = b.part("head", Vector3(0.18, 1.0, 0))
	h.blob(T(Vector3(0.1, 0.34, 0)), Vector3(0.5, 0.44, 0.54), orange.lightened(0.04), 0.0, 0.9, 12, 8)
	h.blob(T(Vector3(0.0, 0.72, 0), Vector3(0, 0, 8)), Vector3(0.36, 0.1, 0.44), soot, 0.0, 0.8, 9, 4)   # strap
	for s in [-1.0, 1.0]:
		h.ring(T(Vector3(0.12, 0.8, 0.2 * s), Vector3(70, 0, 0)), 0.17, 0.05, brass, 0.0, 10, 5)
		h.blob(T(Vector3(0.16, 0.86, 0.2 * s), Vector3(70, 0, 0)), Vector3(0.14, 0.04, 0.14), Color.html("7fe7ff"), 0.6, 1.0, 8, 3)
	for s in [-1.0, 1.0]:   # two little antennae, singed
		h.tube(T(), [Vector3(0.3, 0.7, 0.2 * s), Vector3(0.4, 0.95, 0.3 * s), Vector3(0.3, 1.1, 0.34 * s)],
				[Vector2(0.03, 0.03), Vector2(0.025, 0.025), Vector2(0.02, 0.02)], soot, 0.0, Vector3(0, 0, 1), 4, false, true)
	# Boiler Gauntlet: boxy steel fist + brass bands + long nozzle with a glowing mouth
	var a: Prim = b.part("arm_f", Vector3(0.2, 0.92, 0.66))
	a.tube(T(), [Vector3(0, 0, 0), Vector3(0.14, -0.16, 0.04), Vector3(0.3, -0.1, 0.08)], [Vector2(0.12, 0.12), Vector2(0.11, 0.11), Vector2(0.1, 0.1)], orange.darkened(0.1), 0.0, Vector3(0, 0, 1), 6)
	a.blob(T(Vector3(0.52, -0.1, 0.08)), Vector3(0.34, 0.24, 0.24), steel, 0.0, 0.5, 9, 5)
	for k in [0.36, 0.64]:
		a.blob(T(Vector3(k, -0.1, 0.08)), Vector3(0.06, 0.27, 0.27), brass, 0.0, 0.6, 8, 4)
	a.tube(T(), [Vector3(0.78, -0.1, 0.08), Vector3(1.2, -0.1, 0.08), Vector3(1.42, -0.1, 0.08)], [Vector2(0.11, 0.11), Vector2(0.1, 0.1), Vector2(0.15, 0.15)], steel.darkened(0.1), 0.0, Vector3(0, 0, 1), 8, false, false)
	a.ring(T(Vector3(1.42, -0.1, 0.08), Vector3(0, 90, 0)), 0.15, 0.04, brass, 0.0, 10, 4)
	a.blob(T(Vector3(1.43, -0.1, 0.08), Vector3(0, 0, 0)), Vector3(0.05, 0.12, 0.12), yel, 1.0, 1.0, 8, 4)
	a.blob(T(Vector3(0.58, 0.07, 0.08)), Vector3(0.1, 0.1, 0.1), yel, 0.9, 1.0, 7, 4)
	b.rest_rot["arm_f"] = Vector3(0, 0, 22)
	b.sock("weapon_tip", "arm_f", Vector3(1.5, -0.1, 0.08))
	b.sock("weapon_base", "arm_f", Vector3(0.78, -0.1, 0.08))
	b.sock("hand", "arm_f", Vector3(0.52, -0.1, 0.08))
	var ab: Prim = b.part("arm_b", Vector3(0.2, 0.92, -0.66))
	ab.tube(T(), [Vector3(0, 0, 0), Vector3(0.12, -0.18, -0.04), Vector3(0.22, -0.28, -0.08)], [Vector2(0.12, 0.12), Vector2(0.11, 0.11), Vector2(0.1, 0.1)], orange.darkened(0.15), 0.0, Vector3(0, 0, 1), 6)
	ab.blob(T(Vector3(0.24, -0.3, -0.08)), Vector3(0.14, 0.14, 0.14), soot, 0.0, 1.0, 7, 4)
	ab.tube(T(), [Vector3(0.24, -0.3, -0.08), Vector3(0.5, -0.45, -0.08)], [Vector2(0.04, 0.04), Vector2(0.04, 0.04)], brass, 0.0, Vector3(0, 0, 1), 5)   # wrench
	# firework on a fuse tied to the belt (swings)
	var w: Prim = b.part("weapon", Vector3(-0.1, 0.62, 0.62))
	w.tube(T(), [Vector3(0, 0, 0), Vector3(-0.04, -0.18, 0.03)], [Vector2(0.02, 0.02), Vector2(0.02, 0.02)], soot, 0.0, Vector3(0, 0, 1), 4, false, false)
	w.blob(T(Vector3(-0.04, -0.34, 0.03)), Vector3(0.13, 0.13, 0.13), Color.html("e8453a"), 0.0, 1.0, 8, 5)
	w.blob(T(Vector3(-0.04, -0.2, 0.03)), Vector3(0.05, 0.05, 0.05), yel, 1.0, 1.0, 5, 3)
	# boiler backpack with chimney (lags + wobbles)
	var e: Prim = b.part("extra", Vector3(-0.62, 0.9, 0))
	e.blob(T(Vector3(-0.1, 0.1, 0)), Vector3(0.3, 0.44, 0.34), soot.lightened(0.1), 0.0, 0.8, 9, 6)
	e.tube(T(), [Vector3(-0.1, 0.4, 0.1), Vector3(-0.12, 0.62, 0.1), Vector3(-0.1, 0.78, 0.1)], [Vector2(0.09, 0.09), Vector2(0.08, 0.08), Vector2(0.12, 0.12)], soot.lightened(0.08), 0.0, Vector3(0, 0, 1), 7, false, true)
	e.ring(T(Vector3(-0.1, 0.1, 0), Vector3(90, 0, 0)), 0.3, 0.03, brass, 0.0, 10, 4)
	e.blob(T(Vector3(-0.1, 0.9, 0.1)), Vector3(0.2, 0.14, 0.2), Color(0.5, 0.48, 0.48), 0.0, 1.0, 6, 4)   # soot puff
	b.sock("head", "head", Vector3(0.1, 0.34, 0))
	b.set_face(Vector3(0.1, 0.34, 0), Vector3(0.5, 0.44, 0.54),
			{"eye_sep": 0.4, "eye_y": 0.05, "eye_size": Vector2(0.2, 0.2), "eye_white": 1.0, "eye_col": soot, "sclera": Color.html("fffbe8"),
			"brow_bias": Vector2(0.0, 0.55), "mouth_y": -0.3, "mouth_w": 0.3, "mouth_base": 0.6, "mouth_skew": -0.4, "brow_off": 0.1,
			"brow_len": 0.2, "brow_thick": 0.04, "glint": 1.0}, 1.0, 0.8, -0.02, 0.9)
	b.cfg = {
		"scale": 0.82,
		"wa": 16.0, "sway": 2.0, "stride": 1.3, "bob": 1.2, "waddle": 1.2, "lag_weapon": 0.05, "lag_extra": 0.015, "lag_extra_x": 2.0,
		"guard_th": 70.0, "parry_th": 15.0, "armb_gain": 0.35, "blink_scale": 0.8,
		"style": {"strike_light": "punch", "strike_heavy": "punch", "ability1": "punch", "ability2": "hook", "laststand": "roar", "grab": "hook"},
		"amp": {"strike_heavy": 1.4, "ability1": 1.6, "laststand": 1.5, "strike_light": 0.9},
		"fidget": {"extra": PL.K(0, 0, 14, 0, 0.04), "head": PL.K(0, 0, 6, 0, 0, 0, 1.06, 0.94, 1.06), "torso": PL.K(0, 0, 0, 0, 0, 0, 1.08, 0.94, 1.08)},
	}
