class_name TitleScreen extends Control
## Title: a slow-orbiting 3D arena with two critters squaring up, the CRITTER logo and the main menu.
## PLAY -> character select, TRAINING -> character select with the Training flag, SETTINGS overlay, QUIT on desktop.

signal play_pressed
signal training_pressed
signal new_career_pressed

var _vpc: SubViewportContainer
var _cam: Camera3D
var _rigs: Array[CritterRig] = []
var _t := 0.0
var _acts := ["idle", "strike_light", "idle", "ability1", "idle", "guard"]
var _act_i := 0
var _act_t := 0.0
var _frame := 0
var _pair: Array = []

func setup(seed_value := 0) -> void:
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ids: Array = CombatData.critter_ids()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	var a := rng.randi() % ids.size()
	var b := (a + 1 + rng.randi() % (ids.size() - 1)) % ids.size()
	_pair = [ids[a], ids[b]]
	_vpc = SubViewportContainer.new()
	_vpc.stretch = true
	_vpc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vpc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	_vpc.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	ArenaBuilder.build(world, CombatData.arena("ring"), false)
	for i in 2:
		var h := Node3D.new()
		world.add_child(h)
		h.position = Vector3(-3.0 if i == 0 else 3.0, 0, 0)
		h.rotation.y = 0.0 if i == 0 else PI
		var r := CritterRig.new()
		h.add_child(r)
		r.setup(str(_pair[i]))
		r.three_quarter = 20.0
		_rigs.append(r)
	_cam = Camera3D.new()
	_cam.fov = 36.0
	world.add_child(_cam)
	_cam.current = true
	_build_ui()

func _build_ui() -> void:
	var m := UiStyle.safe_margins(get_viewport())
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.03, 0.03, 0.04, 0.28)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	var logo := UiStyle.label("CRITTER", 168, UiStyle.GOLD, 28)
	logo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	logo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	logo.position.y = maxf(m.y, 14) + 6
	logo.rotation = -0.03
	add_child(logo)
	var tag := UiStyle.label("Fight to survive. Win to be free.", 32, UiStyle.PAPER, 9)
	tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tag.position.y = maxf(m.y, 14) + 206
	add_child(tag)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	col.position.y -= maxf(m.w, 18) + 4
	add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)
	var play := UiStyle.button("CONTINUE" if Career.has_save() else "PLAY", 44, Vector2(300, 108))
	play.pressed.connect(func(): play_pressed.emit())
	row.add_child(play)
	var tr := UiStyle.button("DUEL LAB", 30, Vector2(220, 108), UiStyle.TEAL)
	tr.pressed.connect(func(): training_pressed.emit())
	row.add_child(tr)
	if Career.has_save():
		var nc := UiStyle.button("NEW CAREER", 28, Vector2(230, 108), UiStyle.RUST)
		nc.pressed.connect(func(): new_career_pressed.emit())
		row.add_child(nc)
	var st := UiStyle.button("SETTINGS", 34, Vector2(220, 108), UiStyle.PAPER_DK)
	st.pressed.connect(func(): add_child(SettingsPanel.new()))
	row.add_child(st)
	var ver := UiStyle.label("v%s  playtest build" % str(ProjectSettings.get_setting("application/config/version", "?")), 18, UiStyle.PAPER_DK, 5)
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ver.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ver.position -= Vector2(maxf(m.z, 18), maxf(m.w, 8))
	add_child(ver)
	var cr := UiStyle.label("%s vs %s" % [CombatData.critter(str(_pair[0])).display_name, CombatData.critter(str(_pair[1])).display_name], 18, UiStyle.PAPER_DK, 5)
	cr.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	cr.grow_vertical = Control.GROW_DIRECTION_BEGIN
	cr.position += Vector2(maxf(m.x, 18), -maxf(m.w, 8))
	add_child(cr)

func _process(delta: float) -> void:
	if _cam == null:
		return
	_t += delta
	var ang := 0.35 + sin(_t * 0.25) * 0.35
	var d := 15.0
	_cam.position = Vector3(sin(ang) * d * 0.4, 2.6, cos(ang) * d)
	_cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	_act_t += delta
	var act: String = _acts[_act_i]
	_frame = int(_act_t * 60.0)
	if _act_t > (2.6 if act == "idle" else 1.4):
		_act_t = 0.0
		_act_i = (_act_i + 1) % _acts.size()
	for i in 2:
		var d_: CritterDef = CombatData.critter(str(_pair[i]))
		var use := act if (i == 0) == (_act_i % 4 < 2) else "idle"
		var mid := ""
		match use:
			"strike_light": mid = str(d_.move_ids["light"][0])
			"ability1": mid = str(d_.move_ids["ability1"])
		_rigs[i].apply_fighter_state({"action": use, "action_frame": _frame, "move_id": mid, "vitality_ratio": 1.0, "facing": 1.0}, minf(delta, 0.034))
