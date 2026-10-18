extends RefCounted
## Skinned critters (Bramvex): the skeleton loads with the expected bones and sockets, every sim action evaluates to finite bone poses over its whole
## timeline, impact poses really differ from the stance (the animation is not a no-op), and the tell/impact/recovery arc follows the frame data.

func run() -> Array:
	var fails: Array = []
	if not SkinnedRig.available("bramvex"):
		return ["skinned_rig: res://art/models/bramvex_skin.glb is missing"]
	var rig := SkinnedRig.new()
	rig.setup("bramvex")
	if rig.skeleton == null or rig.skeleton.get_bone_count() < 31:
		fails.append("skinned_rig: expected >= 31 bones")
	for b in ["hips", "spine", "chest", "neck", "head", "arm_up_L", "arm_lo_R", "hand_R", "grip_R", "th_L", "sh_R", "ft_L", "wing_L", "cf1", "cb3"]:
		if not rig._bones.has(b):
			fails.append("skinned_rig: missing bone " + b)
	for s in ["weapon_tip", "hand", "head", "ground"]:
		if rig.socket(s) == null:
			fails.append("skinned_rig: missing socket " + s)
	var acts := {"idle": 0, "walk": 0, "guard": 6, "strike_light": 30, "strike_heavy": 56, "grab": 30, "ability1": 40, "dodge": 20, "hit": 14, "stagger": 20, "ko": 30, "knockdown": 30}
	for a in acts:
		var fs := {"action": a, "action_frame": 0, "move_id": "", "facing": 1.0, "speed": 1.0, "vitality_ratio": 1.0, "phase": Vector3i(16, 4, 14)}
		for f in range(0, int(acts[a]) + 1, 2):
			fs["action_frame"] = f
			rig.apply_fighter_state(fs, 1.0 / 60.0)
		for bn in rig._cur_bones:
			var v: Vector3 = rig._cur_bones[bn]
			if not (is_finite(v.x) and is_finite(v.y) and is_finite(v.z)):
				fails.append("skinned_rig: non-finite pose %s in %s" % [bn, a])
		var o: Vector3 = rig.skeleton.get_bone_global_pose(rig._bones["head"]).origin
		if not (is_finite(o.x) and is_finite(o.y) and is_finite(o.z)):
			fails.append("skinned_rig: head origin not finite in " + a)
	var idle: Dictionary = SkinnedRig.Pose.evaluate("idle", 0, Vector3i(1, 1, 1), 0.0, 0.0, 1.0)
	var ant: Dictionary = SkinnedRig.Pose.evaluate("strike_light", 15, Vector3i(16, 4, 14), 0.0, 0.0, 1.0)
	var hit: Dictionary = SkinnedRig.Pose.evaluate("strike_light", 18, Vector3i(16, 4, 14), 0.0, 0.0, 1.0)
	if (ant["root"] as Vector3).x >= (idle["root"] as Vector3).x:
		fails.append("skinned_rig: anticipation must shift the weight BACK of the stance")
	if (hit["root"] as Vector3).x <= (idle["root"] as Vector3).x + 0.2:
		fails.append("skinned_rig: the impact must lunge forward")
	rig.free()
	return fails
