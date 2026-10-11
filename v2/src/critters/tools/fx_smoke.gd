extends SceneTree
## Exercises detach (Morrow throw/recall, crown orbit), ghosts, compel, rage, plate cracks in a live tree; prints errors via the engine log.
const Rig := preload("res://src/critters/critter_rig.gd")
func _initialize() -> void:
	await process_frame
	for id in ["aruun", "cigarra"]:
		var r = Rig.new()
		root.add_child(r)
		r.setup(id)
		for act in ["ability1", "strike_light", "strike_heavy", "laststand"]:
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
		print("SMOKE ", id, " plates=", r._plates, " swarm_away=", (r.swarm.any_away() if r.swarm else false))
		r.free()
	# VFX stage driven by rig hooks + synthetic sim state / events
	const Stage := preload("res://src/critters/vfx/vfx_stage.gd")
	var stage = Stage.new()
	root.add_child(stage)
	var rigs := []
	for id in ["aruun", "bramvex"]:
		var r2 = Rig.new()
		root.add_child(r2)
		r2.setup(id)
		r2.vfx = stage
		rigs.append(r2)
	for f in range(70):
		for i in range(2):
			rigs[i].apply_fighter_state({"action": "ability1" if f > 2 else "idle", "action_frame": maxi(f - 3, 0), "move_id": ["aruun_reaching_strike", "bramvex_ghost"][i], "status": [{"name": "camo", "remaining": 90}] if i == 1 else [], "facing": 1.0}, 1.0 / 60.0)
		stage.sync({"fighters": [{"status": []}, {"status": [{"name": "camo", "remaining": 90}]}], "zones": [{"id": 1, "kind": "zone", "owner": 0, "pos": Vector2(3, 0), "radius": 2.5, "remaining": 120, "move_id": "aruun_gravity_pull"}], "projectiles": [{"id": 2, "owner": 1, "pos": Vector2(2 + f * 0.1, 0.5), "angle": 0.3, "remaining": 40}]}, rigs, 0.0)
		stage.event({"type": "hit", "fighter": 1, "heavy": f == 10}, rigs)
		await process_frame
	print("VFX alive=", stage.fx_list.size(), " draws=", stage.draws_alive(), " cap=", stage.max_draws())
	quit()
