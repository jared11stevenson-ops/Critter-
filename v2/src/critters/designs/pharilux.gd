extends RefCounted
## PHARILUX - "The Watcher Below". Brief (approved sheet): tall ghost prey-mantis fused with antique diving + lighthouse forms: lantern-helmet
## head with an amber beacon, antennae hung with small lanterns, two raptorial claw arms (one carries a chain + anchor), tattered
## pale membranes, a cloak of rust chains. Palette: weathered teal, rust bronze, amber glow, tide-mist membranes.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func _lantern(m: Prim, c: Vector3, sz: float, brass: Color, amber: Color) -> void:
	m.blob(T(c), Vector3(sz * 0.8, sz * 1.1, sz * 0.8), amber, 1.0, 1.0, 6, 4)
	m.lim(T(), [c + Vector3(0, sz * 1.2, 0), c + Vector3(0, sz * 1.5, 0)], sz * 0.35, sz * 0.2, brass, 0.0, 4)
	m.lim(T(), [c + Vector3(0, -sz * 1.1, 0), c + Vector3(0, -sz * 1.4, 0)], sz * 0.3, sz * 0.15, brass, 0.0, 4)

static func _anchor(m: Prim, c: Vector3, sz: float, col: Color) -> void:
	m.lim(T(), [c + Vector3(0, sz, 0), c + Vector3(0, -sz, 0)], sz * 0.14, sz * 0.14, col, 0.0, 5)
	m.lim(T(), [c + Vector3(-sz * 0.6, sz * 0.55, 0), c + Vector3(sz * 0.6, sz * 0.55, 0)], sz * 0.11, sz * 0.11, col, 0.0, 4)
	m.lim(T(), [c + Vector3(-sz * 0.8, -sz * 0.45, 0), c + Vector3(0, -sz, 0), c + Vector3(sz * 0.8, -sz * 0.45, 0)], sz * 0.13, sz * 0.13, col, 0.0, 4)

