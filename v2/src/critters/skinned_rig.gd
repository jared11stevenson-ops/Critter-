class_name SkinnedRig extends CritterRig
## A critter driven by a real skeleton (res://art/models/<id>_skin.glb built by tools/blender/rig/*_skin.py) instead of rigid parts.
## Same public API as CritterRig (apply_fighter_state / play_event / socket / palette / bounds ...), so BoutScene can use either.
## Animation standard (creator: "Elden Ring"): every attack has a readable ANTICIPATION that coils the body and shifts the weight back
## (startup frames, slow in, a held tremble), a fast IMPACT that snaps through with overshoot and a lunge (active frames), and a long weighty
## RECOVERY that settles out of the pose (recovery frames). Timing always comes from the sim's frame data (Timing.resolve), never from guesses.
##
## Bone axes: each bone's pose is given in the T-pose rest frame as (roll about X, pitch about Y, yaw about Z) degrees, with X forward,
## Y = the critter's LEFT, Z up (Blender frame of the build script; converted to Godot's Y-up on use). Parent rotations carry the child's frame:
## so with the arm hanging, the forearm's "yaw" is elbow flexion. Positive pitch leans/swings backward for hanging limbs and forward for the spine.

const SKIN_PATH := "res://art/models/%s_skin.glb"
const Pose := preload("res://src/critters/skin_poses.gd")
const Props := preload("res://src/critters/skin_props.gd")

var skeleton: Skeleton3D
var _mesh: MeshInstance3D
var _bones: Dictionary = {}        # name -> index
var _rest_axes: Dictionary = {}    # name -> Basis (global rest basis inverse)
var _cur_bones: Dictionary = {}    # name -> Vector3 (roll, pitch, yaw) currently applied
var _from_bones: Dictionary = {}
var _cur_root := Vector3.ZERO
var _from_root := Vector3.ZERO
var _t_walk := 0.0
var _flinch := 0.0
var _flinch_v := 0.0
var _springs: SpringBoneSimulator3D
var _ankle_rest := {}              # side -> ankle height in the rest pose (the ground line for planted feet)
var _prev_action := ""
var _prev_move := ""

static func available(id: String) -> bool:
	return ResourceLoader.exists(SKIN_PATH % id)

func enable_shadows() -> void:
	if _mesh != null:
		_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func setup(critter_id_in: String) -> void:
	critter_id = critter_id_in
	for c in get_children():
		c.queue_free()
	_pivot = Node3D.new(); _pivot.name = "facing"; add_child(_pivot)
	_body = Node3D.new(); _body.name = "body"; _pivot.add_child(_body)
	palette = Pal.get_pal(critter_id)
	var ps: PackedScene = load(SKIN_PATH % critter_id)
	var root: Node3D = ps.instantiate()
	_body.add_child(root)
	skeleton = _find(root, "Skeleton3D") as Skeleton3D
	_mesh = _find(root, "MeshInstance3D") as MeshInstance3D
	assert(skeleton != null and _mesh != null, "skinned model needs a Skeleton3D and a mesh")
	for i in skeleton.get_bone_count():
		var bn := skeleton.get_bone_name(i)
		_bones[bn] = i
		_rest_axes[bn] = skeleton.get_bone_global_rest(i).basis.inverse()
		_cur_bones[bn] = Vector3.ZERO
	# the toon material with the model's own colour + normal atlas (same look as every generated critter)
	var mat := Toon.character(palette["glow"], palette["ink"])
	var gain := 1.0
	var soft := 0.0
	var outline := 1.3
	var jp := "res://art/models/%s.json" % critter_id            # the same sidecar the part models use (texture gain / softness / outline width)
	if FileAccess.file_exists(jp):
		var meta = JSON.parse_string(FileAccess.get_file_as_string(jp))
		if meta is Dictionary:
			gain = float(meta.get("tex_gain", gain)); soft = float(meta.get("tex_soft", soft)); outline = float(meta.get("outline_px", outline))
	var gm = _mesh.mesh.surface_get_material(0)
	if gm is BaseMaterial3D:
		if (gm as BaseMaterial3D).albedo_texture != null:
			mat.set_shader_parameter("albedo_tex", (gm as BaseMaterial3D).albedo_texture)
			mat.set_shader_parameter("use_tex", 1.0)
			mat.set_shader_parameter("tex_gain", gain)
			mat.set_shader_parameter("tex_soft", soft)
		if (gm as BaseMaterial3D).normal_texture != null and int(Settings.get_value("quality")) >= 1:
			mat.set_shader_parameter("normal_tex", (gm as BaseMaterial3D).normal_texture)
			mat.set_shader_parameter("use_nrm", 1.0)
	if mat.next_pass is ShaderMaterial:
		(mat.next_pass as ShaderMaterial).set_shader_parameter("px_width", outline)
	_mesh.material_override = mat
	_mat = mat
	var bb := _mesh.get_aabb()
	bounds = bb
	tri_count = 55000
	# sockets: hands, head, ground, club tip (BoneAttachment3D follow the bones)
	var g := Marker3D.new(); g.name = "socket_ground"; add_child(g); _sockets["ground"] = g
	_sockets["head"] = _attach("head", Vector3(0.0, 0.2, 0.0))
	_sockets["hand"] = _attach("grip_R", Vector3.ZERO)
	_sockets["weapon_base"] = _sockets["hand"]
	_sockets["weapon_tip"] = _attach("grip_R", Vector3(1.6, -0.9, 0.0))
	if critter_id == "bramvex":                                   # he holds Diplomacy in his right hand
		var ba := BoneAttachment3D.new()
		ba.bone_name = "grip_R"
		skeleton.add_child(ba)
		var club := MeshInstance3D.new()
		club.mesh = Props.club()
		club.material_override = Toon.character(palette["glow"], palette["ink"])
		(club.material_override as ShaderMaterial).next_pass.set_shader_parameter("px_width", outline)
		club.rotation_degrees = Vector3(0, 0, -28)                # pointing forward and down from the fist
		ba.add_child(club)
		_sockets["weapon_base"] = club
		var tip := Marker3D.new()
		tip.position = Vector3(2.05, 0, 0)
		club.add_child(tip)
		_sockets["weapon_tip"] = tip
	_add_springs()
	skeleton.reset_bone_poses()
	skeleton.force_update_all_bone_transforms()
	for side in ["L", "R"]:
		if _bones.has("ft_" + side):
			_ankle_rest[side] = skeleton.get_bone_global_pose(_bones["ft_" + side]).origin.y
	fx = FxCtl.new(self, mat, palette["accent"] if (palette["accent"] as Color).get_luminance() > 0.35 else palette["glow"], palette["glow"])
	_cur_bones = Pose.compile(Pose.IDLE)
	_from_bones = _cur_bones.duplicate()
	_apply_bones(_cur_bones)

