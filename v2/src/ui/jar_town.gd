class_name JarTown extends Control
## THE JAR: one big glass jar where all eight species live side by side, each in its own district with its own five structures
## (data/career/habitats.json). Peaceful and visible: villagers haul the materials the player earned in fights and expeditions to the
## next plot and raise the structure themselves. The player only supplies, feeds, expands and collects (CREATOR_GDD s7-8, 14).
## A district is claimed once a living critter of that species is on the shelf. Neighbouring claimed districts trade (free passages).
## Generations / family trees are deliberately not shown (creator: on hold).

const Pal := preload("res://src/critters/palettes.gd")

signal closed
signal details_requested(species: String)

const DW := 480.0                                  # district width in world px
const TOP := 96.0
const GROUND := 520.0                              # y of the ground line on screen
const STYLE := {                                   # per-species look: roof kind + motif (the unique asset language of each critter)
	"aruun": {"roof": "slab", "motif": "rope"},
	"cigarra": {"roof": "dome", "motif": "hang"},
	"bramvex": {"roof": "gable", "motif": "thorn"},
	"scarlith": {"roof": "cap", "motif": "spore"},
	"mollusk": {"roof": "dome", "motif": "shell"},
	"zephyr": {"roof": "cone", "motif": "petal"},
	"nyxaris": {"roof": "spire", "motif": "ice"},
	"pharilux": {"roof": "gable", "motif": "lamp"},
}

var roster: RosterState
var sel := "aruun"
var _cam := 0.0
var _cam_t := 0.0
var _drag := false
var _drag_moved := 0.0
var _t := 0.0
var _claimed: Array = []
var _vill: Dictionary = {}                          # species -> Array of {x, tx, wait, bob}
var _job: Dictionary = {}                           # species -> {stage, t}
var _rise: Dictionary = {}                          # "species:k" -> seconds since built
var _last_mat: Dictionary = {}
var _last_struct: Dictionary = {}
var _crates: Array = []                             # falling supply crates {x, y, vy, species}
var _dust: Array = []
var _traders: Array = []                            # {from, to, t}
var _trade_cd := 2.0
var _info: Label
var _ticker: Label
var _scrap: Label
var _buttons: Dictionary = {}
var _tick_acc := 0.0


static func open(parent: Control, r: RosterState, species: String) -> JarTown:
	var j := JarTown.new()
	j.roster = r
	j.sel = species if Habitat.TOWN_ORDER.has(species) else "aruun"
	parent.add_child(j)
	return j


func _ready() -> void:
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_claimed = roster.unify_town()
	for sp in Habitat.TOWN_ORDER:
		var h := roster.habitat(sp)
		_last_mat[sp] = h.materials
		_last_struct[sp] = h.structures.size()
		for k in h.structures.size():
			_rise["%s:%d" % [sp, k]] = 99.0
		_vill[sp] = []
	var title := UiStyle.label("THE JAR", 44, UiStyle.GOLD, 10)
	title.position = Vector2(34, 16)
	add_child(title)
	_scrap = UiStyle.label("", 28, UiStyle.PAPER, 6)
	_scrap.position = Vector2(300, 28)
	add_child(_scrap)
	_info = UiStyle.label("", 22, UiStyle.PAPER, 5)
	_info.position = Vector2(34, GROUND + 70)
	add_child(_info)
	_ticker = UiStyle.label("", 19, UiStyle.TEAL_LT, 4)
	_ticker.position = Vector2(34, GROUND + 100)
	add_child(_ticker)
	var specs := [["<", "prev", 70, UiStyle.PAPER_DK], [">", "next", 70, UiStyle.PAPER_DK], ["SUPPLY", "supply", 150, UiStyle.TEAL], ["FEED", "feed", 120, UiStyle.GREEN],
		["EXPAND", "expand", 140, UiStyle.TEAL], ["COLLECT", "collect", 160, UiStyle.GOLD], ["DETAILS", "details", 140, UiStyle.PAPER_DK], ["BACK", "back", 120, UiStyle.RUST]]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.position = Vector2(34, GROUND + 126)
	add_child(row)
	for s in specs:
		var b := UiStyle.button(str(s[0]), 22, Vector2(float(s[2]), 58), s[3])
		b.pressed.connect(_on_button.bind(str(s[1])))
		row.add_child(b)
		_buttons[str(s[1])] = b
	_cam = _target_cam(sel)
	_cam_t = _cam
	_refresh_text()


