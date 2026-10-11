extends RefCounted
## ART GATE: palette / color test (ART_BIBLE section 6.2): the seven signature colors must be pairwise distinguishable.
## Threshold justification: categorical hue discrimination for saturated colors needs roughly 15-20 degrees; we require
## 20 degrees of hue between every pair of SIGNATURE hues (accents that carry no hue - black, silver, white, cream - are
## excluded by design: the signature is the most chromatic of main/accent/glow, chosen in palettes.gd), and a CIELAB
## delta-E >= 28 so brightness-only twins (e.g. two oranges) also fail. Palette pure-grey signatures fail outright.

const Pal := preload("res://src/critters/palettes.gd")
const MIN_HUE_DEG := 20.0
const MIN_DELTA_E := 28.0
const MIN_SAT := 0.45

static func _lab(c: Color) -> Vector3:
	var r := _lin(c.r); var g := _lin(c.g); var b := _lin(c.b)
	var x := (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
	var y := (0.2126 * r + 0.7152 * g + 0.0722 * b)
	var z := (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
	var fx := _f(x); var fy := _f(y); var fz := _f(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))

static func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)

static func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0

func run() -> Array:
	var fails: Array = []
	var sigs := {}
	for id in Pal.IDS:
		var p: Dictionary = Pal.get_pal(id)
		for k in ["main", "accent", "glow", "sig", "ink"]:
			if not p.has(k):
				fails.append("%s: palette missing %s" % [id, k])
		var s: Color = p["sig"]
		if s.s < MIN_SAT:
			fails.append("%s: signature saturation %.2f < %.2f (critters must be the most saturated things on screen)" % [id, s.s, MIN_SAT])
		sigs[id] = s
		if (p["ink"] as Color).v > 0.2:
			fails.append("%s: outline ink is not a dark tone (v=%.2f)" % [id, (p["ink"] as Color).v])
	var ids: Array = sigs.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a: Color = sigs[ids[i]]; var b: Color = sigs[ids[j]]
			var dh := absf(a.h - b.h) * 360.0
			dh = minf(dh, 360.0 - dh)
			var l1 := _lab(a); var l2 := _lab(b)
			var de := l1.distance_to(l2)
			if dh < MIN_HUE_DEG:
				fails.append("%s vs %s: signature hue distance %.1f deg < %.0f" % [ids[i], ids[j], dh, MIN_HUE_DEG])
			if de < MIN_DELTA_E:
				fails.append("%s vs %s: signature delta-E %.1f < %.0f" % [ids[i], ids[j], de, MIN_DELTA_E])
	return fails
