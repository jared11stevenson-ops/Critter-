class_name DialogueRunner
extends Node
## Runs CONTRACTS §8 dialogue JSON: who/expr/text, if/if_not, label/goto, choice (text/goto/set/trust/
## item/event/if), set, trust, item, event, end. Looks in game/narrative/dialogue/ first, then dialogue_stub/.
## One per scene. Pauses the tree while a conversation is open (UI runs with PROCESS_MODE_ALWAYS).

signal line_shown(line)          # Dictionary: who, expr, text, style ("normal"|"comms"|"narration"|"handler")
signal choices_shown(choices)    # Array of Dictionaries (filtered)
signal event_emitted(event_name)
signal started(dialogue_id)
signal finished(dialogue_id)

const DIRS := ["res://game/narrative/dialogue/", "res://game/narrative/dialogue_stub/"]

static var current: DialogueRunner = null

var active := false
var dialogue_id := ""
var _lines: Array = []
var _labels: Dictionary = {}
var _i := 0
var _queue: Array = []
var _waiting := ""   # "" | "advance" | "choice"
var _choices: Array = []
var _pause := true
var _was_paused := false
var box: Node = null
var _deferred_events: Array = []

func _enter_tree() -> void:
	current = self

func _exit_tree() -> void:
	if current == self:
		current = null
	if active and _pause:
		get_tree().paused = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 60
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	box = DialogueBox.new()
	layer.add_child(box)
	box.bind(self)
	_prewarm()

static var _warmed := false

## Fonts are dynamic (woff2): the first time a glyph is drawn it is rasterized, which shows up as a hitch on the
## first dialogue line. Draw every common glyph once, nearly invisible, for a few frames at load time, and queue the
## portraits for threaded loading so the first line does not block on disk.
func _prewarm() -> void:
	if _warmed:
		return
	_warmed = true
	var chars := ""
	for c in range(32, 127):
		chars += char(c)
	chars += "’‘“”—–…éèáíóúñüöä▼"
	var warm := CanvasLayer.new()
	warm.layer = 1
	add_child(warm)
	var y := 0.0
	for spec in [["dialogue", 28], ["dialogue_bold", 28], ["title", 36], ["ui", 26], ["bold", 20], ["bold", 30]]:
		var l := UiKit.label(chars, spec[1], Color.WHITE, spec[0])
		l.modulate.a = 0.004
		l.position = Vector2(0, y)
		y += 44.0
		warm.add_child(l)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.text = "[i]%s[/i]" % chars
	rt.modulate.a = 0.004
	rt.size = Vector2(1200, 80)
	rt.position = Vector2(0, y)
	var df := UiKit.font("dialogue")
	if df:
		rt.add_theme_font_override("italics_font", df)
		rt.add_theme_font_size_override("italics_font_size", 28)
	warm.add_child(rt)
	for id in Canon.data.get("characters", {}).keys():
		var pth := "res://game/art/portraits/%s/default.png" % id
		if ResourceLoader.exists(pth):
			ResourceLoader.load_threaded_request(pth)
	for _i in 4:
		await get_tree().process_frame
	warm.queue_free()

static func exists(id: String) -> bool:
	for d in DIRS:
		if FileAccess.file_exists(d + id + ".json") or ResourceLoader.exists(d + id + ".json"):
			return true
	return false

static func load_dialogue(id: String) -> Dictionary:
	for d in DIRS:
		var p: String = d + id + ".json"
		if FileAccess.file_exists(p):
			var f := FileAccess.open(p, FileAccess.READ)
			if f:
				var parsed: Variant = JSON.parse_string(f.get_as_text())
				if parsed is Dictionary:
					return parsed
				push_warning("Dialogue %s failed to parse" % p)
	return {}

## Start a dialogue. If one is running, it is queued. Returns false if the file is missing.
func play(id: String, pause: bool = true) -> bool:
	if active:
		if dialogue_id != id and not _queue.has(id):
			_queue.append([id, pause])
		return true
	var d := load_dialogue(id)
	if d.is_empty():
		push_warning("DialogueRunner: missing dialogue '%s'" % id)
		return false
	return play_data(id, d, pause)

## Run dialogue data directly (used for built-in fallbacks).
func play_data(id: String, d: Dictionary, pause: bool = true) -> bool:
	if active:
		return false
	dialogue_id = id
	sync_derived_flags()
	_lines = d.get("lines", [])
	_labels.clear()
	for i in _lines.size():
		var ln: Variant = _lines[i]
		if ln is Dictionary and ln.has("label"):
			_labels[str(ln["label"])] = i
	_i = 0
	active = true
	_pause = pause
	if pause:
		_was_paused = get_tree().paused
		get_tree().paused = true
	TouchInput.reset()
	started.emit(id)
	Events.dialogue_started.emit(id)
	_step()
	return true

## Flags the Lead's dialogue gates on that are derived from other state.
static func sync_derived_flags() -> void:
	var has_spec := not GameState.specimens.is_empty()
	if bool(GameState.get_flag("has_specimen", false)) != has_spec:
		GameState.set_flag("has_specimen", has_spec)

