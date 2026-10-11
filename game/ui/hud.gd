class_name Hud
extends CanvasLayer
## Field HUD (the Handler's field tablet). Touch-first, keyboard-complete.
## Left: floating joystick. Right: Attack, 3 abilities (icons, cooldown sweep, cost tint), Dash,
## contextual Interact / Contain above. Top-left: partner portraits (tap to swap) with HP + Strain/Noise.
## Top-right: Scan, Pause. Top-centre: objective, toasts, boss bar. Burden HOLD overlay. Noise overlay.

const NOISE_SHADER_PATH := "res://game/art/shaders/future_noise.gdshader"
const FALLBACK_NOISE := """
shader_type canvas_item;
uniform float noise = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;
	float band = step(0.965, fract(sin(floor(uv.y * 70.0 + t * 24.0)) * 43758.5453));
	uv.x += band * noise * 0.025 * sin(t * 61.0);
	float off = 0.007 * noise;
	vec3 c = vec3(texture(screen_tex, uv + vec2(off, 0.0)).r, texture(screen_tex, uv).g, texture(screen_tex, uv - vec2(off, 0.0)).b);
	float vig = smoothstep(0.35, 0.95, length(uv - 0.5) * 1.35);
	c = mix(c, c * vec3(0.9, 0.8, 1.05), noise * 0.5);
	COLOR = vec4(mix(c, vec3(0.42, 0.3, 0.52), vig * noise * 0.65), 1.0);
}
"""

var field: Field
var party: PartyController
var root: Control
var joystick: FloatingJoystick
var btn_attack: TouchButton
var btn_ab: Array = []
var btn_dash: TouchButton
var btn_interact: TouchButton
var btn_contain: TouchButton
var btn_scan: TouchButton
var btn_pause: TouchButton
var btn_hold: TouchButton
var _portraits: Array = []      # [{holder, member, hp_bar, knack_bar, down_label}]
var _objective_panel: PanelContainer
var _objective_label: Label
var _toast_box: VBoxContainer
var _boss_panel: Control
var _boss_bar: ProgressBar
var _boss_name: Label
var _boss: Node = null
var _burden_panel: Control
var _burden_progress: ProgressBar
var _burden_strain: ProgressBar
var _burden_label: Label
var _noise_rect: ColorRect
var _noise_mat: ShaderMaterial
var _vignette: TextureRect
var _revive_label: Label
var _contain_bar: ProgressBar
var _interact_kind := ""
var _layout_dirty := true
var _last_leader: Node = null
var _pause_menu: Node = null
var _tq := HudFlow.ToastQueue.new()
var _rev_combat := false
var _rev_scan := false
var _rev_t := 0.0
var _ctrl_on := true
var _burden_on := false
var _ability_uses := 0
var _scan_started := false
var _tip_pulse := 0.0
var _guide: Control = null
var _guide_dir := Vector2.ZERO
var _guide_dist := -1.0
var _moved_tip_t := 1.5

func setup(f: Field, p: PartyController) -> void:
	field = f
	party = p