func _target_cam(sp: String) -> float:
	var i := Habitat.TOWN_ORDER.find(sp)
	return clampf(float(i) * DW - (size.x - DW) * 0.5, 0.0, DW * 8.0 - size.x)


func _adults(sp: String) -> Array:
	return roster.retired_adults(sp)


func _pop(sp: String) -> int:
	return roster.habitat(sp).population(_adults(sp))


func _is_claimed(sp: String) -> bool:
	return _claimed.has(sp)


func _on_button(kind: String) -> void:
	var i := Habitat.TOWN_ORDER.find(sel)
	match kind:
		"prev":
			_select(Habitat.TOWN_ORDER[maxi(0, i - 1)])
		"next":
			_select(Habitat.TOWN_ORDER[mini(Habitat.TOWN_ORDER.size() - 1, i + 1)])
		"back":
			closed.emit()
			queue_free()
		"details":
			details_requested.emit(sel)
		"collect":
			var got := 0
			for sp in _claimed:
				got += roster.habitat(sp).tribute
				Career.habitat_action(sp, "collect")
			_ticker.text = "Collected %d scrap of tribute from the whole jar." % got if got > 0 else "No tribute waiting yet."
		_:
			if not _is_claimed(sel):
				_ticker.text = "Capture a %s to claim this district." % Career.species_name(sel)
			else:
				var res := Career.habitat_action(sel, kind)
				_ticker.text = res if res != "" else {"supply": "Supplies delivered.", "feed": "The family is fed.", "expand": "The district grew."}.get(kind, "")
	_refresh_text()


func _select(sp: String) -> void:
	sel = sp
	_cam_t = _target_cam(sp)
	_refresh_text()


func _refresh_text() -> void:
	_scrap.text = "Scrap %d    Tribute waiting %d" % [roster.economy.scrap, _tribute_total()]
	var h := roster.habitat(sel)
	var nm := Career.species_name(sel)
	if not _is_claimed(sel):
		_info.text = "%s district: UNCLAIMED. Capture a %s to move its people into the jar." % [nm, nm]
		return
	var nx := h.next_structure()
	var need := "all five structures stand" if nx.is_empty() else "next: %s  %d/%d materials, needs %d villagers" % [nx["name"], h.materials, h.build_cost(), int(nx["pop_req"])]
	_info.text = "%s  |  %s  |  villagers %d/%d  |  food %d  |  %s" % [nm, h.stage_name(_adults(sel).size()), _pop(sel), h.capacity(), h.food, need]
	if _ticker.text == "" and not h.log.is_empty():
		_ticker.text = str(h.log.back())


func _tribute_total() -> int:
	var n := 0
	for sp in _claimed:
		n += roster.habitat(sp).tribute
	return n


# ------------------------------------------------------------------ simulation
func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	_t += dt
	_cam = lerpf(_cam, _cam_t, 1.0 - exp(-8.0 * dt))
	_tick_acc += dt
	if _tick_acc > 3.0:
		_tick_acc = 0.0
		roster.tick_habitats()
		_refresh_text()
	for sp in _claimed:
		_sim_district(sp, dt)
	for k in _rise.keys():
		_rise[k] = float(_rise[k]) + dt
	for c in _crates:
		c["vy"] += 900.0 * dt
		c["y"] += c["vy"] * dt
	_crates = _crates.filter(func(c): return c["y"] < GROUND - 12.0)
	for d in _dust:
		d["t"] += dt
		d["pos"] += d["vel"] * dt
	_dust = _dust.filter(func(d): return d["t"] < 0.8)
	_trade_cd -= dt
	if _trade_cd <= 0.0 and _claimed.size() > 1:
		_trade_cd = randf_range(3.0, 6.0)
		var a: String = _claimed[randi() % _claimed.size()]
		var i := Habitat.TOWN_ORDER.find(a)
		var opts: Array = []
		for j in [i - 1, i + 1]:
			if j >= 0 and j < 8 and _claimed.has(Habitat.TOWN_ORDER[j]):
				opts.append(Habitat.TOWN_ORDER[j])
		if not opts.is_empty():
			_traders.append({"from": a, "to": opts[randi() % opts.size()], "t": 0.0})
	for tr in _traders:
		tr["t"] += dt / 7.0
	_traders = _traders.filter(func(tr): return tr["t"] < 1.0)
	queue_redraw()


