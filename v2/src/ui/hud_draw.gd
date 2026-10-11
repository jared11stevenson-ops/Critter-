class_name HudDraw extends Control
## The bout HUD in one custom-drawn Control: sticker panels with Vitality / Stamina / resource bars, poise rings and the
## lock-on bracket projected onto the fighters, the enemy tell indicator, floating combat text and the big banners.
## Read-only: everything comes from the BoutScene's sim snapshot; nothing here decides gameplay.

const RESOURCES := {
	"aruun": {"label": "RAGE", "key": "rage", "max": "rage_max", "color": Color(0.95, 0.45, 0.2)},
	"cigarra": {"label": "FUTURE-NOISE", "key": "pressure", "max": "pressure_max", "color": Color(0.7, 0.55, 0.95)},
	"bramvex": {"label": "INSIGHT", "key": "intel", "max_const": 1.0, "color": Color(0.55, 0.85, 0.45)},
	"scarlith": {"label": "BREW", "key": "pressure", "max": "pressure_max", "color": Color(0.9, 0.35, 0.45)},
	"mollusk": {"label": "BORROWED", "key": "debt", "max_const": 60.0, "color": Color(0.5, 0.8, 0.85)},
	"nyxaris": {"label": "SILK", "key": "reserve", "max": "reserve_max", "color": Color(0.7, 0.9, 1.0)},
}
const STATUS_COL := {"burn": Color(1.0, 0.5, 0.2), "root": Color(0.6, 0.8, 0.4), "slow": Color(0.5, 0.7, 1.0), "winded": Color(1.0, 0.85, 0.3),
	"last_stand": Color(1.0, 0.35, 0.3), "haste": Color(0.9, 1.0, 0.5), "camo": Color(0.6, 0.7, 0.6)}

var bout: BoutScene
var trail: Array[float] = [1.0, 1.0]
var pops: Array = []
var banner := ""
var banner_sub := ""
var banner_t := 0.0
var banner_life := 1.0
var _t := 0.0
var _ink: Ink
var _ink_b: Ink

