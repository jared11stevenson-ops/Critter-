extends Node3D
## The Red Reaches — "The Red Span Survey" field level (Agent 2).
## Instances Agent 1's terrain builder (or the in-house fallback), spawns the party, encounters,
## triggers, pickups and interactables from layout.json, and runs the beat flow (GDD §7).
## Every beat handler is idempotent and keyed on world flags so checkpoints / reloads never dead-end.

const TERRAIN_PATH := "res://game/world/red_reaches/terrain_builder.gd"
const FALLBACK_TERRAIN := "res://game/world/red_reaches/level_fallback_terrain.gd"
const LAYOUT := "res://game/world/red_reaches/layout.json"
const HUB := "res://game/world/hub/hub.tscn"

var layout: Dictionary = {}
var terrain: Node3D
var field: Field
var party: PartyController
var cam: CameraRig
var hud: Hud
var runner: DialogueRunner
var scanner: Scanner
var actors_root: Node3D

var _fired: Dictionary = {}          # trigger id -> true (this session)
var _interactables: Array = []       # Dictionaries
var _active_interact: Dictionary = {}
var _markers3d: Dictionary = {}
var _obj_t := 0.0
var _objective := ""
var mites: Array = []
var drill_enemies: Array = []
var beetles: Array = []
var pylons: Array = []
var grazers: Array = []
var boss: AugurRig = null
var rivals: RivalEncounters = null
var replay := false                  # Return Descent: the Reaches are cleared; the rivals are out there
var _run_ended := false
var _barrier_boulder: StaticBody3D = null
var _events_seen: Dictionary = {}
var _fade: ColorRect
var region: RegionRunner = null      # generic region recipe runner (side areas, sites, descent events)
var _spoke_signs: Array = []
var _spoke_tick := 0.0
var extra: Dictionary = {}           # world_extra.json: settlements, loot, signs, extra sites/secrets
var settlements: RrSettlements = null
var ambient: RrAmbient = null
var npcs: NpcLife = null
var _marker_mesh: ArrayMesh = null
var _marker_mats: Array = []
const EXTRA := "res://game/world/red_reaches/world_extra.json"
const CANON_NPCS := "res://game/canon/npcs/red_reaches.json"
const NPC_DATA := "res://game/world/red_reaches/rr_npcs.json"

# burden
var burden_active := false
var _burden_p := 0.0
var _burden_strain := 0.0
var _burden_tremor := 0.0
var _convoy: Node3D = null
var _burden_shake_t := 0.0

func _ready() -> void:
	var _t0 := Time.get_ticks_msec()
	_load_layout()
	field = Field.new()
	field.name = "Field"
	field.level = self
	field.music_explore = "explore_reaches"
	add_child(field)
	_build_terrain()
	var _t1 := Time.get_ticks_msec()
	actors_root = Node3D.new()
	actors_root.name = "Actors"
	add_child(actors_root)
	cam = CameraRig.new()
	cam.name = "CameraRig"
	add_child(cam)
	field.camera_rig = cam
	party = PartyController.new()
	party.name = "Party"
	add_child(party)
	field.party = party
	scanner = Scanner.new()
	scanner.name = "Scanner"
	add_child(scanner)
	party.scanner = scanner
	var spawn := _spawn_points()
	party.spawn(spawn[0], spawn[1], actors_root)
	cam.set_target(party.get_leader(), true)
	runner = DialogueRunner.new()
	runner.name = "Dialogue"
	add_child(runner)
	runner.event_emitted.connect(_on_dialogue_event)
	runner.finished.connect(_on_dialogue_finished)
	region = RegionRunner.new()
	region.setup("red_reaches", self)
	var ex: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXTRA)) if FileAccess.file_exists(EXTRA) else null
	if ex is Dictionary:
		extra = ex
		region.merge_extra(extra)
	rivals = RivalEncounters.new()
	rivals.name = "Rivals"
	add_child(rivals)
	rivals.setup(self, runner)
	hud = Hud.new()
	hud.name = "HUD"
	hud.setup(field, party)
	add_child(hud)
	field.hud = hud
	_build_fade()
	_build_world_life()
	_build_interactables()
	replay = bool(GameState.get_flag("rr_complete", false))
	_spawn_content()
	_spawn_spokes()
	if replay:
		rivals.spawn_all()
	_apply_world_state()
	Events.codex_unlocked.connect(_on_codex)
	Events.boss_phase_changed.connect(_on_boss_phase)
	Audio.music("explore_reaches")
	GameState.chapter = "red_reaches"
	GameState.flags["_scene"] = "red_reaches"
	GameState.unlock_codex("place_red_reaches")
	GameState.unlock_codex("char_aruun")
	GameState.unlock_codex("char_cigarra")
	Events.scene_ready.emit("red_reaches")
	_begin_ledger_run()
	_update_objective(true)
	if OS.get_cmdline_user_args().has("qa"):
		print("[PERF] level _ready ms total=%d terrain=%d" % [Time.get_ticks_msec() - _t0, _t1 - _t0])

# ================= setup =================
func _load_layout() -> void:
	var f := FileAccess.open(LAYOUT, FileAccess.READ)
	if f:
		var d: Variant = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			layout = d

func _build_terrain() -> void:
	var path := TERRAIN_PATH if ResourceLoader.exists(TERRAIN_PATH) else FALLBACK_TERRAIN
	var scr: Variant = load(path)
	if scr is Script and (scr as Script).can_instantiate():
		terrain = (scr as Script).new()
	if terrain == null:
		terrain = load(FALLBACK_TERRAIN).new()
	terrain.name = "Terrain"
	add_child(terrain)
	if terrain.has_method("build"):
		terrain.build()

func marker(n: String) -> Vector3:
	if terrain and terrain.has_method("get_marker"):
		var v: Variant = terrain.get_marker(n)
		if v is Vector3 and v != Vector3.ZERO:
			return v
	var m: Variant = layout.get("markers", {}).get(n, null)
	if m is Array:
		return Vector3(m[0], m[1], m[2])
	return Vector3.ZERO

func _trigger(id: String) -> Dictionary:
	for t in layout.get("triggers", []):
		if t.get("id", "") == id:
			return t
	return {}

func _tpos(t: Dictionary) -> Vector3:
	var p: Array = t.get("pos", [0, 0, 0])
	return Vector3(p[0], p[1], p[2])

func ground(p: Vector3, lift: float = 0.2) -> Vector3:
	return Vector3(p.x, height_at(p.x, p.z) + lift, p.z)

func _spawn_points() -> Array:
	var cp := str(GameState.get_flag("_checkpoint", ""))
	var lp := marker("player_spawn")
	var pp := marker("partner_spawn")
	if cp != "" and cp != "t_arrival":
		var t := _trigger(cp)
		if not t.is_empty():
			lp = _tpos(t)
			pp = lp + Vector3(-2.0, 0, 1.2)
	if cp == "" and bool(GameState.get_flag("rr_complete", false)):
		# Return Descent: drop in at the Waystation, with the whole road behind and the rivals ahead
		var tw := _trigger("t_waystation")
		if not tw.is_empty():
			lp = _tpos(tw)
			pp = lp + Vector3(-2.0, 0, 1.2)
	if cp == "t_burden" and not bool(GameState.get_flag("burden_done", false)):
		lp = _tpos(_trigger("t_span"))
		pp = lp + Vector3(-2.0, 0, 1.2)
	return [ground(lp, 0.3), ground(pp, 0.3)]

func _build_fade() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 90
	add_child(cl)
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.03, 0.03, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_fade)

# ================= terrain queries (used by actors / AI) =================
func _on_span(x: float, z: float) -> bool:
	return x > 244.0 and x < 298.0 and absf(z) < 3.4