func _plot_x(sp: String, k: int) -> float:
	return float(Habitat.TOWN_ORDER.find(sp)) * DW + 84.0 + float(k) * 84.0


func _stock_x(sp: String) -> float:
	return float(Habitat.TOWN_ORDER.find(sp)) * DW + 36.0


func _sim_district(sp: String, dt: float) -> void:
	var h := roster.habitat(sp)
	# supplies delivered since last frame: drop crates onto the stockpile
	if h.materials > int(_last_mat[sp]):
		for i in mini(6, (h.materials - int(_last_mat[sp])) / 2 + 1):
			_crates.append({"x": _stock_x(sp) + randf_range(-6.0, 22.0), "y": TOP - float(i) * 40.0, "vy": 0.0, "species": sp})
	_last_mat[sp] = h.materials
	if h.structures.size() > int(_last_struct[sp]):
		_rise["%s:%d" % [sp, h.structures.size() - 1]] = 0.0
	_last_struct[sp] = h.structures.size()
	# villagers
	var n := mini(_pop(sp), 5)
	var vs: Array = _vill[sp]
	while vs.size() < n:
		var x := _stock_x(sp) + randf_range(40.0, DW - 80.0)
		vs.append({"x": x, "tx": x, "wait": randf_range(0.2, 2.0), "bob": randf() * 6.0})
	while vs.size() > n:
		vs.pop_back()
	var job: Dictionary = _job.get(sp, {})
	var adults := _adults(sp)
	if job.is_empty():
		if h.can_build(adults) and n > 0:
			job = {"stage": "fetch", "t": 0.0}
			_job[sp] = job
	else:
		job["t"] += dt
		var k := h.structures.size()
		match str(job["stage"]):
			"fetch":
				if job["t"] > 1.7:
					job["stage"] = "carry"
					job["t"] = 0.0
			"carry":
				if job["t"] > 1.9:
					job["stage"] = "build"
					job["t"] = 0.0
			"build":
				if int(job["t"] * 10.0) % 3 == 0 and randf() < 0.5:
					_dust.append({"pos": Vector2(_plot_x(sp, k) + randf_range(-20.0, 20.0), GROUND - 4.0), "vel": Vector2(randf_range(-30.0, 30.0), randf_range(-50.0, -15.0)), "t": 0.0})
				if job["t"] > 4.2:
					Career.habitat_action(sp, "build")
					_job.erase(sp)
					_ticker.text = str(h.log.back()) if not h.log.is_empty() else ""
					_refresh_text()
	for v in vs:
		var jstage := str(job.get("stage", ""))
		match jstage:
			"fetch":
				v["tx"] = _stock_x(sp) + 40.0 + float(vs.find(v)) * 14.0
			"carry":
				v["tx"] = _plot_x(sp, h.structures.size()) - 30.0 + float(vs.find(v)) * 14.0
			"build":
				v["tx"] = _plot_x(sp, h.structures.size()) - 30.0 + float(vs.find(v)) * 14.0
			_:
				v["wait"] -= dt
				if v["wait"] <= 0.0:
					v["wait"] = randf_range(1.5, 4.5)
					v["tx"] = float(Habitat.TOWN_ORDER.find(sp)) * DW + randf_range(70.0, DW - 50.0)
		var d: float = float(v["tx"]) - float(v["x"])
		v["x"] += clampf(d, -1.0, 1.0) * minf(absf(d), 70.0 * dt * (1.7 if jstage != "" else 1.0))
		v["bob"] += dt * (9.0 if absf(d) > 3.0 else 2.0)


