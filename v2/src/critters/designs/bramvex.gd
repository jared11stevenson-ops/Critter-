extends RefCounted
## BRAMVEX - "The Quiet Command" (Thornmarch). Brief: tall, thin, angular stick-insect sergeant: long jointed limbs, thorny ridges, patched field
## harness with pouches, torn translucent wings folded like a cloak, a huge thorned club (Diplomacy) taller than him, a small red armband.
## Palette: bark brown, olive, dusty tan + ONE red accent (armband / insignia), amber lantern glow. Insect head (no human face, no hat).

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _thorns(m: Prim, pts: Array, col: Color, n: int, ln: float, up: Vector3 = Vector3(0, 1, 0), th: float = 0.03) -> void:
	for i in range(n):
		var f := (float(i) + 0.5) / n
		var seg := mini(int(f * (pts.size() - 1)), pts.size() - 2)
		var lf := f * (pts.size() - 1) - seg
		var p: Vector3 = (pts[seg] as Vector3).lerp(pts[seg + 1], lf)
		var d := (up + Vector3(0, 0, 0.7 if i % 2 == 0 else -0.7)).normalized()
		m.lim(T(), [p, p + d * ln], th, 0.0, col, 0.0, 4, true, false)

## stick-insect limb: long thin tube with a knobby joint and a thorn ridge
static func _limb(m: Prim, pts: Array, r0: float, r1: float, bark: Color, tan: Color, thorn: Color) -> void:
	m.lim(T(), pts, r0, r1, bark, 0.0, 5)
	for i in range(1, pts.size() - 1):
		m.blob(T(pts[i]), Vector3(r0 * 1.25, r0 * 1.25, r0 * 1.25), tan, 0.0, 1.0, 5, 3)
	_thorns(m, pts, thorn, 4, 0.1, Vector3(-1, 0.2, 0), 0.022)