func _ready() -> void:
	layer = 20
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiKit.theme()
	add_child(root)
	_build_overlays()
	joystick = FloatingJoystick.new()
	root.add_child(joystick)
	btn_attack = _btn("attack", 150, "ATTACK")
	btn_attack.glyph_size = 30
	for i in 3:
		var b := _btn("ability_%d" % (i + 1), 100, "")
		btn_ab.append(b)
	btn_dash = _btn("dash", 96, "DASH")
	btn_dash.base_col = UiKit.CARD_EDGE
	btn_dash.icon = UiKit.ability_icon("dash")
	btn_interact = _btn("interact", 96, "")
	btn_interact.pill = true
	btn_interact.custom_minimum_size = Vector2(230, 96)
	btn_interact.size = btn_interact.custom_minimum_size
	btn_interact.base_col = UiKit.ACCENT.darkened(0.25)
	btn_interact.ring_col = UiKit.PARCHMENT
	btn_interact.visible = false
	btn_contain = _btn("capture", 96, "")
	btn_contain.pill = true
	btn_contain.custom_minimum_size = Vector2(230, 96)
	btn_contain.size = btn_contain.custom_minimum_size
	btn_contain.base_col = Color("#1d4a55")
	btn_contain.ring_col = UiKit.SCAN
	btn_contain.caption = "CONTAIN"
	btn_contain.visible = false
	btn_scan = _btn("scan", 92, "SCAN")
	btn_scan.base_col = Color("#183a42")
	btn_scan.icon = UiKit.ability_icon("scan")
	btn_scan.ring_col = UiKit.SCAN
	btn_pause = _btn("", 88, "II")
	btn_pause.ring_col = UiKit.PARCHMENT
	btn_pause.tapped.connect(open_pause)
	btn_hold = _btn("", 200, "HOLD")
	btn_hold.glyph_size = 44
	btn_hold.base_col = UiKit.ACCENT.darkened(0.2)
	btn_hold.ring_col = UiKit.PARCHMENT
	btn_hold.visible = false
	_batch = HudButtonBatch.new()
	_batch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_batch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_batch)
	for bt in [btn_attack, btn_ab[0], btn_ab[1], btn_ab[2], btn_dash, btn_interact, btn_contain, btn_scan, btn_pause, btn_hold]:
		_batch.add_button(bt)
	_build_top()
	_build_burden()
	AbilityIcons.events.baked.connect(_on_icon_baked)
	AbilityIcons.bake_all()
	Events.objective_changed.connect(set_objective)
	Events.toast.connect(toast)
	Events.actor_damaged.connect(_on_damaged)
	Events.ability_used.connect(func(_c, _a): _ability_uses += 1)
	Events.scan_started.connect(func(): _scan_started = true)
	get_viewport().size_changed.connect(func(): _layout_dirty = true)
	if party:
		party.leader_changed.connect(func(_m): _rebuild_portraits())
	_rebuild_portraits()
	set_objective(str(GameState.get_flag("_objective", "")))
	_update_reveal(true)

var _batch: HudButtonBatch

func _btn(act: String, d: float, g: String) -> TouchButton:
	var b := TouchButton.new(act, d, g)
	b.name = "Btn_" + (act if act != "" else g)
	root.add_child(b)
	return b

# ---------------- build ----------------
func _build_overlays() -> void:
	_noise_rect = ColorRect.new()
	_noise_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_noise_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_noise_mat = ShaderMaterial.new()
	if ResourceLoader.exists(NOISE_SHADER_PATH):
		_noise_mat.shader = load(NOISE_SHADER_PATH)
	else:
		var sh := Shader.new()
		sh.code = FALLBACK_NOISE
		_noise_mat.shader = sh
	_noise_rect.material = _noise_mat
	_noise_rect.visible = false
	root.add_child(_noise_rect)
	_vignette = TextureRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	var g := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.7, 0.05, 0.02, 0.0))
	grad.set_color(1, Color(0.7, 0.05, 0.02, 0.75))
	grad.set_offset(0, 0.55)
	g.gradient = grad
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.05, 0.5)
	g.width = 256
	g.height = 256
	_vignette.texture = g
	_vignette.modulate.a = 0.0
	root.add_child(_vignette)

func _build_top() -> void:
	_objective_panel = PanelContainer.new()
	_objective_panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.94), UiKit.ACCENT.darkened(0.2), 22, 3, 18))
	_objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_objective_panel)
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_panel.add_child(hb)
	var tag := UiKit.label("OBJECTIVE", 20, UiKit.ACCENT, "bold")
	hb.add_child(tag)
	_objective_label = UiKit.label("", 26, UiKit.INK, "ui")
	hb.add_child(_objective_label)
	_guide = Control.new()
	_guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guide.custom_minimum_size = Vector2(220, 52)
	_guide.size = Vector2(220, 52)
	_guide.visible = false
	_guide.draw.connect(_draw_guide)
	root.add_child(_guide)
	_toast_box = VBoxContainer.new()
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_theme_constant_override("separation", 8)
	root.add_child(_toast_box)
	_boss_panel = VBoxContainer.new()
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_panel.visible = false
	root.add_child(_boss_panel)
	_boss_name = UiKit.label("AUGUR-7 DEEPCORE RIG", 26, UiKit.PARCHMENT, "solemn", 8, Color(0, 0, 0, 0.85))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_panel.add_child(_boss_name)
	_boss_bar = _bar(Color("#c8261c"), Vector2(640, 26))
	_boss_panel.add_child(_boss_bar)
	_revive_label = UiKit.label("", 26, UiKit.PARCHMENT, "bold", 8, Color(0, 0, 0, 0.85))
	_revive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_revive_label)
	_contain_bar = _bar(UiKit.SCAN, Vector2(260, 18))
	_contain_bar.visible = false
	root.add_child(_contain_bar)