# ------------------------------------------------------------------ input
func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_drag = (ev as InputEventMouseButton).pressed
		if _drag:
			_drag_moved = 0.0
		elif _drag_moved < 12.0:
			_tap((ev as InputEventMouseButton).position)
	elif ev is InputEventMouseMotion and _drag:
		var m := ev as InputEventMouseMotion
		_drag_moved += absf(m.relative.x)
		_cam_t = clampf(_cam_t - m.relative.x, 0.0, DW * 8.0 - size.x)
		_cam = _cam_t
	elif ev is InputEventScreenDrag:
		_cam_t = clampf(_cam_t - (ev as InputEventScreenDrag).relative.x, 0.0, DW * 8.0 - size.x)
		_cam = _cam_t


func _tap(p: Vector2) -> void:
	var wx := p.x + _cam
	var i := clampi(int(wx / DW), 0, 7)
	var sp: String = Habitat.TOWN_ORDER[i]
	if sp != sel:
		sel = sp
		_refresh_text()
	var h := roster.habitat(sp)
	if _is_claimed(sp):
		for k in h.structures.size():
			if absf(wx - _plot_x(sp, k)) < 34.0:
				var st: Dictionary = Habitat.ladder(sp)[h.structures[k]]
				_ticker.text = "%s: %s" % [st["name"], {"housing": "homes for %d more villagers" % int(st["amount"]), "food": "+%d food a day" % int(st["amount"]),
					"tribute": "+%d scrap tribute a day" % int(st["amount"]), "monument": "the district's monument: pride, and festivals"}.get(str(st["effect"]), "")]
				break


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	var w := size.x
	draw_rect(Rect2(0, 0, w, size.y), Color(0.07, 0.07, 0.09))
	var jar := Rect2(18, TOP - 10, w - 36, GROUND - TOP + 52)
	_draw_world(jar)
	draw_rect(jar, Color(0.95, 0.98, 1.0, 0.8), false, 5.0)                                  # glass
	draw_rect(Rect2(jar.position.x + 10, jar.position.y + 10, 12, jar.size.y - 24), Color(1, 1, 1, 0.14))
	draw_rect(Rect2(jar.position.x - 6, TOP - 38, jar.size.x + 12, 26), UiStyle.PAPER_DK)  # lid
	draw_rect(Rect2(jar.position.x - 6, TOP - 38, jar.size.x + 12, 26), UiStyle.INK, false, 4.0)


func _draw_world(jar: Rect2) -> void:
	var font := UiStyle.font()
	# sky: soft gradient bands, tinted by the selected district's palette
	var tint: Color = Pal.get_pal(sel)["main"]
	for b in 12:
		var f := float(b) / 11.0
		draw_rect(Rect2(jar.position.x, jar.position.y + jar.size.y * float(b) / 12.0, jar.size.x, jar.size.y / 12.0 + 1.0), Color(0.30, 0.42, 0.52).lerp(tint.darkened(0.2), 0.18).lerp(Color(0.80, 0.84, 0.70), f * 0.75))
	for i in 8:
		var sp: String = Habitat.TOWN_ORDER[i]
		var x0 := float(i) * DW - _cam
		if x0 > size.x + 10.0 or x0 + DW < -10.0:
			continue
		_draw_district(sp, x0, font)
	# soil strip (covers district bases)
	draw_rect(Rect2(jar.position.x, GROUND, jar.size.x, jar.end.y - GROUND), Color(0.36, 0.25, 0.18))
	draw_rect(Rect2(jar.position.x, GROUND, jar.size.x, 7), Color(0.45, 0.34, 0.22))
	for tr in _traders:
		_draw_trader(tr)
	for c in _crates:
		var cx: float = float(c["x"]) - _cam
		draw_rect(Rect2(cx - 8, float(c["y"]) - 8, 16, 14), Color(0.66, 0.46, 0.24))
		draw_rect(Rect2(cx - 8, float(c["y"]) - 8, 16, 14), UiStyle.INK, false, 2.0)
	for d in _dust:
		var a := 1.0 - float(d["t"]) / 0.8
		draw_circle(Vector2(float(d["pos"].x) - _cam, d["pos"].y), 4.0 + 5.0 * (1.0 - a), Color(0.85, 0.78, 0.65, a * 0.7))


