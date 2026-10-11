class_name Hud extends CanvasLayer
## HUD layer of a bout: the custom-drawn HudDraw, the touch controls, the 'Yield or fight on' panel, the keyboard Last Stand
## hint and the pause menu. BoutScene owns it and calls refresh(dt) every frame.

signal quit_requested
signal rematch_requested

var bout: BoutScene
var draw_ctl: HudDraw
var touch: TouchControls
var yield_panel: PanelContainer
var yield_chip: Button
var pause_panel: PanelContainer
var ls_hint: Label
var _yield_panel_t := 0.0

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(b: BoutScene) -> void:
	bout = b
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiStyle.theme()
	add_child(root)
	draw_ctl = HudDraw.new()
	root.add_child(draw_ctl)
	draw_ctl.setup(b)
	touch = TouchControls.new()
	root.add_child(touch)
	touch.configure(str(UiPrefs.get_pref("layout")), bool(Settings.get_value("left_handed")))
	touch.visible = UiPrefs.touch_enabled() and b.player_idx >= 0
	touch.pause_pressed.connect(_toggle_pause)
	touch.blocker = _touch_blocked
	_build_yield(root)
	_build_pause(root)
	ls_hint = UiStyle.label("LAST STAND   [U] + [I]", 34, UiStyle.RUST)
	ls_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ls_hint.position.y -= 70
	ls_hint.visible = false
	root.add_child(ls_hint)
	b.fight_event.connect(_on_event)
	b.phase_changed.connect(_on_phase)
	_tune_touch()

## Ability move ids [a1, a2, a3] from the critter def: `abilities` when the sim provides it, else the legacy move_ids keys. "" = none.
static func ability_ids(d: CritterDef) -> Array:
	var out: Array = ["", "", ""]
	var list: Variant = d.get("abilities")
	if list is Array and not (list as Array).is_empty():
		for i in mini(3, (list as Array).size()):
			out[i] = str(list[i])
	else:
		for i in 3:
			out[i] = str(d.move_ids.get("ability%d" % (i + 1), ""))
	return out

func _tune_touch() -> void:
	if bout.player_idx < 0:
		return
	var d: CritterDef = bout.sim.fighters[bout.player_idx].def
	var pal: Dictionary = bout.rigs[bout.player_idx].palette
	touch.ab_known = true
	var ids := ability_ids(d)
	for i in 3:
		var m: MoveDef = d.move(ids[i]) if ids[i] != "" else null
		touch.ab_names["ab%d" % (i + 1)] = m.name if m != null else ""
	touch.ab_colors["ab1"] = (pal.get("glow", UiStyle.TEAL_LT) as Color).lightened(0.1)
	touch.ab_colors["ab2"] = (pal.get("accent", UiStyle.GOLD) as Color).lightened(0.25)
	touch.ab_colors["ab3"] = (pal.get("main", UiStyle.PAPER) as Color).lightened(0.35)