func _build_burden() -> void:
	_burden_panel = VBoxContainer.new()
	_burden_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_burden_panel.visible = false
	root.add_child(_burden_panel)
	_burden_label = UiKit.label("HOLD THE SPAN", 40, UiKit.PARCHMENT, "title", 10, Color(0, 0, 0, 0.85))
	_burden_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_burden_panel.add_child(_burden_label)
	var l1 := UiKit.label("CONVOY CROSSING", 20, UiKit.PARCHMENT, "bold", 6)
	_burden_panel.add_child(l1)
	_burden_progress = _bar(UiKit.PSI, Vector2(520, 24))
	_burden_panel.add_child(_burden_progress)
	var l2 := UiKit.label("ARUUN'S STRAIN", 20, UiKit.PARCHMENT, "bold", 6)
	_burden_panel.add_child(l2)
	_burden_strain = _bar(UiKit.ACCENT, Vector2(520, 18))
	_burden_panel.add_child(_burden_strain)

func _bar(col: Color, sz: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = sz
	b.show_percentage = false
	b.max_value = 1.0
	b.step = 0.0
	b.value = 1.0
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("background", UiKit.box(Color(0.08, 0.05, 0.05, 0.8), Color(0.9, 0.85, 0.75, 0.7), 8, 2, 0))
	b.add_theme_stylebox_override("fill", UiKit.box(col, Color(0, 0, 0, 0), 8, 0, 0))
	return b

func _rebuild_portraits() -> void:
	for p in _portraits:
		p["holder"].queue_free()
	_portraits.clear()
	if party == null or party.members.size() < 2:
		return
	var order := [party.get_leader(), party.get_partner()]
	for i in 2:
		var m: PlayableCritter = order[i]
		var sz := 108.0 if i == 0 else 88.0
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.custom_minimum_size = Vector2(sz, sz + 30)
		root.add_child(holder)
		var pc := UiKit.portrait_control(m.char_id, "default", sz)
		holder.add_child(pc)
		var hpb := _bar(Color("#5fbf5a"), Vector2(sz, 12))
		hpb.position = Vector2(0, sz + 4)
		hpb.size = Vector2(sz, 12)
		holder.add_child(hpb)
		var kcol := UiKit.ACCENT if m.char_id == "aruun" else UiKit.PSI
		var kb := _bar(kcol, Vector2(sz, 9))
		kb.position = Vector2(0, sz + 19)
		kb.size = Vector2(sz, 9)
		kb.value = 0.0
		holder.add_child(kb)
		var down := UiKit.label("DOWN", 26, Color(1, 0.4, 0.3), "bold", 8, Color(0, 0, 0, 0.9))
		down.position = Vector2(sz * 0.5 - 28, sz * 0.5 - 18)
		down.visible = false
		holder.add_child(down)
		var tag := UiKit.label("SWAP" if i == 1 else "", 18, UiKit.PARCHMENT, "bold", 6, Color(0, 0, 0, 0.9))
		tag.position = Vector2(sz - 34, -6)
		holder.add_child(tag)
		var swap_btn: TouchButton = null
		if i == 1:
			swap_btn = TouchButton.new("swap", sz, "")
			swap_btn.base_col = Color(0, 0, 0, 0)
			swap_btn.ring_col = Color(0, 0, 0, 0)
			swap_btn.custom_minimum_size = Vector2(sz, sz)
			swap_btn.size = Vector2(sz, sz)
			holder.add_child(swap_btn)
		_portraits.append({"holder": holder, "member": m, "hp": hpb, "knack": kb, "down": down, "size": sz, "swap": swap_btn})
	_layout_dirty = true
	_refresh_ability_icons()
	_apply_vis()

func _on_icon_baked(_id: String) -> void:
	btn_dash.icon = UiKit.ability_icon("dash")
	btn_scan.icon = UiKit.ability_icon("scan")
	btn_dash.redraw()
	btn_scan.redraw()
	_refresh_ability_icons()

func _refresh_ability_icons() -> void:
	if party == null:
		return
	var l := party.get_leader()
	if l == null or l.kit == null:
		return
	for i in 3:
		var b: TouchButton = btn_ab[i]
		var aid: String = l.kit.ability_ids[i]
		b.icon = UiKit.ability_icon(aid)
		b.ring_col = UiKit.char_color(l.char_id).lightened(0.25)
		b.glyph = UiKit.ability_glyph(aid)
		b.caption = str(Canon.ability(aid).get("name", aid)).to_upper()
		b.redraw()
	btn_attack.icon = UiKit.ability_icon("aruun_combo" if l.char_id == "aruun" else "bad_thought")
	btn_attack.glyph = "MORROW" if l.char_id == "aruun" else "BAD THOUGHT"
	btn_attack.glyph_size = 26
	btn_attack.redraw()

# ---------------- layout ----------------
func _layout() -> void:
	_layout_dirty = false
	var vs := root.get_viewport_rect().size
	var lh := bool(GameState.settings.get("left_handed", false))
	var W := vs.x
	var H := vs.y
	var fx := func(x: float, w: float) -> float: return (W - x - w) if lh else x
	# right cluster (relative to right edge)
	# Attack in the corner; the three abilities on a clean 200 px arc around it (180°, 225°, 270°)
	# so each caption (drawn under its disc) clears its neighbours; Dash sits outside the arc.
	var C := Vector2(W - 130, H - 130)
	_place(btn_attack, C, lh, W)
	var R := 200.0
	for i in 3:
		var a := deg_to_rad(180.0 + 45.0 * i)
		_place(btn_ab[i], C + Vector2(cos(a), sin(a)) * R, lh, W)
	_place(btn_dash, C + Vector2(-335, 36), lh, W)
	_place(btn_interact, C + Vector2(-60, -330), lh, W)
	_place(btn_contain, C + Vector2(-60, -440), lh, W)
	_place(btn_scan, Vector2(W - 170, 62), lh, W)
	_place(btn_pause, Vector2(W - 62, 56), lh, W)
	_place(btn_hold, Vector2(W - 250, H * 0.55), lh, W)
	# joystick zone: left 45% below portraits
	var zx := 0.0 if not lh else W * 0.55
	joystick.zone = Rect2(zx, 170, W * 0.45, H - 170)
	joystick.set_idle(Vector2((W - 200) if lh else 200, H - 170))
	# portraits top-left
	var x := 18.0
	for p in _portraits:
		var h: Control = p["holder"]
		var sz: float = p["size"]
		h.position = Vector2(fx.call(x, sz), 16 if sz > 100 else 26)
		x += sz + 18
	# objective + toasts + boss centre
	_objective_panel.reset_size()
	var ow := _objective_panel.get_combined_minimum_size().x
	_objective_panel.position = Vector2((W - ow) * 0.5, 14)
	_guide.position = Vector2(W * 0.5 - 110, 78)
	_toast_box.position = Vector2(W * 0.5 - 260, 156 if _boss_panel.visible else 136)
	_toast_box.size = Vector2(520, 10)
	_boss_panel.position = Vector2(W * 0.5 - 320, 80)
	_revive_label.position = Vector2(W * 0.5 - 250, H * 0.36)
	if _batch:
		_batch.queue_redraw()
	_revive_label.size = Vector2(500, 40)
	_contain_bar.position = Vector2(W * 0.5 - 130, H * 0.42)
	_burden_panel.position = Vector2(W * 0.5 - 260, H - 236)

func _place(c: Control, center: Vector2, lh: bool, W: float) -> void:
	var s := c.custom_minimum_size
	c.size = s
	var cx := center.x
	if lh:
		cx = W - center.x
	c.position = Vector2(cx - s.x * 0.5, center.y - s.y * 0.5)

# ---------------- per-frame ----------------
var _last_vs := Vector2.ZERO

func _process(delta: float) -> void:
	# While a dialogue is up the touch controls are not usable: stop drawing them (saves ~12 batches, less overdraw).
	var talking := DialogueRunner.current != null and DialogueRunner.current.active
	if _batch and _batch.visible == talking:
		_batch.visible = not talking
		joystick.visible = not talking
	var vs := root.get_viewport_rect().size
	if vs != _last_vs:
		_last_vs = vs
		_layout_dirty = true
	if _layout_dirty:
		_layout()
	_update_toasts()
	if _moved_tip_t > 0.0:
		_moved_tip_t -= delta
		if _moved_tip_t <= 0.0 and not bool(GameState.flags.get("_hud_combat", false)) and not talking:
			tip("move")
	if party == null or party.members.size() < 2:
		return
	_update_reveal(false, delta)
	var l := party.get_leader()
	if l != _last_leader:
		_last_leader = l
		_refresh_ability_icons()
	# abilities
	if l.kit:
		for i in 3:
			var b: TouchButton = btn_ab[i]
			var tint := Color(0, 0, 0, 0)
			if l.char_id == "aruun" and i == 2:
				tint = Color(0.85, 0.15, 0.1, 0.9)
			elif l.char_id == "cigarra":
				var n: float = l.kit.knack_value() / l.kit.knack_max()
				tint = Color(0.72, 0.76, 0.29, 0.35 + n * 0.6)
			b.set_state(l.kit.cd_frac(i), tint, l.kit.blocked_reason(i) == "" and not l.downed)
			b.cd_secs = l.kit.cd[i]
	var dcd := maxf(0.1, Balance.f("%s.dash_cd" % l.char_id, 1.2))
	btn_dash.set_state(clampf(l.dash_cd / dcd, 0.0, 1.0), Color(0, 0, 0, 0), true)
	btn_dash.cd_secs = l.dash_cd
	# portraits
	for p in _portraits:
		var m: PlayableCritter = p["member"]
		(p["hp"] as ProgressBar).value = m.hp / m.max_hp
		var kv := 0.0
		if m.kit:
			kv = m.kit.knack_value() / maxf(1.0, m.kit.knack_max())
		(p["knack"] as ProgressBar).value = kv
		(p["down"] as Label).visible = m.downed
		var sw: TouchButton = p["swap"]
		if sw:
			sw.modulate.a = 1.0 if party.can_swap() else 0.5
	# contain button
	var ct := party.contain_target
	btn_contain.visible = ct != null and is_instance_valid(ct)
	if btn_contain.visible:
		tip("contain")
		btn_contain.caption = "CONTAIN %s" % str(ct.display_name).to_upper()
	var cp := party.contain_progress()
	_contain_bar.visible = cp > 0.0
	_contain_bar.value = cp
	# revive status
	var rtxt := ""
	for m in party.members:
		if m.downed:
			var other: PlayableCritter = party.members[1 - party.members.find(m)]
			if not other.downed:
				rtxt = "%s is down — stand beside to revive  %d%%" % [m.display_name, int(m.revive_progress / Balance.f("global.revive_time", 2.0) * 100.0)]
	_revive_label.text = rtxt
	# noise overlay
	var noise := 0.0
	for m in party.members:
		if m.char_id == "cigarra" and m.kit:
			noise = m.kit.knack_value()
	var thr := Balance.f("cigarra.noise.distort_at", 60.0)
	var nv := clampf((noise - thr) / (100.0 - thr), 0.0, 1.0)
	if bool(GameState.settings.get("reduce_flashing", false)):
		nv *= 0.4
	_noise_rect.visible = nv > 0.01
	if _noise_rect.visible:
		_noise_mat.set_shader_parameter("noise", nv)
	# boss
	if _boss and is_instance_valid(_boss):
		_boss_bar.value = lerpf(_boss_bar.value, _boss.hp / _boss.max_hp, 1.0 - exp(-8.0 * delta))
		var ph: int = int(_boss.get("phase")) if "phase" in _boss else 1
		_boss_name.text = "AUGUR-7 DEEPCORE RIG  ·  PHASE %d" % ph
		if not _boss.alive:
			_boss_panel.visible = false
			_layout_dirty = true
			_boss = null
	# vignette fade
	if _vignette.modulate.a > 0.0:
		_vignette.modulate.a = maxf(0.0, _vignette.modulate.a - delta * 1.6)

# ---------------- API ----------------
func set_objective(text: String) -> void:
	GameState.flags["_objective"] = text
	_objective_label.text = text
	_objective_panel.visible = text != ""
	_layout_dirty = true
	if not bool(GameState.settings.get("reduce_flashing", false)):
		_objective_panel.modulate = Color(1.4, 1.2, 1.0)
		var tw := create_tween()
		tw.tween_property(_objective_panel, "modulate", Color.WHITE, 0.6)

func set_interact(text: String) -> void:
	btn_interact.visible = text != ""
	btn_interact.caption = text.to_upper()
	btn_interact.redraw()

## Toasts go through one queue: a single short line on screen, warnings first, a backlog of at most three.
func toast(text: String, kind: String = "info") -> void:
	if _toast_box == null:
		return
	_tq.push(text, kind, Time.get_ticks_msec() * 0.001)

func _update_toasts() -> void:
	if _tq.tick(Time.get_ticks_msec() * 0.001):
		_render_toast()

func _render_toast() -> void:
	for c in _toast_box.get_children():
		c.queue_free()
	var cur: Dictionary = _tq.current
	if cur.is_empty():
		return
	var kind: String = cur["kind"]
	var edge := UiKit.PARCHMENT
	match kind:
		"codex":
			edge = UiKit.SCAN
		"item":
			edge = UiKit.PSI
		"warning":
			edge = UiKit.ACCENT
		"trust":
			edge = UiKit.ACCENT_2
		"tip":
			edge = UiKit.SCAN
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.CARD, 0.9), edge, 12, 3 if kind == "tip" else 2, 10))
	var l := UiKit.label(str(cur["text"]), 24 if kind == "tip" else 22, UiKit.PARCHMENT, "bold" if kind == "tip" else "ui")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(480, 0)
	pc.add_child(l)
	_toast_box.add_child(pc)
	if not bool(GameState.settings.get("reduce_flashing", false)):
		pc.modulate.a = 0.0
		pc.create_tween().tween_property(pc, "modulate:a", 1.0, 0.15)
	if kind == "codex":
		Audio.sfx("codex")

