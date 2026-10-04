class_name RivalEncounters
extends Node
## Runs Ledger Rival encounters for a field level (LEDGER_SPEC §7/§8):
##   spawn  -> Rivals.active_in(region) (+ released bondables) at authored spots,
##   greet  -> Rivals.greeting(id) through the dialogue box, Rivals.encounter_begin(id),
##   fight  -> RivalEnemy AI mapped from Rivals.behavior_profile(id),
##   yield  -> Rivals.resolution_options(id) as buttons (12 s window; no answer = they escape),
##   close  -> Rivals.encounter_end(id, outcome, hit_by) and the consequences of each outcome.
## Rules held here: one rival at a time per spot, no ranks, no rival-vs-rival, non-lethal outcomes first-class.

const REGION := "red_reaches"
const SPOTS := {
	"foreman_orrin": {"trigger": "drill_enter", "anchor": "drill_camp", "offset": Vector3(5, 0, -6), "place": "Drill Site"},
	"poacher_vesk": {"trigger": "waystation_enter", "anchor": "", "pos": Vector3(128, -3, -9), "place": "Waystation"},
}

signal rival_resolved(rival_id: String, outcome: String)

var level: Node3D
var runner: DialogueRunner
var live: Dictionary = {}              # rival id -> RivalEnemy
var _spawned: Dictionary = {}          # rival id -> true (this level load)
var _after: Dictionary = {}            # dialogue id -> Callable
var _layer: CanvasLayer
var _panel: PanelContainer
var _panel_rival: RivalEnemy = null
var _timer := 0.0
var _timed := false
var _bar: ProgressBar
var _head: Label
var _note: Label
var _grid: GridContainer

func setup(lvl: Node3D, run: DialogueRunner) -> void:
	level = lvl
	runner = run
	process_mode = Node.PROCESS_MODE_PAUSABLE
	runner.finished.connect(_on_dialogue_finished)
	_layer = CanvasLayer.new()
	_layer.layer = 45
	add_child(_layer)

# ---------------- spawning ----------------
## Who can show up in this region right now (active/escaped/unmet, plus released bondables for the bond offer).
func candidates() -> Array:
	var out: Array = []
	for r in Rivals.active_in(REGION):
		out.append(str(r["id"]))
	for r in Rivals.all():
		if str(r["region"]) == REGION and str(r["state"]) == "released" and bool(r["bondable"]) and not (str(r["id"]) in out):
			out.append(str(r["id"]))
	return out

func spot_pos(id: String) -> Vector3:
	var s: Dictionary = SPOTS.get(id, {})
	var p: Vector3 = s.get("pos", Vector3.ZERO)
	if str(s.get("anchor", "")) != "":
		p = level._structure_pos(str(s["anchor"]), Vector3(208, -6, 26)) + (s.get("offset", Vector3.ZERO) as Vector3)
	return p

func spawn(id: String) -> RivalEnemy:
	if _spawned.has(id) or not SPOTS.has(id):
		return null
	var r := Rivals.get_rival(id)
	if r.is_empty():
		return null
	_spawned[id] = true
	var e := RivalEnemy.make(id)
	level.actors_root.add_child(e)
	e.global_position = level.ground(spot_pos(id), 0.3)
	e.home = e.global_position
	e.talk_first = Director.rivals_talk_first()
	e.engaged.connect(_on_engaged)
	e.yielded.connect(_on_yielded)
	e.removed.connect(_on_removed)
	live[id] = e
	return e

## Level trigger events ("drill_enter", "waystation_enter") bring the rival who works that spot.
func on_trigger(ev: String) -> void:
	var cands := candidates()
	for id in SPOTS:
		if SPOTS[id]["trigger"] == ev and id in cands:
			spawn(id)

## Return Descent: every unresolved rival is already out there when the party arrives.
func spawn_all() -> void:
	for id in candidates():
		spawn(id)

func any_engaged() -> bool:
	for id in live:
		var e: RivalEnemy = live[id]
		if is_instance_valid(e) and e.engaged_once and e.alive and e.state != "calm":
			return true
	return false