## Follow-through: banner, back shreds and wings are driven by Godot's SpringBoneSimulator3D on top of the pose (cloth lags and swings on every lunge).
## chain = [root bone, end bone, stiffness, drag, gravity]; values are tuned by eye (lower stiffness = floppier).
const SPRINGS := {
	"bramvex": [["cf1", "cf3", 0.28, 0.30, 0.9], ["cb1", "cb3", 0.34, 0.30, 0.8], ["wing_L", "wing2_L", 0.55, 0.35, 0.3], ["wing_R", "wing2_R", 0.55, 0.35, 0.3], ["ant1_L", "ant3_L", 0.18, 0.25, 0.5], ["ant1_R", "ant3_R", 0.18, 0.25, 0.5]],
}

func _add_springs() -> void:
	var chains: Array = SPRINGS.get(critter_id, [])
	if chains.is_empty():
		return
	var sp := SpringBoneSimulator3D.new()
	skeleton.add_child(sp)
	sp.set_setting_count(chains.size())
	for i in chains.size():
		var c: Array = chains[i]
		if not (_bones.has(c[0]) and _bones.has(c[1])):
			continue
		sp.set_root_bone_name(i, c[0])
		sp.set_end_bone_name(i, c[1])
		sp.set_extend_end_bone(i, true)
		sp.set_end_bone_direction(i, SpringBoneSimulator3D.BONE_DIRECTION_FROM_PARENT)
		sp.set_end_bone_length(i, 0.35)
		sp.set_stiffness(i, c[2])
		sp.set_drag(i, c[3])
		sp.set_gravity(i, c[4])
		sp.set_gravity_direction(i, Vector3(0, -1, 0))
		sp.set_radius(i, 0.03)
	_springs = sp

func _find(n: Node, type: String) -> Node:
	if n.get_class() == type:
		return n
	for c in n.get_children():
		var r := _find(c, type)
		if r != null:
			return r
	return null

func _attach(bone: String, offset: Vector3) -> Node3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = bone
	skeleton.add_child(ba)
	var m := Marker3D.new()
	m.position = offset
	ba.add_child(m)
	return m

func part(_pname: String) -> Node3D:
	return null

