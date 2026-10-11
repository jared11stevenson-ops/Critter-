extends SceneTree
## Exercises detach (Morrow throw/recall, crown orbit), ghosts, compel, rage, plate cracks in a live tree; prints errors via the engine log.
const Rig := preload("res://src/critters/critter_rig.gd")
func _initialize() -> void:
	await process_frame
	for id in ["aruun", "cigarra"]:
		var r = Rig.new()
		root.add_child(r)
		r.setup(id)
		for act in ["ability1", "ability2", "strike_light", "laststand"]:
			var tim: Vector3i = r._timing_for(act)
			for f in range(tim.x + tim.y + tim.z + 20):
				r.apply_fighter_state({"action": act, "action_frame": f, "vitality_ratio": 0.4, "rage": 0.8, "facing": 1.0}, 1.0 / 60.0)
				if f % 7 == 0:
					await process_frame
		r.play_event({"type": "compel", "source_pos": Vector3(3, 1, 0)})
		r.play_event({"type": "premonition", "ghost_action": "strike_heavy", "ghost_frame": 10})
		for i in range(30):
			r.apply_fighter_state({"action": "idle", "action_frame": 0, "vitality_ratio": 0.2}, 1.0 / 60.0)
			await process_frame
		print("SMOKE ", id, " plates=", r._plates, " weapon_free=", r.detach_part("weapon").is_free())
		r.free()
	quit()
