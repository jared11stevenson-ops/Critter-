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
	UiSfx.hook(get_tree())
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
		"shelf": _debug_shelf()
		"career": go_play()
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
	Music.play("menu")
	_clear()
	var t := TitleScreen.new()
	add_child(t)
	t.setup(int(_args.get("seed", 0)))
	t.play_pressed.connect(go_play)
	t.new_career_pressed.connect(func(): CareerPanels.confirm(t, "NEW CAREER?", "Start over with Aruun. Your current shelf is replaced. Critters that already died stay dead on the Wall.", "START OVER", go_new_career))
	t.training_pressed.connect(func(): training = true; go_select())
	screen = t

## Practice only offers critters you own (living on your shelf); with no career yet that is the tutorial critter.
func owned_species() -> Array:
	var out: Array = []
	if Career.has_save() and GameSave.roster != null:
		for c in GameSave.roster.rack.living():
			if not out.has(c.species):
				out.append(c.species)
	if out.is_empty():
		out.append("aruun")
	return out

func go_select() -> void:
	_clear()
	var s := SelectScreen.new()
	s.owned = owned_species()
	add_child(s)
	s.setup("player", player_id)
	s.back_pressed.connect(go_title)
	s.chosen.connect(func(id: String): player_id = id; UiPrefs.set_pref("player", id); go_opponent())
	screen = s

func go_opponent() -> void:
	_clear()
	var s := SelectScreen.new()
	s.owned = owned_species()
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

# ------------------------------------------------------------------ career (the real game loop; see design/v2/CREATOR_GDD.md)
var career_ctx: Dictionary = {}
var career_layer: CanvasLayer
var tips: TutorialTips

## QA only: a populated career (screenshots): --screen=shelf
func _debug_shelf() -> void:
	var r := GameSave.start_new("qa")
	var a := r.seal("aruun", "Aruun")
	a.bouts_survived = 9
	a.bond_points = 40
	a.chapters_unlocked = [1, 2, 3]
	a.vitality = 0.8
	for sp in ["cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris", "pharilux", "aruun", "cigarra"]:
		var c := r.seal(sp, Career.random_name(sp, r))
		c.vitality = randf_range(0.3, 1.0)
	var ch := r.seal("mollusk", "Pebble")
	ch.champion = true
	ch.retired = true
	var d := r.seal("zephyr", "Whisk")
	r.kill(d.uid, "a tournament bout against Aruun")
	r.economy.scrap = 140
	var hm := r.habitat("mollusk")
	hm.materials = 25
	for i in 45:
		hm.step_day(r.retired_adults("mollusk"))
	go_shelf(a.uid)
	match str(_args.get("panel", "")):
		"jar": CareerPanels.jar(screen, a)
		"jar2": CareerPanels.jar(screen, ch)
		"watch": CareerPanels.watch(screen, "mollusk")
		"explore":
			var erng := RandomNumberGenerator.new()
			erng.seed = 3
			CareerPanels.explore(screen, "Frostbloom", Career.explore_nodes("frostbloom", erng), {"uid": a.uid}, erng, func(): pass)
		"scout": CareerPanels.scout(screen, "nyxaris", "expert", "Frostbloom", func(_a: String) -> String: return "")
		"wall": CareerPanels.wall(screen, r)
		"hall": CareerPanels.hall(screen, r)
		"moves": CareerPanels.move_card(screen, "pharilux")
		"expedition": CareerPanels.expedition(screen, r, func(_a, _b): pass)
		"tournament": CareerPanels.tournament(screen, r, a.uid, func(_u): pass, func(_u): pass)
		"chapter": screen._read(a, 3)

func go_play() -> void:
	if Career.has_save() and GameSave.continue_game():
		Career.roster().tick_habitats()
		go_shelf("", Career.settle_abandoned(Career.roster()))
	else:
		go_new_career()

func go_new_career() -> void:
	Career.start_new()
	var r := Career.roster()
	var c: CritterInstance = r.rack.living()[0]
	career_ctx = {"kind": "tutorial", "uid": c.uid, "opp_species": "mollusk", "profile": "novice"}
	go_career_bout(true)

func go_shelf(select_uid := "", notice := "") -> void:
	Music.play("menu")
	_clear()
	if tips != null:
		tips.queue_free()
		tips = null
	var sh := ShelfScreen.new()
	add_child(sh)
	sh.setup(Career.roster(), select_uid)
	sh.title_pressed.connect(go_title)
	sh.wall_pressed.connect(func(): CareerPanels.wall(sh, Career.roster()))
	sh.expedition_pressed.connect(func(): CareerPanels.expedition(sh, Career.roster(), _launch_expedition))
	sh.tournament_pressed.connect(func(uid: String):
		CareerPanels.tournament(sh, Career.roster(), uid, _launch_tournament, func(u: String): _retire(sh, u))
		var cc := Career.roster().get_critter(uid)
		if cc != null and not Career.rung_mods(Career.next_rung(cc), cc).is_empty():
			Tips.once(sh, "rules"))
	sh.training_pressed.connect(_launch_training)
	screen = sh
	if notice != "":
		CareerPanels.notice(sh, "WHILE YOU WERE AWAY", notice)
	else:
		Tips.once(sh, "shelf")

func _retire(sh: ShelfScreen, uid: String) -> void:
	Career.retire(Career.roster(), uid)
	sh.refresh(uid)

func _launch_training(uid: String) -> void:
	CareerPanels.practice(screen, owned_species(), func(opp: String, profile_id: String):
		career_ctx = {"kind": "training", "uid": uid, "opp_species": opp, "profile": profile_id}
		go_career_bout(true))