func _on_rope(x: float, z: float) -> bool:
	return bool(GameState.get_flag("rope_dropped", false)) and x > 84.5 and x < 99.5 and absf(z + 1.0) < 1.3

func height_at(x: float, z: float) -> float:
	if _on_span(x, z):
		return -2.0
	if _on_rope(x, z):
		return lerpf(-4.0, -3.0, clampf((x - 85.0) / 14.0, 0.0, 1.0))
	if terrain and terrain.has_method("height_at"):
		return terrain.height_at(x, z)
	return 0.0

func is_hazard(x: float, z: float) -> bool:
	return height_at(x, z) < -12.0

func _barrier_blocks(a: Vector3, b: Vector3) -> bool:
	var bars := [[92.0, "rope_dropped"], [151.0, "boulder_broken"]]
	for br in bars:
		var bx: float = br[0]
		if (a.x - bx) * (b.x - bx) < 0.0 and not bool(GameState.get_flag(br[1], false)):
			return true
	return false

func can_partner_reach(a: Vector3, b: Vector3) -> bool:
	return not _barrier_blocks(a, b)

func path_clear(a: Vector3, b: Vector3) -> bool:
	if _barrier_blocks(a, b):
		return false
	var d := b - a
	d.y = 0
	var n := int(d.length() / 1.5)
	for i in range(1, n + 1):
		var p := a + d * (float(i) / float(n + 1))
		if is_hazard(p.x, p.z):
			return false
	return true

func safe_point_near(p: Vector3, _who: Node) -> Vector3:
	if is_hazard(p.x, p.z):
		var cp := _trigger(str(GameState.get_flag("_checkpoint", "t_arrival")))
		return ground(_tpos(cp) if not cp.is_empty() else marker("player_spawn"), 0.4)
	return ground(p, 0.4)

# ================= content =================
func spawn_enemy(species: String, pos: Vector3) -> EnemyBase:
	var e := EnemyBase.create(species)
	actors_root.add_child(e)
	e.global_position = ground(pos, 0.3)
	e.home = e.global_position
	return e

func spawn_pickup(kind: String, pos: Vector3, n: int = -1, key: String = "") -> LevelPickup:
	var amt := n if n > 0 else int(Balance.v("pickups.amount." + kind, 1))
	amt = maxi(1, roundi(float(amt) * Director.pickup_mult()))
	var p := LevelPickup.new()
	p.setup(kind, amt, key)
	actors_root.add_child(p)
	p.global_position = ground(pos, 0.0)
	return p

func _spawn_content() -> void:
	# pickups (persisted by index)
	var i := 0
	for pk in layout.get("pickups", []):
		var key := "_pk_%d" % i
		i += 1
		if bool(GameState.flags.get(key, false)):
			continue
		var pp: Array = pk["pos"]
		spawn_pickup(pk["kind"], Vector3(pp[0], pp[1], pp[2]), -1, key)
	# loot from the region loot_table, placed near its sources (persisted per spot)
	var li := 0
	for lt in extra.get("loot", []):
		var lkey := "_loot_%d" % li
		li += 1
		if bool(GameState.flags.get(lkey, false)):
			continue
		var lp: Array = lt["p"]
		spawn_pickup(str(lt["item"]), Vector3(float(lp[0]), 0.0, float(lp[1])), 1, lkey)
	# Fracture Valley mites
	if not bool(GameState.get_flag("valley_clear", false)):
		_spawn_swarm(marker("encounter_valley"), 5)
		_spawn_swarm(marker("encounter_valley") + Vector3(14, 0, -3), 4)
	# Waystation grazer herd (keystone wildlife — they stay unless harmed/contained)
	var gh := marker("grazer_herd")
	for k in 5:
		var g := spawn_enemy("dust_grazer", gh + Vector3(randf_range(-5, 5), 0, randf_range(-4, 4)))
		g.set("herd_center", gh)
		grazers.append(g)
	# Drill site
	if not bool(GameState.get_flag("drill_clear", false)):
		for k in 3:
			if bool(GameState.flags.get("_pylon_%d" % (k + 1), false)):
				continue
			var py := spawn_enemy("resonance_pylon", marker("pylon_%d" % (k + 1)))
			py.set("pylon_id", "pylon_%d" % (k + 1))
			py.died.connect(_on_pylon_destroyed)
			pylons.append(py)
		for k in 2:
			var b := spawn_enemy("plate_beetle", marker("beetle_%d" % (k + 1)))
			b.removed.connect(_on_drill_enemy_gone)
			beetles.append(b)
			drill_enemies.append(b)
		var dc := marker("encounter_drill")
		for k in 3:
			var d := spawn_enemy("dominion_drone", dc + Vector3(cos(k * 2.1) * 7.0, 0, sin(k * 2.1) * 7.0))
			d.removed.connect(_on_drill_enemy_gone)
			drill_enemies.append(d)
		_update_beetle_calm()
	# Boss
	if not bool(GameState.get_flag("boss_defeated", false)):
		boss = EnemyBase.create("augur_rig") as AugurRig
		actors_root.add_child(boss)
		boss.global_position = ground(marker("boss_pos"), 0.0)
		boss.defeated.connect(_on_boss_defeated)
	# invisible barrier at the cracked boulder until it breaks (no squeezing past)
	if not bool(GameState.get_flag("boulder_broken", false)):
		_barrier_boulder = StaticBody3D.new()
		_barrier_boulder.collision_layer = 1
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(1.5, 8.0, 18.0)
		cs.shape = bs
		_barrier_boulder.add_child(cs)
		add_child(_barrier_boulder)
		var bp := _structure_pos("thought_boulder", Vector3(151, -3.5, 3.5))
		_barrier_boulder.global_position = Vector3(bp.x, bp.y + 3.0, bp.z - 1.0)

func _spawn_swarm(center: Vector3, n: int) -> void:
	var swarm: Array = []
	for k in n:
		var a := TAU * float(k) / float(n)
		var m := spawn_enemy("skitter_mite", center + Vector3(cos(a) * 2.5, 0, sin(a) * 2.5))
		(m as SkitterMite).swarm = swarm
		swarm.append(m)
		m.removed.connect(_on_mite_gone)
		mites.append(m)

func _structure_pos(id: String, fallback: Vector3) -> Vector3:
	for s in layout.get("structures", []):
		if s.get("id", "") == id and s.has("pos"):
			var p: Array = s["pos"]
			return Vector3(p[0], p[1], p[2])
	return fallback

func _apply_world_state() -> void:
	if terrain == null:
		return
	if terrain.has_method("set_rope_span_visible"):
		terrain.set_rope_span_visible(bool(GameState.get_flag("rope_dropped", false)))
	if bool(GameState.get_flag("boulder_broken", false)) and terrain.has_method("break_boulder"):
		terrain.break_boulder()
	var st := str(GameState.get_flag("ochre_span", ""))
	if terrain.has_method("set_span_state"):
		terrain.set_span_state(st if st != "" else "intact")

