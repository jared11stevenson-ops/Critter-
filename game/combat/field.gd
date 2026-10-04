class_name Field
extends Node
## Per-scene combat services. One instance lives in each field scene (Red Reaches).
## Owns: time-scale requests (slow-mo / hit-stop), shake routing, actor registry, auto-aim,
## damage numbers, projectile pool, VFX spawning with fallbacks, ground telegraphs, combat-music state.
## Access from anywhere with Field.current (null outside the field).

static var current: Field = null

var camera_rig: Node = null       # CameraRig
var party: Node = null            # PartyController
var level: Node = null            # level script (terrain access, gates, hooks)
var hud: Node = null              # HUD (CanvasLayer)

var enemies: Array = []           # CritterActor (team "enemy" / "neutral" wildlife / objects)
var party_members: Array = []     # PlayableCritter
var decoys: Array = []            # False Memory decoys (Node3D with global_position, alive)
var future_ghosts: Array = []     # Premonition ghost visuals (dash through = counter)
var premonition_active := false
var dangers: Array = []           # hostile Telegraphs (the AI partner steps out of these)

# --- time scale ---
var _scale_req: Dictionary = {}   # id -> [scale, end_usec]  (end 0 = until cleared)
var _hitstop_end := 0
var _hitstop_started := 0
var _base_scale := 1.0

# --- pools ---
var _dmg_labels: Array = []
var _dmg_i := 0
var _projectiles: Array = []
var _fx_pool: Array = []
var _fx_i := 0
var _vfx_exists: Dictionary = {}
var _vfx_cache: Dictionary = {}

# --- combat music ---
var in_combat := false
var _combat_check_t := 0.0
var music_explore := "explore_reaches"
var boss_active := false

const DMG_POOL := 28
const FX_POOL := 24

func _enter_tree() -> void:
	current = self
	Balance.reload()

func _exit_tree() -> void:
	if current == self:
		current = null
	Engine.time_scale = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in DMG_POOL:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.fixed_size = true
		l.pixel_size = 0.0011
		l.font_size = 46
		l.outline_size = 14
		l.outline_modulate = Color(0.08, 0.05, 0.04, 1)
		l.visible = false
		l.render_priority = 10
		l.outline_render_priority = 9
		var fnt := UiKit.font("bold")
		if fnt:
			l.font = fnt
		add_child(l)
		_dmg_labels.append(l)
	for i in FX_POOL:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 8
		sm.rings = 4
		mi.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1, 0.9, 0.6, 0.9)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_fx_pool.append(mi)
	_prewarm_vfx.call_deferred()

const WARM_VFX := ["hit_spark", "heavy_impact", "dust_puff", "mace_arc", "reach_line", "gravity_well", "psychic_bolt", "psychic_burst",
	"false_memory_echo", "brain_skip_glitch", "capture_beam", "scan_ping", "pickup_glint", "drill_sparks", "coolant_vent", "leap_trail",
	"heal_motes", "rage_aura"]

## Compatibility compiles a material's shader the first time it is drawn, and loads scene files synchronously: both showed up as
## a hitch on the first hit/ability. Instantiate each effect once, right in front of the camera, while the transition fade still
## covers the screen (Router waits two frames before fading in), then free them.
func _prewarm_vfx() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var at := cam.global_position - cam.global_transform.basis.z * 5.0
	var made: Array = []
	for n in WARM_VFX:
		var node := vfx(n, at, {}, self)
		if node:
			made.append(node)
	await get_tree().process_frame
	await get_tree().process_frame
	for m in made:
		if is_instance_valid(m):
			m.queue_free()

func _process(delta: float) -> void:
	_update_time_scale()
	_combat_check_t -= delta
	if _combat_check_t <= 0.0:
		_combat_check_t = 0.5
		_update_combat_state()

# ================= TIME =================
func request_time_scale(id: String, scale: float, real_duration: float = -1.0) -> void:
	var end := 0
	if real_duration > 0.0:
		end = Time.get_ticks_usec() + int(real_duration * 1000000.0)
	_scale_req[id] = [scale, end]
	_update_time_scale()

func clear_time_scale(id: String) -> void:
	_scale_req.erase(id)
	_update_time_scale()