func _draw_district(sp: String, x0: float, font: Font) -> void:
	var h := roster.habitat(sp)
	var claimed := _is_claimed(sp)
	var pal: Dictionary = Pal.get_pal(sp)
	var main: Color = pal["main"]
	var selected := sp == sel
	if selected:
		draw_rect(Rect2(x0 + 4, TOP + 14, DW - 8, GROUND - TOP - 14), Color(1, 1, 1, 0.05))
	# rolling hills behind
	var hill := PackedVector2Array([Vector2(x0, GROUND), Vector2(x0, GROUND - 90), Vector2(x0 + DW * 0.3, GROUND - 130), Vector2(x0 + DW * 0.65, GROUND - 100), Vector2(x0 + DW, GROUND - 120), Vector2(x0 + DW, GROUND)])
	draw_colored_polygon(hill, main.darkened(0.45).lerp(Color(0.22, 0.34, 0.24), 0.55) if claimed else Color(0.2, 0.22, 0.24))
	for g in 14:
		var gx := x0 + 14.0 + float(g) * 31.0
		draw_line(Vector2(gx, GROUND), Vector2(gx - 3, GROUND - 9), Color(0.4, 0.6, 0.3), 2.0)
		draw_line(Vector2(gx, GROUND), Vector2(gx + 4, GROUND - 7), Color(0.35, 0.55, 0.28), 2.0)
	# district banner
	var tex := Portraits.tex(sp)
	var bx := x0 + 14.0
	if tex != null:
		draw_texture_rect(tex, Rect2(bx, TOP + 18, 54, 54), false, Color(1, 1, 1, 1.0 if claimed else 0.3))
	draw_string(font, Vector2(bx + 62, TOP + 44), Career.species_name(sp).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UiStyle.PAPER if claimed else UiStyle.PAPER_DK)
	if not claimed:
		draw_string(font, Vector2(bx + 62, TOP + 68), "unclaimed: capture one", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiStyle.PAPER_DK)
		for k in 5:
			var px := x0 + 84.0 + float(k) * 84.0
			draw_rect(Rect2(px - 22, GROUND - 6, 44, 6), Color(0.2, 0.2, 0.22))
		return
	# stockpile of materials
	var crates := mini(h.materials / 3, 12)
	for c in crates:
		var cx := x0 + 20.0 + float(c % 3) * 18.0
		var cy := GROUND - 14.0 - float(c / 3) * 14.0
		draw_rect(Rect2(cx, cy, 16, 13), Color(0.66, 0.46, 0.24))
		draw_rect(Rect2(cx, cy, 16, 13), UiStyle.INK, false, 2.0)
	# structures, then the plot being built
	var ladder := Habitat.ladder(sp)
	for k in 5:
		var px := x0 + 84.0 + float(k) * 84.0
		draw_rect(Rect2(px - 28, GROUND - 5, 56, 5), Color(0.5, 0.42, 0.3))
		if k < h.structures.size():
			var st: Dictionary = ladder[h.structures[k]]
			var age: float = float(_rise.get("%s:%d" % [sp, k], 99.0))
			var s := _ease_back(clampf(age / 1.3, 0.0, 1.0))
			_draw_structure(sp, str(st["effect"]), k, px, s, main, pal)
			if selected:
				draw_string(font, Vector2(px - 32, GROUND + 18), str(st["name"]), HORIZONTAL_ALIGNMENT_CENTER, 64, 12, UiStyle.PAPER)
		elif k == h.structures.size():
			var nx := h.next_structure()
			var job: Dictionary = _job.get(sp, {})
			var prog := float(job.get("t", 0.0)) / 4.2 if str(job.get("stage", "")) == "build" else 0.0
			_draw_scaffold(px, prog, h.can_build(_adults(sp)))
			if not nx.is_empty() and selected:
				draw_string(font, Vector2(px - 32, GROUND + 18), "%d/%d" % [h.materials, h.build_cost()], HORIZONTAL_ALIGNMENT_CENTER, 64, 13, UiStyle.GOLD)
	# overseer (the species' own critter) and villagers
	if tex != null:
		for c in roster.rack.living():
			if c.species == sp:
				draw_texture_rect(tex, Rect2(x0 + DW - 84, GROUND - 82, 74, 74), false)
				draw_string(font, Vector2(x0 + DW - 92, GROUND - 86), c.name, HORIZONTAL_ALIGNMENT_CENTER, 90, 14, UiStyle.GOLD)
				break
	var job2: Dictionary = _job.get(sp, {})
	var carrying := str(job2.get("stage", "")) == "carry"
	for v in _vill[sp]:
		var vx: float = float(v["x"]) - _cam
		var vy := GROUND - 4.0 - absf(sin(float(v["bob"]))) * 5.0
		draw_circle(Vector2(vx, GROUND - 2.0), 11.0, Color(0, 0, 0, 0.3))
		if tex != null:
			draw_texture_rect(tex, Rect2(vx - 22, vy - 44, 44, 44), false)
		else:
			draw_circle(Vector2(vx, vy - 14), 12.0, main)
		if carrying:
			draw_rect(Rect2(vx - 8, vy - 62, 16, 14), Color(0.66, 0.46, 0.24))
			draw_rect(Rect2(vx - 8, vy - 62, 16, 14), UiStyle.INK, false, 2.0)
		if str(job2.get("stage", "")) == "build":
			var sw := sin(_t * 14.0 + float(v["bob"]))
			draw_line(Vector2(vx + 12, vy - 20), Vector2(vx + 22, vy - 30 + sw * 8.0), Color(0.5, 0.35, 0.2), 3.0)
	if _pop(sp) == 0:
		draw_string(font, Vector2(x0 + 90, GROUND - 100), "Retire a %s to settle villagers" % Career.species_name(sp), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiStyle.GOLD)
	# link bridge to the right neighbour
	var i := Habitat.TOWN_ORDER.find(sp)
	if h.links.has(Habitat.TOWN_ORDER[mini(i + 1, 7)]) and i < 7:
		draw_rect(Rect2(x0 + DW - 44, GROUND - 16, 88, 6), Color(0.55, 0.4, 0.25))
		draw_rect(Rect2(x0 + DW - 44, GROUND - 16, 88, 6), UiStyle.INK, false, 2.0)
	if h.tribute > 0:
		draw_circle(Vector2(x0 + DW - 24, TOP + 36), 13.0, UiStyle.GOLD)
		draw_string(font, Vector2(x0 + DW - 40, TOP + 42), str(h.tribute), HORIZONTAL_ALIGNMENT_CENTER, 32, 13, UiStyle.INK)


