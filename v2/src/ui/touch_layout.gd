class_name TouchLayout extends RefCounted
## Pure geometry of the on-screen controls (testable without a window). Coordinates are viewport units; the game uses
## canvas_items stretch with 'expand', so the height is always >= 720 and every unit is >= 1 px at 1280x720.
## Offsets are measured from the bottom-right inner corner (viewport minus safe-area margin) and mirrored for left-handed play.

const MIN_DIAMETER := 96.0
# id: [dx, dy, radius, label]
const A := {
	"strike": [-150.0, -150.0, 76.0, "STRIKE"],
	"guard": [-340.0, -92.0, 56.0, "GUARD"],
	"dodge": [-92.0, -326.0, 56.0, "DODGE"],
	"grab": [-262.0, -278.0, 52.0, "GRAB"],
	"ab1": [-456.0, -232.0, 52.0, "A1"],
	"ab2": [-372.0, -384.0, 52.0, "A2"],
	"ls": [-230.0, -440.0, 60.0, "LAST STAND"],
}
const B := {
	"heavy": [-150.0, -150.0, 76.0, "HEAVY"],
	"grab": [-340.0, -92.0, 56.0, "GRAB"],
	"ab1": [-92.0, -326.0, 56.0, "A1"],
	"ab2": [-262.0, -278.0, 52.0, "A2"],
	"ls": [-230.0, -440.0, 60.0, "LAST STAND"],
}
const PAUSE_R := 48.0
const STICK_R := 96.0

## Returns {id: {center: Vector2, r: float, label: String}} for the layout ("A" or "B") in a viewport of `size`.
static func buttons(layout: String, size: Vector2, margins: Vector4, left_handed := false) -> Dictionary:
	var table: Dictionary = A if layout == "A" else B
	var corner := Vector2(size.x - margins.z, size.y - margins.w)
	var out := {}
	for id in table:
		var d: Array = table[id]
		var c := corner + Vector2(float(d[0]), float(d[1]))
		if left_handed:
			c.x = size.x - c.x
		out[id] = {"center": c, "r": float(d[2]), "label": str(d[3])}
	var pc := Vector2(size.x - margins.z - PAUSE_R - 8.0, margins.y + PAUSE_R + 8.0)
	if left_handed:
		pc.x = size.x - pc.x
	out["pause"] = {"center": pc, "r": PAUSE_R, "label": "II"}
	return out

## Where the floating stick may start (the thumb's half of the screen) and its idle hint position.
static func stick_zone(size: Vector2, margins: Vector4, left_handed := false) -> Rect2:
	var r := Rect2(0, size.y * 0.22, size.x * 0.42, size.y * 0.78)
	if left_handed:
		r.position.x = size.x - r.size.x
	return r

static func stick_home(size: Vector2, margins: Vector4, left_handed := false) -> Vector2:
	var p := Vector2(margins.x + 190.0, size.y - margins.w - 170.0)
	if left_handed:
		p.x = size.x - p.x
	return p

## Layout B: the empty right part of the screen where tap / swipe / hold gestures are read.
static func gesture_zone(size: Vector2, left_handed := false) -> Rect2:
	var r := Rect2(size.x * 0.5, size.y * 0.2, size.x * 0.5, size.y * 0.8)
	if left_handed:
		r.position.x = 0.0
	return r

## Names of buttons whose circles overlap or are smaller than the minimum touch size (empty = good).
static func problems(layout: String, size: Vector2, margins: Vector4, left_handed := false) -> Array:
	var bt := buttons(layout, size, margins, left_handed)
	var bad: Array = []
	var ids := bt.keys()
	for i in ids.size():
		var a: Dictionary = bt[ids[i]]
		if float(a["r"]) * 2.0 < MIN_DIAMETER:
			bad.append("%s too small" % ids[i])
		var c: Vector2 = a["center"]
		var rr := float(a["r"])
		if c.x - rr < 0.0 or c.y - rr < 0.0 or c.x + rr > size.x or c.y + rr > size.y:
			bad.append("%s off screen" % ids[i])
		for j in range(i + 1, ids.size()):
			var b: Dictionary = bt[ids[j]]
			if (a["center"] as Vector2).distance_to(b["center"]) < float(a["r"]) + float(b["r"]) + 6.0:
				bad.append("%s overlaps %s" % [ids[i], ids[j]])
	return bad
