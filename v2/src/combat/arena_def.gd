class_name ArenaDef extends RefCounted
## 2D fighting plane in meters (x, y). Rectangle or circle. Edges are "wall" (blocks) or
## "drop" (forced movement past it is a ring-out). Optional hazard zones.
var id := "arena"
var shape := "circle"                 # circle | rect
var radius := 7.0
var half := Vector2(8.0, 5.0)
var edge := "drop"                    # circle edge type
var walls: Array = []                 # circle: [[deg_from, deg_to], ...] arcs that are walls
var sides: Dictionary = {"n": "drop", "s": "drop", "e": "drop", "w": "drop"}   # rect
var hazards: Array = []               # {kind: dps|pulse|slow, shape: circle|rect, pos:[x,y], radius, half, dps, period, knock, slow}
var spawns: Array = [Vector2(-3.0, 0.0), Vector2(3.0, 0.0)]
var cracks: Array = []                # [[x, y, radius]] cracked Thoughtstone (Reaching Strike shatters it)

static func from_dict(d: Dictionary) -> ArenaDef:
	var a := ArenaDef.new()
	a.id = str(d.get("id", "arena"))
	a.shape = str(d.get("shape", "circle"))
	a.radius = float(d.get("radius", 7.0))
	var h: Array = d.get("half", [8.0, 5.0])
	a.half = Vector2(float(h[0]), float(h[1]))
	a.edge = str(d.get("edge", "drop"))
	a.walls = d.get("walls", [])
	a.sides = d.get("sides", a.sides)
	a.hazards = d.get("hazards", [])
	a.cracks = d.get("cracks", []).duplicate(true)
	if d.has("spawns"):
		a.spawns = [Vector2(d["spawns"][0][0], d["spawns"][0][1]), Vector2(d["spawns"][1][0], d["spawns"][1][1])]
	return a

static func make_circle(r: float, edge_type: String = "drop") -> ArenaDef:
	var a := ArenaDef.new()
	a.shape = "circle"
	a.radius = r
	a.edge = edge_type
	return a

static func make_rect(w: float, h: float, edge_type: String = "drop") -> ArenaDef:
	var a := ArenaDef.new()
	a.shape = "rect"
	a.half = Vector2(w * 0.5, h * 0.5)
	a.sides = {"n": edge_type, "s": edge_type, "e": edge_type, "w": edge_type}
	return a

## > 0 when p is outside the playable area (distance past the edge), <= 0 inside.
func depth(p: Vector2) -> float:
	if shape == "circle":
		return p.length() - radius
	return maxf(absf(p.x) - half.x, absf(p.y) - half.y)

## Edge type nearest to p ("wall" or "drop").
func edge_type(p: Vector2) -> String:
	if shape == "circle":
		if walls.is_empty():
			return edge
		var ang := fmod(rad_to_deg(atan2(p.y, p.x)) + 360.0, 360.0)
		for w in walls:
			var a0 := fmod(float(w[0]) + 360.0, 360.0)
			var a1 := fmod(float(w[1]) + 360.0, 360.0)
			if (a0 <= a1 and ang >= a0 and ang <= a1) or (a0 > a1 and (ang >= a0 or ang <= a1)):
				return "wall"
		return edge
	var ex := absf(p.x) - half.x
	var ey := absf(p.y) - half.y
	if ex > ey:
		return str(sides["e"] if p.x > 0.0 else sides["w"])
	return str(sides["s"] if p.y > 0.0 else sides["n"])

## Pull p inside the area, leaving `margin` meters to the edge.
func clamp_inside(p: Vector2, margin: float) -> Vector2:
	if shape == "circle":
		var r := radius - margin
		if p.length_squared() > r * r:
			return p.normalized() * r
		return p
	return Vector2(clampf(p.x, -half.x + margin, half.x - margin), clampf(p.y, -half.y + margin, half.y - margin))

func hazard_contains(hz: Dictionary, p: Vector2) -> bool:
	var c := Vector2(float(hz["pos"][0]), float(hz["pos"][1]))
	if str(hz.get("shape", "circle")) == "circle":
		return p.distance_to(c) <= float(hz.get("radius", 1.0))
	var hh: Array = hz.get("half", [1.0, 1.0])
	return absf(p.x - c.x) <= float(hh[0]) and absf(p.y - c.y) <= float(hh[1])