func is_running(id: String = "") -> bool:
	return active and (id == "" or id == dialogue_id)

func _gate_ok(ln: Dictionary) -> bool:
	if ln.has("if"):
		if not _flag_true(str(ln["if"])):
			return false
	if ln.has("if_not"):
		if _flag_true(str(ln["if_not"])):
			return false
	return true

func _flag_true(fl: String) -> bool:
	var v: Variant = GameState.get_flag(fl, false)
	if v is bool:
		return v
	if v is String:
		return v != ""
	if v is int or v is float:
		return v != 0
	return v != null

func _step() -> void:
	while _i < _lines.size():
		var ln: Variant = _lines[_i]
		_i += 1
		if not (ln is Dictionary):
			continue
		var d: Dictionary = ln
		if not _gate_ok(d):
			continue
		if d.has("label") and d.size() <= 3 and not d.has("text"):
			continue
		if d.has("set"):
			_apply_set(d["set"])
		if d.has("trust"):
			_apply_trust(d["trust"])
		if d.has("item"):
			_apply_item(d["item"])
		if d.has("event"):
			_emit_event(str(d["event"]))
		if d.has("end") and bool(d["end"]):
			_finish()
			return
		if d.has("goto"):
			_goto(str(d["goto"]))
			continue
		if d.has("choice"):
			var opts: Array = []
			for o in d["choice"]:
				if o is Dictionary and _gate_ok(o):
					opts.append(o)
			if opts.is_empty():
				continue
			_choices = opts
			_waiting = "choice"
			choices_shown.emit(opts)
			return
		if d.has("text"):
			var who := str(d.get("who", "narration"))
			var style := "normal"
			var speaker := who
			if who.begins_with("comms:"):
				style = "comms"
				speaker = who.substr(6)
			elif who == "narration":
				style = "narration"
			elif who == "handler":
				style = "handler"
			var out := {"who": speaker, "expr": str(d.get("expr", "default")), "text": str(d["text"]), "style": style}
			_waiting = "advance"
			line_shown.emit(out)
			return
	_finish()

func _goto(lbl: String) -> void:
	if _labels.has(lbl):
		_i = int(_labels[lbl]) + 1
	else:
		push_warning("Dialogue %s: missing label %s" % [dialogue_id, lbl])
		_i = _lines.size()

func advance() -> void:
	if _waiting != "advance":
		return
	_waiting = ""
	_step()

func choose(idx: int) -> void:
	if _waiting != "choice" or idx < 0 or idx >= _choices.size():
		return
	var o: Dictionary = _choices[idx]
	_waiting = ""
	Audio.sfx("ui_confirm")
	if o.has("set"):
		_apply_set(o["set"])
	if o.has("trust"):
		_apply_trust(o["trust"])
	if o.has("item"):
		_apply_item(o["item"])
	if o.has("event"):
		_emit_event(str(o["event"]))
	if o.has("goto"):
		_goto(str(o["goto"]))
	_step()

func _apply_set(s: Variant) -> void:
	if s is Dictionary:
		for k in s:
			GameState.set_flag(str(k), s[k])

func _apply_trust(t: Variant) -> void:
	if t is Dictionary:
		for k in t:
			GameState.add_trust(str(k), int(t[k]))
			Audio.sfx("trust_up" if int(t[k]) > 0 else "trust_down")

func _apply_item(t: Variant) -> void:
	if t is Dictionary:
		for k in t:
			var n := int(t[k])
			GameState.add_item(str(k), n)
			Events.toast.emit("%s%d %s" % ["+" if n > 0 else "", n, UiKit.item_name(str(k))], "item")

func _emit_event(ev: String) -> void:
	# Generic flag side effects so the slice works no matter which scene hears it.
	match ev:
		"briefing_done": GameState.set_flag("briefed", true)
		"unlock_combo":
			if not bool(GameState.get_flag("combo_unlocked", false)):
				GameState.set_flag("combo_unlocked", true)
				Events.toast.emit("Combo unlocked: PROBABLE IMPACT — Gravity Pull during Premonition", "codex")
	event_emitted.emit(ev)

func _finish() -> void:
	var id := dialogue_id
	active = false
	_waiting = ""
	dialogue_id = ""
	GameState.flags["_seen_" + id] = true
	if _pause:
		get_tree().paused = _was_paused if _queue.size() > 0 else false
	finished.emit(id)
	Events.dialogue_finished.emit(id)
	if _queue.size() > 0:
		var nx: Array = _queue.pop_front()
		play.call_deferred(nx[0], nx[1])

func skip_all() -> void:
	## QA helper: run to the end, auto-picking the first choice.
	var guard := 0
	while active and guard < 500:
		guard += 1
		if _waiting == "advance":
			advance()
		elif _waiting == "choice":
			choose(0)
		else:
			break

static func seen(id: String) -> bool:
	return bool(GameState.flags.get("_seen_" + id, false))
