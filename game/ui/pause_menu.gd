class_name PauseMenu
extends CanvasLayer
## Pause: Resume, Field Codex, Settings, Return to Title. Pauses the tree while open.

var _was_paused := false
var _panel: PanelContainer
var _sub: Node = null

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	TouchInput.reset()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UiKit.theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.03, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(460, 0)
	root.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	_panel.add_child(vb)
	var t := UiKit.label("PAUSED", 48, UiKit.INK, "title")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var sub := UiKit.label("Handler's field tablet", 22, UiKit.MUTED, "ui")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var items := [["Resume", _resume], ["Field Codex", _codex], ["Settings", _settings], ["Return to Title", _title]]
	for it in items:
		var b := UiKit.button(it[0], Vector2(400, 88))
		b.pressed.connect(it[1])
		vb.add_child(b)
	_panel.reset_size.call_deferred()
	_center.call_deferred()
	(vb.get_child(2) as Button).grab_focus.call_deferred()
	Audio.sfx("ui_tap")

func _center() -> void:
	var vs := get_viewport().get_visible_rect().size
	_panel.reset_size()
	_panel.position = (vs - _panel.size) * 0.5

func _resume() -> void:
	Audio.sfx("ui_back")
	get_tree().paused = false
	queue_free()

func _codex() -> void:
	Audio.sfx("ui_confirm")
	_panel.visible = false
	_sub = CodexScreen.new()
	add_child(_sub)
	_sub.tree_exited.connect(func(): _panel.visible = true)

func _settings() -> void:
	Audio.sfx("ui_confirm")
	_panel.visible = false
	_sub = SettingsPanel.new()
	add_child(_sub)
	_sub.tree_exited.connect(func(): _panel.visible = true)

func _title() -> void:
	Audio.sfx("ui_back")
	GameState.save_game()
	get_tree().paused = false
	queue_free()
	Router.goto("res://game/ui/title/title.tscn")

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel"):
		if _sub and is_instance_valid(_sub):
			return
		_resume()
		get_viewport().set_input_as_handled()
