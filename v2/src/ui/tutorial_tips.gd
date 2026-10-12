class_name TutorialTips
extends CanvasLayer
## Timed control hints for the first (tutorial) bout. Add as a child of the boot node while the bout runs.
const TIPS := [
	[1.0, "Welcome, Handler. Move Aruun with the LEFT STICK."],
	[6.0, "Tap STRIKE to attack. Hold it for a heavy blow."],
	[12.0, "Hold GUARD to block. Guard just before a hit lands to PARRY."],
	[18.0, "DODGE slips through heavy attacks. It costs stamina."],
	[24.0, "The round icons are Aruun's abilities. Try them all."],
	[31.0, "Guard + Strike together is a GRAB. It beats a guard."],
	[40.0, "Watch the enemy's tells. Every attack shows its wind-up."]]
var _t := 0.0
var _label: Label
var _shown := -1

func _ready() -> void:
	layer = 25
	_label = UiStyle.label("", 30, UiStyle.PAPER, 8)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label.position = Vector2(-500, 205)
	_label.custom_minimum_size = Vector2(1000, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)

func _process(delta: float) -> void:
	_t += delta
	var idx := -1
	for i in TIPS.size():
		if _t >= float(TIPS[i][0]) and _t < float(TIPS[i][0]) + 5.0:
			idx = i
	if idx != _shown:
		_shown = idx
		_label.text = str(TIPS[idx][1]) if idx >= 0 else ""
