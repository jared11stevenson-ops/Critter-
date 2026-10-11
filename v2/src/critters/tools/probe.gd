extends SceneTree
const Stage := preload("res://src/critters/stage.gd")
const Rig := preload("res://src/critters/critter_rig.gd")

func _init() -> void:
	var ids: PackedStringArray = ["haldor"]
	var angle := 0.0
	var action := "idle"
	var frame := 0
	var tq := 0.0
	var dist := 11.0
	var ty := 1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="): ids = a.substr(5).split(",")
		if a.begins_with("--yaw="): angle = float(a.substr(6))
		if a.begins_with("--action="): action = a.substr(9)
		if a.begins_with("--tq="): tq = float(a.substr(5))
		if a.begins_with("--dist="): dist = float(a.substr(7))
		if a.begins_with("--ty="): ty = float(a.substr(5))
		if a.begins_with("--frame="): frame = int(a.substr(8))
	var vp := SubViewport.new()
	vp.size = Vector2i(640 * ids.size(), 640)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var st := Stage.build(world)
	var rigs := []
	var i := 0
	for id in ids:
		var rig = Rig.new()
		world.add_child(rig)
		rig.setup(id)
		rig.three_quarter = tq
		rig.position = Vector3(i * 3.0 - (ids.size() - 1) * 1.5, 0, 0)
		rigs.append(rig)
		print(id, " tris ", rig.tri_count)
		i += 1
	await process_frame
	var cam: Camera3D = st["cam"]
	var yaw := deg_to_rad(angle)
	cam.look_at_from_position(Vector3(sin(yaw), 0.18, cos(yaw)) * dist, Vector3(0, ty, 0))
	for f in range(frame + 4):
		for rig in rigs:
			rig.apply_fighter_state({"action": action, "action_frame": f if f <= frame else frame, "facing": 1.0}, 1.0 / 60.0)
		await process_frame
	await process_frame
	vp.get_texture().get_image().save_png("/tmp/probe.png")
	print("draws ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	for rig in rigs: rig.free()
	quit()