## Brief freeze on impact. Never stacks beyond hitstop_max of continuous freeze.
func hitstop(dur: float) -> void:
	if dur <= 0.0:
		return
	var now := Time.get_ticks_usec()
	var maxd := int(Balance.f("global.hitstop_max", 0.16) * 1000000.0)
	if now > _hitstop_end:
		_hitstop_started = now
	var want := now + int(dur * 1000000.0)
	_hitstop_end = mini(maxi(_hitstop_end, want), _hitstop_started + maxd)
	_update_time_scale()

func _update_time_scale() -> void:
	if get_tree() and get_tree().paused:
		return
	var now := Time.get_ticks_usec()
	var s := 1.0
	for id in _scale_req.keys():
		var r: Array = _scale_req[id]
		if int(r[1]) != 0 and now >= int(r[1]):
			_scale_req.erase(id)
			continue
		s = minf(s, float(r[0]))
	if now < _hitstop_end:
		s = minf(s, 0.04)
	if not is_equal_approx(Engine.time_scale, s):
		Engine.time_scale = s

# ================= CAMERA FX =================
func shake(amount: float) -> void:
	if camera_rig and camera_rig.has_method("add_shake"):
		camera_rig.add_shake(amount)

func impact(kind: String) -> void:
	match kind:
		"light":
			hitstop(Balance.f("global.hitstop_light", 0.045))
			shake(Balance.f("global.shake_light", 0.12))
		"heavy":
			hitstop(Balance.f("global.hitstop_heavy", 0.085))
			shake(Balance.f("global.shake_heavy", 0.32))
		"crit":
			hitstop(Balance.f("global.hitstop_crit", 0.11))
			shake(Balance.f("global.shake_heavy", 0.32) * 1.2)
		"boss":
			hitstop(0.12)
			shake(Balance.f("global.shake_boss", 0.6))

# ================= REGISTRY / TARGETING =================
func register_enemy(e: Node) -> void:
	if not enemies.has(e):
		enemies.append(e)

func unregister_enemy(e: Node) -> void:
	enemies.erase(e)

func register_party(p: Node) -> void:
	if not party_members.has(p):
		party_members.append(p)

func leader() -> Node:
	if party and party.has_method("get_leader"):
		return party.get_leader()
	return null

## Nearest valid hostile target inside a cone. Passive wildlife is never auto-aimed (keystone safety).
func find_target(origin: Vector3, facing: Vector3, max_range: float, cone_deg: float = -1.0, include_objects: bool = true) -> Node:
	if cone_deg < 0.0:
		cone_deg = Balance.f("global.autoaim_cone_deg", 70.0)
	var half := deg_to_rad(cone_deg * 0.5)
	var best: Node = null
	var best_score := INF
	var fwd := Vector3(facing.x, 0, facing.z)
	if fwd.length_squared() < 0.0001:
		fwd = Vector3.FORWARD
	fwd = fwd.normalized()
	for e in enemies:
		if not is_instance_valid(e) or not e.is_targetable():
			continue
		if e.passive:
			continue
		if e.is_object and not include_objects:
			continue
		var to: Vector3 = e.global_position - origin
		to.y = 0
		var d: float = to.length() - e.body_radius
		if d > max_range:
			continue
		var ang := 0.0
		if to.length() > 0.3:
			ang = fwd.angle_to(to.normalized())
		if ang > half and d > 1.2:
			continue
		var score: float = d + ang * 2.0 + (6.0 if e.is_object else 0.0)
		if score < best_score:
			best_score = score
			best = e
	return best

func nearest_enemy(origin: Vector3, max_range: float, hostile_only: bool = true) -> Node:
	var best: Node = null
	var bd := max_range
	for e in enemies:
		if not is_instance_valid(e) or not e.is_targetable():
			continue
		if hostile_only and (e.passive or e.is_object):
			continue
		var d: float = e.global_position.distance_to(origin) - e.body_radius
		if d < bd:
			bd = d
			best = e
	return best

func enemies_in_radius(center: Vector3, radius: float, out: Array) -> void:
	out.clear()
	for e in enemies:
		if not is_instance_valid(e) or not e.is_targetable():
			continue
		var p: Vector3 = e.global_position
		var dx := p.x - center.x
		var dz := p.z - center.z
		var r: float = radius + e.body_radius
		if dx * dx + dz * dz <= r * r and absf(p.y - center.y) < 6.0:
			out.append(e)

