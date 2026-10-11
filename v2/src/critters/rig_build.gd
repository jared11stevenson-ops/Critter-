extends RefCounted
## RigBuilder: what a design script talks to. Parts are positioned in BODY space (origin = between the feet on the
## ground, +X = forward, +Y = up, +Z = the viewer's side in a side-on bout). Geometry for a part is authored in the
## part's own pivot space (pivot = joint). Parts: torso head arm_f arm_b leg_f leg_b weapon extra.

const Prim := preload("res://src/critters/prim.gd")
const Toon := preload("res://src/critters/toon.gd")

const PART_NAMES := ["torso", "head", "arm_f", "arm_b", "leg_f", "leg_b", "weapon", "extra"]
const DEFAULT_PARENT := {"torso": "", "leg_f": "", "leg_b": "", "head": "torso", "arm_f": "torso", "arm_b": "torso",
		"weapon": "torso", "extra": "torso"}

var pal: Dictionary = {}
var parts: Dictionary = {}      # name -> {mb: Prim, pos: Vector3, parent: String}
var sockets: Dictionary = {}    # name -> {part: String, pos: Vector3}
var face: Dictionary = {}       # {center, radii, half_lon, half_lat, lat_center, params}
var rest_rot: Dictionary = {}   # part -> Vector3 euler degrees baked into the rest pose (poses are relative to it)
var glass: Array = []           # part names rendered with the transparent glass material (no outline)
var cfg: Dictionary = {}        # design config (styles, poses, timings stub, ...)

func part(name: String, pos: Vector3, parent: String = "-") -> Prim:
	var p: String = DEFAULT_PARENT[name] if parent == "-" else parent
	var mb := Prim.new()
	parts[name] = {"mb": mb, "pos": pos, "parent": p}
	return mb

func sock(name: String, part_name: String, local: Vector3) -> void:
	sockets[name] = {"part": part_name, "pos": local}

func set_face(center: Vector3, radii: Vector3, params: Dictionary, half_lon: float = 0.95, half_lat: float = 0.62,
		lat_center: float = -0.05, e: float = 1.0) -> void:
	face = {"e": e, "center": center, "radii": radii, "half_lon": half_lon, "half_lat": half_lat,
			"lat_center": lat_center, "params": params}

## Build MeshInstance3D per part under `rig_root`; returns {nodes, rest, tris, material, face_mat, face_node}
func assemble(rig_root: Node3D) -> Dictionary:
	var mat := Toon.character(pal["glow"], pal["ink"])
	var nodes := {}
	var rest := {}
	var tris := 0
	var order: Array = []
	for n in PART_NAMES:
		if parts.has(n):
			order.append(n)
	# parents first
	order.sort_custom(func(a, b): return (parts[a]["parent"] != "") < (parts[b]["parent"] != ""))
	for n in order:
		var d: Dictionary = parts[n]
		var mi := MeshInstance3D.new()
		mi.name = n
		var mb: Prim = d["mb"]
		mi.mesh = mb.build()
		tris += mb.tris()
		mi.material_override = Toon.glass(pal["glow"]) if glass.has(n) else mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 2.0
		var parent_node: Node3D = rig_root if d["parent"] == "" else nodes[d["parent"]]
		var ppos: Vector3 = Vector3.ZERO if d["parent"] == "" else parts[d["parent"]]["pos"]
		parent_node.add_child(mi)
		mi.position = d["pos"] - ppos
		nodes[n] = mi
		rest[n] = mi.position
	for sn in sockets:
		var s: Dictionary = sockets[sn]
		var m := Marker3D.new()
		m.name = "socket_" + sn
		nodes[s["part"]].add_child(m)
		m.position = s["pos"]
		nodes["sock_" + sn] = m
	var bb := AABB()
	var first := true
	for n in parts:
		var d2: Dictionary = parts[n]
		for v in (d2["mb"] as Prim).verts:
			var wp: Vector3 = v + (d2["pos"] as Vector3)
			if first:
				bb = AABB(wp, Vector3.ZERO)
				first = false
			else:
				bb = bb.expand(wp)
	var res := {"rest_rot": rest_rot, "bounds": bb, "nodes": nodes, "rest": rest, "tris": tris, "mat": mat, "face_node": null, "face_mat": null}
	if not face.is_empty() and nodes.has("head"):
		var fb := Prim.new()
		fb.face_patch(face["center"], face["radii"], face["half_lon"], face["half_lat"], face["lat_center"], 10, 8, 1.015, 0.0, face["e"])
		var fm := MeshInstance3D.new()
		fm.name = "face"
		fm.mesh = fb.build(true)
		var fmat := Toon.face(pal["ink"], pal["glow"])
		fmat.set_shader_parameter("aspect", face["half_lat"] * face["radii"].y / (face["half_lon"] * face["radii"].x))
		for k in face["params"]:
			fmat.set_shader_parameter(k, face["params"][k])
		fm.material_override = fmat
		fm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nodes["head"].add_child(fm)
		res["face_node"] = fm
		res["face_mat"] = fmat
		res["tris"] += fb.tris()
	return res
