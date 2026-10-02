class_name Scanner
extends Node
## Handler Scan (GDD §6): 0.4 s slow-mo pulse; classification labels over every organism/object
## within 25 m: WILDLIFE · SAPIENT · SACRED · RESOURCE · DOMINION ASSET · STRUCTURE.
## First scan of a species unlocks its Codex entry and notifies the level (hints).

const COLORS := {
	"WILDLIFE": Color("#8fd16a"), "SAPIENT": Color("#59d2e6"), "SACRED": Color("#f0c75a"),
	"RESOURCE": Color("#6fe0c0"), "DOMINION ASSET": Color("#ff5a45"), "STRUCTURE": Color("#e9dcc0"),
}
const POOL := 24

var _labels: Array = []
var _targets: Array = []     # Node3D or Vector3 per label
var _offsets: Array = []
var _t := 0.0
var _cd := 0.0
var _highlighted: Array = []

func _ready() -> void:
	for i in POOL:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.fixed_size = true
		l.pixel_size = 0.0009
		l.font_size = 30
		l.outline_size = 10
		l.outline_modulate = Color(0.05, 0.04, 0.04, 0.95)
		l.render_priority = 20
		l.outline_render_priority = 19
		l.visible = false
		var f := UiKit.font("bold")
		if f:
			l.font = f
		add_child(l)
		_labels.append(l)
		_targets.append(null)
		_offsets.append(Vector3.ZERO)

func scan(from: Node3D) -> void:
	if _cd > 0.0 or Field.current == null:
		return
	_cd = 0.8
	var f := Field.current
	var radius := Balance.f("global.scan_radius", 25.0)
	f.request_time_scale("scan", Balance.f("global.scan_slowmo_scale", 0.3), Balance.f("global.scan_slowmo_time", 0.4))
	f.vfx("scan_ping", from.global_position + Vector3(0, 0.3, 0), {"radius": radius})
	Audio.sfx("scan")
	Events.scan_started.emit()
	_clear()
	var n := 0
	var origin := from.global_position
	var first_species: Array = []
	for e in f.enemies:
		if n >= POOL:
			break
		if not is_instance_valid(e) or not e.alive or e is VentWeakpoint:
			continue
		if e.global_position.distance_to(origin) > radius:
			continue
		var sp: String = e.species_id
		var info := Canon.species(sp)
		var tag: String = info.get("class", "DOMINION ASSET" if e.team == "enemy" and not e.wild else "WILDLIFE")
		if e is ResonancePylon:
			tag = "DOMINION ASSET"
		var line2 := ""
		if e is PlateBeetle:
			line2 = "agitated by pylons" if e.agitated else "calm"
		elif e is DustGrazer:
			line2 = "keystone · do not harm"
		elif e.wild:
			line2 = "containable <30%"
		elif tag == "DOMINION ASSET":
			line2 = "cannot be contained"
		_show(n, e, Vector3(0, e.height + 0.9, 0), tag, e.display_name, line2)
		n += 1
		e.vis("set_highlight", COLORS.get(tag, Color.WHITE), true)
		_highlighted.append(e)
		if sp != "" and Canon.species(sp).size() > 0:
			if GameState.unlock_codex("species_" + sp):
				first_species.append(sp)
	for m in f.party_members:
		if n >= POOL:
			break
		_show(n, m, Vector3(0, m.height + 0.9, 0), "SAPIENT", m.display_name, "partner · trust %d" % GameState.get_trust(m.char_id))
		n += 1
	if f.level and f.level.has_method("get_scannables"):
		for s in f.level.get_scannables():
			if n >= POOL:
				break
			var p: Vector3 = s["pos"]
			if p.distance_to(origin) > radius:
				continue
			_show(n, p, Vector3(0, float(s.get("h", 2.5)), 0), s["tag"], s["name"], s.get("line2", ""))
			n += 1
			if s.has("codex"):
				GameState.unlock_codex(s["codex"])
			if f.level.has_method("on_scanned_object"):
				f.level.on_scanned_object(s.get("id", ""))
	_t = Balance.f("global.scan_label_time", 5.5)
	if f.level and f.level.has_method("on_scan"):
		f.level.on_scan(first_species)
	Events.scan_finished.emit()

func _show(i: int, target: Variant, off: Vector3, tag: String, nm: String, line2: String) -> void:
	var l: Label3D = _labels[i]
	l.text = "%s\n%s%s" % [tag, nm, ("\n" + line2) if line2 != "" else ""]
	l.modulate = COLORS.get(tag, Color.WHITE)
	l.visible = true
	l.scale = Vector3.ONE * 0.3
	var tw := l.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(l, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_targets[i] = target
	_offsets[i] = off
	_place(i)

func _place(i: int) -> void:
	var t: Variant = _targets[i]
	var l: Label3D = _labels[i]
	if typeof(t) == TYPE_OBJECT and not is_instance_valid(t):
		l.visible = false
		_targets[i] = null
		return
	if t is Vector3:
		l.global_position = (t as Vector3) + _offsets[i]
	elif t is Node3D and is_instance_valid(t):
		l.global_position = (t as Node3D).global_position + _offsets[i]
	else:
		l.visible = false

func _process(delta: float) -> void:
	_cd = maxf(0.0, _cd - delta)
	if _t <= 0.0:
		return
	_t -= delta
	for i in POOL:
		if _labels[i].visible:
			_place(i)
	if _t <= 0.0:
		_clear()

func _clear() -> void:
	for l in _labels:
		l.visible = false
	for i in POOL:
		_targets[i] = null
	for e in _highlighted:
		if is_instance_valid(e) and e.alive:
			e.vis("set_highlight", Color.WHITE, false)
	_highlighted.clear()