func objective_text() -> String:
	for id in live:
		var e: RivalEnemy = live[id]
		if not is_instance_valid(e) or not e.alive:
			continue
		if e.state == "yield":
			return "Decide %s's fate" % e.display_name
		if e.engaged_once and e.state != "calm":
			return "Stop %s (%s)" % [e.display_name, "ranged" if e.attack_kind == "shot" else "close"]
	return ""

# ---------------- engage / greet ----------------
func _on_engaged(e: RivalEnemy) -> void:
	Rivals.encounter_begin(e.rival_id)
	var g: Dictionary = Rivals.greeting(e.rival_id)
	var lines: Array = [{"who": "rival:" + e.rival_id, "expr": str(g.get("expr", "serious")), "text": str(g.get("text", "..."))}]
	var taunts: Array = e.profile.get("taunts", [])
	if Director.story_level() >= 3 and not taunts.is_empty() and int(Rivals.get_rival(e.rival_id)["encounters"]) == 0:
		lines.append({"who": "rival:" + e.rival_id, "expr": "serious", "text": str(taunts[0])})
	var did := "rival_greet_" + e.rival_id
	_after[did] = _after_greeting.bind(e)
	if not runner.play_data(did, {"lines": lines}):
		_after.erase(did)
		_after_greeting(e)

func _after_greeting(e: RivalEnemy) -> void:
	if not is_instance_valid(e) or not e.alive:
		return
	if e.talk_first:
		_show_panel(e, true)
	else:
		e.begin_fight()

func _on_dialogue_finished(id: String) -> void:
	if _after.has(id):
		var c: Callable = _after[id]
		_after.erase(id)
		c.call_deferred()

# ---------------- yield / resolution panel ----------------
func _on_yielded(e: RivalEnemy) -> void:
	_show_panel(e, false)

func _show_panel(e: RivalEnemy, talk: bool) -> void:
	_close_panel()
	_panel_rival = e
	_timed = not talk
	_timer = float(e.cfg.get("yield_window", 12.0))
	_panel = PanelContainer.new()
	_panel.process_mode = Node.PROCESS_MODE_PAUSABLE
	_panel.theme = UiKit.theme()
	_panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.97), UiKit.char_color("rival:" + e.rival_id), 18, 5, 18))
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -410
	_panel.offset_right = 410
	_panel.offset_top = 92
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	_layer.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_panel.add_child(vb)
	var title := "%s %s" % [e.profile.get("title", ""), e.display_name]
	_head = UiKit.label(title.strip_edges(), 34, UiKit.INK, "title")
	_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_head)
	var note := "Stands armed and waiting. How do you want this to go?" if talk else "Hurt and finished. What do you do with them?"
	_note = UiKit.label(note, 24, UiKit.MUTED.darkened(0.25), "dialogue")
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_note)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 10)
	vb.add_child(_grid)
	for opt in Rivals.resolution_options(e.rival_id):
		var label := str(opt["label"])
		if talk and str(opt["id"]) == "fight":
			label = "Fight them"
		var b := UiKit.button(label, Vector2(380, 74), 26)
		b.name = "Res_" + str(opt["id"])
		b.pressed.connect(_pick.bind(str(opt["id"]), str(opt["outcome"])))
		_grid.add_child(b)
	_bar = ProgressBar.new()
	_bar.min_value = 0.0
	_bar.max_value = _timer
	_bar.value = _timer
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 14)
	_bar.visible = _timed
	vb.add_child(_bar)
	if _timed:
		var warn := UiKit.label("Decide before they slip away.", 20, UiKit.ACCENT, "ui")
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(warn)
	(_grid.get_child(0) as Control).grab_focus.call_deferred()
	Audio.sfx("codex", -6.0)

func _close_panel() -> void:
	if _panel and is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	_panel_rival = null

