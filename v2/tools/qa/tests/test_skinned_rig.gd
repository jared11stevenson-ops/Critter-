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
	var acts := {"idle": 0, "walk": 0, "guard": 6, "strike_light": 30, "strike_heavy": 56, "grab": 30, "ability1": 40, "ability2": 40, "ability3": 40, "laststand": 50, "parry": 20, "dodge": 20, "hit": 14, "stagger": 20, "ko": 30, "knockdown": 30}
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
	for combo in [[0.0, 1.0], [-1.0, 0.0], [1.0, -0.9], [0.0, -1.0], [0.7, 0.7]]:      # dodge / strafe in every direction stay finite
		for a2 in ["dodge", "walk"]:
			for f2 in range(0, 24, 3):
				var pr: Dictionary = SkinnedRig.Pose.evaluate(a2, f2, Vector3i(6, 8, 10), 1.3, 0.5, 1.0, 1.0, float(combo[0]), float(combo[1]))
				for bn2 in pr["bones"]:
					var v2: Vector3 = pr["bones"][bn2]
					if not (is_finite(v2.x) and is_finite(v2.y) and is_finite(v2.z)):
						fails.append("skinned_rig: non-finite %s pose in %s" % [bn2, a2])
	var win: Dictionary = SkinnedRig.Pose.evaluate("idle", 0, Vector3i(1, 1, 1), 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, "won")
	var salute: Dictionary = SkinnedRig.Pose.evaluate("idle", 0, Vector3i(1, 1, 1), 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, "intro")
	if (salute["bones"]["arm_up_R"] as Vector3).is_equal_approx((SkinnedRig.Pose.evaluate("idle", 0, Vector3i(1, 1, 1), 0.0, 0.0, 1.0)["bones"]["arm_up_R"] as Vector3)):
		fails.append("skinned_rig: the intro salute must differ from idle")
	var calm: Dictionary = SkinnedRig.Pose.evaluate("idle", 0, Vector3i(1, 1, 1), 0.0, 0.0, 1.0)
	if (win["bones"]["arm_up_R"] as Vector3).is_equal_approx(calm["bones"]["arm_up_R"] as Vector3):
		fails.append("skinned_rig: the victory pose must differ from idle")
	var idle: Dictionary = SkinnedRig.Pose.evaluate("idle", 0, Vector3i(1, 1, 1), 0.0, 0.0, 1.0)
	var ant: Dictionary = SkinnedRig.Pose.evaluate("strike_light", 15, Vector3i(16, 4, 14), 0.0, 0.0, 1.0)
	var hit: Dictionary = SkinnedRig.Pose.evaluate("strike_light", 18, Vector3i(16, 4, 14), 0.0, 0.0, 1.0)
	if (ant["root"] as Vector3).x >= (idle["root"] as Vector3).x:
		fails.append("skinned_rig: anticipation must shift the weight BACK of the stance")
	if (hit["root"] as Vector3).x <= (idle["root"] as Vector3).x + 0.2:
		fails.append("skinned_rig: the impact must lunge forward")
	# head look-at plumbing: a positive look angle adds head yaw (the pose convention is "yaw positive turns left"), a negative one subtracts it
	var yaws: Array = []
	for lk in [-40.0, 0.0, 40.0]:
		var rg := SkinnedRig.new()
		rg.setup("bramvex")
		var fl := {"action": "idle", "action_frame": 0, "move_id": "", "facing": 1.0, "speed": 0.0, "vitality_ratio": 1.0, "look": lk}
		for k in 60:
			rg.apply_fighter_state(fl, 1.0 / 60.0)
		yaws.append((rg._cur_bones["head"] as Vector3).z)
		rg.free()
	if not (float(yaws[0]) < float(yaws[1]) - 10.0 and float(yaws[2]) > float(yaws[1]) + 10.0):
		fails.append("skinned_rig: head look-at yaw must follow the look angle (%s)" % [yaws])
	rig.free()
	return fails
