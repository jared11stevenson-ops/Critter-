class_name GearScreen
extends Control
## Gear / loadout screen: pick a character, see their three slots (weapon, charm, garment), tap an owned item to equip it,
## tap the equipped one to remove it. Stats are applied through Gear.modify (see game/core/gear.gd) the next time that
## character is spawned. Characters other than Aruun and Cigarra are not playable yet, so their gear is stored and shown
## but only the global.* stats apply today.

var _chars: VBoxContainer
var _page: VBoxContainer
var _sel := "aruun"

func _ready() -> void:
	Quality.set_covered(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.04, 0.95)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	var vb := VBoxContainer.new()
	margin.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var title := UiKit.label("GEAR", 44, UiKit.PARCHMENT, "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := UiKit.button("Close", Vector2(180, 80))
	close.name = "Close"
	close.pressed.connect(_close)
	top.add_child(close)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	vb.add_child(body)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(280, 0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	_chars = VBoxContainer.new()
	_chars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_chars)
	var page := PanelContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.98), UiKit.PARCHMENT_DARK.darkened(0.35), 18, 4, 22))
	body.add_child(page)
	var psc := ScrollContainer.new()
	psc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(psc)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", 8)
	psc.add_child(_page)
	var chars := _character_list()
	if not chars.has(_sel):
		_sel = chars[0]
	for c in chars:
		var b := UiKit.button(Canon.display_name(c), Vector2(0, 64), 26)
		b.name = "Char_" + c
		b.pressed.connect(_select.bind(c))
		_chars.add_child(b)
	_show()

func _exit_tree() -> void:
	Quality.set_covered(false)

func _character_list() -> Array:
	var out: Array = ["aruun", "cigarra"]
	for c in Gear.characters_with_gear():
		if not out.has(c):
			out.append(c)
	return out

func _select(c: String) -> void:
	_sel = c
	Audio.sfx("ui_tap", -6.0)
	_show()

func _show() -> void:
	for c in _page.get_children():
		c.queue_free()
	_page.add_child(UiKit.label(Canon.display_name(_sel), 38, UiKit.INK, "title"))
	var note := ""
	if _sel != "aruun" and _sel != "cigarra":
		note = "Not in the field party yet: only party-wide (global) stats apply."
	if note != "":
		var n := UiKit.label(note, 20, UiKit.MUTED, "ui")
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_page.add_child(n)
	var own: Array = Gear.owned_for(_sel)
	if own.is_empty():
		var l := UiKit.label("No gear yet. Gear comes from act rewards, side quests, secrets and loot in the field.", 24, UiKit.INK, "dialogue")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_page.add_child(l)
		return
	for slot in Gear.slots():
		_page.add_child(UiKit.label(str(slot).to_upper(), 22, UiKit.ACCENT, "bold"))
		var any := false
		for it in own:
			if str(it["slot"]) != slot:
				continue
			any = true
			var on: bool = Gear.equipped(_sel, slot) == str(it["id"])
			var row := Button.new()
			row.name = "Item_" + str(it["id"])
			row.custom_minimum_size = Vector2(0, 92)
			row.alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_theme_font_size_override("font_size", 22)
			row.text = "%s%s  [%s]\n%s" % ["EQUIPPED  " if on else "", it["name"], it.get("rarity", ""), Gear.describe(it)]
			row.tooltip_text = str(it.get("lore_reason", ""))
			row.pressed.connect(_toggle.bind(str(it["id"]), on))
			_page.add_child(row)
			var lore := UiKit.label(str(it.get("lore_reason", "")), 18, UiKit.MUTED, "dialogue")
			lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_page.add_child(lore)
		if not any:
			_page.add_child(UiKit.label("(none)", 20, UiKit.MUTED, "ui"))

func _toggle(id: String, on: bool) -> void:
	Audio.sfx("ui_confirm")
	var it := Gear.item(id)
	if on:
		Gear.unequip(_sel, str(it["slot"]))
	else:
		Gear.equip(id)
	_show()

func _close() -> void:
	Audio.sfx("ui_back")
	queue_free()
