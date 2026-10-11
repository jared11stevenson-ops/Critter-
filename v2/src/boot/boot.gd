extends Control
## Placeholder boot screen for the v2 skeleton. Replaced by the title/bout flow in Sprint 1.

func _ready() -> void:
	var l := Label.new()
	l.text = "CRITTER 2\nCapture it. Raise it. Fight with it. Keep it alive.\n\nv%s  (skeleton)" % ProjectSettings.get_setting("application/config/version")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.add_theme_font_size_override("font_size", 36)
	add_child(l)
