extends RefCounted
## ART GATE (ART_BIBLE 6.1): each critter must be identifiable as a flat black shape at 64 px. We render every critter
## flat black on white at 64x64 (side-on, orthographic, one shared world scale so size differences count) and require the
## pairwise intersection-over-union of the masks to stay below MAX_IOU. Threshold: two silhouettes sharing more than 60% of
## their combined area read as the same blob at thumbnail size; measured values are printed in `report` so it can be tuned.
## Runs only when a renderer exists (skipped under --headless; use xvfb-run with --rendering-driver opengl3).

const Rig := preload("res://src/critters/critter_rig.gd")
const Pal := preload("res://src/critters/palettes.gd")
const MAX_IOU := 0.60
const MIN_FILL := 0.035   # a silhouette that fills <3.5% of the frame is unreadable
var RES := 64
var report: Array = []
var skipped := false

func _render(rig: Node3D, cam: Camera3D, vp: SubViewport) -> Image:
	RenderingServer.force_draw(false)
	RenderingServer.force_draw(false)
	return vp.get_texture().get_image()

func run() -> Array:
	var fails: Array = []
	if DisplayServer.get_name() == "headless":
		skipped = true
		report.append("silhouette gate skipped (no renderer)")
		return fails
	var loop := Engine.get_main_loop() as SceneTree
	if OS.get_environment("ART_RES") != "": RES = int(OS.get_environment("ART_RES"))
	var vp := SubViewport.new()
	vp.size = Vector2i(RES, RES)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_DISABLED
	loop.root.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.WHITE
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.WHITE
	env.environment = e
	vp.add_child(env)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.4
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0.2, 1.35, 8.0), Vector3(0.2, 1.35, 0.0))
	var masks := {}
	for id in Pal.IDS:
		if not ResourceLoader.exists("res://src/critters/designs/%s.gd" % id):
			fails.append("%s: design script missing" % id)
			continue
		var rig = Rig.new()
		vp.add_child(rig)
		rig.setup(id)
		rig.three_quarter = 0.0
		rig.set_silhouette(true)
		rig.apply_fighter_state({"action": "idle", "action_frame": 0, "facing": 1.0}, 1.0 / 60.0)
		var img := _render(rig, cam, vp)
		if OS.get_environment("ART_DUMP") != "":
			img.save_png("%s/%s_sil64.png" % [OS.get_environment("ART_DUMP"), id])
		var m := PackedByteArray()
		m.resize(RES * RES)
		var filled := 0
		for y in range(RES):
			for x in range(RES):
				var dark := img.get_pixel(x, y).get_luminance() < 0.5
				m[y * RES + x] = 1 if dark else 0
				filled += 1 if dark else 0
		masks[id] = m
		var fill := float(filled) / (RES * RES)
		report.append({"id": id, "fill": snappedf(fill, 0.001)})
		if fill < MIN_FILL:
			fails.append("%s: silhouette fills only %.1f%% of the 64px frame" % [id, fill * 100.0])
		rig.free()
	var ids: Array = masks.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a: PackedByteArray = masks[ids[i]]; var b: PackedByteArray = masks[ids[j]]
			var inter := 0
			var uni := 0
			for k in range(RES * RES):
				inter += 1 if (a[k] == 1 and b[k] == 1) else 0
				uni += 1 if (a[k] == 1 or b[k] == 1) else 0
			var iou := float(inter) / maxf(uni, 1)
			report.append("IoU %s/%s = %.3f" % [ids[i], ids[j], iou])
			if iou > MAX_IOU:
				fails.append("%s vs %s: silhouette IoU %.2f > %.2f" % [ids[i], ids[j], iou, MAX_IOU])
	vp.queue_free()
	return fails
