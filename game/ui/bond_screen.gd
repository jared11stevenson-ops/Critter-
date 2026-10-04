class_name BondScreen
extends Control
## Bond Contracts: shows each character's contract stage track, the contradiction their test is built on,
## the test hint, how they feel about you, and the LIVE state of any promise made to them.
## Data comes only from the Ledger (bond_defs, bonds, promises, opinion); nothing is stored here.

const PROMISE_TEXT := {
	"open": "OPEN. The wording is being tested right now.",
	"kept": "KEPT. Letter and spirit.",
	"loophole": "LOOPHOLE. Kept to the letter only.",
	"bent": "BENT. Kept in spirit, not in wording.",
	"broken": "BROKEN.",
}

var _list: VBoxContainer
var _page: VBoxContainer
var _sel := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.04, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var title := UiKit.label("BOND CONTRACTS", 44, UiKit.PARCHMENT, "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := UiKit.button("Close", Vector2(180, 80))
	close.pressed.connect(_close)
	close.name = "Close"
	top.add_child(close)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	vb.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	var page := PanelContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.98), UiKit.PARCHMENT_DARK.darkened(0.35), 18, 4, 22))
	body.add_child(page)
	var ps := ScrollContainer.new()
	ps.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(ps)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", 8)
	ps.add_child(_page)
	for c in characters():
		var b := UiKit.button("%s  ·  %s" % [Canon.display_name(c), Ledger.bond_stage(c)], Vector2(0, 72), 24)
		b.pressed.connect(select.bind(c))
		b.name = "Bond_" + c
		_list.add_child(b)
		if _sel == "":
			_sel = c
	select(_sel)
	if _list.get_child_count() > 0:
		(_list.get_child(0) as Button).grab_focus.call_deferred()

## Characters with a bond contract (staged ones first, then those already bonded).
static func characters() -> Array:
	var out: Array = []
	for c in Ledger.bond_defs:
		if not str(c).begins_with("_"):
			out.append(c)
	for c in Ledger.bonds:
		if not (c in out):
			out.append(c)
	return out

func select(c: String) -> void:
	_sel = c
	Audio.sfx("ui_tap", -6.0)
	for ch in _page.get_children():
		ch.queue_free()
	var def: Dictionary = Ledger.bond_defs.get(c, {})
	var stage := Ledger.bond_stage(c)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	_page.add_child(head)
	head.add_child(UiKit.portrait_control(c, "default", 110))
	var hv := VBoxContainer.new()
	head.add_child(hv)
	hv.add_child(UiKit.label(Canon.display_name(c), 40, UiKit.char_color(c).darkened(0.1), "title"))
	var op := Ledger.opinion(c)
	hv.add_child(UiKit.label("Feels %s toward you  (%+.0f)" % [Ledger.opinion_label(op), op], 24, UiKit.INK, "bold"))
	if def.has("contradiction"):
		var ct := UiKit.label("Contradiction: " + str(def["contradiction"]), 24, UiKit.INK, "dialogue")
		ct.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ct.custom_minimum_size = Vector2(700, 0)
		_page.add_child(ct)
	_page.add_child(_stage_track(def, stage))
	if def.has("test_hint"):
		_page.add_child(UiKit.label("THE TEST", 20, UiKit.ACCENT, "bold"))
		var th := UiKit.label(str(def["test_hint"]), 26, UiKit.INK, "dialogue")
		th.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		th.custom_minimum_size = Vector2(700, 0)
		_page.add_child(th)
	elif stage == "bonded":
		_page.add_child(UiKit.label("Bonded. Their contradiction is yours to keep faith with.", 26, UiKit.INK, "dialogue"))
	var any_prom := false
	for pid in Ledger.promises:
		var p: Dictionary = Ledger.promises[pid]
		if str(p["to"]) != c:
			continue
		any_prom = true
		_page.add_child(UiKit.label("PROMISE", 20, UiKit.ACCENT, "bold"))
		var w := UiKit.label("“%s”" % str(p["wording"]), 28, UiKit.INK, "dialogue_bold")
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		w.custom_minimum_size = Vector2(700, 0)
		_page.add_child(w)
		var st := str(p["status"])
		var sl := UiKit.label(str(PROMISE_TEXT.get(st, st)), 24, _status_color(st), "bold")
		sl.name = "PromiseState"
		_page.add_child(sl)
		for ln in _live_lines(p):
			var l := UiKit.label(ln, 22, UiKit.MUTED.darkened(0.2), "ui")
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(700, 0)
			_page.add_child(l)
	if not any_prom and def.has("test_hint"):
		_page.add_child(UiKit.label("No promise made yet. Talk to them at the Common.", 22, UiKit.MUTED.darkened(0.2), "ui"))

func _stage_track(def: Dictionary, stage: String) -> Control:
	var stages: Array = def.get("stages", [])
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	if stages.is_empty():
		hb.add_child(UiKit.label("Stage: " + stage, 24, UiKit.INK, "bold"))
		return hb
	var cur := stages.find(stage)
	for i in stages.size():
		var done := i <= cur
		var pc := PanelContainer.new()
		var col := UiKit.ACCENT if i == cur else (UiKit.PSI.darkened(0.35) if done else UiKit.PARCHMENT_DARK)
		pc.add_theme_stylebox_override("panel", UiKit.box(col, UiKit.INK, 12, 2, 10))
		var l := UiKit.label(str(stages[i]).capitalize(), 22, UiKit.PARCHMENT if done else UiKit.INK, "bold")
		pc.add_child(l)
		hb.add_child(pc)
		if i < stages.size() - 1:
			hb.add_child(UiKit.label("›", 26, UiKit.INK, "bold"))
	if stage == "estranged":
		var e := UiKit.label("  ESTRANGED", 24, UiKit.ACCENT, "bold")
		hb.add_child(e)
	return hb

func _status_color(st: String) -> Color:
	match st:
		"kept": return Color("#3f7a3a")
		"loophole": return Color("#a8761e")
		"bent": return Color("#a8761e")
		"broken": return UiKit.ACCENT
	return UiKit.INK

## Plain-language live state for an open promise (what is true so far).
func _live_lines(p: Dictionary) -> Array:
	var out: Array = []
	if str(p["status"]) != "open":
		return out
	var since := int(p["made_tick"])
	var cas := Ledger.count({"tag": "casualty", "since": since})
	out.append("Judged when you return. Partners who have gone down since you promised: %d." % cas)
	out.append("Letter: everyone conscious at the Gate.  Spirit: nobody paid for it along the way.")
	return out

func _close() -> void:
	Audio.sfx("ui_back")
	queue_free()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()