func _ease_back(t: float) -> float:
	var c := 1.70158
	return 1.0 + (c + 1.0) * pow(t - 1.0, 3.0) + c * pow(t - 1.0, 2.0)


func _draw_scaffold(px: float, prog: float, ready: bool) -> void:
	draw_set_transform(Vector2(px - _cam, GROUND - 5.0), 0.0, Vector2(1.6, 1.6))
	var col := Color(0.62, 0.5, 0.32, 0.9 if ready else 0.45)
	draw_line(Vector2(-22, 0), Vector2(-22, -48), col, 3.0)
	draw_line(Vector2(22, 0), Vector2(22, -48), col, 3.0)
	draw_line(Vector2(-22, -24), Vector2(22, -24), col, 3.0)
	draw_line(Vector2(-22, -48), Vector2(22, -48), col, 3.0)
	if prog > 0.0:
		draw_rect(Rect2(-22, -46.0 * prog, 44, 46.0 * prog), Color(0.72, 0.62, 0.44, 0.75))
		draw_rect(Rect2(-22, -62, 44, 7), Color(0.1, 0.1, 0.1, 0.8))
		draw_rect(Rect2(-22, -62, 44.0 * prog, 7), UiStyle.GOLD)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_trader(tr: Dictionary) -> void:
	var a := float(Habitat.TOWN_ORDER.find(str(tr["from"]))) * DW + DW * 0.5
	var b := float(Habitat.TOWN_ORDER.find(str(tr["to"]))) * DW + DW * 0.5
	var f := float(tr["t"])
	var go := f * 2.0 if f < 0.5 else (1.0 - f) * 2.0
	var x := lerpf(a, b, go) - _cam
	var tex := Portraits.tex(str(tr["from"]))
	var y := GROUND - 4.0 - absf(sin(f * 60.0)) * 5.0
	if tex != null:
		draw_texture_rect(tex, Rect2(x - 15, y - 30, 30, 30), false)
	if f < 0.5:
		draw_rect(Rect2(x - 6, y - 42, 12, 10), UiStyle.GOLD)