## Hostile-side targeting for enemies: picks decoy if one is near, else nearest standing party member.
func enemy_pick_target(origin: Vector3, aggro: float) -> Node:
	var best: Node = null
	var bd := aggro
	for d in decoys:
		if is_instance_valid(d) and d.alive:
			var dd: float = d.global_position.distance_to(origin)
			if dd < aggro * 1.4:
				return d
	for p in party_members:
		if not is_instance_valid(p) or not p.is_targetable():
			continue
		var dist: float = p.global_position.distance_to(origin)
		if dist < bd:
			bd = dist
			best = p
	return best

# ================= DAMAGE NUMBERS =================
func damage_number(pos: Vector3, amount: float, kind: String = "normal") -> void:
	if not bool(GameState.settings.get("show_damage_numbers", true)):
		return
	var l: Label3D = _dmg_labels[_dmg_i]
	_dmg_i = (_dmg_i + 1) % DMG_POOL
	l.visible = true
	var col := Color(1, 0.96, 0.86)
	var size := 46
	match kind:
		"crit":
			col = Color(1.0, 0.78, 0.2)
			size = 66
			l.text = "%d!" % int(round(amount))
		"party":
			col = Color(1.0, 0.36, 0.3)
			l.text = "-%d" % int(round(amount))
		"strain":
			col = Color(0.75, 0.16, 0.12)
			size = 36
			l.text = "-%d STRAIN" % int(round(amount))
		"armor":
			col = Color(0.7, 0.72, 0.76)
			size = 34
			l.text = "ARMORED"
		"heal":
			col = Color(0.5, 1.0, 0.6)
			l.text = "+%d" % int(round(amount))
		_:
			l.text = str(int(round(amount)))
	l.font_size = size
	l.modulate = col
	l.global_position = pos + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.2, 0.2))
	l.scale = Vector3.ONE * (1.5 if kind == "crit" else 1.0)
	var tw := l.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(l, "global_position:y", l.global_position.y + 1.4, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "scale", Vector3.ONE, 0.18)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.tween_callback(l.hide)

func float_text(pos: Vector3, text: String, col: Color = Color(0.95, 0.95, 1.0), size: int = 40) -> void:
	var l: Label3D = _dmg_labels[_dmg_i]
	_dmg_i = (_dmg_i + 1) % DMG_POOL
	l.visible = true
	l.text = text
	l.font_size = size
	l.modulate = col
	l.scale = Vector3.ONE
	l.global_position = pos
	var tw := l.create_tween()
	tw.set_ignore_time_scale(true)
	tw.tween_property(l, "global_position:y", pos.y + 1.0, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.6)
	tw.tween_callback(l.hide)

# ================= VFX =================
## Spawns Agent 1's VFX if it exists; otherwise a cheap fallback for the important ones.
func vfx(vfx_name: String, pos: Vector3, params: Dictionary = {}, parent: Node = null) -> Node:
	var path := "res://game/art/vfx/%s.tscn" % vfx_name
	if not _vfx_exists.has(vfx_name):
		_vfx_exists[vfx_name] = ResourceLoader.exists(path)
	if _vfx_exists[vfx_name]:
		if not _vfx_cache.has(vfx_name):
			_vfx_cache[vfx_name] = load(path)
		var ps: PackedScene = _vfx_cache[vfx_name]
		if ps:
			var n: Node = ps.instantiate()
			var host: Node = parent if parent else get_tree().current_scene
			host.add_child(n)
			if n is Node3D:
				(n as Node3D).global_position = pos
			if n.has_method("setup"):
				n.setup(params)
			return n
	_fallback_fx(vfx_name, pos, params)
	return null