# ------------------------------------------------------------------ animation
func apply_fighter_state(fs: Dictionary, dt: float) -> void:
	if _body == null:
		return
	_tick += 1
	_time += dt
	var action: String = str(fs.get("action", "idle"))
	var frame: int = int(fs.get("action_frame", 0))
	var move_id: String = str(fs.get("move_id", ""))
	_vit = float(fs.get("vitality_ratio", 1.0))
	if fs.has("facing") and float(fs["facing"]) != 0.0:
		_facing = signf(float(fs["facing"]))
	if action != _prev_action or move_id != _prev_move:
		_from_bones = _cur_bones.duplicate()
		_from_root = _cur_root
		_blend_f = 0
		_blend_n = int(BLEND_FRAMES.get(action, BLEND_DEFAULT))
		_prev_action = action
		_prev_move = move_id
	_action = action
	_move_id = move_id
	_action_frame = frame
	_timing = Timing.resolve(critter_id, action, move_id, fs)
	var spd := absf(float(fs.get("speed", 1.0 if action == "walk" else 0.0)))
	if action == "walk":
		_t_walk += dt * Pose.WALK_RATE * clampf(spd, 0.5, 1.6)
	var tgt: Dictionary = Pose.evaluate(action, frame, _timing, _t_walk, _time, _vit, spd, float(fs.get("fwd", 1.0)))
	var bones: Dictionary = tgt["bones"]
	var root: Vector3 = tgt["root"]
	if _blend_f < _blend_n:
		var w := float(_blend_f + 1) / float(_blend_n + 1)
		w = w * w * (3.0 - 2.0 * w)
		_blend_f += 1
		bones = Pose.mix(_from_bones, bones, w)
		root = _from_root.lerp(root, w)
	# flinch spring (hit reactions kick the whole body back and let it recover) + shake
	_flinch_v += (-_flinch * 220.0 - _flinch_v * 16.0) * dt
	_flinch += _flinch_v * dt
	var flinch_pose := {"spine": Vector3(0, -_flinch * 38.0, 0), "chest": Vector3(0, -_flinch * 26.0, 0), "neck": Vector3(0, _flinch * 20.0, 0)}
	bones = Pose.add(bones, flinch_pose)
	if action not in ["ko", "knockdown"] and not _ankle_rest.is_empty():
		bones = _plant_feet(bones, root)
	_cur_bones = bones
	_cur_root = root
	_apply_bones(bones)
	var jitter := Vector3.ZERO
	if _shake_f > 0:
		_shake_f -= 1
		jitter = Vector3(sin(_time * 90.0), cos(_time * 70.0) * 0.5, 0.0) * 0.012 * _shake_amp
	_body.position = root + jitter
	_update_facing(dt)
	fx.update(dt)

func _kick(amount: float) -> void:
	_flinch_v -= amount * 14.0

## Foot planting: both ankles are held on the ground line. For each leg a small Newton solve on the knee (then the thigh) removes any lift or sinking the
## authored pose or the body's root offset would cause, so feet never float after a strike and never sink into the floor.
func _ankle_y(side: String, bones: Dictionary, root: Vector3) -> float:
	_apply_bones(bones)
	skeleton.force_update_all_bone_transforms()
	return skeleton.get_bone_global_pose(_bones["ft_" + side]).origin.y + root.y

func _plant_feet(bones: Dictionary, root: Vector3) -> Dictionary:
	var out := bones.duplicate()
	for side in ["L", "R"]:
		var th: String = "th_" + side
		var sh: String = "sh_" + side
		var target: float = float(_ankle_rest[side])
		for it in 3:
			var err: float = _ankle_y(side, out, root) - target
			if absf(err) < 0.02:
				break
			var key: String = sh
			var v: Vector3 = out.get(key, Vector3.ZERO)
			var probe: Dictionary = out.duplicate()
			probe[key] = v + Vector3(0, 4.0, 0)
			var slope: float = (_ankle_y(side, probe, root) - target - err) / 4.0        # metres per degree of extra knee bend
			if absf(slope) < 0.0005:
				key = th
				v = out.get(key, Vector3.ZERO)
				probe = out.duplicate()
				probe[key] = v + Vector3(0, 4.0, 0)
				slope = (_ankle_y(side, probe, root) - target - err) / 4.0
				if absf(slope) < 0.0005:
					break
			var step: float = clampf(-err / slope, -25.0, 25.0)
			var nv: Vector3 = v + Vector3(0, step, 0)
			if key == sh:
				nv.y = clampf(nv.y, 0.0, 130.0)                                    # a knee only bends one way
			out[key] = nv
	return out

## Rotations (roll/pitch/yaw degrees about the T-pose rest frame, Blender axes) -> bone pose rotations.
func _apply_bones(bones: Dictionary) -> void:
	skeleton.reset_bone_poses()
	for bn in bones:
		if not _bones.has(bn):
			continue
		var v: Vector3 = bones[bn]
		if v.is_zero_approx():
			continue
		var i: int = _bones[bn]
		# Blender (x fwd, y left, z up) -> Godot (x fwd, y up, z right): axis (x, y, z) -> (x, z, -y)
		var q := Quaternion(Vector3(0, 1, 0), deg_to_rad(v.z)) * Quaternion(Vector3(0, 0, -1), deg_to_rad(v.y)) * Quaternion(Vector3(1, 0, 0), deg_to_rad(v.x))
		var rest_b: Basis = (_rest_axes[bn] as Basis).inverse().orthonormalized()     # the bone's global rest orientation (no scale)
		var ang := q.get_angle()
		var axis_q := Quaternion()
		if ang > 0.0001:
			axis_q = Quaternion((rest_b.inverse() * q.get_axis()).normalized(), ang)
		skeleton.set_bone_pose_rotation(i, skeleton.get_bone_rest(i).basis.get_rotation_quaternion() * axis_q)   # Godot's bone pose REPLACES the local rotation, so compose with the rest rotation