## One structure: the base shape comes from what it does (home / food / tribute / monument), the roof and decoration from the species.
func _draw_structure(sp: String, effect: String, k: int, px: float, s: float, main: Color, pal: Dictionary) -> void:
	var style: Dictionary = STYLE.get(sp, {"roof": "gable", "motif": "rope"})
	var x := px - _cam
	var sc := (0.92 + 0.07 * float(k)) * 1.55
	draw_set_transform(Vector2(x, GROUND - 5.0), 0.0, Vector2(sc, sc * maxf(s, 0.02)))
	var wall := main.lerp(Color(0.5, 0.4, 0.3), 0.45)
	var roof: Color = (pal.get("accent", UiStyle.RUST) as Color).darkened(0.1)
	var glow: Color = pal.get("glow", UiStyle.GOLD)
	match effect:
		"housing":
			draw_rect(Rect2(-22, -36, 44, 36), wall)
			draw_rect(Rect2(-22, -36, 44, 36), UiStyle.INK, false, 3.0)
			draw_rect(Rect2(-6, -22, 12, 22), Color(0.12, 0.09, 0.08))
			_roof(str(style["roof"]), roof)
		"food":
			for b in 3:
				var bx := -16.0 + float(b) * 16.0
				draw_circle(Vector2(bx, -12), 11.0, wall.lightened(0.1))
				draw_arc(Vector2(bx, -12), 11.0, 0.0, TAU, 14, UiStyle.INK, 2.0)
			draw_rect(Rect2(-26, -4, 52, 6), Color(0.4, 0.3, 0.2))
			draw_circle(Vector2(0, -30), 9.0, glow.darkened(0.2))
		"tribute":
			draw_line(Vector2(-22, 0), Vector2(-22, -40), Color(0.4, 0.3, 0.2), 4.0)
			draw_line(Vector2(22, 0), Vector2(22, -40), Color(0.4, 0.3, 0.2), 4.0)
			for st in 4:
				draw_rect(Rect2(-24.0 + float(st) * 12.0, -48, 12, 14), roof if st % 2 == 0 else UiStyle.PAPER)
			draw_circle(Vector2(0, -16), 8.0, UiStyle.GOLD)
			draw_arc(Vector2(0, -16), 8.0, 0.0, TAU, 12, UiStyle.INK, 2.0)
		_:
			var tw := PackedVector2Array([Vector2(-18, 0), Vector2(18, 0), Vector2(11, -78), Vector2(-11, -78)])
			draw_colored_polygon(tw, wall.lightened(0.05))
			draw_polyline(PackedVector2Array([Vector2(-18, 0), Vector2(-11, -78), Vector2(11, -78), Vector2(18, 0)]), UiStyle.INK, 3.0)
			draw_circle(Vector2(0, -86), 8.0 + sin(_t * 3.0) * 1.5, glow)
	_motif(str(style["motif"]), effect, glow, wall)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _roof(kind: String, col: Color) -> void:
	var pts: PackedVector2Array
	match kind:
		"dome":
			draw_arc(Vector2(0, -36), 26.0, PI, TAU, 16, col, 12.0)
			return
		"cap":
			pts = PackedVector2Array([Vector2(-30, -34), Vector2(-20, -52), Vector2(20, -52), Vector2(30, -34)])
		"cone":
			pts = PackedVector2Array([Vector2(-28, -34), Vector2(0, -66), Vector2(28, -34)])
		"spire":
			pts = PackedVector2Array([Vector2(-26, -36), Vector2(0, -78), Vector2(26, -36)])
		"slab":
			pts = PackedVector2Array([Vector2(-28, -36), Vector2(-28, -46), Vector2(28, -46), Vector2(28, -36)])
		_:
			pts = PackedVector2Array([Vector2(-28, -34), Vector2(0, -60), Vector2(28, -34)])
	draw_colored_polygon(pts, col)
	var ol := pts.duplicate()
	ol.append(pts[0])
	draw_polyline(ol, UiStyle.INK, 3.0)