# ================= interactables =================
func _build_interactables() -> void:
	_interactables = [
		{"id": "leap", "pos": marker("leap_a"), "r": 3.2, "label": "Leap (Grasshopper)", "cond": func(): return not bool(GameState.get_flag("rope_dropped", false)), "act": _do_leap},
		{"id": "marker_stone", "pos": _structure_pos("old_road_marker", marker("waystation_talk")), "r": 3.2, "label": "Read Marker", "cond": func(): return not ("old_roads" in GameState.codex), "act": _do_marker},
		{"id": "boulder", "pos": marker("boulder_interact"), "r": 3.6, "label": "Reaching Strike", "cond": func(): return not bool(GameState.get_flag("boulder_broken", false)), "act": _do_boulder},
		{"id": "choice", "pos": marker("choice_point"), "r": 3.6, "label": "Decide", "cond": func(): return bool(GameState.get_flag("boss_defeated", false)) and str(GameState.get_flag("ochre_span", "")) == "", "act": _do_choice},
		{"id": "exfil", "pos": marker("exfil_beacon"), "r": 3.6, "label": "Exfil", "cond": func(): return str(GameState.get_flag("ochre_span", "")) != "", "act": _do_exfil},
	]
	if region:
		_interactables.append_array(region.interactables())
	if npcs:
		# NPCs own their quests / descent events: drop the stand-alone sites for them
		var drop: Array = []
		for q in npcs.owned_quests():
			drop.append("rg_quest_" + str(q))
		_interactables = _interactables.filter(func(it): return not drop.has(str(it["id"])))
		_interactables.append_array(npcs.interactables())
		_interactables.append_array(npcs.ambient_interactables())
	_marker_mesh = _make_marker_mesh()
	_marker_mats = [ToonKit.glow(UiKit.ACCENT_2, 1.4), ToonKit.glow(UiKit.PSI, 1.6)]
	for it in _interactables:
		if it.get("nomark", false):
			continue
		var mk := MeshInstance3D.new()
		mk.mesh = _marker_mesh
		mk.material_override = _marker_mats[0]
		mk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mk.visible = false
		add_child(mk)
		mk.global_position = ground(it["pos"], 2.6)
		_markers3d[it["id"]] = mk

## A small spinning 3D diamond (two pyramids) over every interactable: one shared mesh + material, no sprites or glyphs.
func _make_marker_mesh() -> ArrayMesh:
	var st := ToonKit.begin()
	var r := 0.26
	var top := Vector3(0, 0.42, 0)
	var bot := Vector3(0, -0.42, 0)
	var ring := [Vector3(r, 0, 0), Vector3(0, 0, r), Vector3(-r, 0, 0), Vector3(0, 0, -r)]
	for i in 4:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		ToonKit.tri(st, top, b, a, Color.WHITE)
		ToonKit.tri(st, bot, a, b, Color(0.8, 0.8, 0.8))
	return ToonKit.finish(st)

## Settlements, NPCs, ambience and loot of the living region.
func _build_world_life() -> void:
	var _w0 := Time.get_ticks_msec()
	ambient = RrAmbient.new()
	ambient.name = "Ambient"
	add_child(ambient)
	ambient.setup(self, height_at, player_position)
	settlements = RrSettlements.new()
	settlements.name = "Settlements"
	add_child(settlements)
	settlements.build(extra, height_at)
	npcs = NpcLife.new()
	npcs.name = "Npcs"
	add_child(npcs)
	npcs.setup(self, NPC_DATA, CANON_NPCS, region, runner, player_position, height_at, func() -> String: return ambient.phase, "red_reaches")
	npcs.hide_fn = func(id: String) -> bool:
		# the claims broker is a truce form of the Undermarket rival: hide him while the rival fight is on the field
		return id == "vesk_dunmore" and rivals != null and not rivals.live.is_empty() and rivals.any_engaged()
	if OS.get_cmdline_user_args().has("qa"):
		print("[PERF] world life (ambient+settlement dispatch+npcs) ms=%d" % (Time.get_ticks_msec() - _w0))

## Optional side areas: a faint signpost at each unvisited spoke entrance, plus the spoke's guardians/wildlife.
func _spawn_spokes() -> void:
	if region == null:
		return
	for sid in region.recipe.get("spokes", []).map(func(x): return x["id"]):
		var sp: Dictionary = region.spoke(sid)
		var tp: Array = sp["trigger"]["pos"]
		if not bool(GameState.flags.get("_spoke_" + sid, false)):
			var l := Label3D.new()
			l.text = "< %s >" % str(sp.get("name", sid))
			l.font_size = 48
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.fixed_size = true
			l.pixel_size = 0.0009
			l.no_depth_test = true
			l.outline_size = 8
			l.modulate = Color(UiKit.PARCHMENT, 0.8)
			l.visible = false
			add_child(l)
			# The sign stands at the junction on the critical path, not at the spoke itself.
			var sgp := Vector3(float(tp[0]), float(tp[1]), float(tp[2]))
			for sg in extra.get("signs", []):
				if str(sg["spoke"]) == sid:
					sgp = Vector3(float(sg["p"][0]), 0.0, float(sg["p"][1]))
			l.global_position = ground(sgp, 3.2)
			_spoke_signs.append({"node": l, "id": sid})
		var swarm: Array = []
		for sw in sp.get("spawn", []):
			var at: Array = sw.get("at", tp)
			for k in int(sw.get("n", 1)):
				var a := TAU * float(k) / float(maxi(1, int(sw.get("n", 1))))
				var e := spawn_enemy(str(sw["species"]), Vector3(float(at[0]) + cos(a) * 2.5, float(at[1]), float(at[2]) + sin(a) * 2.5))
				if e is SkitterMite:
					(e as SkitterMite).swarm = swarm
					swarm.append(e)

func player_position() -> Vector3:
	return party.get_leader().global_position if party and party.get_leader() else Vector3.ZERO

func _spoke_sign_tick() -> void:
	var l := party.get_leader()
	for ss in _spoke_signs:
		var n: Label3D = ss["node"]
		var gone: bool = bool(GameState.flags.get("_spoke_" + str(ss["id"]), false))
		n.visible = not gone and n.global_position.distance_squared_to(l.global_position) < 1400.0
		if gone:
			_spoke_signs.erase(ss)
			n.queue_free()
			return

func _interact_tick(delta: float) -> void:
	var l := party.get_leader()
	var best: Dictionary = {}
	var bd := INF
	for it in _interactables:
		var ok: bool = (it["cond"] as Callable).call()
		var mk: Node3D = _markers3d.get(it["id"], null)
		if mk:
			mk.visible = ok
		if not ok:
			continue
		var ip: Vector3 = (it["pos_fn"] as Callable).call() if it.has("pos_fn") else it["pos"]
		if mk:
			mk.position = Vector3(ip.x, height_at(ip.x, ip.z) + float(it.get("y_off", 2.6)) + sin(Time.get_ticks_msec() * 0.004) * 0.2, ip.z)
			mk.rotation.y += delta * 1.8
		if mk and it.has("hot"):
			var hot: bool = (it["hot"] as Callable).call()
			(mk as MeshInstance3D).material_override = _marker_mats[1 if hot else 0]
		var d := Vector2(l.global_position.x - ip.x, l.global_position.z - ip.z).length()
		if d < float(it["r"]) and d < bd:
			bd = d
			best = it
	if best != _active_interact:
		_active_interact = best
		hud.set_interact(best.get("label", "") if not best.is_empty() else "")
	if not best.is_empty() and Input.is_action_just_pressed("interact") and party.input_enabled and not burden_active:
		(best["act"] as Callable).call()

func _do_leap() -> void:
	var c := party.get_member("cigarra")
	if c.downed:
		Events.toast.emit("Revive Cigarra first", "warning")
		return
	if party.get_leader().char_id != "cigarra":
		party.swap_to("cigarra")
		Events.toast.emit("Cigarra: \"Gaps are just bridges nobody's thought of yet.\"", "info")
	c.teleport(ground(marker("leap_a"), 0.2))
	(c.kit as CigarraKit).grasshopper(ground(marker("leap_b"), 0.1), _on_cigarra_landed)
	party.clear_trail()

func _on_cigarra_landed() -> void:
	GameState.set_flag("_cig_across", true)
	_say("rr_rope")

func _do_marker() -> void:
	GameState.unlock_codex("old_roads")
	_say("rr_marker_stone")

