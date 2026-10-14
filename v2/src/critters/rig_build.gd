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
var swarm: Dictionary = {}      # {mb: Prim (ONE body), rest: [Vector3], parent: String, pos: Vector3 (body space)} drawn with a MultiMesh
var quality := 1.0              # tri-budget knob, see Prim.quality
var glass: Array = []           # part names rendered with the transparent glass material (no outline)
var cfg: Dictionary = {}        # design config (styles, poses, timings stub, ...)
var glb_meshes: Dictionary = {} # part name -> Mesh authored in Blender (res://art/models/<id>.glb); replaces the procedural geometry of that part
var glb_used := false
var glb_gain := 1.35               # texture brightness for generated models (sidecar "tex_gain")
var glb_nrm: Texture2D = null      # baked tangent-space normal atlas of a generated model (keeps the fine detail the low-poly parts lost)
var glb_soft := 0.0                # 0 = classic cel bands, 1 = soft wrap lighting so painted detail stays readable
var glb_outline := -1.0            # outline width override in px (thinner ink keeps faces readable); <0 = default
var glb_tex: Texture2D = null   # albedo texture of a generated (textured) model; the toon shader samples it instead of vertex colour

func part(name: String, pos: Vector3, parent: String = "-") -> Prim:
	var p: String = DEFAULT_PARENT[name] if parent == "-" else parent
	var mb := Prim.new()
	mb.quality = quality
	parts[name] = {"mb": mb, "pos": pos, "parent": p}
	return mb

func sock(name: String, part_name: String, local: Vector3) -> void:
	sockets[name] = {"part": part_name, "pos": local}

func set_face(center: Vector3, radii: Vector3, params: Dictionary, half_lon: float = 0.95, half_lat: float = 0.62,
		lat_center: float = -0.05, e: float = 1.0) -> void:
	face = {"e": e, "center": center, "radii": radii, "half_lon": half_lon, "half_lat": half_lat,
			"lat_center": lat_center, "params": params}

## Replaces procedural part geometry with the Blender model res://art/models/<id>.glb (+ <id>.json: face patch, sockets, cfg overrides).
## Node origins in the glb are the joint pivots (body space). Returns false when there is no model.
func use_glb(id: String) -> bool:
	var path := "res://art/models/%s.glb" % id
	if not ResourceLoader.exists(path):
		return false
	var ps = load(path)
	if ps == null:
		return false
	var root: Node = (ps as PackedScene).instantiate()
	for ch in root.get_children():
		if ch is MeshInstance3D and PART_NAMES.has(str(ch.name)):
			var pn := str(ch.name)
			glb_meshes[pn] = (ch as MeshInstance3D).mesh
			if glb_tex == null and (ch as MeshInstance3D).mesh.get_surface_count() > 0:
				var gm = (ch as MeshInstance3D).mesh.surface_get_material(0)
				if gm is BaseMaterial3D and (gm as BaseMaterial3D).albedo_texture != null:
					glb_tex = (gm as BaseMaterial3D).albedo_texture
				if gm is BaseMaterial3D and (gm as BaseMaterial3D).normal_enabled and (gm as BaseMaterial3D).normal_texture != null:
					glb_nrm = (gm as BaseMaterial3D).normal_texture
			if parts.has(pn):
				parts[pn]["pos"] = (ch as Node3D).position
				parts[pn]["mb"] = Prim.new()
			else:
				parts[pn] = {"mb": Prim.new(), "pos": (ch as Node3D).position, "parent": DEFAULT_PARENT[pn]}
	root.queue_free()
	var jp := "res://art/models/%s.json" % id
	if FileAccess.file_exists(jp):
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(jp))
		for sn in meta.get("sockets", {}):
			var sd: Array = meta["sockets"][sn]
			sockets[sn] = {"part": str(sd[0]), "pos": Vector3(sd[1], sd[2], sd[3])}
		if meta.has("face") and not face.is_empty():
			var fd: Dictionary = meta["face"]
			face["center"] = Vector3(fd["center"][0], fd["center"][1], fd["center"][2])
			face["radii"] = Vector3(fd["radii"][0], fd["radii"][1], fd["radii"][2])
			for k in ["half_lon", "half_lat", "lat_center", "e"]:
				if fd.has(k):
					face[k] = float(fd[k])
		elif meta.has("face_off"):
			face = {}
		if meta.has("tex_soft"):
			glb_soft = float(meta["tex_soft"])
		if meta.has("outline_px"):
			glb_outline = float(meta["outline_px"])
		if meta.has("tex_gain"):
			glb_gain = float(meta["tex_gain"])
		if bool(meta.get("textured", false)):
			glass = []                       # a textured model carries its own wings/cloth: no transparent glass override
		if bool(meta.get("swarm_off", false)):
			swarm = {}                       # the model carries its own (static) crown spheres: no procedural swarm
			cfg.erase("swarm_rest")
			cfg.erase("swarm_act")
		elif meta.has("swarm_rest") and not swarm.is_empty():
			var rest: Array = []
			for r in meta["swarm_rest"]:
				rest.append(Vector3(r[0], r[1], r[2]))
			swarm["rest"] = rest
			cfg["swarm_rest"] = rest
			var sp: Array = meta["swarm_pos"]
			swarm["pos"] = Vector3(sp[0], sp[1], sp[2])
		for k in meta.get("cfg", {}):
			cfg[k] = meta["cfg"][k]
	glb_used = not glb_meshes.is_empty()
	return glb_used