# ---------------- first-time tips ----------------
## Show a tip once ever, and pulse the control it is about until it is used (or ~6 s).
func tip(id: String) -> void:
	var t := HudFlow.take_tip(GameState.flags, id)
	if t == "":
		return
	_tq.push(t, "tip", Time.get_ticks_msec() * 0.001)
	var tgt := _tip_target(id)
	if tgt:
		tgt.hint = 6.0
		tgt.redraw()

func _tip_target(id: String) -> TouchButton:
	match str(HudFlow.TIPS[id]["target"]):
		"attack": return btn_attack
		"ability": return btn_ab[0]
		"dash": return btn_dash
		"scan": return btn_scan
		"contain": return btn_contain
		"swap":
			for p in _portraits:
				if p["swap"]:
					return p["swap"]
	return null

# ---------------- progressive disclosure ----------------
## Abilities / dash / partner appear when an enemy is near (or an ability was used); Scan when the valley asks for it.
func _update_reveal(force: bool, delta: float = 0.0) -> void:
	_rev_t -= delta
	if not force and _rev_t > 0.0:
		return
	_rev_t = 0.25
	var d := INF
	if field and party and party.get_leader():
		var e: Node = field.nearest_enemy(party.get_leader().global_position, HudFlow.REVEAL_DIST_M + 1.0, true)
		if e:
			d = e.global_position.distance_to(party.get_leader().global_position)
	var r := HudFlow.reveal(GameState.flags, d, _ability_uses > 0, _scan_started)
	var changed := false
	if r["combat"] and not _rev_combat:
		_rev_combat = true
		changed = true
		if not bool(GameState.flags.get("_hud_combat", false)):
			GameState.flags["_hud_combat"] = true
			tip("attack")
			tip("abilities")
	if r["scan"] and not _rev_scan:
		_rev_scan = true
		changed = true
		if not bool(GameState.flags.get("_hud_scan", false)):
			GameState.flags["_hud_scan"] = true
			if not _scan_started:
				tip("scan")
	if changed:
		_apply_vis()
	if _rev_combat and _ability_uses >= 2:
		tip("swap")