func _launch_expedition(region_id: String, uid: String) -> void:
	var reg := Career.region(region_id)
	career_ctx = {"kind": "expedition", "uid": uid, "region": region_id, "opp_species": str(reg["species"]), "profile": str(reg["profile"])}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var nodes := Career.explore_nodes(region_id, rng)
	CareerPanels.explore(screen, str(reg["name"]), nodes, career_ctx, rng, func():
		Career._autosave("explore")
		CareerPanels.scout(screen, str(reg["species"]), str(reg["profile"]), str(reg["name"]), func(ap: String) -> String:
			var why := Career.apply_approach(Career.roster(), career_ctx, ap)
			if why == "":
				go_career_bout(false)
			return why)
		Tips.once(screen, "approaches"))

func _launch_tournament(uid: String) -> void:
	var c := Career.roster().get_critter(uid)
	var rung := Career.next_rung(c)
	career_ctx = {"kind": "tournament", "uid": uid, "rung": c.tourney_wins, "opp_species": Career.opponent_for_rung(rung, c), "profile": str(rung["profile"]), "mods": Career.rung_mods(rung, c)}
	go_career_bout(false)

func go_career_bout(training_flag: bool) -> void:
	Music.play("bout")
	_clear()
	var c := Career.roster().get_critter(str(career_ctx["uid"]))
	if c == null:
		go_shelf()
		return
	if str(career_ctx["kind"]) in ["expedition", "extraction", "tournament"]:
		Career.commit(Career.roster(), career_ctx)
	var cfg := Career.make_config(c, str(career_ctx["opp_species"]), str(career_ctx["profile"]), float(career_ctx.get("opp_vit", 1.0)), training_flag or str(career_ctx["kind"]) in ["tutorial", "training"], Career.arena_for(career_ctx) if str(career_ctx["kind"]) in ["expedition", "extraction"] else arena_id)
	if str(career_ctx["kind"]) == "extraction":
		cfg.b_vit = 0.8
	cfg.intro = not _args.has("nointro")
	cfg.human_a = not _args.has("spectate")
	cfg.mods = (career_ctx.get("mods", []) as Array).duplicate()
	if str(career_ctx["kind"]) in ["expedition", "extraction", "tournament"]:
		cfg.b_name = Career.opponent_name(str(career_ctx["opp_species"]), int(career_ctx.get("rung", c.bouts_survived)) + c.titles_defended * 7)
	var b := BoutScene.new()
	add_child(b)
	b.start(cfg)
	b.hud.quit_requested.connect(go_shelf)
	b.finished.connect(_on_career_finished)
	bout = b
	if str(career_ctx["kind"]) == "tutorial":
		tips = TutorialTips.new()
		add_child(tips)

func _on_career_finished(res: Dictionary) -> void:
	if tips != null:
		tips.queue_free()
		tips = null
	if bout != null:
		bout.hud.touch.release_all()
		bout.hud.visible = false
	var kind := str(career_ctx["kind"])
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.theme = UiStyle.theme()
	layer.add_child(host)
	career_layer = layer
	var uid := str(career_ctx["uid"])
	if kind in ["tutorial", "training"]:
		var won := int(res.get("winner", -1)) == 0
		var rep := {"headline": ("Well fought." if won else "Not yet."), "tone": "win" if won else "loss", "lines": [
			"Practice is safe: nothing is lost and nothing counts." if kind == "training" else "That was the tutorial. From here on every fight is real, and death is permanent.",
			"Your Shelf is ready. Send Aruun on an expedition to capture a new critter, or enter a tournament."], "died": false}
		var choices := [["shelf", "TO THE SHELF", UiStyle.GOLD], ["retry", "AGAIN", UiStyle.TEAL_LT]]
		CareerPanels.result(host, rep, choices, func(id: String): _tutorial_choice(id, layer, uid))
		if kind == "tutorial":
			Tips.once(host, "controls")
		return
	var rep := Career.resolve(Career.roster(), career_ctx, res)
	var choices: Array = []
	if bool(rep["died"]):
		choices = [["shelf", "TO THE SHELF", UiStyle.GOLD]]
	elif bool(rep["capture_offer"]):
		choices = [["seal", "SEAL IT", UiStyle.GREEN], ["finish", "FINISH IT", UiStyle.RUST]]
	elif bool(rep.get("champion", false)):
		choices = [["shelf", "TO THE SHELF", UiStyle.GOLD]]
	else:
		choices = [["shelf", "CONTINUE", UiStyle.GOLD]]
	CareerPanels.result(host, rep, choices, func(id: String): _career_choice(id, layer, uid))

func _tutorial_choice(id: String, layer: CanvasLayer, uid: String) -> void:
	layer.queue_free()
	if id == "retry":
		go_career_bout(true)
	else:
		go_shelf(uid)

func _career_choice(id: String, layer: CanvasLayer, uid: String) -> void:
	layer.queue_free()
	if id == "seal":
		var c := Career.roster().get_critter(uid)
		career_ctx = Career.begin_extraction(c, str(career_ctx["opp_species"]), str(career_ctx.get("region", "")))
		career_ctx["profile"] = "standard"
		go_career_bout(false)
	elif id == "finish":
		Career.finish_wild(Career.roster())
		go_shelf(uid)
	else:
		go_shelf(uid)

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
	Music.play("bout")
	_clear()
	var b := BoutScene.new()
	add_child(b)
	b.start(make_config())
	b.hud.quit_requested.connect(go_title)
	b.finished.connect(_on_finished)
	bout = b

func _on_finished(res: Dictionary) -> void:
	var r := ResultScreen.new()
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	layer.add_child(r)
	r.tree_exited.connect(layer.queue_free)
	if bout != null:
		bout.hud.touch.release_all()
		bout.hud.visible = false
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
