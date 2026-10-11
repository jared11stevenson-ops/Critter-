class_name ExploreRules
extends RefCounted
## Pure, allocation-light helpers for open-world feel: steering/avoidance for wandering NPCs, respawn cooldown maths,
## weighted picks, floor-shape queries and minimap projection. No scene access, so every rule is unit-testable headless.

## Steer `dir` (unit, XZ) away from nearby bodies. `others` are Vector3 positions; each closer than `radius` pushes back in
## proportion to how deep we are inside it; a body dead ahead also adds a sidestep (always to the same side for a given
## pair, so two NPCs walking head-on pass each other instead of mirroring). Returns a unit vector (or `dir` if free).
static func steer(pos: Vector3, dir: Vector3, others: Array, radius: float, strength: float = 1.6) -> Vector3:
	var d := Vector3(dir.x, 0.0, dir.z)
	if d.length_squared() < 0.0001:
		return Vector3.ZERO
	d = d.normalized()
	var push := Vector3.ZERO
	var r2 := radius * radius
	for o in others:
		var off: Vector3 = pos - (o as Vector3)
		off.y = 0.0
		var l2 := off.length_squared()
		if l2 >= r2 or l2 < 0.000001:      # out of reach, or it is ourselves
			continue
		var l := sqrt(l2)
		var depth := 1.0 - l / radius
		var away := off / l
		push += away * depth
		var ahead := -away.dot(d)               # 1 = body straight in front
		if ahead > 0.25:
			var side := Vector3(-d.z, 0.0, d.x)   # left of travel
			push += side * depth * ahead * 0.9    # everyone slips to their own left: head-on pairs part cleanly
	var out := d + push * strength
	out.y = 0.0
	return out.normalized() if out.length_squared() > 0.0001 else d

## True when `pos` is overlapping any of `others` closer than `min_dist` (XZ).
static func overlaps(pos: Vector3, others: Array, min_dist: float) -> bool:
	for o in others:
		var off: Vector3 = pos - (o as Vector3)
		if Vector2(off.x, off.z).length() < min_dist:
			return true
	return false

## Indices of `candidates` (Vector3) that are at least `min_dist` from every `occupied` spot. Used so two NPCs never
## reserve the same standing place; the caller picks among them at random for variety.
static func free_indices(candidates: Array, occupied: Array, min_dist: float) -> Array:
	var out: Array = []
	for i in candidates.size():
		if not overlaps(candidates[i], occupied, min_dist):
			out.append(i)
	return out

## Cooldown before a cleared roaming group may return: base * growth^clears, capped at base * cap_mult.
static func cooldown(base_s: float, clears: int, growth: float = 1.6, cap_mult: float = 4.0) -> float:
	return base_s * minf(pow(growth, float(maxi(clears, 0))), cap_mult)

## Weighted pick: entries are Dictionaries with "w"; `roll` is 0..1. `mods` multiplies weight by species (e.g. time of day).
static func pick_weighted(entries: Array, roll: float, mods: Dictionary = {}) -> int:
	var total := 0.0
	for e in entries:
		total += maxf(0.0, float(e.get("w", 1.0)) * float(mods.get(str(e.get("species", "")), 1.0)))
	if total <= 0.0:
		return -1
	var r := clampf(roll, 0.0, 0.99999) * total
	for i in entries.size():
		var e: Dictionary = entries[i]
		r -= maxf(0.0, float(e.get("w", 1.0)) * float(mods.get(str(e.get("species", "")), 1.0)))
		if r < 0.0:
			return i
	return entries.size() - 1

# ---------------------------------------------------------------- floors (layout.json shapes)
## Distance from (x,z) to the walkable shape `f` (negative inside). Shapes: disc {c,r}, capsule {a,b,r}.
static func shape_dist(f: Dictionary, x: float, z: float) -> float:
	var p := Vector2(x, z)
	if str(f.get("type", "")) == "disc":
		var c: Array = f["c"]
		return p.distance_to(Vector2(float(c[0]), float(c[1]))) - float(f["r"])
	var a: Array = f["a"]
	var b: Array = f["b"]
	var pa := Vector2(float(a[0]), float(a[1]))
	var pb := Vector2(float(b[0]), float(b[1]))
	var ab := pb - pa
	var t := clampf((p - pa).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(pa + ab * t) - float(f["r"])

## Inside some floor with at least `margin` metres to spare?
static func on_floor(floors: Array, x: float, z: float, margin: float = 0.0) -> bool:
	for f in floors:
		if shape_dist(f, x, z) <= -margin:
			return true
	return false

## Polygon outline (Vector2 points, XZ plane) of a floor shape for the minimap.
static func shape_poly(f: Dictionary, segs: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if str(f.get("type", "")) == "disc":
		var c: Array = f["c"]
		var r := float(f["r"])
		for i in segs:
			var a := TAU * float(i) / float(segs)
			pts.append(Vector2(float(c[0]) + cos(a) * r, float(c[1]) + sin(a) * r))
		return pts
	var pa := Vector2(float(f["a"][0]), float(f["a"][1]))
	var pb := Vector2(float(f["b"][0]), float(f["b"][1]))
	var r2 := float(f["r"])
	var ang := (pb - pa).angle()
	var half := segs / 2
	for i in half + 1:      # cap around b
		var a := ang - PI * 0.5 + PI * float(i) / float(half)
		pts.append(pb + Vector2(cos(a), sin(a)) * r2)
	for i in half + 1:      # cap around a
		var a := ang + PI * 0.5 + PI * float(i) / float(half)
		pts.append(pa + Vector2(cos(a), sin(a)) * r2)
	return pts

# ---------------------------------------------------------------- minimap projection
## World XZ offset -> panel pixel offset from the panel centre (north up: -z is up). `px_per_m` zoom.
static func to_map(dx: float, dz: float, px_per_m: float) -> Vector2:
	return Vector2(dx, dz) * px_per_m

## Clamp a panel offset to the inside of a square of half-size `half` along the same ray (for edge chevrons).
static func clamp_to_edge(off: Vector2, half: float) -> Vector2:
	var m := maxf(absf(off.x), absf(off.y))
	if m <= half or m < 0.0001:
		return off
	return off * (half / m)

static func compass_word(dx: float, dz: float) -> String:
	if Vector2(dx, dz).length() < 0.5:
		return "here"
	var a := fposmod(rad_to_deg(atan2(dx, -dz)), 360.0)    # 0 = north (-z), 90 = east (+x)
	var names := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	return names[int(round(a / 45.0)) % 8]