static func build(b) -> void:
	b.quality = 0.85
	var P: Dictionary = b.pal
	var teal: Color = P["main"]; var rust: Color = P["accent"]; var amber: Color = P["glow"]; var mist: Color = P["belly"]
	var brass := Color.html("b98a3e"); var dark := Color.html("2a3a3a"); var membrane := Color.html("b9c9a0"); var spot := Color.html("e6d9a0")
	b.glass = ["extra"]
	# ---- legs: long thin mantis stilts ending in anchor-hook feet
	for leg in [["leg_f", 0.14, 0.2], ["leg_b", -0.14, -0.2]]:
		var l: Prim = b.part(leg[0], Vector3(leg[1], 1.15, leg[2]))
		l.lim(T(), [Vector3(0, 0, 0), Vector3(0.18, -0.55, 0), Vector3(-0.06, -1.1, 0)], 0.085, 0.05, teal, 0.0, 6)
		l.blob(T(Vector3(0.18, -0.55, 0)), Vector3(0.09, 0.09, 0.09), rust, 0.0, 1.0, 6, 4)
		l.lim(T(), [Vector3(-0.06, -1.1, 0), Vector3(0.18, -1.14, 0)], 0.05, 0.02, rust, 0.0, 4, true, false)
	# ---- torso: slim thorax, banded abdomen, rust chain cloak, mantle of membrane scraps
	var t: Prim = b.part("torso", Vector3(0, 1.15, 0))
	t.blob(T(Vector3(0.02, 0.45, 0)), Vector3(0.3, 0.55, 0.26), teal, 0.0, 0.95, 10, 7)
	t.blob(T(Vector3(0.12, 0.42, 0)), Vector3(0.18, 0.4, 0.2), mist, 0.0, 0.9, 8, 5)
	t.lim(T(), [Vector3(-0.2, 0.1, 0), Vector3(-0.5, -0.1, 0), Vector3(-0.85, -0.45, 0)], 0.18, 0.07, teal.darkened(0.12), 0.0, 7)      # abdomen
	for k in range(3):
		t.ring(T(Vector3(-0.3 - 0.17 * k, 0.04 - 0.1 * k, 0), Vector3(0, 90, -20)), 0.15 - 0.03 * k, 0.025, rust, 0.0, 9, 3)
	for k in range(5):   # chain cloak: hanging links with anchor/lantern drops
		var z := (float(k) - 2.0) * 0.12
		t.lim(T(), [Vector3(-0.1, 0.7, z), Vector3(-0.2, 0.2, z * 1.4), Vector3(-0.22, -0.3, z * 1.6)], 0.022, 0.022, rust, 0.0, 4, false, false)
	_anchor(t, Vector3(-0.25, -0.5, 0.0), 0.17, dark)
	_lantern(t, Vector3(0.0, 0.1, 0.25), 0.06, brass, amber)
	t.lim(T(), [Vector3(0.1, 0.9, 0.24), Vector3(0.18, 0.4, 0.0), Vector3(0.1, 0.0, -0.24)], 0.03, 0.03, brass, 0.0, 4, false, false)      # diver's harness strap
	# ---- head: brass diving/lantern helmet with an amber beacon, hooked antennae hung with lanterns
	var h: Prim = b.part("head", Vector3(0.14, 1.95, 0))
	h.blob(T(Vector3(0.05, 0.25, 0)), Vector3(0.3, 0.34, 0.28), teal.lightened(0.05), 0.0, 0.9, 10, 7)
	h.blob(T(Vector3(0.1, 0.32, 0)), Vector3(0.27, 0.27, 0.3), brass, 0.0, 0.85, 10, 6)                       # helmet shell
	h.blob(T(Vector3(0.16, 0.3, 0)), Vector3(0.19, 0.2, 0.2), amber, 1.0, 1.0, 8, 5)                          # beacon lens
	h.lim(T(), [Vector3(0.0, 0.62, 0), Vector3(0.0, 0.78, 0)], 0.05, 0.03, brass, 0.0, 5)                       # helmet crown
	h.blob(T(Vector3(0.0, 0.84, 0)), Vector3(0.06, 0.06, 0.06), amber, 1.0, 1.0, 5, 3)
	for s in [-1.0, 1.0]:
		var ant := [Vector3(0.0, 0.55, 0.1 * s), Vector3(-0.12, 0.95, 0.26 * s), Vector3(-0.1, 1.25, 0.5 * s), Vector3(0.05, 1.2, 0.72 * s)]
		h.lim(T(), ant, 0.022, 0.012, brass, 0.0, 4, true, false)
		_lantern(h, ant[3] + Vector3(0.0, -0.22, 0.0), 0.05, brass, amber)
		_lantern(h, ant[2] + Vector3(-0.06, -0.3, 0.0), 0.035, brass, amber.lightened(0.1))
	b.sock("head", "head", Vector3(0.1, 0.3, 0))
	b.set_face(Vector3(0.1, 0.3, 0), Vector3(0.27, 0.27, 0.3),
			{"eye_sep": 0.5, "eye_y": 0.08, "eye_size": Vector2(0.2, 0.2), "eye_white": 1.0, "sclera": Color.html("1a1208"), "eye_col": amber,
			"mouth_y": -0.62, "mouth_w": 0.06, "mouth_base": 0.1, "brow_off": 0.12, "brow_len": 0.14, "brow_thick": 0.03, "accent": amber, "ringed": 1.0}, 1.0, 0.7, 0.0, 0.9)
	# ---- arms: raptorial mantis claws; front carries the anchor-claw, back is a hooked lantern arm
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.1, 1.75, 0.3 * side))
		a.blob(T(), Vector3(0.1, 0.1, 0.1), rust, 0.0, 1.0, 6, 4)
		a.lim(T(), [Vector3(0, 0, 0), Vector3(0.22, -0.3, 0.04 * side), Vector3(0.1, -0.7, 0.06 * side)], 0.07, 0.05, teal, 0.0, 6)
		a.lim(T(), [Vector3(0.1, -0.7, 0.06 * side), Vector3(0.5, -0.82, 0.08 * side), Vector3(0.78, -0.55, 0.08 * side), Vector3(0.8, -0.25, 0.08 * side)], 0.055, 0.015, rust, 0.0, 6, true, false)   # curved claw
		for k in range(3):
			a.lim(T(), [Vector3(0.45 + k * 0.1, -0.78 + k * 0.03, 0.08 * side), Vector3(0.5 + k * 0.1, -0.62 + k * 0.03, 0.08 * side)], 0.018, 0.0, brass, 0.0, 4, true, false)
	var hand := Vector3(0.8, -0.3, 0.08)
	var af: Prim = b.parts["arm_f"]["mb"]
	af.lim(T(), [hand, hand + Vector3(0.18, 0.14, 0), hand + Vector3(0.1, 0.4, 0)], 0.03, 0.0, rust, 0.0, 4, true, false)
	b.sock("weapon_tip", "arm_f", hand + Vector3(0.05, 0.1, 0))
	b.sock("weapon_base", "arm_f", Vector3(0.1, -0.7, 0.06))
	b.sock("hand", "arm_f", Vector3(0.1, -0.7, 0.06))
	# ---- weapon (lagging): chain and anchor swinging at the hip
	var w: Prim = b.part("weapon", Vector3(-0.12, 1.3, 0.34))
	w.lim(T(), [Vector3(0, 0, 0), Vector3(-0.04, -0.3, 0.02), Vector3(0.02, -0.6, 0.0)], 0.025, 0.025, rust, 0.0, 4, false, false)
	for k in range(4):
		w.ring(T(Vector3(0.0, -0.08 - 0.14 * k, 0.0), Vector3(90 * (k % 2), 0, 0)), 0.04, 0.012, rust.lightened(0.1), 0.0, 6, 3)
	_anchor(w, Vector3(0.02, -0.82, 0.0), 0.22, dark)
	# ---- membranes: long tattered translucent wings with holes, a frayed hem
	var e: Prim = b.part("extra", Vector3(-0.18, 1.8, 0))
	for z in [0.12, -0.12]:
		var xf := T(Vector3(-0.1, -0.35, z * 2.0), Vector3(25.0 * signf(z), 0, 20.0))
		e.blob(xf, Vector3(0.012, 0.95, 0.4), membrane, 0.0, 1.0, 8, 6)
		for k in range(4):
			e.blob(xf * T(Vector3(0.012, -0.6 + k * 0.38, (0.15 - 0.1 * k) * signf(z))), Vector3(0.01, 0.07, 0.07), spot, 0.0, 1.0, 5, 3)
		for k in range(5):   # frayed hem tatters
			e.flat(T(), [Vector3(-0.15, -1.2, (k - 2) * 0.16 * signf(z) + z * 2.0), Vector3(-0.2, -1.55 - 0.1 * (k % 2), (k - 2) * 0.2 * signf(z) + z * 2.0)], 0.1, 0.02, 0.012, membrane.darkened(0.08), Vector3(0, 0, 1), 0.2, 0.2, true, 3)
	b.cfg = {
		"scale": 1.12, "wa": -63.0, "sway": 1.4, "stride": 1.0, "bob": 0.3, "waddle": 0.2, "lag_weapon": 0.09, "lag_extra": 0.02, "flap": 4.0, "flap_hz": 3.0,
		"armb_gain": 0.4, "guard_th": 35.0, "parry_th": 5.0, "blink_scale": 0.7, "hover": 0.12,
		"style": {"strike_light": "hook", "strike_heavy": "overhead", "ability1": "roar", "ability2": "hook", "laststand": "leap", "grab": "grab"},
		"amp": {"strike_light": 0.9, "strike_heavy": 1.0, "laststand": 1.2},
		"fidget": {"head": PL.K(0, 0, 10, 0.02, 0.0), "arm_b": PL.K(0, 0, 30, 0.0, 0.03)},
	}
