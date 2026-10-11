extends RefCounted
## BRAMVEX - "The Quiet Command": prickly stick-insect sergeant. Thin pale-bone limbs and thorny twigs, olive field jacket with belts and
## pouches, green peaked cap with a red band, long red thorny antennae, one red eye, ragged bat-like membranous wing with thorny struts,
## red tattered cape with a gold chevron, glowing red lanterns, and the huge thorned club "Diplomacy".
## Reference: tools/source_art/bramvex_sheet.png.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _thorns(m: Prim, pts: Array, col: Color, n: int, ln: float, up: Vector3 = Vector3(0, 1, 0)) -> void:
	for i in range(n):
		var f := (float(i) + 0.5) / n
		var seg := mini(int(f * (pts.size() - 1)), pts.size() - 2)
		var lf := f * (pts.size() - 1) - seg
		var p: Vector3 = (pts[seg] as Vector3).lerp(pts[seg + 1], lf)
		var d := (up + Vector3(0, 0, 0.6 if i % 2 == 0 else -0.6)).normalized()
		m.lim(T(), [p, p + d * ln], 0.03, 0.0, col, 0.0, 4, true, false)

static func build(b) -> void:
	b.quality = 0.8
	var P: Dictionary = b.pal
	var olive: Color = P["main"]; var red: Color = P["accent"]; var glow: Color = P["glow"]; var tan: Color = P["belly"]
	var bone := Color.html("c4b088"); var wood := Color.html("6b4a30"); var brown := Color.html("4a3322"); var thorn := Color.html("b32a22")
	var gold := Color.html("d9a73c"); var wing := Color.html("808a58")
	# ---- legs: thin pale stick legs, sharp knees, heavy brown boots
	for leg in [["leg_f", 0.12, 0.2], ["leg_b", -0.12, -0.2]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 1.05, leg[2]))
		l.lim(T(), [Vector3(0, 0, 0), Vector3(0.18, -0.5, 0), Vector3(-0.02, -0.98, 0)], 0.085, 0.06, bone, 0.0, 5)
		l.blob(T(Vector3(0.2, -0.5, 0)), Vector3(0.07, 0.07, 0.07), tan.darkened(0.2), 0.0, 1.0, 5, 3)
		l.lim(T(), [Vector3(0.2, -0.5, 0), Vector3(0.34, -0.46, 0)], 0.035, 0.0, thorn, 0.0, 4, true, false)    # knee thorn
		l.blob(T(Vector3(0.1, -1.0, 0)), Vector3(0.3, 0.1, 0.16), brown, 0.0, 0.8, 8, 4)
		l.blob(T(Vector3(0.0, -0.9, 0)), Vector3(0.13, 0.16, 0.13), olive.darkened(0.2), 0.0, 0.9, 6, 4)
	# ---- torso: olive jacket, belts, pouches, strap, gold-chevron red sash; tattered olive skirt
	var t: Prim = b.part("torso", Vector3(0, 1.05, 0))
	t.blob(T(Vector3(0, 0.1, 0)), Vector3(0.28, 0.2, 0.26), olive.darkened(0.1), 0.0, 0.9, 8, 5)
	t.blob(T(Vector3(0.02, 0.5, 0)), Vector3(0.3, 0.42, 0.28), olive, 0.0, 0.85, 9, 6)
	t.ring(T(Vector3(0, 0.2, 0), Vector3(90, 0, 0)), 0.28, 0.04, brown, 0.0, 10, 4)
	for z in [-0.18, 0.0, 0.18]:
		t.blob(T(Vector3(0.22, 0.14, z)), Vector3(0.09, 0.1, 0.07), wood, 0.0, 0.7, 6, 4)
	t.lim(T(), [Vector3(0.16, 0.9, 0.2), Vector3(0.28, 0.5, 0.0), Vector3(0.16, 0.12, -0.2)], 0.035, 0.035, brown, 0.0, 4, false, false)    # bandolier
	for k in range(6):
		var z := -0.25 + k * 0.1
		t.flat(T(), [Vector3(0.1, 0.05, z), Vector3(0.12, -0.25, z), Vector3(0.05, -0.55 - 0.05 * (k % 2), z)], 0.09, 0.05, 0.015, olive.lightened(0.05) if k % 2 == 0 else olive.darkened(0.2), Vector3(1, 0, 0), 0.0, 0.0, true)
	t.flat(T(), [Vector3(0.28, 0.0, 0.0), Vector3(0.34, -0.3, 0), Vector3(0.3, -0.62, 0)], 0.12, 0.1, 0.015, red, Vector3(0, 0, 1), 0.0, 0.0, true)
	t.blob(T(Vector3(0.345, -0.2, 0), Vector3(0, 90, 0)), Vector3(0.05, 0.09, 0.015), gold, 0.0, 1.0, 5, 3)    # chevron
	t.lim(T(), [Vector3(0.0, 0.88, 0), Vector3(0.1, 1.05, 0)], 0.09, 0.08, bone, 0.0, 5)    # neck
	for tw2 in [[Vector3(-0.2, 0.8, 0.2), Vector3(-0.4, 1.1, 0.35), Vector3(-0.45, 1.4, 0.3)], [Vector3(-0.15, 0.7, -0.22), Vector3(-0.35, 0.95, -0.4), Vector3(-0.3, 1.25, -0.45)]]:
		t.lim(T(), tw2, 0.035, 0.012, wood, 0.0, 4, true, false)
		t.flat(T(), [tw2[2], tw2[2] + Vector3(-0.1, 0.1, 0.0), tw2[2] + Vector3(-0.2, 0.18, 0.05)], 0.07, 0.03, 0.012, olive.lightened(0.15), Vector3(0, 0, 1), 0.0, 0.3, true)
	for sp2 in [Vector3(0.0, 0.85, 0.3), Vector3(0.0, 0.85, -0.3), Vector3(-0.2, 0.7, 0.28), Vector3(-0.2, 0.7, -0.28)]:
		t.lim(T(), [sp2, sp2 + Vector3(-0.1, 0.25, sign(sp2.z) * 0.18)], 0.05, 0.0, thorn, 0.0, 4, true, false)
	# ---- head: narrow skull-like face, red eye, peaked cap, long red thorny antennae, twig with leaves
	var h: Prim = b.part("head", Vector3(0.16, 2.12, 0))
	h.blob(T(Vector3(0.1, 0.1, 0)), Vector3(0.34, 0.34, 0.3), bone, 0.0, 0.9, 11, 7)
	h.blob(T(Vector3(0.3, -0.12, 0), Vector3(0, 0, -20)), Vector3(0.2, 0.12, 0.14), bone.darkened(0.1), 0.0, 0.9, 7, 4)
	for s2 in [-1.0, 1.0]:
		h.lim(T(), [Vector3(0.0, 0.0, 0.3 * s2), Vector3(-0.1, -0.05, 0.5 * s2)], 0.05, 0.0, thorn, 0.0, 4, true, false)
		h.lim(T(), [Vector3(0.2, -0.18, 0.12 * s2), Vector3(0.28, -0.4, 0.2 * s2)], 0.04, 0.0, thorn, 0.0, 4, true, false)
		h.lim(T(), [Vector3(0.1, 0.25, 0.28 * s2), Vector3(0.05, 0.3, 0.46 * s2)], 0.04, 0.0, thorn, 0.0, 4, true, false)
	h.blob(T(Vector3(0.02, 0.38, 0), Vector3(0, 0, 4)), Vector3(0.38, 0.14, 0.38), olive.darkened(0.15), 0.0, 0.8, 10, 4)             # cap crown
	h.blob(T(Vector3(0.2, 0.3, 0), Vector3(0, 0, -10)), Vector3(0.3, 0.035, 0.34), brown, 0.0, 0.8, 9, 3)                              # visor
	h.ring(T(Vector3(0.02, 0.3, 0), Vector3(90, 0, 0)), 0.34, 0.035, red, 0.0, 12, 3)
	h.blob(T(Vector3(0.4, 0.4, 0), Vector3(0, 90, 0)), Vector3(0.05, 0.05, 0.02), gold, 0.0, 1.0, 5, 3)
	for s in [-1.0, 1.0]:
		var ant := [Vector3(0.1, 0.45, 0.1 * s), Vector3(0.2, 0.95, 0.2 * s), Vector3(0.28, 1.45, 0.3 * s), Vector3(0.42, 1.85, 0.34 * s)]
		h.lim(T(), ant, 0.03, 0.01, thorn, 0.0, 4, true, false)
		_thorns(h, ant, thorn, 5, 0.1, Vector3(-1, 0.2, 0))
	var tw := [Vector3(-0.1, 0.5, 0), Vector3(-0.25, 0.8, 0.05), Vector3(-0.2, 1.1, 0.0)]
	h.lim(T(), tw, 0.035, 0.015, wood, 0.0, 4, true, false)
	for lp in [Vector3(-0.25, 0.8, 0.05), Vector3(-0.2, 1.1, 0)]:
		h.flat(T(), [lp, lp + Vector3(-0.1, 0.1, 0.12), lp + Vector3(-0.16, 0.2, 0.2)], 0.07, 0.03, 0.012, olive.lightened(0.12), Vector3(1, 0, 0), 0.0, 0.3, true)
	b.sock("head", "head", Vector3(0.1, 0.1, 0))
	b.set_face(Vector3(0.1, 0.1, 0), Vector3(0.34, 0.34, 0.3),
			{"eye_sep": 0.42, "eye_y": 0.05, "eye_size": Vector2(0.14, 0.14), "eye_white": 1.0, "sclera": Color.html("1c0f0f"), "eye_col": Color.html("ff2a1a"),
			"lid_bias": 0.35, "mouth_y": -0.45, "mouth_w": 0.12, "mouth_base": -0.2, "brow_off": 0.05, "brow_len": 0.17, "brow_thick": 0.04}, 1.0, 0.7, -0.15, 0.9)
	# ---- arms: long bone-pale, sharp elbows; both hands on Diplomacy
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.05, 1.82, 0.36 * side))
		a.blob(T(Vector3(0, 0.0, 0.0)), Vector3(0.16, 0.14, 0.16), olive, 0.0, 1.0, 6, 4)
		a.lim(T(), [Vector3(0, 0, 0), Vector3(-0.1, -0.5, 0.04 * side), Vector3(0.28, -0.7, 0.06 * side)], 0.075, 0.06, bone, 0.0, 5)
		a.lim(T(), [Vector3(-0.1, -0.5, 0.04 * side), Vector3(-0.24, -0.58, 0.06 * side)], 0.035, 0.0, thorn, 0.0, 4, true, false)
		a.blob(T(Vector3(0.3, -0.72, 0.07 * side)), Vector3(0.1, 0.09, 0.09), bone.lightened(0.05), 0.0, 1.0, 6, 4)
	b.sock("hand", "arm_f", Vector3(0.3, -0.72, 0.07))
	# Diplomacy: huge thorn-studded club, spiked tip (rigid on the front arm)
	var a2: Prim = null
	var w2 := Vector3(0.3, -0.72, 0.07)
	var dir := Vector3(0.82, -0.57, 0).normalized()
	var stk := [w2 - dir * 0.7, w2 + dir * 0.6, w2 + dir * 1.5, w2 + dir * 2.4]
	var af: Prim = b.parts["arm_f"]["mb"]
	af.tube(T(), stk, [Vector2(0.07, 0.07), Vector2(0.12, 0.12), Vector2(0.17, 0.17), Vector2(0.12, 0.12)], wood, 0.0, Vector3(0, 0, 1), 7)
	af.lim(T(), [w2 + dir * 2.35, w2 + dir * 2.85], 0.12, 0.0, brown, 0.0, 6, false, true)
	for i in range(9):
		var f := 0.3 + i * 0.2
		var p := w2 + dir * (f * 2.2)
		var up := Vector3(0.57, 0.82, 0).normalized()
		af.lim(T(), [p + up * 0.12, p + up * 0.34], 0.045, 0.0, thorn, 0.0, 4, true, false)
		af.lim(T(), [p + Vector3(0, 0, 0.12), p + Vector3(0, 0, 0.3) + dir * 0.05], 0.04, 0.0, thorn, 0.0, 4, true, false)
	b.sock("weapon_tip", "arm_f", w2 + dir * 2.85)
	b.sock("weapon_base", "arm_f", w2 + dir * 0.4)
	# ---- lantern + red cape tatters hanging from the shoulders (lag)
	var w: Prim = b.part("weapon", Vector3(-0.1, 1.85, 0.3))
	for k in range(4):
		var z := -0.1 + k * 0.2 - 0.3
		w.flat(T(), [Vector3(0, 0, z), Vector3(-0.1, -0.5, z), Vector3(-0.15 - 0.05 * k, -1.1 + 0.1 * (k % 2), z)], 0.13, 0.08, 0.015, red if k % 2 == 0 else red.darkened(0.2), Vector3(1, 0, 0), 0.0, 0.0, true)
	w.lim(T(), [Vector3(0.1, -0.1, 0.36), Vector3(0.1, -0.5, 0.36)], 0.012, 0.012, brown, 0.0, 3, false, false)
	w.blob(T(Vector3(0.1, -0.62, 0.36)), Vector3(0.1, 0.14, 0.1), glow, 1.0, 0.8, 7, 5)
	w.ring(T(Vector3(0.1, -0.5, 0.36), Vector3(90, 0, 0)), 0.08, 0.02, gold, 0.0, 8, 3)
	# ---- ragged bat wing with thorny bone struts (arches up behind; flaps/sways)
	var e: Prim = b.part("extra", Vector3(-0.2, 1.7, 0), "-")
	e.lim(T(), [Vector3(0, 0, 0), Vector3(0, 0, 0)], 0.001, 0.001, wood, 0.0, 3)
	var sh := Vector3(0, 0, 0.0)
	var wr := Vector3(-0.5, 1.3, 0.0)
	var struts := [wr + Vector3(-0.2, 0.8, 0), wr + Vector3(-1.1, 0.3, 0), wr + Vector3(-1.2, -0.7, 0), wr + Vector3(-0.6, -1.6, 0)]
	e.lim(T(), [sh, Vector3(-0.25, 0.7, 0), wr], 0.09, 0.06, wood, 0.0, 5)
	for sp in struts:
		e.lim(T(), [wr, wr.lerp(sp, 0.55) + Vector3(0, 0, 0.0), sp], 0.045, 0.012, wood, 0.0, 4, false, false)
		_thorns(e, [wr, sp], thorn, 3, 0.1, Vector3(0, 0.3, 1))
	for i in range(struts.size() - 1):
		var a1: Vector3 = struts[i]
		var a2v: Vector3 = struts[i + 1]
		var mid := wr.lerp(a1.lerp(a2v, 0.5), 0.55)
		var d := (a1 - a2v)
		e.flat(T(), [wr.lerp(a1, 0.25).lerp(wr.lerp(a2v, 0.25), 0.5), mid, a1.lerp(a2v, 0.5) * 0.92], d.length() * 0.35, d.length() * 0.45, 0.012, wing if i % 2 == 0 else wing.darkened(0.1), Vector3(-d.y, d.x, 0).normalized(), 0.0, 0.2, true)
	b.rest_rot["torso"] = Vector3(0, 0, -16)
	b.cfg = {
		"scale": 1.0, "wa": -35.0, "arm_b_follow": true, "sway": 1.5, "stride": 0.9, "bob": 0.5, "waddle": 0.3, "lag_weapon": 0.04, "lag_extra": 0.01,
		"flap": 3.0, "flap_hz": 2.0, "guard_th": 30.0, "parry_th": 5.0, "blink_scale": 1.2,
		"style": {"strike_light": "thrust", "strike_heavy": "overhead", "ability1": "stance", "ability2": "thrust", "laststand": "roar", "grab": "hook"},
		"amp": {"strike_light": 0.8, "strike_heavy": 1.0, "ability2": 1.4, "laststand": 1.0},
		"fidget": {"head": PL.K(0, 0, -10, 0.02, 0.0), "extra": PL.K(0, 0, 12)},
	}
