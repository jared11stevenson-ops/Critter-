extends Node3D
## Lookdev / turnaround scene: the Seven on a neutral stage under the golden-hour / teal-shade rig.
## Modes (Tab): LINEUP (idle) -> CYCLE (every action pose with real frame timing) -> EXPRESSIONS -> SILHOUETTE.
## Keys: Space = next mode, 1-7 = focus a critter (0 = all), Left/Right = orbit, Up/Down = zoom, A = next action (cycle),
## E = next expression, Esc = quit. Mouse drag orbits. Touch drag orbits.

const Stage := preload("res://src/critters/stage.gd")
const Rig := preload("res://src/critters/critter_rig.gd")
const Pal := preload("res://src/critters/palettes.gd")
const PoseLib := preload("res://src/critters/pose_lib.gd")
const Face := preload("res://src/critters/face_ctl.gd")

const SPACING := 3.1
const MODES := ["lineup", "cycle", "expressions", "silhouette"]

var rigs: Array = []
var st: Dictionary = {}
var mode := 0
var focus := 0          # 0 = all, 1..7
var yaw := 0.0
var zoom := 1.0
var action_i := 1
var expr_i := 0
var frame := 0
var hud: Label
var dragging := false

func _ready() -> void:
	st = Stage.build(self)
	for i in range(Pal.IDS.size()):
		if not ResourceLoader.exists("res://src/critters/designs/%s.gd" % Pal.IDS[i]):
			continue
		var rig = Rig.new()
		add_child(rig)
		rig.setup(Pal.IDS[i])
		rig.position = Vector3((float(i) - 3.0) * SPACING, 0, 0)
		rig.three_quarter = 0.0
		rigs.append(rig)
	var cl := CanvasLayer.new()
	add_child(cl)
	hud = Label.new()
	hud.position = Vector2(14, 10)
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.05))
	hud.add_theme_constant_override("outline_size", 6)
	cl.add_child(hud)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="): mode = maxi(MODES.find(a.substr(7)), 0)
		if a.begins_with("--focus="): focus = int(a.substr(8))
		if a.begins_with("--yaw="): yaw = float(a.substr(6))
	_apply_mode()

func _apply_mode() -> void:
	var sil: bool = MODES[mode] == "silhouette"
	st["env"].background_color = Color.WHITE if sil else Color(0.36, 0.40, 0.42)
	st["ground"].visible = not sil
	for r in rigs:
		r.set_silhouette(sil)
		r.set_expression("auto")
	frame = 0

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_SPACE:
				mode = (mode + 1) % MODES.size(); _apply_mode()
			KEY_A: action_i = 1 + action_i % (PoseLib.ACTIONS.size() - 1); frame = 0
			KEY_E: expr_i = (expr_i + 1) % Face.NAMES.size()
			KEY_LEFT: yaw -= 20.0
			KEY_RIGHT: yaw += 20.0
			KEY_UP: zoom = maxf(0.4, zoom - 0.15)
			KEY_DOWN: zoom = minf(2.0, zoom + 0.15)
			KEY_ESCAPE: get_tree().quit()
			_:
				if ev.keycode >= KEY_0 and ev.keycode <= KEY_7:
					focus = ev.keycode - KEY_0
	elif ev is InputEventMouseButton:
		dragging = ev.pressed
	elif ev is InputEventMouseMotion and dragging:
		yaw += ev.relative.x * 0.4

func _physics_process(_dt: float) -> void:
	var cur_action: String = PoseLib.ACTIONS[action_i]
	for r in rigs:
		var fs := {"facing": 1.0, "action": "idle", "action_frame": 0, "vitality_ratio": 1.0}
		if MODES[mode] == "cycle":
			var tim: Vector3i = r.call("_timing_for", cur_action)
			var total := tim.x + tim.y + tim.z + 20
			fs["action"] = cur_action
			fs["action_frame"] = frame % total
			if cur_action in ["guard", "stagger", "ko"]:
				fs["action_frame"] = frame % (total + 40)
			if cur_action == "walk":
				fs["speed"] = 1.0
		elif MODES[mode] == "expressions":
			r.set_expression(Face.NAMES[(expr_i + rigs.find(r)) % Face.NAMES.size()])
		r.apply_fighter_state(fs, 1.0 / 60.0)
	frame += 1
	if MODES[mode] == "cycle":
		var tim0: Vector3i = rigs[0].call("_timing_for", cur_action)
		if frame > tim0.x + tim0.y + tim0.z + 80:
			action_i = 1 + action_i % (PoseLib.ACTIONS.size() - 1)
			frame = 0
	if MODES[mode] == "expressions" and frame % 90 == 0:
		expr_i += 1
	_update_camera()
	hud.text = "%s | %s%s  (Space mode, 1-7 focus, arrows orbit/zoom, A action, E expression)" % [MODES[mode].to_upper(),
			Pal.IDS[focus - 1].to_upper() if focus > 0 else "THE SEVEN", ("  action: " + PoseLib.ACTIONS[action_i]) if MODES[mode] == "cycle" else ""]

func _update_camera() -> void:
	var cam: Camera3D = st["cam"]
	var y := deg_to_rad(yaw)
	if focus == 0:
		cam.fov = 26.0
		var d := 24.0 * zoom
		cam.look_at_from_position(Vector3(sin(y), 0.16, cos(y)) * d + Vector3(0, 2.2, 0), Vector3(0, 1.3, 0))
	else:
		cam.fov = 28.0
		var r: Node3D = rigs[focus - 1]
		var h: float = r.nominal_height()
		var d: float = (h * 1.5 * zoom) / tan(deg_to_rad(cam.fov * 0.5))
		var c: Vector3 = r.position + Vector3(0.2, h * 0.5, 0)
		cam.look_at_from_position(c + Vector3(sin(y), 0.15, cos(y)) * d, c)
	var sun: DirectionalLight3D = st["sun"]
	sun.rotation_degrees = Vector3(-30, yaw + 35.0, 0)