func setup(b: BoutScene) -> void:
	bout = b
	_ink = Ink.new(self)
	_ink_b = Ink.new(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func show_banner(text: String, sub := "", seconds := 1.2) -> void:
	banner = text
	banner_sub = sub
	banner_t = 0.0
	banner_life = seconds

func add_pop(text: String, world: Vector3, color: Color, size := 34) -> void:
	pops.append({"text": text, "pos": world, "t": 0.0, "col": color, "size": size})

func refresh(dt: float) -> void:
	_t += dt
	var st := bout.sim.state()
	for i in 2:
		var f: Dictionary = st["fighters"][i]
		var r := float(f["vitality"]) / maxf(1.0, float(f["vitality_max"]))
		trail[i] = r if r > trail[i] else maxf(r, trail[i] - dt * 0.35)
	for p in pops:
		p["t"] += dt
	pops = pops.filter(func(p): return p["t"] < 0.9)
	banner_t += dt
	queue_redraw()

func _pal(i: int, key: String) -> Color:
	return bout.rigs[i].palette.get(key, Color.WHITE)

func _draw() -> void:
	if bout == null or bout.sim == null:
		return
	var st := bout.sim.state()
	var m := UiStyle.safe_margins(get_viewport())
	var lefty: bool = Settings.get_value("left_handed")
	var reserve := 124.0
	var pw := minf(560.0, (size.x - m.x - m.z - reserve - 150.0) * 0.5)
	var ph := 112.0
	var rect_a := Rect2(m.x + (reserve if lefty else 0.0), m.y, pw, ph)
	var rect_b := Rect2(size.x - m.z - pw - (0.0 if lefty else reserve), m.y, pw, ph)
	_draw_panel(0, st["fighters"][0], rect_a, false)
	_draw_panel(1, st["fighters"][1], rect_b, true)
	_draw_clock(st, Vector2((rect_a.end.x + rect_b.position.x) * 0.5, m.y))
	for i in 2:
		_draw_world(i, st)
	for p in pops:
		var sp := _project(p["pos"])
		if sp.x > -9000:
			var k: float = p["t"] / 0.9
			_ink.text(sp + Vector2(-100, -60.0 * k - 30), p["text"], 44 if int(p["size"]) >= 44 else 34, p["col"].lerp(Color(p["col"], 0.0), k * k), HORIZONTAL_ALIGNMENT_CENTER, 200)
	if bout.cfg.training:
		_ink.text(Vector2(m.x + 8, m.y + ph + 36), "TRAINING - nobody can die", 18, UiStyle.TEAL_LT)
	_ink.flush()
	_draw_banner()

func _project(world: Vector3) -> Vector2:
	var c := bout.cam
	if c == null or c.is_position_behind(world):
		return Vector2(-9999, -9999)
	return c.unproject_position(world)

func _draw_clock(st: Dictionary, top_center: Vector2) -> void:
	var left := maxi(0, int(bout.sim.R["timeout_ticks"]) - int(st["frame"])) / 60
	var txt := "%d:%02d" % [left / 60, left % 60]
	var r := Rect2(top_center + Vector2(-56, 4), Vector2(112, 46))
	_ink.panel(r, UiStyle.NIGHT, UiStyle.INK, 4.0)
	_ink.text(r.position + Vector2(0, 35), txt, 34, UiStyle.PAPER if left > 20 else UiStyle.RUST, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

func _draw_panel(i: int, f: Dictionary, r: Rect2, mirror: bool) -> void:
	var id: String = bout.cfg.a_id if i == 0 else bout.cfg.b_id
	var pal_main := _pal(i, "main")
	var pal_glow := _pal(i, "glow")
	_ink.panel(r, Color(0.10, 0.09, 0.10, 0.82), UiStyle.INK, 5.0)
	# portrait: palette disc with the critter's initial
	var pr := 40.0
	var pc := Vector2(r.end.x - pr - 12 if mirror else r.position.x + pr + 12, r.position.y + r.size.y * 0.5)
	_ink.disc(pc, pr + 4, UiStyle.INK)
	_ink.disc(pc, pr, pal_main)
	_ink.ring(pc, pr - 5, Color(1, 1, 1, 0.25))
	_ink.text(pc + Vector2(-pr, 14), id.substr(0, 1).to_upper(), 44, UiStyle.PAPER, HORIZONTAL_ALIGNMENT_CENTER, pr * 2.0)
	var bx := r.position.x + 12 if mirror else r.position.x + pr * 2 + 26
	var bw := r.size.x - pr * 2 - 38
	var def: CritterDef = bout.sim.fighters[i].def
	var tag := "YOU" if i == bout.player_idx else ("AI " + (bout.cfg.profile_a if i == 0 else bout.cfg.profile_b))
	var name_al := HORIZONTAL_ALIGNMENT_RIGHT if mirror else HORIZONTAL_ALIGNMENT_LEFT
	_ink.text(Vector2(bx, r.position.y + 30), def.display_name.to_upper(), 26, UiStyle.PAPER, name_al, bw)
	var tag_w := 150.0
	_ink.text(Vector2(bx + (0.0 if mirror else bw - tag_w), r.position.y + 30), tag, 18, UiStyle.GOLD if i == bout.player_idx else UiStyle.TEAL_LT, HORIZONTAL_ALIGNMENT_LEFT if mirror else HORIZONTAL_ALIGNMENT_RIGHT, tag_w)
	var vr := float(f["vitality"]) / maxf(1.0, float(f["vitality_max"]))
	var low := vr < float(bout.sim.R["last_stand_ratio"])
	var vcol := pal_glow if pal_glow.get_luminance() > 0.35 else pal_glow.lightened(0.35)
	if low:
		vcol = vcol.lerp(UiStyle.RUST, 0.5 + 0.5 * sin(_t * 12.0))
	_bar(Rect2(bx, r.position.y + 40, bw, 28), vr, vcol, trail[i], mirror, 3.0)
	_ink.text(Vector2(bx, r.position.y + 62), "%d" % ceili(float(f["vitality"])), 18, UiStyle.PAPER, HORIZONTAL_ALIGNMENT_RIGHT if mirror else HORIZONTAL_ALIGNMENT_LEFT, bw)
	var sr := float(f["stamina"]) / maxf(1.0, float(f["stamina_max"]))
	var scol := UiStyle.GREEN
	if f["winded"]:
		scol = UiStyle.RUST.lerp(UiStyle.GOLD, 0.5 + 0.5 * sin(_t * 14.0))
	_bar(Rect2(bx, r.position.y + 72, bw * 0.82, 14), sr, scol, -1.0, mirror, 2.0)
	var rs: Dictionary = RESOURCES.get(id, {})
	if not rs.is_empty():
		var T: Dictionary = bout.sim.fighters[i].T
		var mx := float(rs.get("max_const", 0.0))
		if mx <= 0.0:
			mx = maxf(1.0, float(T.get(rs.get("max", ""), 100.0)))
		var rv := clampf(float(f.get(rs["key"], 0.0)) / mx, 0.0, 1.0)
		var rr := Rect2(bx, r.position.y + 91, bw * 0.62, 14)
		_bar(rr, rv, rs["color"], -1.0, mirror, 2.0)
		_ink.text(Vector2(rr.position.x + 4, rr.position.y + 12), str(rs["label"]), 14, UiStyle.PAPER, HORIZONTAL_ALIGNMENT_RIGHT if mirror else HORIZONTAL_ALIGNMENT_LEFT, rr.size.x - 8)
	# status chips under the panel
	var cx := r.position.x if not mirror else r.end.x
	for s in f["status"]:
		var col: Color = STATUS_COL.get(str(s), UiStyle.PAPER_DK)
		var w := 18.0 + 11.0 * str(s).length()
		var cr := Rect2(cx - (w if mirror else 0.0), r.end.y + 6, w, 28)
		_ink.panel(cr, col.darkened(0.45), col, 2.0, false)
		_ink.text(cr.position + Vector2(0, 21), str(s).to_upper(), 14, UiStyle.PAPER, HORIZONTAL_ALIGNMENT_CENTER, w)
		cx += (-w - 6.0) if mirror else (w + 6.0)

func _bar(r: Rect2, ratio: float, col: Color, trail_ratio: float, mirror: bool, bw: float) -> void:
	_ink.bar(r, Color(0.2, 0.17, 0.17), UiStyle.INK, bw)
	var fill := func(rr: float, c: Color) -> void:
		var w := r.size.x * clampf(rr, 0.0, 1.0)
		var fr := Rect2(r.end.x - w if mirror else r.position.x, r.position.y, w, r.size.y)
		_ink.rect(fr, c)
	if trail_ratio > ratio:
		fill.call(trail_ratio, Color(0.98, 0.93, 0.8, 0.9))
	fill.call(ratio, col)
	_ink.rect(Rect2(r.position.x, r.position.y + 2, r.size.x, maxf(2.0, r.size.y * 0.22)), Color(1, 1, 1, 0.18))

# ------------------------------------------------------------------ on the fighters
func _draw_world(i: int, st: Dictionary) -> void:
	var f: Dictionary = st["fighters"][i]
	var c3 := bout.chest(i, 1.05)
	var c2 := _project(c3)
	if c2.x < -9000:
		return
	var edge := _project(c3 + bout.cam.global_transform.basis.x * 0.75)
	var rad := clampf(c2.distance_to(edge), 22.0, 140.0)
	var pr := float(f["poise"]) / maxf(1.0, float(f["poise_max"]))
	var col := UiStyle.RUST.lerp(UiStyle.TEAL_LT, clampf(pr * 1.3 - 0.1, 0.0, 1.0))
	var broken: bool = f["action"] == "stagger"
	if broken:
		col = UiStyle.RUST.lerp(Color.WHITE, 0.5 + 0.5 * sin(_t * 30.0))
	if f["alive"]:
		_ink.ring(c2, rad + 5.0, Color(0.09, 0.07, 0.07, 0.4), true)
		if pr > 0.01:
			draw_arc(c2, rad, -PI * 0.5, -PI * 0.5 + TAU * pr, 40, col, 6.0, true)
	if i != bout.player_idx and f["alive"]:
		_draw_lock(c2, rad + 14.0)
	if i != bout.player_idx or bout.player_idx < 0:
		_draw_tell(i, f, c2, rad)

func _draw_lock(c: Vector2, r: float) -> void:
	var rot := _t * 0.8
	for k in 4:
		var a := rot + float(k) * PI * 0.5
		draw_arc(c, r, a - 0.18, a + 0.18, 8, UiStyle.GOLD, 5.0, true)

func _draw_tell(i: int, f: Dictionary, c2: Vector2, rad: float) -> void:
	var mid := str(f["move_id"])
	if mid == "" or f["stun"] > 0:
		return
	var m: MoveDef = bout.sim.fighters[i].def.move(mid)
	if m == null or m.kind == "dodge" or not str(f["action"]) in ["strike_light", "strike_heavy", "grab", "ability1", "ability2", "laststand"]:
		return
	var af := int(f["action_frame"])
	if af >= m.startup + 2 or m.startup <= 0:
		return
	var k := clampf(float(af) / float(m.startup), 0.0, 1.0)
	var unblock: bool = bool(m.props.get("unblockable", false)) or bool(m.props.get("guard_crush", false)) or m.kind == "grab"
	var col := UiStyle.GOLD
	var hint := "BLOCK"
	if m.kind == "heavy":
		col = Color(1.0, 0.55, 0.2)
	if unblock:
		col = Color(1.0, 0.25, 0.3)
		hint = "DODGE"
	if m.kind in ["ability", "laststand"]:
		col = Color(0.8, 0.5, 1.0)
	if not unblock and m.startup - af <= 9 and m.startup - af >= 0:
		hint = "PARRY!"
	var top := c2 + Vector2(0, -rad - 54)
	var r := lerpf(46.0, 26.0, k)
	_ink.disc(top, r + 5.0, UiStyle.INK)
	_ink.disc(top, r, col)
	draw_arc(top, r + 11.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - k), 28, Color.WHITE, 5.0, true)
	_ink.text(top + Vector2(-20, 13), "!", 44, UiStyle.INK if col.get_luminance() > 0.5 else UiStyle.PAPER, HORIZONTAL_ALIGNMENT_CENTER, 40)
	_ink.text(top + Vector2(-80, r + 30), hint, 26, col.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER, 160)

func _draw_banner() -> void:
	if banner == "" or banner_t > banner_life:
		return
	var k := clampf(banner_t / 0.18, 0.0, 1.0)
	var sc := lerpf(1.7, 1.0, 1.0 - pow(1.0 - k, 3.0))
	var fade := clampf((banner_life - banner_t) / 0.25, 0.0, 1.0)
	var c := Vector2(size.x * 0.5, size.y * 0.40)
	draw_set_transform(c, 0.0, Vector2(sc, sc))
	_ink_b.text(Vector2(-500, 30), banner, 110, Color(UiStyle.GOLD, fade), HORIZONTAL_ALIGNMENT_CENTER, 1000, 18)
	if banner_sub != "":
		_ink_b.text(Vector2(-500, 84), banner_sub, 36, Color(UiStyle.PAPER, fade), HORIZONTAL_ALIGNMENT_CENTER, 1000, 10)
	_ink_b.flush()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
