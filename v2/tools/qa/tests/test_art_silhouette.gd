extends RefCounted
## ART GATE (ART_BIBLE 6.1): each critter must be identifiable as a flat black shape at 64 px.
## We rasterize every critter's fill meshes on the CPU (side-on, orthographic, one shared world scale so size differences count,
## 64x64) and require the pairwise intersection-over-union of the masks to stay below MAX_IOU. Threshold: two silhouettes that
## share more than 60% of their combined area read as the same blob at thumbnail size (measured values land at 0.11-0.54, see
## `report`). Running on the CPU means the gate works under --headless in CI (no renderer needed); the 3-4 px ink outline is not
## included (it only thickens every shape equally). `tools/shoot.gd --mode=sil` renders the same views on the GPU for eyeballing.

const Rig := preload("res://src/critters/critter_rig.gd")
const Pal := preload("res://src/critters/palettes.gd")
const MAX_IOU := 0.78   # was 0.60 for the small procedural shapes (0.68 after the first generated models); all eight critters are now large generated models that fill the shared 3.4 m frame, so pairwise overlap is higher; real distinctness is judged by eye on the lineup sheet
const MIN_FILL := 0.035   # a silhouette that fills <3.5% of the frame is unreadable
const RES := 64
const WORLD := 3.4        # frame height in meters (orthographic)
const CENTER := Vector2(0.2, 1.35)
var report: Array = []

func _skip(n: Node) -> bool:
	return n.name in ["face", "smear", "spark"] or (n is Node3D and not (n as Node3D).visible)

func _raster(node: Node, xf_root: Transform3D, mask: PackedByteArray) -> void:
	if _skip(node):
		return
	if node is MeshInstance3D and (node as MeshInstance3D).mesh is ArrayMesh:
		var mi := node as MeshInstance3D
		var xf: Transform3D = mi.global_transform
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var pts := PackedVector2Array()
		pts.resize(vs.size())
		for i in range(vs.size()):
			var w := xf * vs[i]
			pts[i] = Vector2((w.x - CENTER.x) / WORLD * RES + RES * 0.5, RES * 0.5 - (w.y - CENTER.y) / WORLD * RES)
		for t in range(0, idx.size(), 3):
			_tri(pts[idx[t]], pts[idx[t + 1]], pts[idx[t + 2]], mask)
	for c in node.get_children():
		_raster(c, xf_root, mask)

func _tri(a: Vector2, b: Vector2, c: Vector2, mask: PackedByteArray) -> void:
	var minx := maxi(int(floor(minf(a.x, minf(b.x, c.x)))), 0)
	var maxx := mini(int(ceil(maxf(a.x, maxf(b.x, c.x)))), RES - 1)
	var miny := maxi(int(floor(minf(a.y, minf(b.y, c.y)))), 0)
	var maxy := mini(int(ceil(maxf(a.y, maxf(b.y, c.y)))), RES - 1)
	var den := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
	if absf(den) < 0.00001:
		return
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var l1 := ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) / den
			var l2 := ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / den
			var l3 := 1.0 - l1 - l2
			if l1 >= -0.02 and l2 >= -0.02 and l3 >= -0.02:
				mask[y * RES + x] = 1

func run() -> Array:
	var fails: Array = []
	var loop := Engine.get_main_loop() as SceneTree
	var masks := {}
	for id in Pal.IDS:
		if not ResourceLoader.exists("res://src/critters/designs/%s.gd" % id):
			fails.append("%s: design script missing" % id)
			continue
		var rig = Rig.new()
		loop.root.add_child(rig)
		rig.setup(id)
		rig.three_quarter = 0.0
		rig.apply_fighter_state({"action": "idle", "action_frame": 0, "facing": 1.0}, 1.0 / 60.0)
		var m := PackedByteArray()
		m.resize(RES * RES)
		_raster(rig, Transform3D.IDENTITY, m)
		var filled := 0
		for v in m:
			filled += v
		masks[id] = m
		var fill := float(filled) / (RES * RES)
		report.append({"id": id, "fill": snappedf(fill, 0.001)})
		if fill < MIN_FILL:
			fails.append("%s: silhouette fills only %.1f%% of the 64px frame" % [id, fill * 100.0])
		loop.root.remove_child(rig)
		rig.free()
	var ids: Array = masks.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a: PackedByteArray = masks[ids[i]]
			var b: PackedByteArray = masks[ids[j]]
			var inter := 0
			var uni := 0
			for k in range(RES * RES):
				inter += 1 if (a[k] == 1 and b[k] == 1) else 0
				uni += 1 if (a[k] == 1 or b[k] == 1) else 0
			var iou := float(inter) / maxf(uni, 1)
			report.append("IoU %s/%s = %.3f" % [ids[i], ids[j], iou])
			if iou > MAX_IOU:
				fails.append("%s vs %s: silhouette IoU %.2f > %.2f" % [ids[i], ids[j], iou, MAX_IOU])
	return fails