func _do_boulder() -> void:
	if party.get_leader().char_id != "aruun":
		party.swap_to("aruun")
	var a := party.get_member("aruun")
	var bp := _structure_pos("thought_boulder", Vector3(151, -3.5, 3.5))
	a.face_toward(bp - a.global_position)
	a.in_aim = Vector3.ZERO
	if a.kit.cd[0] > 0.0:
		a.kit.cd[0] = 0.0
	a.kit.cast(0)

func _do_choice() -> void:
	if GameState.item_count("thoughtstone_cache") <= 0:
		GameState.add_item("thoughtstone_cache", 1)
	_say("rr_choice")

func _do_exfil() -> void:
	_say("rr_exfil")

# ================= scannables & hooks =================
func get_scannables() -> Array:
	var out: Array = []
	out.append({"id": "marker", "pos": _structure_pos("old_road_marker", Vector3(112, -3, -13)), "tag": "SACRED", "name": "Old Road Marker", "line2": "glyphs seen continents apart", "h": 3.4})
	if not bool(GameState.get_flag("boulder_broken", false)):
		out.append({"id": "boulder", "pos": _structure_pos("thought_boulder", Vector3(151, -3.5, 3.5)), "tag": "RESOURCE", "name": "Cracked Thoughtstone", "line2": "Reaching Strike can shatter it", "h": 6.0})
	out.append({"id": "ochre_span", "pos": Vector3(250, -2, 0), "tag": "STRUCTURE", "name": "The Ochre Span", "line2": "Spanwright crossing · stressed", "h": 3.0, "codex": "place_ochre_span"})
	out.append({"id": "gate", "pos": _structure_pos("gate_ring", Vector3(-7, 0, -4)), "tag": "STRUCTURE", "name": "Gate", "line2": "Terrarium One link", "h": 9.0})
	out.append({"id": "camp", "pos": _structure_pos("drill_camp", Vector3(208, -6, 26)), "tag": "DOMINION ASSET", "name": "Survey Camp", "line2": "permit: D. Mane", "h": 3.5})
	return out

func on_scan(first_species: Array) -> void:
	if region and party and party.get_leader():
		region.reveal_near(party.get_leader().global_position, 18.0)
	if not bool(GameState.get_flag("first_scan_done", false)):
		GameState.set_flag("first_scan_done", true)
		_say("rr_first_scan")
	if "plate_beetle" in first_species or (not bool(GameState.get_flag("beetle_scanned", false)) and _beetle_in_scan()):
		GameState.set_flag("beetle_scanned", true)
		_say("rr_beetle_scanned")
	_update_objective()

func _beetle_in_scan() -> bool:
	var l := party.get_leader()
	for b in beetles:
		if is_instance_valid(b) and b.alive and b.global_position.distance_to(l.global_position) < Balance.f("global.scan_radius", 25.0):
			return true
	return false

func on_scanned_object(id: String) -> void:
	# Reading the Dominion survey camp's permit turns up paperwork that does not match: evidence
	# (unlocks "Expose them" against any rival, see rivals.json resolutions).
	if id == "camp" and not Ledger.exists({"type": "discovered", "target": "survey_camp"}):
		Ledger.record("discovered", "player", "survey_camp", ["evidence", "discovery"], {}, 2)
		Events.toast.emit("Evidence logged: the camp's permit does not match the survey on file", "codex")

func on_enemy_hit(e: Node, hit: Dictionary) -> void:
	if e is DustGrazer:
		var src: Node = hit.get("source", null)
		if src and src.get("team") == "party" and not bool(GameState.get_flag("grazers_harmed", false)):
			GameState.set_flag("grazers_harmed", true)
			_say("rr_grazers_harmed")

func breakable_dir(origin: Vector3, dir: Vector3, reach: float) -> Variant:
	if bool(GameState.get_flag("boulder_broken", false)):
		return null
	var bp := _structure_pos("thought_boulder", Vector3(151, -3.5, 3.5))
	var to := bp - origin
	to.y = 0
	if to.length() < reach + 3.6 and (dir.angle_to(to.normalized()) < 1.2 or to.length() < 7.0):
		return to.normalized()
	return null

func on_line_strike(origin: Vector3, dir: Vector3, length: float, ability: String) -> void:
	if ability != "reaching_strike" or bool(GameState.get_flag("boulder_broken", false)):
		return
	var bp := _structure_pos("thought_boulder", Vector3(151, -3.5, 3.5))
	var rad := 3.6
	var to := bp - origin
	to.y = 0
	var along := clampf(to.dot(dir), 0.0, length)
	var perp := (to - dir * along).length()
	if perp < rad + 1.2 and to.length() < length + rad + 0.5:
		_break_boulder(bp)

func _break_boulder(bp: Vector3) -> void:
	GameState.set_flag("boulder_broken", true)
	if terrain.has_method("break_boulder"):
		terrain.break_boulder()
	if _barrier_boulder:
		_barrier_boulder.queue_free()
		_barrier_boulder = null
	Audio.sfx_at("boulder_break", bp)
	field.vfx("thoughtstone_shards", bp + Vector3(0, 1.5, 0))
	# the impact puff follows a beat later so the shards, the strike beam and the puff never share one frame's draw budget
	get_tree().create_timer(0.3).timeout.connect(func(): field.vfx("heavy_impact", bp + Vector3(0, 1.5, 0)))
	field.impact("boss")
	spawn_pickup("thoughtstone_dust", bp + Vector3(-3.5, 0, -1.5), 2)
	_say("rr_boulder_broken")
	_checkpoint("t_boulder")
	_update_objective()

# ================= triggers / beats =================
func _physics_process(_delta: float) -> void:
	var l := party.get_leader() if party else null
	if l == null:
		return
	for t in layout.get("triggers", []):
		var id: String = t["id"]
		if _fired.has(id):
			continue
		var p := _tpos(t)
		var d := Vector2(l.global_position.x - p.x, l.global_position.z - p.z).length()
		if d < float(t.get("r", 4.0)) and absf(l.global_position.y - p.y) < 8.0:
			_fired[id] = true
			_fire_trigger(id, str(t.get("event", "")))

func _fire_trigger(id: String, ev: String) -> void:
	Events.trigger_entered.emit(ev)
	if ev.begins_with("spoke:"):
		if region:
			region.enter_spoke(ev.substr(6))
		return
	_checkpoint(id)
	if rivals:
		rivals.on_trigger(ev)
	match ev:
		"arrival":
			GameState.set_flag("arrived_rr", true)
			_say("rr_arrival")
		"valley_enter":
			_say("rr_valley")
		"gap_reached":
			_say("rr_gap")
		"waystation_enter":
			_say("rr_waystation")
		"boulder_seen":
			_say("rr_boulder")
		"drill_enter":
			_say("rr_drill")
		"span_enter":
			GameState.unlock_codex("place_ochre_span")
			_say("rr_span")
		"span_burden":
			if not bool(GameState.get_flag("burden_done", false)):
				if not _say("rr_burden"):
					_start_burden()
		"boss_start":
			if boss and not bool(GameState.get_flag("boss_defeated", false)):
				if DialogueRunner.seen("rr_boss_intro") or not _say("rr_boss_intro"):
					_start_boss()
	_update_objective()

# ================= Ledger run =================
func _begin_ledger_run() -> void:
	Director.attach()
	Director.reset_run()
	if Ledger.current_region != "red_reaches":
		Ledger.begin_run("red_reaches")
		GameState.flags["_returned_pending"] = false
	GameState.save_game()

func _end_ledger_run() -> void:
	if _run_ended:
		return
	_run_ended = true
	if rivals:
		rivals.on_leave_level()
	var all_conscious := true
	for m in party.members:
		if m.downed:
			all_conscious = false
	Ledger.end_run(all_conscious)
	GameState.flags["_returned_pending"] = true