func _process(delta: float) -> void:
	if _panel_rival != null and is_instance_valid(_panel):
		if _timed:
			_timer -= delta
			if _bar:
				_bar.value = maxf(0.0, _timer)
			if _timer <= 0.0:
				_finish(_panel_rival, "escaped")
	_update_framing()
	# leash: walking off from a live fight lets them go
	if level and level.party and level.party.get_leader():
		var lp: Vector3 = level.party.get_leader().global_position
		for id in live.keys():
			var e: RivalEnemy = live[id]
			if not is_instance_valid(e) or not e.alive or not e.engaged_once:
				continue
			if e.state in ["chase", "windup", "attack", "recover"] and e.global_position.distance_to(lp) > float(e.cfg.get("leash", 60.0)):
				_finish(e, "escaped")

var _framing := false

## Keep the fighting rival in frame (the camera follows only the leader otherwise).
func _update_framing() -> void:
	var cam: Variant = level.get("cam")
	if cam == null:
		return
	var fighter: RivalEnemy = null
	for id in live:
		var e: RivalEnemy = live[id]
		if is_instance_valid(e) and e.alive and e.engaged_once and e.state in ["chase", "windup", "attack", "recover", "yield", "talk"]:
			fighter = e
			break
	var busy: bool = bool(level.get("burden_active")) or (level.get("boss") != null and is_instance_valid(level.get("boss")) and bool(level.boss.active))
	if fighter != null and not busy:
		cam.set_framing(fighter.global_position, 1.15)
		_framing = true
	elif _framing:
		_framing = false
		if not busy:
			cam.set_framing(null)

func _pick(res_id: String, outcome: String) -> void:
	var e := _panel_rival
	if e == null or not is_instance_valid(e):
		_close_panel()
		return
	Audio.sfx("ui_confirm")
	if res_id == "fight" and e.state == "talk":
		# talk-first mode: the player chose to fight; no outcome yet
		_close_panel()
		e.begin_fight()
		return
	_finish(e, outcome)

# ---------------- closing an encounter ----------------
func _finish(e: RivalEnemy, outcome: String) -> void:
	if e == null or not is_instance_valid(e):
		return
	var id := e.rival_id
	if not live.has(id):
		return
	live.erase(id)
	_close_panel()
	Rivals.encounter_end(id, outcome, e.hit_by)
	var nm := e.display_name
	match outcome:
		"defeated":
			e.detain()
			GameState.add_item("salvage", 2)
			_toast("%s is stopped and detained. +2 Salvage logged." % nm, "info")
		"negotiated":
			e.walk_away()
			_toast("Terms agreed with %s. They will be checking yours." % nm, "trust")
		"exposed":
			e.walk_away()
			if str(Rivals.get_rival(id).get("faction", "")) == "dominion":
				GameState.dominion_standing -= 1
			_toast("%s is exposed. The paper trail is out." % nm, "info")
		"released":
			e.walk_away()
			_toast("You let %s walk. They have not forgotten it." % nm, "info")
		"bonded":
			e.walk_away()
			GameState.set_flag(id + "_bonded", true)
			_toast("%s accepts a Bond Contract." % nm, "trust")
		_:
			e.flee_field()
			_toast("%s got away. They will remember how you fight." % nm, "warning")
	GameState.save_game()
	rival_resolved.emit(id, outcome)

func _on_removed(_e: Node) -> void:
	pass

func on_party_wiped() -> void:
	for id in live.keys():
		var e: RivalEnemy = live[id]
		if is_instance_valid(e) and e.alive and e.engaged_once and e.state in ["chase", "windup", "attack", "recover", "yield", "talk"]:
			_finish(e, "escaped")

## Leaving the level with a rival still standing counts as an escape; unmet rivals are untouched.
func on_leave_level() -> void:
	for id in live.keys():
		var e: RivalEnemy = live[id]
		if is_instance_valid(e) and e.alive and e.engaged_once:
			_finish(e, "escaped")

func _toast(text: String, kind: String) -> void:
	Events.toast.emit(text, kind)

# ---------------- QA ----------------
func qa_force_yield(id: String) -> void:
	var e: RivalEnemy = live.get(id, null)
	if e and is_instance_valid(e):
		e._wake()
		e.hp = e.max_hp * 0.1
		e._yield()

func qa_resolve(id: String, outcome: String) -> void:
	var e: RivalEnemy = live.get(id, null)
	if e and is_instance_valid(e):
		_finish(e, outcome)
