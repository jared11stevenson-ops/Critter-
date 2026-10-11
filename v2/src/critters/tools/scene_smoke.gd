extends SceneTree
## Loads turnaround.tscn, steps every mode for a few seconds, saves screenshots to --out (default /tmp). Exit code 1 on script errors is not detectable here; read the log.
func _initialize() -> void:
	var out := "/tmp"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	var sc: Node = load("res://src/critters/turnaround.tscn").instantiate()
	root.add_child(sc)
	await process_frame
	await process_frame
	for m in range(4):
		sc.mode = m
		sc._apply_mode()
		sc.focus = 0
		for i in range(150):
			await physics_frame
		await process_frame
		root.get_texture().get_image().save_png("%s/scene_mode%d.png" % [out, m])
	sc.mode = 1
	sc._apply_mode()
	sc.focus = 3
	sc.action_i = 3
	for i in range(40):
		await physics_frame
	await process_frame
	root.get_texture().get_image().save_png("%s/scene_focus.png" % out)
	quit()