func _fallback_fx(vfx_name: String, pos: Vector3, params: Dictionary) -> void:
	var flashing_ok := not bool(GameState.settings.get("reduce_flashing", false))
	match vfx_name:
		"hit_spark":
			burst(pos, Color(1.0, 0.85, 0.5), 0.6, 0.14)
		"heavy_impact":
			burst(pos, Color(1.0, 0.6, 0.3), 1.6, 0.22)
		"dust_puff":
			burst(pos, Color(0.7, 0.5, 0.35, 0.6), 1.4, 0.35)
		"psychic_burst":
			burst(pos, Color(0.75, 0.85, 0.3, 0.8), 1.4, 0.25)
		"brain_skip_glitch":
			burst(pos, Color(0.6, 1.0, 0.9, 0.8), 1.8, 0.3)
		"boss_explosion":
			burst(pos, Color(1.0, 0.5, 0.2), 9.0, 0.8)
		"capture_beam":
			burst(pos, Color(0.4, 0.9, 1.0, 0.7), 1.4, 0.3)
		"scan_ping":
			burst(pos, Color(0.4, 0.9, 1.0, 0.25), float(params.get("radius", 8.0)), 0.5)
		"pickup_glint":
			burst(pos, Color(1.0, 0.95, 0.6, 0.7), 0.7, 0.25)
		"thoughtstone_align":
			burst(pos, Color(0.6, 0.9, 1.0, 0.7), 3.0, 1.2)
		"heal_motes":
			burst(pos, Color(0.5, 1.0, 0.6, 0.6), 1.6, 0.5)
		"thoughtstone_shards":
			burst(pos, Color(0.55, 0.8, 0.95, 0.8), 2.4, 0.3)
		"drill_sparks":
			burst(pos, Color(1.0, 0.7, 0.3), 1.2, 0.2)
		_:
			pass
	if not flashing_ok:
		return

func burst(pos: Vector3, col: Color, size: float, dur: float) -> void:
	var mi: MeshInstance3D = _fx_pool[_fx_i]
	_fx_i = (_fx_i + 1) % FX_POOL
	mi.visible = true
	mi.global_position = pos
	mi.scale = Vector3.ONE * size * 0.3
	var mat: StandardMaterial3D = mi.material_override
	if bool(GameState.settings.get("reduce_flashing", false)):
		col.a *= 0.5
	mat.albedo_color = col
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * size, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, dur)
	tw.tween_callback(mi.hide)

# ================= TELEGRAPHS =================
## Ground telegraph circle that fills over `dur`, then frees. Gameplay-critical readability.
func telegraph_circle(pos: Vector3, radius: float, dur: float, col: Color = Color(1, 0.25, 0.15), hostile: bool = true) -> Node3D:
	var t := Telegraph.new()
	t.hostile = hostile and col.r > 0.8 and col.b < 0.5
	add_child(t)
	t.setup_circle(pos, radius, dur, col)
	return t

func telegraph_rect(origin: Vector3, dir: Vector3, length: float, width: float, dur: float, col: Color = Color(1, 0.25, 0.15), hostile: bool = true) -> Node3D:
	var t := Telegraph.new()
	t.hostile = hostile and col.r > 0.8 and col.g < 0.5
	add_child(t)
	t.setup_rect(origin, dir, length, width, dur, col)
	return t

func telegraph_arc(origin: Vector3, from_angle: float, to_angle: float, radius: float, dur: float, col: Color = Color(1, 0.25, 0.15), hostile: bool = true) -> Node3D:
	var t := Telegraph.new()
	t.hostile = hostile
	add_child(t)
	t.setup_arc(origin, from_angle, to_angle, radius, dur, col)
	return t

# ================= PROJECTILES =================
func spawn_projectile(from: Vector3, dir: Vector3, speed: float, max_dist: float, hit: Dictionary, team: String, homing: Node = null, style: String = "psychic") -> void:
	var p: Projectile = null
	for q in _projectiles:
		if not q.active:
			p = q
			break
	if p == null:
		if _projectiles.size() >= 48:
			return
		p = Projectile.new()
		add_child(p)
		_projectiles.append(p)
	p.launch(from, dir, speed, max_dist, hit, team, homing, style)

# ================= COMBAT MUSIC =================
func _update_combat_state() -> void:
	var l := leader()
	var engaged := false
	if l:
		for e in enemies:
			if is_instance_valid(e) and e.is_targetable() and e.hostile_now() and e.global_position.distance_to(l.global_position) < 22.0:
				engaged = true
				break
	if boss_active:
		Audio.music("boss")
		in_combat = true
		return
	if engaged != in_combat:
		in_combat = engaged
		Audio.music("combat" if engaged else music_explore)

## Terrain height helper (level provides terrain).
func height_at(x: float, z: float) -> float:
	if level and level.has_method("height_at"):
		return level.height_at(x, z)
	return 0.0