func _checkpoint(id: String) -> void:
	GameState.flags["_checkpoint"] = id
	GameState.flags["_scene"] = "red_reaches"
	GameState.save_game()

## Plays a dialogue once (by seen-flag). Returns true if it started (or queued).
func _say(id: String, force: bool = false) -> bool:
	if not force and DialogueRunner.seen(id):
		_ensure_after(id)
		return false
	var ok := runner.play(id)
	if not ok:
		_ensure_after(id)
	return ok

func _on_dialogue_event(ev: String) -> void:
	if npcs and npcs.handle_event(ev):
		return
	if region and region.handle_dialogue_event(ev):
		return
	_events_seen[ev] = true
	match ev:
		"drop_rope": _drop_rope()
		"start_burden": _start_burden.call_deferred()
		"start_boss": _start_boss.call_deferred()
		"choice_repair": _choice("repair")
		"choice_extract": _choice("extract")
		"thoughtstone_align": _thoughtstone_align()
		"exfil": _exfil.call_deferred()
	_update_objective()

func _on_dialogue_finished(id: String) -> void:
	_ensure_after(id)
	_update_objective()

## Guarantees each beat's critical effect happens even if the dialogue file omits its event.
func _ensure_after(id: String) -> void:
	match id:
		"rr_rope":
			if bool(GameState.get_flag("_cig_across", false)):
				_drop_rope()
		"rr_waystation":
			if not bool(GameState.get_flag("combo_unlocked", false)):
				runner._emit_event("unlock_combo")
		"rr_burden":
			if not bool(GameState.get_flag("burden_done", false)) and not burden_active and _fired.has("t_burden"):
				_start_burden.call_deferred()
		"rr_boss_intro":
			if boss and not boss.active and not bool(GameState.get_flag("boss_defeated", false)):
				_start_boss.call_deferred()
		"rr_choice":
			if str(GameState.get_flag("ochre_span", "")) == "" and bool(GameState.get_flag("boss_defeated", false)):
				_fallback_choice.call_deferred()
		"rr_after_choice":
			if not _events_seen.has("thoughtstone_align"):
				_thoughtstone_align()
		"rr_exfil":
			_exfil.call_deferred()

func _fallback_choice() -> void:
	if runner.active:
		return
	runner.play_data("rr_choice_fallback", {"lines": [
		{"who": "aruun", "expr": "focused", "text": "The cache can brace the foundation. Or it goes to the Dominion contract. Your call, Handler."},
		{"choice": [{"text": "Brace the foundation (spend the Thoughtstone)", "event": "choice_repair"}, {"text": "Hand the cache to the Dominion contract", "event": "choice_extract"}]},
	]})

# ---------------- rope ----------------
func _drop_rope() -> void:
	if bool(GameState.get_flag("rope_dropped", false)):
		return
	GameState.set_flag("rope_dropped", true)
	if terrain.has_method("set_rope_span_visible"):
		terrain.set_rope_span_visible(true)
	Audio.sfx_at("rope_unroll", marker("rope_anchor"))
	field.vfx("rope_unroll", marker("rope_anchor"))
	# Aruun crosses the new rope span to join her
	var a := party.get_member("aruun")
	if a and a != party.get_leader() and a.global_position.x < 92.0:
		var y0 := marker("leap_a").y
		a.scripted_move([ground(Vector3(84.0, y0, -1.0), 0.2), Vector3(86.0, -3.9, -1.0), Vector3(98.5, -3.0, -1.0), ground(marker("leap_b") + Vector3(1.5, 0, 1.5), 0.2)])
	party.clear_trail()
	_checkpoint("t_gap")

# ---------------- encounters ----------------
func _on_mite_gone(_m: Node) -> void:
	for m in mites:
		if is_instance_valid(m) and m.alive:
			return
	if not bool(GameState.get_flag("valley_clear", false)):
		GameState.set_flag("valley_clear", true)
		_say("rr_valley_clear")
		_checkpoint("t_valley")
		_update_objective()

func _on_pylon_destroyed(p: Node) -> void:
	var pid: String = p.get("pylon_id")
	GameState.flags["_" + pid] = true
	var n: int = int(GameState.get_flag("pylons_down", 0)) + 1
	GameState.set_flag("pylons_down", n)
	Events.toast.emit("Resonance pylon destroyed (%d/3)" % n, "info")
	_update_beetle_calm()
	if n >= 3:
		_say("rr_pylons_done")
	_update_objective()

func _update_beetle_calm() -> void:
	var r := Balance.f("enemies.plate_beetle.pylon_radius", 32.0)
	for b in beetles:
		if not is_instance_valid(b) or not b.alive or not b.agitated:
			continue
		var near := false
		for p in pylons:
			if is_instance_valid(p) and p.alive and p.global_position.distance_to(b.global_position) < r:
				near = true
		if not near:
			b.calm_down()

func _on_drill_enemy_gone(e: Node) -> void:
	if e is PlateBeetle:
		_beetle_outcomes.append(not e.agitated and not e.was_contained() and e.hp > 0.0)
	for x in drill_enemies:
		if is_instance_valid(x) and x.alive:
			return
	if bool(GameState.get_flag("drill_clear", false)):
		return
	var all_calm := _beetle_outcomes.size() > 0
	for ok in _beetle_outcomes:
		if not ok:
			all_calm = false
	if all_calm:
		GameState.set_flag("beetles_calmed", true)
		GameState.add_trust("aruun", 2)
	GameState.set_flag("drill_clear", true)
	_say("rr_drill_clear")
	_checkpoint("t_drill")
	_update_objective()

var _beetle_outcomes: Array = []

func _on_codex(id: String) -> void:
	hud.toast("Codex updated: %s" % CodexData.title(id), "codex")

# ---------------- burden ----------------
func _start_burden() -> void:
	if burden_active or bool(GameState.get_flag("burden_done", false)):
		return
	burden_active = true
	var a := party.get_member("aruun")
	var c := party.get_member("cigarra")
	if a.downed:
		a.revive(0.5)
	if c.downed:
		c.revive(0.5)
	if party.get_leader().char_id != "aruun":
		party.swap_to("aruun")
		Events.toast.emit("Aruun: \"Only one of us can carry this. Go.\"", "info")
	party.locked_leader = "aruun"
	party.ai_enabled = false
	var bpnt := ground(marker("span_burden_point"), 0.2)
	a.teleport(bpnt)
	a.state = "burden"
	a.face_toward(Vector3.RIGHT)
	c.teleport(ground(bpnt + Vector3(1.6, 0, 1.4), 0.2))
	_convoy = _make_convoy()
	c.add_child(_convoy)
	_convoy.position = Vector3(0, 2.3, 0)
	_burden_p = 0.0
	_burden_strain = 0.0
	_burden_tremor = 0.6
	hud.show_burden(true)
	cam.set_framing(bpnt + Vector3(12, 0, 0), 1.25)
	Audio.sfx_at("span_creak", bpnt)

func _make_convoy() -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.7, 1.0, 0.5)
	mi.material_override = m
	n.add_child(mi)
	var l := Label3D.new()
	l.text = "CONVOY MARKER"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = 0.0008
	l.font_size = 26
	l.outline_size = 8
	l.position.y = 0.7
	l.no_depth_test = true
	n.add_child(l)
	return n

