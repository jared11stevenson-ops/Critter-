extends Control
## Main flow: Title -> Character select -> Opponent select -> Bout -> Result (rematch / change fighters / title).
## Death is shown honestly on the result screen but NOTHING is persisted in this prototype (roster milestone).
## Command line (after `--`): --autostart=a:b[:profile] jumps straight into a bout, --screen=title|select|opponent|bout|result|settings
## and --layout=A|B --touch force UI state for screenshots (see tools/shoot_flow.sh).

var screen: Node = null
var bout: BoutScene = null
var result_ui: ResultScreen = null
var player_id := "aruun"
var opponent_id := "cigarra"
var profile := "standard"
var arena_id := "ring"
var training := false
var _args := {}
var _shot_t := 0.0
var _shot_done := false

func _ready() -> void:
	Perf.context = "menu"
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for a in OS.get_cmdline_user_args():
		var p := a.trim_prefix("--").split("=", true, 1)
		_args[p[0]] = p[1] if p.size() > 1 else "1"
	player_id = str(UiPrefs.get_pref("player"))
	opponent_id = str(UiPrefs.get_pref("opponent"))
	profile = str(UiPrefs.get_pref("profile"))
	arena_id = str(UiPrefs.get_pref("arena"))
	if _args.has("layout"):
		UiPrefs.set_pref("layout", str(_args["layout"]), false)
	if _args.has("touch"):
		UiPrefs.set_pref("touch", "on", false)
	if _args.has("lefty"):
		Settings.set_value("left_handed", true)
	if _args.has("speed"):
		Engine.time_scale = float(_args["speed"])
	if _args.has("autostart"):
		var q := str(_args["autostart"]).split(":")
		player_id = q[0]
		opponent_id = q[1] if q.size() > 1 else opponent_id
		profile = q[2] if q.size() > 2 else profile
		training = _args.has("training")
		go_bout()
		if _args.has("fake-result"):
			get_tree().create_timer(0.8).timeout.connect(_fake_result)
		return
	match str(_args.get("screen", "title")):
		"select": go_select()
		"opponent": go_opponent()
		"bout": go_bout()
		"settings":
			go_title()
			add_child(SettingsPanel.new())
		_: go_title()

func _clear() -> void:
	if result_ui != null:
		result_ui.queue_free()
		result_ui = null
	if bout != null:
		bout.queue_free()
		bout = null
	if screen != null:
		screen.queue_free()
		screen = null
	get_tree().paused = false
	Perf.context = "menu"

func go_title() -> void:
	_clear()
	var t := TitleScreen.new()
	add_child(t)
	t.setup(int(_args.get("seed", 0)))
	t.play_pressed.connect(func(): training = false; go_select())
	t.training_pressed.connect(func(): training = true; go_select())
	screen = t

func go_select() -> void:
	_clear()
	var s := SelectScreen.new()
	add_child(s)
	s.setup("player", player_id)
	s.back_pressed.connect(go_title)
	s.chosen.connect(func(id: String): player_id = id; UiPrefs.set_pref("player", id); go_opponent())
	screen = s

func go_opponent() -> void:
	_clear()
	var s := SelectScreen.new()
	s.profile = profile
	s.arena_id = arena_id
	s.training = training
	add_child(s)
	s.setup("opponent", opponent_id)
	s.back_pressed.connect(go_select)
	s.chosen.connect(func(id: String):
		opponent_id = id
		profile = s.profile
		arena_id = s.arena_id
		training = s.training
		UiPrefs.set_pref("opponent", id, false)
		UiPrefs.set_pref("profile", profile, false)
		UiPrefs.set_pref("arena", arena_id)
		go_bout())
	screen = s

func make_config() -> BoutConfig:
	var cfg := BoutConfig.new()
	cfg.a_id = player_id
	cfg.b_id = opponent_id
	cfg.human_a = not _args.has("spectate")
	cfg.intro = not _args.has("nointro")
	cfg.profile_b = profile
	cfg.arena_id = arena_id
	cfg.training = training
	cfg.seed_value = int(Time.get_ticks_usec() & 0xffffff)
	return cfg

func go_bout() -> void:
	_clear()
	var b := BoutScene.new()
	add_child(b)
	b.start(make_config())
	b.hud.quit_requested.connect(go_title)
	b.finished.connect(_on_finished)
	bout = b

func _on_finished(res: Dictionary) -> void:
	var r := ResultScreen.new()
	add_child(r)
	r.show_result(res)
	r.rematch_requested.connect(go_bout)
	r.change_requested.connect(go_select)
	r.title_requested.connect(go_title)
	result_ui = r

func _fake_result() -> void:
	var tone := str(_args["fake-result"])
	var res := {"winner": 1 if tone in ["death", "defeat", "spare"] else 0, "reason": "yield" if tone == "spare" else "ko", "killed": tone in ["death", "win"],
		"loser": 0 if tone in ["death", "defeat", "spare"] else 1, "ticks": 5421, "vitality_ratio": [0.0, 0.62] if tone != "win" else [0.41, 0.0],
		"damage_dealt": [212.0, 388.0] if tone != "win" else [380.0, 190.0], "a_id": player_id, "b_id": opponent_id, "player_idx": 0, "training": training}
	if tone == "draw":
		res["winner"] = -1
	_on_finished(res)

func _process(delta: float) -> void:
	if _shot_done or not _args.has("shot"):
		return
	_shot_t += delta
	if _shot_t >= float(_args.get("shot-at", 2.0)):
		_shot_done = true
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		DirAccess.make_dir_recursive_absolute(str(_args["shot"]).get_base_dir())
		img.save_png(str(_args["shot"]))
		print("SHOT ", _args["shot"], " ", img.get_size())
		get_tree().quit()
