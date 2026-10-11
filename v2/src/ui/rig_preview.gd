class_name RigPreview extends SubViewportContainer
## A live critter on a small stage for menus: its own 3D world in a SubViewport, slow turn, and a loop that plays the real
## idle / light / heavy / ability poses from the critter's move data so a player sees how it fights before picking it.

var vp: SubViewport
var holder: Node3D
var rig: CritterRig
var cam: Camera3D
var critter_id := ""
var spin := true
var _t := 0.0
var _seq: Array = []
var _seq_i := 0
var _seq_t := 0.0
var _frame := 0.0
var _def: CritterDef

func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CANVAS
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.38, 0.62, 0.70)
	e.ambient_light_energy = 0.75
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.84, 0.62)
	sun.light_energy = 0.95
	sun.rotation_degrees = Vector3(-30, 140, 0)
	vp.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	cam.current = true
	holder = Node3D.new()
	vp.add_child(holder)

func show_critter(id: String) -> void:
	if id == critter_id and rig != null:
		return
	critter_id = id
	if rig != null:
		rig.queue_free()
	rig = CritterRig.new()
	holder.add_child(rig)
	rig.setup(id)
	rig.three_quarter = 30.0
	_def = CombatData.critter(id)
	var h := maxf(1.6, rig.nominal_height())
	var d := h * 2.1 + 1.4
	cam.position = Vector3(0, h * 0.55, d)
	cam.look_at(Vector3(0, h * 0.48, 0), Vector3.UP)
	_build_seq()
	_seq_i = 0
	_seq_t = 0.0
	_t = 0.0

func _build_seq() -> void:
	var m := _def.move_ids
	var l: String = str(m["light"][0])
	_seq = [["idle", "", 2.2], ["strike_light", l, 0.0], ["idle", "", 0.7], ["strike_heavy", str(m["heavy"]), 0.0], ["idle", "", 1.1],
		["ability1", str(m["ability1"]), 0.0], ["idle", "", 1.1], ["ability2", str(m["ability2"]), 0.0], ["idle", "", 1.6], ["guard", "", 1.2], ["idle", "", 1.5]]

func _process(delta: float) -> void:
	if rig == null or not is_visible_in_tree():
		return
	_t += delta
	var step: Array = _seq[_seq_i]
	var action: String = step[0]
	var mid: String = step[1]
	var dur: float = step[2]
	if mid != "":
		var mv: MoveDef = _def.move(mid)
		dur = float(mv.startup + mv.active + mv.recovery) / 60.0 + 0.25
	_seq_t += delta
	_frame = _seq_t * 60.0
	if _seq_t >= dur:
		_seq_t = 0.0
		_seq_i = (_seq_i + 1) % _seq.size()
	holder.rotation.y = (sin(_t * 0.5) * 0.45 if spin else 0.0) - 0.15
	rig.apply_fighter_state({"action": action, "action_frame": int(_frame), "move_id": mid, "vitality_ratio": 1.0, "facing": 1.0}, minf(delta, 0.034))