## Shrinks/grows the head about the neck pivot (face patch and head sockets follow).
func scale_head(k: float) -> void:
	if not parts.has("head") or is_equal_approx(k, 1.0):
		return
	(parts["head"]["mb"] as Prim).scale_all(Vector3.ONE * k)
	if not face.is_empty():
		face["center"] = (face["center"] as Vector3) * k
		face["radii"] = (face["radii"] as Vector3) * k
	for sn in sockets:
		if str(sockets[sn]["part"]) == "head":
			sockets[sn]["pos"] = (sockets[sn]["pos"] as Vector3) * k

## Build MeshInstance3D per part under `rig_root`; returns {nodes, rest, tris, material, face_mat, face_node}
func assemble(rig_root: Node3D) -> Dictionary:
	var mat := Toon.character(pal["glow"], pal["ink"])
	if glb_tex != null:
		mat.set_shader_parameter("albedo_tex", glb_tex)
		mat.set_shader_parameter("use_tex", 1.0)
		mat.set_shader_parameter("tex_gain", glb_gain)
		mat.set_shader_parameter("tex_soft", glb_soft)
		if glb_nrm != null and int(Settings.get_value("quality")) >= 1:       # Low quality skips the normal map (one less texture fetch per pixel)
			mat.set_shader_parameter("normal_tex", glb_nrm)
			mat.set_shader_parameter("use_nrm", 1.0)
		if glb_outline > 0.0 and mat.next_pass is ShaderMaterial:
			(mat.next_pass as ShaderMaterial).set_shader_parameter("px_width", glb_outline)
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
		if glb_meshes.has(n):
			mi.mesh = glb_meshes[n]
			for si in mi.mesh.get_surface_count():
				tris += (mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		else:
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
		if glb_meshes.has(n):
			var ab: AABB = (glb_meshes[n] as Mesh).get_aabb()
			var corners := [ab.position, ab.end]
			for cv in corners:
				var wp2: Vector3 = (cv as Vector3) + (d2["pos"] as Vector3)
				if first:
					bb = AABB(wp2, Vector3.ZERO)
					first = false
				else:
					bb = bb.expand(wp2)
			continue
		for v in (d2["mb"] as Prim).verts:
			var wp: Vector3 = v + (d2["pos"] as Vector3)
			if first:
				bb = AABB(wp, Vector3.ZERO)
				first = false
			else:
				bb = bb.expand(wp)
	var swarm_node: MultiMeshInstance3D = null
	if not swarm.is_empty():
		swarm_node = MultiMeshInstance3D.new()
		swarm_node.name = "swarm"
		var mmesh := MultiMesh.new()
		mmesh.transform_format = MultiMesh.TRANSFORM_3D
		mmesh.mesh = (swarm["mb"] as Prim).build()
		mmesh.instance_count = (swarm["rest"] as Array).size()
		swarm_node.multimesh = mmesh
		swarm_node.material_override = mat
		swarm_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		swarm_node.extra_cull_margin = 4.0
		var sp: String = swarm["parent"]
		nodes[sp].add_child(swarm_node)
		swarm_node.position = (swarm["pos"] as Vector3) - (parts[sp]["pos"] as Vector3)
		tris += (swarm["mb"] as Prim).tris() * (swarm["rest"] as Array).size()
	var res := {"swarm_node": swarm_node, "rest_rot": rest_rot, "bounds": bb, "nodes": nodes, "rest": rest, "tris": tris, "mat": mat, "face_node": null, "face_mat": null}
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