func _burden_tick(delta: float) -> void:
	var a := party.get_member("aruun")
	var c := party.get_member("cigarra")
	var holding := hud.hold_pressed() or Input.is_action_pressed("attack") or Input.is_action_pressed("interact")
	var hold_time := Balance.f("burden.hold_time", 6.0) * Director.hold_time_mult()
	if holding:
		_burden_p = minf(1.0, _burden_p + delta / hold_time)
	_burden_tremor -= delta
	_burden_shake_t -= delta
	if _burden_tremor <= 0.0:
		_burden_tremor = Balance.f("burden.tremor_interval", 1.3)
		var mult := 1.0 if holding else 2.0
		var dmg := a.max_hp * Balance.f("burden.strain_per_tremor", 0.025) * mult
		dmg = minf(dmg, a.hp - 1.0)
		if dmg > 0.0:
			a.hp -= dmg
			a.hp_changed.emit(a.hp, a.max_hp)
			field.damage_number(a.global_position + Vector3(0, a.height + 0.3, 0), dmg, "strain")
		_burden_strain = clampf(_burden_strain + 0.12 * mult, 0.0, 1.0)
		if terrain.has_method("shake_span"):
			terrain.shake_span(1.5 * mult)
		field.shake(0.25 * mult)
		Audio.sfx_at("span_creak", a.global_position)
		a.vis("play_attack", "heavy")
		if not holding:
			Events.toast.emit("The span lurches! HOLD!", "warning")
	if holding and _burden_shake_t <= 0.0:
		_burden_shake_t = 0.35
		field.shake(0.07)
	# Cigarra runs the convoy marker across while Aruun holds
	var target_x := lerpf(a.global_position.x + 1.6, 302.0, _burden_p)
	var to := Vector3(target_x, 0, 0.0) - Vector3(c.global_position.x, 0, c.global_position.z)
	c.in_move = to.normalized() * clampf(to.length(), 0.0, 1.0) if to.length() > 0.3 else Vector3.ZERO
	a.in_move = Vector3.ZERO
	hud.set_burden(_burden_p, _burden_strain, holding)
	if _burden_p >= 1.0:
		_end_burden()

func _end_burden() -> void:
	burden_active = false
	var a := party.get_member("aruun")
	a.state = "normal"
	party.locked_leader = ""
	party.ai_enabled = true
	party.clear_trail()
	hud.show_burden(false)
	cam.set_framing(null)
	if _convoy:
		_convoy.queue_free()
		_convoy = null
	GameState.set_flag("burden_done", true)
	GameState.add_trust("aruun", 3)
	field.vfx("heal_motes", a.global_position)
	_say("rr_burden_done")
	_checkpoint("t_burden")
	_update_objective()

# ---------------- boss ----------------
func _start_boss() -> void:
	if boss == null or boss.active or bool(GameState.get_flag("boss_defeated", false)):
		return
	boss.activate()
	hud.set_boss(boss)
	cam.set_framing(boss.global_position + Vector3(-2, 0, 0), 1.45)
	Audio.music("boss")
	_update_objective()

func _on_boss_phase(p: int) -> void:
	if p == 2:
		_say("rr_boss_phase2")
	elif p == 3:
		_say("rr_boss_phase3")
	_update_objective()

func _on_boss_defeated() -> void:
	GameState.set_flag("boss_defeated", true)
	hud.set_boss(null)
	cam.set_framing(null)
	field.boss_active = false
	Audio.music("explore_reaches")
	var drop := ground(marker("choice_point") + Vector3(-3, 0, 2), 0.0)
	spawn_pickup("thoughtstone_cache", drop, 1, "_pk_cache")
	await get_tree().create_timer(1.6, false).timeout
	_say("rr_boss_down")
	_checkpoint("t_boss")
	_update_objective()

# ---------------- choice / ending ----------------
func _choice(kind: String) -> void:
	if str(GameState.get_flag("ochre_span", "")) != "":
		return
	if kind == "repair":
		GameState.spend_item("thoughtstone_cache", 1)
		GameState.add_trust("aruun", 10)
		GameState.set_flag("ochre_span", "braced")
		GameState.set_flag("ochre_span_braced", true)
		GameState.unlock_codex("lore_burden_architecture")
		Events.toast.emit("The Ochre Span is BRACED", "info")
	else:
		GameState.spend_item("thoughtstone_cache", 1)
		GameState.dominion_standing += 2
		GameState.add_item("salvage", 6)
		GameState.add_trust("aruun", -10)
		GameState.set_flag("ochre_span", "failing")
		GameState.set_flag("ochre_span_failing", true)
		Events.toast.emit("+6 Salvage · Dominion standing +2 · The Ochre Span is FAILING", "warning")
	if terrain.has_method("set_span_state"):
		terrain.set_span_state(str(GameState.get_flag("ochre_span", "intact")))
	GameState.save_game()
	_say.call_deferred("rr_after_choice")

func _thoughtstone_align() -> void:
	if _events_seen.has("_aligned"):
		return
	_events_seen["_aligned"] = true
	var a := party.get_member("aruun")
	# Canon (Bible XIV): a loose sliver on the ground turns until it points at Morrow — spawn it a few
	# metres in front of Aruun (toward the camera so the player sees it turn), aimed at him.
	var spot := a.global_position + Vector3(1.8, 0.0, 2.6)
	field.vfx("thoughtstone_align", spot, {"target": a, "duration": 4.5})
	GameState.unlock_codex("mystery_thoughtstone")
	field.request_time_scale("align", 0.5, 1.2)
	cam.add_shake(0.15)

func _exit_level() -> void:
	pass

func _exfil() -> void:
	if Router.is_busy():
		return
	_end_ledger_run()
	GameState.set_flag("rr_complete", true)
	GameState.flags["_scene"] = "hub"
	GameState.flags["_checkpoint"] = ""
	GameState.chapter = "debrief"
	GameState.save_game()
	Audio.sfx("gate_whoosh")
	Router.goto(HUB, "gate")

# ---------------- wipe ----------------
func on_party_wiped() -> void:
	Ledger.record("party_wipe", "player", "", ["casualty"], {}, 3)
	Director.on_wipe()
	if rivals:
		rivals.on_party_wiped()
	party.input_enabled = false
	Audio.sfx("downed")
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_fade, "color:a", 1.0, 0.8)
	await tw.finished
	var cp := _trigger(str(GameState.get_flag("_checkpoint", "t_arrival")))
	var p := _tpos(cp) if not cp.is_empty() else marker("player_spawn")
	if str(GameState.get_flag("_checkpoint", "")) == "t_burden" and not bool(GameState.get_flag("burden_done", false)):
		p = _tpos(_trigger("t_span"))
	party.respawn_at(ground(p, 0.4), ground(p + Vector3(-2, 0, 1.2), 0.4), Balance.f("global.respawn_hp_frac", 0.6))
	await get_tree().create_timer(0.4).timeout
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.8)
	party.input_enabled = true
	_say("rr_party_down", true)

# ---------------- per frame ----------------
func _process(delta: float) -> void:
	if party == null or party.members.is_empty():
		return
	_interact_tick(delta)
	if region:
		region.tick(party.get_leader().global_position, delta)
	_spoke_tick -= delta
	if _spoke_tick <= 0.0:
		_spoke_tick = 0.4
		_spoke_sign_tick()
	if burden_active:
		_burden_tick(delta)
	_obj_t -= delta
	if _obj_t <= 0.0:
		_obj_t = 0.5
		_update_objective()

func _update_objective(force: bool = false) -> void:
	var t := _compute_objective()
	if t != _objective or force:
		_objective = t
		Events.objective_changed.emit(t)