func _build_yield(root: Control) -> void:
	yield_panel = PanelContainer.new()
	yield_panel.visible = false
	yield_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	yield_panel.position.y = 150
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	yield_panel.add_child(v)
	var l := UiStyle.label("Yield, or fight on?", 40, UiStyle.GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var l2 := UiStyle.label("Yielding spares your life but loses the bout.", 22, UiStyle.PAPER, 6)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var y := UiStyle.button("YIELD", 36, Vector2(240, 96), UiStyle.RUST)
	y.pressed.connect(func(): _do_yield())
	row.add_child(y)
	var f := UiStyle.button("FIGHT ON", 36, Vector2(240, 96), UiStyle.GOLD)
	f.pressed.connect(func(): yield_panel.visible = false; _yield_panel_t = 0.0)
	row.add_child(f)
	root.add_child(yield_panel)
	yield_chip = UiStyle.button("Yield", 28, Vector2(150, 96), UiStyle.RUST)
	yield_chip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	yield_chip.position.y = 128
	yield_chip.visible = false
	yield_chip.pressed.connect(func(): _do_yield())
	root.add_child(yield_chip)

func _build_pause(root: Control) -> void:
	pause_panel = PanelContainer.new()
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	pause_panel.add_child(v)
	var l := UiStyle.label("PAUSED", 56, UiStyle.GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	for spec in [["Resume", func(): _toggle_pause()],
			["Performance report", func(): Perf.open_report()],
			["Yield the bout", func(): _toggle_pause(); _do_yield()],
			["Quit to menu", func(): get_tree().paused = false; quit_requested.emit()]]:
		var b := UiStyle.button(spec[0], 32, Vector2(420, 88), UiStyle.GOLD if spec[0] == "Resume" else UiStyle.PAPER_DK)
		b.pressed.connect(spec[1])
		v.add_child(b)
	root.add_child(pause_panel)

func _touch_blocked(p: Vector2) -> bool:
	if pause_panel.visible:
		return true
	return (yield_panel.visible and yield_panel.get_global_rect().grow(8).has_point(p)) or (yield_chip.visible and yield_chip.get_global_rect().grow(8).has_point(p))

func _toggle_pause() -> void:
	if bout.is_over():
		return
	var on := not get_tree().paused
	get_tree().paused = on
	pause_panel.visible = on
	touch.release_all()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pause") and bout != null and not bout.is_over():
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _do_yield() -> void:
	yield_panel.visible = false
	if bout.player != null:
		bout.player.press("yield")

func offer_yield() -> void:
	_yield_panel_t = 3.2
	yield_panel.visible = true

func refresh(dt: float) -> void:
	draw_ctl.refresh(dt)
	if _yield_panel_t > 0.0:
		_yield_panel_t -= dt
		if _yield_panel_t <= 0.0:
			yield_panel.visible = false
	var pi := bout.player_idx
	var show_chip := false
	var can_ls := false
	if pi >= 0:
		var f: Dictionary = bout.fighter_state(pi)
		can_ls = bool(f["can_last_stand"]) and bout.phase == "fight"
		show_chip = bout.low_vit_offered and f["alive"] and bout.phase == "fight" and not yield_panel.visible \
			and float(f["vitality"]) / maxf(1.0, float(f["vitality_max"])) < float(bout.sim.R["last_stand_ratio"])
		touch.can_ls = can_ls
		var d: CritterDef = bout.sim.fighters[pi].def
		var aids := ability_ids(d)
		for i in 3:
			var k := ["ab%d" % (i + 1)]
			var m: MoveDef = d.move(aids[i]) if aids[i] != "" else null
			var left := float(f["cooldowns"].get(m.id, 0)) if m != null else 0.0
			touch.cooldowns[k[0]] = clampf(left / maxf(1.0, float(m.cooldown)), 0.0, 1.0) if (m != null and m.cooldown > 0) else 0.0
	yield_chip.visible = show_chip
	ls_hint.visible = can_ls and not touch.visible
	ls_hint.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.012)

func _on_phase(p: String) -> void:
	var a: String = bout.sim.fighters[0].def.display_name.to_upper()
	var b: String = bout.sim.fighters[1].def.display_name.to_upper()
	match p:
		"intro":
			draw_ctl.show_banner("%s  vs  %s" % [a, b], "Training bout - nobody dies" if bout.cfg.training else "Blood bout - one life each", 2.0)
		"fight":
			draw_ctl.show_banner("FIGHT!", "", 0.9)

func _on_event(ev: Dictionary) -> void:
	var idx := int(ev.get("fighter", 0))
	var foe := idx != bout.player_idx
	var wp := bout.chest(idx, 1.9)
	match str(ev["type"]):
		"hit":
			var dmg := int(round(float(ev.get("damage", 0.0))))
			if bool(ev.get("counter", false)):
				draw_ctl.add_pop("COUNTER!", wp + Vector3(0, 0.5, 0), UiStyle.GOLD, 40)
			draw_ctl.add_pop(str(dmg), wp, UiStyle.GOLD if foe else UiStyle.RUST, 36)
		"block":
			draw_ctl.add_pop("GUARD BREAK!" if ev.get("broke", false) else "BLOCK", wp, UiStyle.TEAL_LT, 30)
		"parry":
			draw_ctl.add_pop("PARRY!", wp, UiStyle.GREEN, 46)
		"stagger":
			draw_ctl.add_pop("STAGGER!", wp, UiStyle.RUST, 38)
		"dodge":
			draw_ctl.add_pop("DODGE", wp, UiStyle.PAPER, 28)
		"clash":
			if idx == 0:
				draw_ctl.add_pop("CLASH!", wp, UiStyle.GOLD, 40)
		"grab":
			draw_ctl.add_pop("GRABBED", wp, Color(0.85, 0.45, 0.3), 34)
		"laststand":
			draw_ctl.show_banner("LAST STAND", bout.sim.fighters[idx].def.display_name, 1.3)
		"ringout":
			draw_ctl.show_banner("RING OUT!", "", 2.0)
		"ko":
			draw_ctl.show_banner("K.O.", "", 2.0)
		"yield":
			draw_ctl.show_banner("YIELDED", "", 2.0)
