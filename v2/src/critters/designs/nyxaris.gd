extends RefCounted
## NYXARIS - "The Frostbloom Weaver" (Frostbloom). Brief: elegant tall spider-weaver silhouette: two arms + six legs, frost-crystal spinnerets,
## an abdomen patterned like an ice flower, a translucent silk train, venom fangs framing the face, ice-flower accents.
## Palette: deep indigo, ice-blue glow, white-silver silk, pink-magenta flower accents.

const Prim := preload("res://src/critters/prim.gd")
const PL := preload("res://src/critters/pose_lib.gd")

static func T(p: Vector3 = Vector3.ZERO, r: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Prim.T(p, r, s)

static func build(b) -> void:
	b.quality = 0.75
	var P: Dictionary = b.pal
	var ind: Color = P["main"]; var pink: Color = P["accent"]; var ice: Color = P["glow"]; var silk: Color = P["belly"]
	var plum := Color.html("4a2d6a"); var crystal := Color.html("a8d8f0"); var rose := Color.html("f08cc0")
	b.glass = ["extra"]
	# ---- six long spider legs: front trio + rear trio (each trio spans both sides), jointed, with ice tips
	var spec := [["leg_f", 0.35, [[0.45, 1.0], [0.45, -1.0], [-0.05, 1.15]]], ["leg_b", -0.3, [[-0.05, -1.15], [-0.55, 1.0], [-0.55, -1.0]]]]
	for sp in spec:
		var l: Prim = b.part(sp[0], Vector3(sp[1], 1.45, 0.0))
		for ld in sp[2]:
			var dx: float = ld[0]; var dz: float = ld[1]
			var pts := [Vector3(0, 0, dz * 0.12), Vector3(dx * 0.6, 0.55, dz * 0.55), Vector3(dx * 1.1 + 0.05, 0.25, dz * 1.15), Vector3(dx * 1.45 + 0.1, -1.4, dz * 1.45)]
			l.lim(T(), pts, 0.1, 0.035, ind, 0.0, 5)
			l.blob(T(pts[1]), Vector3(0.12, 0.12, 0.12), plum, 0.0, 1.0, 5, 3)
			l.blob(T(pts[2]), Vector3(0.09, 0.09, 0.09), plum, 0.0, 1.0, 5, 3)
			l.lim(T(), [pts[3] + Vector3(0, 0.3, 0), pts[3] + Vector3(0.03, -0.05, 0)], 0.04, 0.0, ice, 0.4, 4, true, false)
			l.ring(T(pts[2].lerp(pts[3], 0.35), Vector3(80, 0, 0)), 0.06, 0.02, silk, 0.0, 6, 3)
	# ---- torso: upright cephalothorax + big abdomen behind patterned like a frost flower (petal crystals), spinnerets
	var t: Prim = b.part("torso", Vector3(0, 1.45, 0))
	t.blob(T(Vector3(0.05, 0.45, 0)), Vector3(0.4, 0.55, 0.4), ind, 0.0, 0.9, 10, 7)
	t.blob(T(Vector3(0.3, 0.45, 0)), Vector3(0.22, 0.4, 0.3), silk.darkened(0.1), 0.0, 0.9, 7, 5)      # fur chest ruff
	for k in range(12):   # chest ruff tufts
		var a := float(k) * 2.4
		var d := Vector3(0.6, sin(a) * 0.8, cos(a) * 0.8).normalized()
		t.lim(T(), [Vector3(0.28, 0.45, 0) + d * 0.2, Vector3(0.28, 0.45, 0) + d * 0.38], 0.06, 0.0, silk, 0.0, 4, true, false)
	t.lim(T(), [Vector3(-0.2, 0.2, 0), Vector3(-0.7, 0.05, 0)], 0.15, 0.15, ind, 0.0, 6)               # pedicel
	t.blob(T(Vector3(-1.1, 0.0, 0), Vector3(0, 0, 10)), Vector3(0.7, 0.55, 0.52), ind.lightened(0.04), 0.0, 0.9, 11, 7)    # abdomen
	for k in range(8):   # ice-flower petals radiating on the abdomen's upper side
		var ang := lerpf(-70.0, 70.0, float(k) / 7.0)
		var ln := 0.55 + 0.2 * sin(float(k) / 7.0 * PI)
		var col := crystal if k % 2 == 0 else rose
		t.flat(T(Vector3(-1.1, 0.35, 0.0), Vector3(ang, 0, 25 + 20 * absf(ang) / 70.0)), [Vector3(0, 0, 0), Vector3(0, ln * 0.55, 0), Vector3(0, ln, 0)], 0.15, 0.08, 0.02, col, Vector3(1, 0, 0), 0.25, 0.25, true, 4)
	t.blob(T(Vector3(-1.1, 0.42, 0)), Vector3(0.1, 0.07, 0.1), Color.html("f4d24a"), 0.8, 1.0, 6, 3)         # flower heart
	for k in range(5):   # glowing pink vein dots / patterns on the abdomen sides
		for sd in [-1.0, 1.0]:
			t.blob(T(Vector3(-0.8 - k * 0.12, 0.05 + 0.08 * sin(k), 0.45 * sd)), Vector3(0.06, 0.06, 0.03), pink, 1.0, 1.0, 5, 3)
	# frost-crystal spinnerets at the tail
	for k in range(3):
		t.flat(T(), [Vector3(-1.7, -0.05, (k - 1) * 0.12), Vector3(-1.95, -0.12 - 0.05 * k, (k - 1) * 0.2), Vector3(-2.15, -0.25, (k - 1) * 0.28)], 0.09, 0.05, 0.03, crystal, Vector3(0, 1, 0), 0.5, 0.3, true, 4)
	# ---- head: furred cream face, venom fangs framing a small mouth, big pink eyes + 4 small eyes, crystal crest
	var h: Prim = b.part("head", Vector3(0.45, 2.25, 0))
	h.blob(T(Vector3(0.1, 0.1, 0)), Vector3(0.4, 0.34, 0.4), silk, 0.0, 0.9, 10, 7)
	for k in range(14):
		var a := float(k) * 2.4
		var d := Vector3(cos(a) * 0.5, sin(a * 1.3) * 0.7, sin(a)).normalized()
		h.lim(T(), [Vector3(0.1, 0.1, 0) + d * Vector3(0.4, 0.34, 0.4), Vector3(0.1, 0.1, 0) + d * Vector3(0.4, 0.34, 0.4) * 1.3], 0.05, 0.0, silk, 0.0, 4, true, false)
	for s in [-1.0, 1.0]:
		h.lim(T(), [Vector3(0.38, -0.12, 0.14 * s), Vector3(0.52, -0.38, 0.2 * s), Vector3(0.48, -0.65, 0.12 * s)], 0.07, 0.0, crystal, 0.3, 5, true, false)    # venom fangs
		h.blob(T(Vector3(0.42, -0.1, 0.22 * s)), Vector3(0.1, 0.1, 0.1), ind, 0.0, 1.0, 6, 4)                                                     # chelicerae
		h.blob(T(Vector3(0.36, 0.34, 0.1 * s)), Vector3(0.045, 0.045, 0.045), pink, 0.9, 1.0, 5, 3)                                              # small eyes
		h.blob(T(Vector3(0.3, 0.45, 0.2 * s)), Vector3(0.04, 0.04, 0.04), pink, 0.9, 1.0, 5, 3)
		h.lim(T(), [Vector3(0.0, 0.4, 0.15 * s), Vector3(-0.1, 0.85, 0.3 * s), Vector3(0.05, 1.2, 0.38 * s)], 0.05, 0.015, pink, 0.4, 5, true, false)  # crest horns
	h.flat(T(), [Vector3(0.1, 0.4, 0), Vector3(0.0, 0.8, 0), Vector3(-0.05, 1.15, 0)], 0.1, 0.05, 0.02, crystal, Vector3(0, 0, 1), 0.4, 0.2, true, 4)
	b.sock("head", "head", Vector3(0.1, 0.1, 0))
	b.set_face(Vector3(0.1, 0.1, 0), Vector3(0.4, 0.34, 0.4),
			{"eye_sep": 0.38, "eye_y": 0.04, "eye_size": Vector2(0.17, 0.17), "eye_white": 1.0, "sclera": Color.html("e0568e"), "eye_col": Color.html("2a0a1c"),
			"mouth_y": -0.42, "mouth_w": 0.12, "mouth_base": -0.2, "brow_off": 0.08, "brow_len": 0.18, "brow_thick": 0.04, "accent": pink}, 1.0, 0.7, -0.05, 0.9)
	# ---- arms: two slender arms with silk-wand hands (pedipalps), silver-wrapped
	for side in [1.0, -1.0]:
		var nm := "arm_f" if side > 0 else "arm_b"
		var a: Prim = b.part(nm, Vector3(0.3, 1.95, 0.4 * side))
		a.lim(T(), [Vector3(0, 0, 0), Vector3(0.12, -0.45, 0.08 * side), Vector3(0.35, -0.8, 0.12 * side)], 0.1, 0.07, ind, 0.0, 6)
		a.ring(T(Vector3(0.1, -0.4, 0.08 * side), Vector3(90, 0, 14)), 0.1, 0.03, silk, 0.0, 8, 3)
		a.blob(T(Vector3(0.38, -0.86, 0.12 * side)), Vector3(0.12, 0.1, 0.1), ind.lightened(0.05), 0.0, 1.0, 6, 4)
		for dz in [-0.04, 0.0, 0.04]:
			a.lim(T(), [Vector3(0.44, -0.9, 0.12 * side + dz), Vector3(0.58, -1.02, 0.13 * side + dz * 1.5)], 0.025, 0.0, crystal, 0.2, 4, false, false)
	var hand := Vector3(0.38, -0.86, 0.12)
	var af: Prim = b.parts["arm_f"]["mb"]
	af.lim(T(), [hand - Vector3(0.1, 0.3, 0), hand + Vector3(0.5, 0.2, 0), hand + Vector3(1.3, 0.5, 0)], 0.03, 0.01, silk, 0.6, 4, true, false)     # silk-line wand
	af.blob(T(hand + Vector3(1.3, 0.5, 0)), Vector3(0.09, 0.09, 0.09), pink, 0.9, 1.0, 6, 4)
	b.sock("weapon_tip", "arm_f", hand + Vector3(1.3, 0.5, 0))
	b.sock("weapon_base", "arm_f", hand)
	b.sock("hand", "arm_f", hand)
	# ---- hanging pink teardrop pendants (lag)
	var w: Prim = b.part("weapon", Vector3(0.55, 1.5, 0.45))
	for k in range(3):
		w.lim(T(), [Vector3(0, 0, k * 0.1 - 0.1), Vector3(0, -0.2 - 0.1 * k, k * 0.1 - 0.1)], 0.012, 0.012, silk, 0.0, 3, false, false)
		w.blob(T(Vector3(0, -0.34 - 0.1 * k, k * 0.1 - 0.1)), Vector3(0.07, 0.12, 0.07), pink, 0.8, 1.0, 6, 4)
	# ---- translucent silk train from the spinnerets (glass): long layered ribbons trailing behind
	var e: Prim = b.part("extra", Vector3(-2.0, 1.45, 0))
	for k in range(7):
		var z := (k - 3) * 0.2
		var ln := 1.6 + 0.3 * (3 - absf(k - 3))
		e.flat(T(), [Vector3(0, 0, z), Vector3(-0.4, -0.5, z * 1.3), Vector3(-0.9, -ln * 0.7, z * 1.6), Vector3(-1.3, -ln + 0.0, z * 1.8)], 0.13, 0.1, 0.012, silk if k % 2 == 0 else crystal.lightened(0.3), Vector3(0, 0, 1), 0.5 if k % 2 else 0.0, 0.2, true, 4)
	b.cfg = {
		"scale": 1.0, "wa": -30.0, "sway": 1.2, "stride": 1.1, "bob": 0.35, "waddle": 0.7, "lag_weapon": 0.04, "lag_extra": 0.02, "lag_extra_x": 2.0,
		"armb_gain": 0.5, "guard_th": 30.0, "parry_th": 0.0, "blink_scale": 1.3,
		"style": {"strike_light": "punch", "strike_heavy": "chop", "ability1": "grab", "ability2": "hook", "laststand": "roar", "grab": "grab"},
		"amp": {"strike_light": 0.8, "strike_heavy": 0.85, "ability1": 0.8, "grab": 0.8},
		"fidget": {"head": PL.K(10, 0, -8, 0.0, 0.0), "extra": PL.K(0, 0, 14)},
	}