func _compute_objective() -> String:
	var f := func(n: String) -> bool: return bool(GameState.get_flag(n, false))
	var ro := rivals.objective_text() if rivals else ""
	if ro != "":
		return ro
	var lx: float = party.get_leader().global_position.x if party and party.get_leader() else 0.0
	if not f.call("valley_clear"):
		return "Descend into the Fracture Valley" if lx < 40.0 else "Drive off the Skitter Mite swarm"
	if not f.call("first_scan_done"):
		return "Tap SCAN (top-right) to read the valley"
	if not f.call("rope_dropped"):
		return "Head east to the Gap" if lx < 76.0 else "Cigarra: LEAP the gap from the marked ledge"
	if not f.call("boulder_broken"):
		return "Cross to the Spanwright Waystation and head east" if lx < 134.0 else "Aruun: shatter the cracked Thoughtstone (Reaching Strike)"
	if not f.call("drill_clear"):
		if lx < 166.0:
			return "Investigate the Dominion drill site"
		if not f.call("beetle_scanned"):
			return "Scan a Plate Beetle — why is it so agitated?"
		return "Destroy the resonance pylons (%d/3) · stop the drones" % int(GameState.get_flag("pylons_down", 0))
	if not f.call("burden_done"):
		return "Cross the Ochre Span"
	if not f.call("boss_defeated"):
		if boss and boss.active:
			return "Stop AUGUR-7 — strike its vents when they open" if boss.phase >= 2 else "Stop AUGUR-7 — destroy the rig"
		return "Reach the foundation beyond the span"
	if str(GameState.get_flag("ochre_span", "")) == "":
		return "Decide the foundation's fate (marked point)"
	if rivals and not rivals.live.is_empty():
		return "Meet the rivals on the road, then reach the exfil beacon"
	return "Return to the exfil beacon"

# ================= QA helpers =================
func qa_teleport(marker_name: String) -> void:
	var p := Vector3.ZERO if marker_name.begins_with("site:") else marker(marker_name)
	var t := _trigger(marker_name)
	if not t.is_empty():
		p = _tpos(t)
	if marker_name.begins_with("site:") and region:
		for st in region.recipe.get("sites", []):
			if st["id"] == marker_name.substr(5):
				p = Vector3(st["pos"][0], st["pos"][1], st["pos"][2]) + Vector3(1.0, 0, 0)
	if marker_name.begins_with("secret:") and region:
		for sc in region.recipe.get("secrets", []):
			if sc["id"] == marker_name.substr(7):
				p = Vector3(sc["trigger"]["pos"][0], sc["trigger"]["pos"][1], sc["trigger"]["pos"][2]) + Vector3(0.6, 0, 0.4)
	if marker_name.begins_with("loot:"):
		var lt: Dictionary = extra.get("loot", [])[int(marker_name.substr(5))]
		p = Vector3(float(lt["p"][0]), 0.0, float(lt["p"][1])) + Vector3(0.5, 0, 0.5)
	var l := party.get_leader()
	l.teleport(ground(p, 0.4))
	party.get_partner().teleport(ground(p + Vector3(-2, 0, 1.2), 0.4))
	party.clear_trail()
	cam.set_target(l, true)
	print("[QA] teleport ", marker_name, " -> ", p)

func qa_npc(id: String) -> void:
	## teleport next to a named NPC (ids in rr_npcs.json)
	if npcs == null or not npcs.has_npc(id):
		print("[QA] no npc ", id)
		return
	var p := npcs.npc_position(id) + Vector3(2.2, 0, 1.4)
	var l := party.get_leader()
	l.teleport(ground(p, 0.4))
	party.get_partner().teleport(ground(p + Vector3(-1.6, 0, 1.0), 0.4))
	party.clear_trail()
	cam.set_target(l, true)
	print("[QA] teleport npc ", id, " -> ", p)

func qa_talk(id: String) -> void:
	if npcs:
		npcs.talk(id)

func qa_clock(t: float) -> void:
	if ambient:
		ambient.qa_set_clock(t)

func qa_weather(w: String) -> void:
	if ambient:
		ambient.qa_set_weather(w)

func qa_npcs() -> void:
	qa_npc_log()

func qa_npc_log() -> void:
	if npcs == null:
		return
	for id in npcs.ids():
		print("[QA] NPC ", id, " at ", npcs.npc_position(id), " quest=", npcs.quest_state(npcs._gives(npcs._npcs[id]["spec"])))
	print("[QA] items=", GameState.items)
	var fl: Array = []
	for k in GameState.flags:
		if str(k).begins_with("_quest_") or str(k).begins_with("_secret_") or str(k).begins_with("_loot_") or str(k).begins_with("_rg_") or str(k).begins_with("rr_") or str(k).begins_with("_npc_") or str(k).begins_with("_rr_"):
			fl.append(str(k))
	fl.sort()
	print("[QA] flags=", fl)
	print("[QA] clock=%.2f phase=%s weather=%s dusk=%.2f dust=%.2f settlements_built=%s tris=%d" % [ambient.t_day, ambient.phase, ambient.weather, ambient.dusk_k, ambient.dust_k, str(settlements.built), settlements.tri_count])
func qa_npcs() -> void:
	if npcs:
		var o := party.get_leader().global_position
		npcs.qa_lineup(o + Vector3(0, 0, 0))

func qa_skip_to(beat: String) -> void:
	var order := ["valley", "gap", "waystation", "boulder", "drill", "span", "burden", "boss", "choice", "exfil"]
	var idx := order.find(beat)
	var sets := [
		["arrived_rr"], ["valley_clear", "first_scan_done"], ["rope_dropped", "_cig_across"], ["combo_unlocked"],
		["boulder_broken"], ["drill_clear", "beetle_scanned"], [], ["burden_done"], ["boss_defeated"], [],
	]
	for i in range(0, idx + 1):
		for fl in sets[i]:
			GameState.set_flag(fl, true)
	for id in ["rr_arrival", "rr_valley", "rr_gap", "rr_waystation", "rr_boulder", "rr_drill", "rr_span"]:
		GameState.flags["_seen_" + id] = true
	if idx >= order.find("drill"):
		for e in drill_enemies + pylons:
			if is_instance_valid(e) and e.alive:
				e.queue_free()
	if idx >= order.find("gap"):
		for m in mites:
			if is_instance_valid(m):
				m.queue_free()
	if idx >= order.find("choice") and boss and is_instance_valid(boss):
		boss.queue_free()
		boss = null
	if idx >= order.find("choice"):
		GameState.add_item("thoughtstone_cache", 1)
	_apply_world_state()
	if _barrier_boulder and bool(GameState.get_flag("boulder_broken", false)):
		_barrier_boulder.queue_free()
		_barrier_boulder = null
	var where := {"valley": "t_valley", "gap": "t_gap", "waystation": "t_waystation", "boulder": "t_boulder",
		"drill": "t_drill", "span": "t_span", "burden": "t_span", "boss": "t_boss", "choice": "choice_point", "exfil": "exfil_beacon"}
	qa_teleport(where.get(beat, "player_spawn"))
	print("[QA] skip_to ", beat)

func qa_kill_all(radius: float = 40.0) -> void:
	var l := party.get_leader()
	for e in field.enemies.duplicate():
		if is_instance_valid(e) and e.alive and not e.passive and e.global_position.distance_to(l.global_position) < radius:
			e.receive_hit({"amount": 99999.0, "source": l, "can_crit": false, "feel": false, "ignore_invuln": true})

func qa_kill_species(sp: String) -> void:
	var l := party.get_leader()
	for e in field.enemies.duplicate():
		if is_instance_valid(e) and e.alive and e.species_id == sp and not (e is VentWeakpoint):
			e.receive_hit({"amount": 99999.0, "source": l, "can_crit": false, "feel": false, "ignore_invuln": true})

func qa_damage_boss(frac: float) -> void:
	if boss and boss.active:
		boss._transition_t = 0.0
		boss.receive_hit({"amount": boss.max_hp * frac, "source": party.get_leader(), "can_crit": false, "via_vent": true, "feel": true})

func qa_skip_dialogue() -> void:
	runner.skip_all()