## One place decides which touch controls are visible (burden, dialogue-free mode and the reveal all feed it).
func _apply_vis() -> void:
	var on := _ctrl_on and not _burden_on
	btn_attack.visible = on
	for b in btn_ab:
		b.visible = on and _rev_combat
	btn_dash.visible = on and _rev_combat
	btn_scan.visible = _ctrl_on and _rev_scan
	if _portraits.size() > 1:
		(_portraits[1]["holder"] as Control).visible = _rev_combat
	_layout_dirty = true

# ---------------- guide arrow ----------------
## Called by ExploreHud (a few times a second): `dir` is the screen-space direction (x right, y down) to the story target.
func set_guide(dir: Vector2, dist: float) -> void:
	var show_it := dist >= 6.0 and dir != Vector2.ZERO and not _boss_panel.visible
	if _guide.visible != show_it:
		_guide.visible = show_it
	if not show_it:
		return
	var nd := dir.normalized()
	if int(dist) != int(_guide_dist) or nd.distance_to(_guide_dir) > 0.04:
		_guide_dir = nd
		_guide_dist = dist
		_guide.queue_redraw()

func _draw_guide() -> void:
	var c := Vector2(30, 26)
	var ang := _guide_dir.angle()
	var pts := PackedVector2Array()
	for q in [[18.0, 0.0], [-10.0, -13.0], [-4.0, 0.0], [-10.0, 13.0]]:
		pts.append(c + Vector2(q[0], q[1]).rotated(ang))
	_guide.draw_rect(Rect2(Vector2.ZERO, Vector2(220, 52)), Color(UiKit.CARD, 0.82))
	_guide.draw_rect(Rect2(Vector2.ZERO, Vector2(220, 52)), Color(1.0, 0.82, 0.30), false, 2.0)
	_guide.draw_colored_polygon(pts, Color(1.0, 0.82, 0.30))
	_guide.draw_string(UiKit.font("bold"), Vector2(62, 36), "%d m" % int(_guide_dist), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UiKit.PARCHMENT)

