extends RefCounted
## ART GATES (ART_BIBLE 6.5 + INTERFACES CritterRig contract): every critter builds, stays inside the perf budget
## (<= 20 draw calls, <= 6000 triangles INCLUDING the outline hull), exposes the contract sockets, and every action
## pose resolves (finite transforms) across its whole timeline. Draw calls are counted statically (surfaces x material
## passes of every mesh, FX quads included even when hidden, so this is the worst case).

const Rig := preload("res://src/critters/critter_rig.gd")
const Pal := preload("res://src/critters/palettes.gd")
const PoseLib := preload("res://src/critters/pose_lib.gd")
const FxCtl := preload("res://src/critters/fx_ctrl.gd")
const MAX_DRAWS := 20
const MAX_TRIS := 6000
const SOCKETS := ["weapon_tip", "hand", "head", "ground"]
var report: Array = []   # per-critter numbers, read by sheet tooling

static func count(node: Node) -> Vector2i:
	var draws := 0
	var tris := 0
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var m: Material = mi.get_active_material(s)
				var passes := 0
				while m != null:
					passes += 1
					m = m.next_pass
				draws += passes
				var idx: int = 0
				if mi.mesh is ArrayMesh:
					idx = (mi.mesh as ArrayMesh).surface_get_array_index_len(s) / 3
				else:
					idx = ((mi.mesh as PrimitiveMesh).get_mesh_arrays()[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
				tris += idx * passes
	for c in node.get_children():
		var v := count(c)
		draws += v.x
		tris += v.y
	return Vector2i(draws, tris)

func run() -> Array:
	var fails: Array = []
	for id in Pal.IDS:
		if not ResourceLoader.exists("res://src/critters/designs/%s.gd" % id):
			fails.append("%s: design script missing" % id)
			continue
		var rig = Rig.new()
		rig.setup(id)
		var c := count(rig)
		# hidden-by-default dynamic FX: smear (ribbon, built at runtime) + spark quad (already counted as a mesh)
		var smear_tris := (FxCtl.TRAIL_LEN - 1) * 2
		var smear_draw := (1 if rig.fx.smear.mesh == null else 0) + (1 if rig.fx.thread.mesh == null else 0)
		var draws: int = c.x + smear_draw
		var tris: int = c.y + smear_tris
		report.append({"id": id, "draws": draws, "tris": tris, "bounds": rig.bounds})
		if draws > MAX_DRAWS:
			fails.append("%s: %d draw calls > %d" % [id, draws, MAX_DRAWS])
		if tris > MAX_TRIS:
			fails.append("%s: %d triangles (incl. outline) > %d" % [id, tris, MAX_TRIS])
		for s in SOCKETS:
			var n: Node3D = rig.socket(s)
			if n == null:
				fails.append("%s: socket %s missing" % [id, s])
			elif s != "ground" and n == rig.socket("ground"):
				fails.append("%s: socket %s falls back to ground (not authored)" % [id, s])
		for a in PoseLib.ACTIONS:
			var tim: Vector3i = rig.call("_timing_for", a)
			var total: int = tim.x + tim.y + tim.z + 4
			if total > 400:
				fails.append("%s: action %s has implausible length %d" % [id, a, total])
				continue
			for f in range(0, total, 1):
				rig.apply_fighter_state({"action": a, "action_frame": f, "move_id": "", "vitality_ratio": 0.8, "facing": 1.0}, 1.0 / 60.0)
				for pn in rig.get("_nodes"):
					var nd = rig.get("_nodes")[pn]
					if nd is Node3D and not (nd as Node3D).transform.is_finite():
						fails.append("%s: action %s frame %d part %s non-finite transform" % [id, a, f, pn])
						break
			rig.apply_fighter_state({"action": "idle", "action_frame": 0}, 1.0 / 60.0)
		for e in ["calm", "grin", "angry", "hurt", "scared", "dying"]:
			rig.set_expression(e)
		for ev in ["tell", "hit", "block", "parry", "clash", "grab", "dodge", "stagger", "ringout", "ko", "laststand", "yield"]:
			rig.play_event({"type": ev, "fighter": 0, "heavy": true})
		rig.free()
	return fails