var _qa_auto := false
var _qa_choice := 0
var _qa_delay := 0.6

## QA: auto-advance every dialogue after `delay` real seconds, picking choice `choice`.
func qa_auto_dialogue(on: bool, choice: int = 0, delay: float = 0.6) -> void:
	_qa_auto = on
	_qa_choice = choice
	_qa_delay = delay
	if on and not runner.started.is_connected(_qa_on_started):
		runner.started.connect(_qa_on_started)
	if on and runner.active:
		_qa_on_started(runner.dialogue_id)

func _qa_on_started(_id: String) -> void:
	if not _qa_auto:
		return
	await get_tree().create_timer(_qa_delay, true, false, true).timeout
	var guard := 0
	while runner.active and guard < 200:
		guard += 1
		if runner._waiting == "choice":
			runner.choose(mini(_qa_choice, runner._choices.size() - 1))
		elif runner._waiting == "advance":
			runner.advance()
		else:
			break

func qa_choose(i: int) -> void:
	runner.choose(i)

func qa_scan() -> void:
	scanner.scan(party.get_leader())

func qa_interact() -> void:
	if not _active_interact.is_empty():
		(_active_interact["act"] as Callable).call()

func qa_debug() -> void:
	var l := party.get_leader()
	print("[QA] leader ", l.char_id, " hp ", l.hp, " vel ", l.velocity, " knock ", l.knock, " pos ", l.global_position, " cam ", cam.global_position, " rot ", cam.rotation_degrees, " vp ", get_viewport().get_visible_rect().size, " fps ", Engine.get_frames_per_second(), " paused ", get_tree().paused, " dlg ", runner.active, " ", runner.dialogue_id, " boxvis ", runner.box.visible)
	print("[QA] terrain h at leader ", height_at(l.global_position.x, l.global_position.z), " boss ", (boss.global_position if boss and is_instance_valid(boss) else Vector3.ZERO), " boss h ", (height_at(boss.global_position.x, boss.global_position.z) if boss and is_instance_valid(boss) else 0.0))

func qa_log_flags() -> void:
	if region:
		print("[QA] REGION acts=%s secrets=%d gear=%s" % [[region.act_done(1), region.act_done(2), region.act_done(3)], region.secrets_found(), str(Gear.owned())])
		print("[QA] REGION spokes=%d/%d sites=%d/%d" % [region.visited_spokes(), region.total_spokes(), region.sites_done(), region.total_sites()])
		for e in Ledger.events_where({"type": "descent_event"}):
			print("[QA] REGION event ", e["target"], " -> ", e["data"])
	var keys := ["briefed", "arrived_rr", "valley_clear", "first_scan_done", "rope_dropped", "combo_unlocked", "grazers_harmed",
		"boulder_broken", "beetle_scanned", "pylons_down", "beetles_calmed", "drill_clear", "burden_done", "boss_defeated",
		"ochre_span", "ochre_span_braced", "ochre_span_failing", "rr_complete", "debriefed", "habitat_built", "slice_complete"]
	var out := []
	for k in keys:
		out.append("%s=%s" % [k, str(GameState.get_flag(k, false))])
	print("[QA] FLAGS ", ", ".join(out))
	print("[QA] ITEMS ", GameState.items, " SPECIMENS ", GameState.specimens.size(), " TRUST ", GameState.trust, " CODEX ", GameState.codex)

## QA: draw-call breakdown. Pauses the tree (frozen frame), hides each child of `path` (default: the
## level's top-level nodes + actors grouped by script) in turn and prints what it was costing.
func qa_perf_breakdown(path: String = "") -> void:
	var dc := func() -> int: return int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var was_paused := get_tree().paused
	get_tree().paused = true
	var cam_mode := cam.process_mode
	cam.process_mode = Node.PROCESS_MODE_DISABLED
	for _i in 4:
		await get_tree().process_frame
	var base: int = dc.call()
	var out: Array = ["total=%d" % base]
	var groups: Dictionary = {}
	var root: Node = get_node(path) if path != "" else self
	for c in root.get_children():
		if c == actors_root:
			continue
		var key: String = str(c.name)
		if key.begins_with("@"):
			key = c.get_class()
		if not groups.has(key):
			groups[key] = []
		groups[key].append(c)
	if path == "":
		for a in actors_root.get_children():
			var k: String = "actor:" + (a.get_script().resource_path.get_file().get_basename() if a.get_script() else a.get_class())
			if not groups.has(k):
				groups[k] = []
			groups[k].append(a)
	for k in groups.keys():
		var nodes: Array = groups[k]
		var hid: Array = []
		for n in nodes:
			if "visible" in n and n.visible:
				n.visible = false
				hid.append(n)
		if hid.is_empty():
			continue
		for _i in 3:
			await get_tree().process_frame
		var v: int = dc.call()
		for n in hid:
			n.visible = true
		for _i in 3:
			await get_tree().process_frame
		if base - v != 0:
			out.append("%s(x%d)=%d" % [k, nodes.size(), base - v])
	cam.process_mode = cam_mode
	get_tree().paused = was_paused
	print("[QA] PERF BREAKDOWN %s " % (path if path != "" else "level"), ", ".join(out))

## QA: start a drill-beam cycle now (telegraph → sweep), for screenshots.
func qa_boss_beam() -> void:
	if boss and is_instance_valid(boss):
		boss._beam_state = ""
		boss._beam_t = 0.0

# ---- QA: Ledger Rivals ----
## Spawn a rival (if needed) and put the party 9 m from them.
func qa_rival_meet(id: String) -> void:
	var e: RivalEnemy = rivals.live.get(id, null)
	if e == null:
		e = rivals.spawn(id)
	if e == null:
		print("[QA] rival ", id, " not available")
		return
	var p := e.global_position + Vector3(-9, 0, 0)
	var l := party.get_leader()
	l.teleport(ground(p, 0.4))
	party.get_partner().teleport(ground(p + Vector3(-2, 0, 1.2), 0.4))
	party.clear_trail()
	cam.set_target(l, true)

func qa_rival_hurt(id: String, frac: float) -> void:
	var e: RivalEnemy = rivals.live.get(id, null)
	if e and is_instance_valid(e) and e.alive:
		e.receive_hit({"amount": e.max_hp * frac, "source": party.get_leader(), "ability": "reaching_strike", "can_crit": false, "feel": true, "kind": "heavy"})

func qa_rival_resolve(id: String, outcome: String) -> void:
	rivals.qa_resolve(id, outcome)

func qa_rival_log() -> void:
	for id in rivals.live:
		var e: RivalEnemy = rivals.live[id]
		print("[QA] RIVAL ", id, " state=", e.state, " hp=", snappedf(e.hp, 0.1), "/", snappedf(e.max_hp, 0.1), " tactics=", e.tactics, " kind=", e.attack_kind)
	for r in Rivals.all():
		print("[QA] ROSTER ", r["id"], " state=", r["state"], " enc=", r["encounters"], " adapt=", r["adaptations"], " scars=", r["scars"], " grudge=", r["grudge"])

## QA: make Orrin an escaped rival who learned two counters, then re-spawn everyone (Return Descent look).
func qa_prime_rivals() -> void:
	var o := Rivals.get_rival("foreman_orrin")
	o["state"] = "escaped"
	o["last_outcome"] = "escaped"
	o["encounters"] = 1
	o["grudge"] = 1
	o["adaptations"] = ["stay_off_the_line", "kite_and_wait", "bait_projectiles"]
	o["scars"] = ["dented_pauldron"]
	for id in rivals.live.keys():
		if is_instance_valid(rivals.live[id]):
			rivals.live[id].queue_free()
	rivals.live.clear()
	rivals._spawned.clear()
	rivals.spawn_all()