func set_boss(b: Node) -> void:
	_boss = b
	_boss_panel.visible = b != null
	_layout_dirty = true
	_boss_bar.value = 1.0

func show_burden(on: bool) -> void:
	_burden_panel.visible = on
	btn_hold.visible = on
	_burden_on = on
	_apply_vis()

func set_burden(progress: float, strain: float, holding: bool) -> void:
	_burden_progress.value = progress
	_burden_strain.value = strain
	_burden_label.text = "HOLDING..." if holding else "HOLD THE SPAN!"
	_burden_label.label_settings.font_color = UiKit.PARCHMENT if holding else Color(1, 0.55, 0.4)

func hold_pressed() -> bool:
	return btn_hold.visible and btn_hold.is_held()

func set_controls_visible(on: bool) -> void:
	_ctrl_on = on
	joystick.visible = on
	_apply_vis()
	if not on:
		btn_interact.visible = false
		btn_contain.visible = false

func _on_damaged(actor: Node, amount: float, _src: Node) -> void:
	if party and actor == party.get_leader() and amount > 0.0:
		if _rev_combat:
			tip("dash")
		var a := clampf(amount / 40.0, 0.25, 0.8)
		if bool(GameState.settings.get("reduce_flashing", false)):
			a *= 0.4
		_vignette.modulate.a = maxf(_vignette.modulate.a, a)

func open_pause() -> void:
	if _pause_menu and is_instance_valid(_pause_menu):
		return
	if DialogueRunner.current and DialogueRunner.current.active:
		return
	_pause_menu = PauseMenu.new()
	get_parent().add_child(_pause_menu)

func _unhandled_input(ev: InputEvent) -> void:
	if get_tree().paused:
		return
	if ev.is_action_pressed("pause"):
		open_pause()
		get_viewport().set_input_as_handled()


## Paints all round HUD buttons in phases (see TouchButton.paint). The buttons stay real Controls for input and layout.
class HudButtonBatch extends Control:
	var buttons: Array = []
	func add_button(b: TouchButton) -> void:
		buttons.append(b)
		b.batcher = self
		b.visibility_changed.connect(queue_redraw)
		b.resized.connect(queue_redraw)
	func _draw() -> void:
		for ph in 5:
			for b in buttons:
				var bt: TouchButton = b
				if not bt.visible:
					continue
				draw_set_transform(bt.position, 0.0, Vector2.ONE)
				bt.paint(self, ph)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