## The species' decoration language, drawn on every structure of that district so each critter's town reads as its own.
func _motif(kind: String, effect: String, glow: Color, wall: Color) -> void:
	match kind:
		"rope":
			draw_line(Vector2(-26, -14), Vector2(26, -22), Color(0.8, 0.7, 0.45), 2.0)
			draw_line(Vector2(-26, -8), Vector2(26, -14), Color(0.8, 0.7, 0.45), 2.0)
		"hang":
			for i in 3:
				var hx := -16.0 + float(i) * 16.0
				draw_line(Vector2(hx, -34), Vector2(hx, -22), Color(0.4, 0.55, 0.3), 2.0)
				draw_circle(Vector2(hx, -19.0 + sin(_t * 2.0 + float(i)) * 2.0), 4.0, glow)
		"thorn":
			for i in 6:
				var tx := -24.0 + float(i) * 9.6
				draw_colored_polygon(PackedVector2Array([Vector2(tx - 3, 0), Vector2(tx + 3, 0), Vector2(tx, -12)]), Color(0.22, 0.14, 0.1))
		"spore":
			for i in 3:
				var sx := -18.0 + float(i) * 18.0
				draw_circle(Vector2(sx, -4), 7.0, glow.darkened(0.1))
				draw_rect(Rect2(sx - 2, -2, 4, 6), wall.lightened(0.3))
		"shell":
			draw_arc(Vector2(18, -10), 8.0, 0.0, TAU * 0.9, 14, UiStyle.PAPER, 3.0)
			draw_arc(Vector2(18, -10), 4.0, 0.0, TAU * 0.9, 10, UiStyle.PAPER, 2.0)
		"petal":
			for i in 5:
				var a := float(i) / 5.0 * TAU + _t * 0.4
				draw_circle(Vector2(0, -16) + Vector2(cos(a), sin(a)) * 13.0, 4.0, glow.lightened(0.2))
		"ice":
			for i in 3:
				var ix := -16.0 + float(i) * 16.0
				draw_colored_polygon(PackedVector2Array([Vector2(ix - 5, 0), Vector2(ix + 5, 0), Vector2(ix, -16 - float(i % 2) * 8.0)]), Color(0.7, 0.9, 1.0, 0.8))
		"lamp":
			draw_line(Vector2(-26, -38), Vector2(-26, -20), Color(0.35, 0.3, 0.3), 2.0)
			draw_circle(Vector2(-26, -17), 6.0 + sin(_t * 4.0) * 1.0, glow)


# ------------------------------------------------------------------ QA helper (screenshots)
## Builds a thriving demo jar for screenshots: --screen=shelf --panel=town
static func demo_state(r: RosterState) -> void:
	var skipped := false
	for c in r.rack.living():
		if c.species == "aruun" and not skipped:
			skipped = true
			continue
		c.retired = true
	for sp in Habitat.TOWN_ORDER:
		var h := r.habitat(sp)
		h.materials = 18 if sp != "aruun" else 14
		for i in 20:
			h.step_day(r.retired_adults(sp))