static func build(b) -> void:
	b.quality = 0.8
	var P: Dictionary = b.pal
	var bark: Color = P["main"]; var red: Color = P["accent"]; var amber: Color = P["glow"]; var tan: Color = P["belly"]
	var olive := Color.html("6b7240"); var wood := Color.html("5a4128"); var thorn := Color.html("8a6a3a"); var brass := Color.html("c9a24a")
	var wing := Color.html("a9b07a")
	# ---- legs: very long thin jointed stick legs, big boots
	for leg in [["leg_f", 0.1, 0.2], ["leg_b", -0.12, -0.2]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 1.5, leg[2]))
		_limb(l, [Vector3(0, 0, 0), Vector3(0.22, -0.7, 0), Vector3(-0.02, -1.42, 0)], 0.075, 0.05, bark, tan, thorn)
		l.blob(T(Vector3(0.12, -1.5, 0)), Vector3(0.3, 0.1, 0.15), wood, 0.0, 0.8, 8, 4)
		l.blob(T(Vector3(0.0, -1.3, 0)), Vector3(0.1, 0.18, 0.1), olive.darkened(0.2), 0.0, 0.9, 6, 4)       # gaiter
	# ---- torso: three slender thorax segments + abdomen stub, olive field jacket scraps, harness with pouches, red armband
	var t: Prim = b.part("torso", Vector3(0, 1.5, 0))
	t.blob(T(Vector3(0, 0.05, 0)), Vector3(0.24, 0.16, 0.2), bark.darkened(0.1), 0.0, 0.9, 8, 5)
	t.blob(T(Vector3(0.02, 0.4, 0)), Vector3(0.26, 0.3, 0.22), bark, 0.0, 0.9, 9, 6)
	t.blob(T(Vector3(0.05, 0.85, 0)), Vector3(0.3, 0.3, 0.24), bark.lightened(0.04), 0.0, 0.9, 9, 6)
	for k in range(3):
		t.ring(T(Vector3(0.02 + 0.015 * k, 0.28 + k * 0.32, 0), Vector3(90, 0, 0)), 0.24 + 0.02 * k, 0.03, thorn, 0.0, 9, 3)    # segment rings
	_thorns(t, [Vector3(-0.2, 0.2, 0), Vector3(-0.2, 0.6, 0), Vector3(-0.15, 1.0, 0)], thorn, 5, 0.2, Vector3(-1, 0.5, 0), 0.04)      # spine thorns
	t.blob(T(Vector3(0.18, 0.6, 0), Vector3(0, 0, 8)), Vector3(0.1, 0.3, 0.3), olive, 0.0, 0.8, 7, 5)                                  # vest panel
	t.lim(T(), [Vector3(0.15, 1.05, 0.22), Vector3(0.3, 0.6, 0.0), Vector3(0.15, 0.2, -0.22)], 0.04, 0.04, wood, 0.0, 4, false, false)   # strap
	t.lim(T(), [Vector3(0.15, 1.05, -0.22), Vector3(0.3, 0.55, 0.0), Vector3(0.15, 0.2, 0.22)], 0.04, 0.04, wood, 0.0, 4, false, false)
	t.ring(T(Vector3(0.0, 0.15, 0), Vector3(90, 0, 0)), 0.26, 0.05, wood, 0.0, 10, 4)                                               # belt
	for z in [-0.2, 0.0, 0.2]:
		t.blob(T(Vector3(0.22, 0.12, z)), Vector3(0.1, 0.12, 0.08), olive.darkened(0.1), 0.0, 0.7, 6, 4)                              # pouches
		t.blob(T(Vector3(0.28, 0.16, z)), Vector3(0.025, 0.04, 0.05), brass, 0.0, 1.0, 4, 3)
	t.blob(T(Vector3(-0.35, 0.05, 0)), Vector3(0.4, 0.2, 0.22), bark.darkened(0.15), 0.0, 0.9, 8, 5)                                  # abdomen stub
	# ---- head: long narrow insect head, two big dark eyes, mandibles, long thorned antennae
	var h: Prim = b.part("head", Vector3(0.12, 2.65, 0))
	h.blob(T(Vector3(0.12, 0.05, 0)), Vector3(0.3, 0.26, 0.24), bark.lightened(0.05), 0.0, 0.9, 10, 6)
	h.blob(T(Vector3(0.38, -0.08, 0), Vector3(0, 0, -15)), Vector3(0.24, 0.13, 0.15), tan.darkened(0.2), 0.0, 0.9, 8, 5)
	for s in [-1.0, 1.0]:
		h.lim(T(), [Vector3(0.5, -0.17, 0.08 * s), Vector3(0.62, -0.32, 0.06 * s)], 0.045, 0.0, thorn, 0.0, 4, true, false)    # mandibles
		var ant := [Vector3(0.1, 0.25, 0.1 * s), Vector3(0.0, 0.8, 0.22 * s), Vector3(-0.1, 1.4, 0.3 * s), Vector3(0.0, 1.9, 0.34 * s)]
		h.lim(T(), ant, 0.03, 0.012, bark, 0.0, 4, true, false)
		_thorns(h, ant, thorn, 6, 0.1, Vector3(-1, 0.2, 0), 0.022)
	h.lim(T(), [Vector3(-0.1, 0.25, 0), Vector3(-0.35, 0.35, 0), Vector3(-0.5, 0.2, 0)], 0.04, 0.02, wood, 0.0, 4, true, false)     # head spine
	b.sock("head", "head", Vector3(0.12, 0.05, 0))
	b.set_face(Vector3(0.12, 0.05, 0), Vector3(0.3, 0.26, 0.24),
			{"eye_sep": 0.5, "eye_y": 0.1, "eye_size": Vector2(0.2, 0.2), "eye_white": 1.0, "sclera": Color.html("1c1410"), "eye_col": Color.html("ff6a3a"),
			"lid_bias": 0.3, "mouth_y": -0.5, "mouth_w": 0.12, "mouth_base": -0.2, "brow_off": 0.06, "brow_len": 0.16, "brow_thick": 0.04}, 1.15, 0.8, 0.05, 0.9)
	# ---- arms: long thin, pale bark, sharp elbows, red armband on the left arm; both hands on Diplomacy
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.05, 2.3, 0.34 * side))
		a.blob(T(), Vector3(0.14, 0.12, 0.14), olive, 0.0, 1.0, 6, 4)
		_limb(a, [Vector3(0, 0, 0), Vector3(-0.1, -0.6, 0.04 * side), Vector3(0.12, -1.2, 0.06 * side)], 0.06, 0.05, bark.lightened(0.08), tan, thorn)
		a.blob(T(Vector3(0.14, -1.28, 0.07 * side)), Vector3(0.1, 0.12, 0.09), tan.darkened(0.1), 0.0, 1.0, 6, 4)
		for dz in [-0.04, 0.0, 0.04]:
			a.lim(T(), [Vector3(0.18, -1.34, 0.07 * side + dz), Vector3(0.26, -1.46, 0.08 * side + dz * 1.4)], 0.02, 0.0, tan, 0.0, 4, false, false)
		if side < 0:
			a.ring(T(Vector3(-0.04, -0.3, -0.02), Vector3(90, 0, 8)), 0.075, 0.035, red, 0.0, 8, 3)     # red armband: the one accent
	b.sock("hand", "arm_f", Vector3(0.14, -1.28, 0.07))
	# Diplomacy: huge thorned club, taller than he is, held diagonally (rigid with the front arm)
	var w2 := Vector3(0.14, -1.28, 0.07)
	var dir := Vector3(0.45, 0.89, 0).normalized()
	var af: Prim = b.parts["arm_f"]["mb"]
	af.tube(T(), [w2 - dir * 0.9, w2 + dir * 0.9, w2 + dir * 2.3, w2 + dir * 3.2], [Vector2(0.06, 0.06), Vector2(0.1, 0.1), Vector2(0.17, 0.17), Vector2(0.15, 0.15)], wood, 0.0, Vector3(0, 0, 1), 7)
	af.lim(T(), [w2 + dir * 3.15, w2 + dir * 3.7], 0.13, 0.0, thorn, 0.0, 6, false, true)
	var up := Vector3(-dir.y, dir.x, 0).normalized()
	for i in range(11):
		var p := w2 + dir * (1.1 + i * 0.2)
		af.lim(T(), [p + up * 0.1, p + up * 0.36], 0.05, 0.0, thorn, 0.0, 4, true, false)
		af.lim(T(), [p + Vector3(0, 0, 0.1), p + Vector3(0, 0, 0.34)], 0.045, 0.0, thorn, 0.0, 4, true, false)
		af.lim(T(), [p - up * 0.1, p - up * 0.3], 0.04, 0.0, thorn, 0.0, 4, true, false)
	af.ring(T(w2 + dir * 1.05, Vector3(0, 0, 25)), 0.15, 0.03, brass, 0.0, 8, 3)
	b.sock("weapon_tip", "arm_f", w2 + dir * 3.7)
	b.sock("weapon_base", "arm_f", w2 + dir * 0.6)
	# ---- lantern + tattered olive sash (lag): small amber glow
	var w: Prim = b.part("weapon", Vector3(0.0, 2.2, 0.36))
	w.lim(T(), [Vector3(0, 0, 0), Vector3(0.0, -0.5, 0)], 0.012, 0.012, wood, 0.0, 3, false, false)
	w.blob(T(Vector3(0, -0.62, 0)), Vector3(0.1, 0.14, 0.1), amber, 1.0, 0.8, 7, 5)
	w.ring(T(Vector3(0, -0.5, 0), Vector3(90, 0, 0)), 0.08, 0.02, brass, 0.0, 8, 3)
	for k in range(3):
		w.flat(T(), [Vector3(-0.1, -0.1, -0.15 + k * 0.1), Vector3(-0.15, -0.7, -0.15 + k * 0.1), Vector3(-0.2, -1.2 + 0.1 * (k % 2), -0.15 + k * 0.1)], 0.07, 0.05, 0.015, olive if k % 2 == 0 else olive.darkened(0.15), Vector3(1, 0, 0), 0.0, 0.0, true)
	# ---- torn translucent wings folded like a cloak (glass), with bark veins and ragged lower edge
	b.glass = ["extra"]
	var e: Prim = b.part("extra", Vector3(-0.15, 2.3, 0))
	for sd in [-1.0, 1.0]:
		for k in range(3):
			var xf := T(Vector3(-0.1 - 0.05 * k, -0.7 - k * 0.1, 0.18 * sd + 0.08 * k * sd), Vector3(0, 0, 8 + 6 * k))
			var ln := 1.3 - 0.2 * k
			e.blob(xf, Vector3(0.012, ln * 0.5, 0.16), wing if k % 2 == 0 else wing.darkened(0.1), 0.0, 1.0, 6, 5)
			e.lim(xf, [Vector3(0.014, ln * 0.5, 0), Vector3(0.014, -ln * 0.48, 0)], 0.016, 0.01, wood, 1.0, 3, false, false)
			e.lim(xf, [Vector3(0.014, ln * 0.1, 0), Vector3(0.014, -ln * 0.15, 0.13 * sd)], 0.01, 0.007, wood, 1.0, 3, false, false)
	b.cfg = {
		"scale": 1.0, "wa": 62.0, "arm_b_follow": true, "sway": 1.5, "stride": 0.9, "bob": 0.5, "waddle": 0.3, "lag_weapon": 0.04, "lag_extra": 0.01,
		"flap": 2.0, "flap_hz": 2.0, "guard_th": 60.0, "parry_th": 40.0, "blink_scale": 1.2,
		"style": {"strike_light": "thrust", "strike_heavy": "overhead", "ability1": "stance", "ability2": "thrust", "laststand": "roar", "grab": "hook"},
		"amp": {"strike_light": 0.8, "strike_heavy": 1.0, "ability2": 1.4, "laststand": 1.0},
		"fidget": {"head": PL.K(0, 0, -10, 0.02, 0.0), "extra": PL.K(0, 0, 12)},
	}
