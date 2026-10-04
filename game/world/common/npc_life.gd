class_name NpcLife
extends Node
## Reusable field-NPC life (generalised from the hub's HubLife): named NPCs with schedules, idle "work" behaviours,
## wander/stroll, barks in pooled bubbles, paired chats, interaction hotspots and data-driven dialogue that hands off
## to the region's side quests / descent events. Data: a JSON file (see game/world/red_reaches/rr_npcs.json for the schema).
## Visuals: game/art/models/npcs/npc_registry.json maps ids to model scenes (Agent 1's art drops in with no code change);
## until a scene exists each NPC is a FallbackVisual silhouette BAKED INTO ONE MESH (1 draw call per NPC).
## Cost model: nothing allocates per frame; NPCs farther than ACTIVE_RANGE from the focus are skipped entirely; the tree
## pauses during dialogue so nothing ticks then; 2 bubbles and N name tags are created once.

const REGISTRY := "res://game/art/models/npcs/npc_registry.json"
const WALK_SPEED := 1.3
const ACTIVE_RANGE := 60.0
const TAG_RANGE := 11.0
const FADE_RANGE := 38.0           # beyond this the model is not rendered at all (the gameplay camera sees ~25 m)

## act -> procedural motion for the baked placeholders: bob (m), hz, lean (rad, forward), nod (rad), sway (rad), sweep (yaw rad)
const ACTS := {
	"idle": {"bob": 0.012, "hz": 0.25, "lean": 0.0, "nod": 0.0, "sway": 0.015, "sweep": 0.0},
	"rest": {"bob": 0.01, "hz": 0.2, "lean": -0.05, "nod": 0.0, "sway": 0.01, "sweep": 0.0},
	"watch": {"bob": 0.01, "hz": 0.2, "lean": 0.0, "nod": 0.0, "sway": 0.01, "sweep": 0.55},
	"crank": {"bob": 0.07, "hz": 0.8, "lean": 0.2, "nod": 0.14, "sway": 0.1, "sweep": 0.0},
	"pluck": {"bob": 0.015, "hz": 1.4, "lean": 0.12, "nod": 0.09, "sway": 0.02, "sweep": 0.0},
	"sketch": {"bob": 0.01, "hz": 2.0, "lean": 0.28, "nod": 0.05, "sway": 0.04, "sweep": 0.0},
	"write": {"bob": 0.008, "hz": 3.0, "lean": 0.2, "nod": 0.04, "sway": 0.02, "sweep": 0.0},
	"haul": {"bob": 0.05, "hz": 0.7, "lean": 0.32, "nod": 0.1, "sway": 0.06, "sweep": 0.0},
	"walk": {"bob": 0.06, "hz": 2.1, "lean": 0.04, "nod": 0.0, "sway": 0.05, "sweep": 0.0},
}

static var _bake_mat: StandardMaterial3D = null

var host: Node3D
var ui_layer: CanvasLayer
var _bubble_root: Control
var runner: DialogueRunner
var quest_api: Object = null            # RegionRunner (duck-typed: quest_available, event_taken, play_quest, play_event)
var region_id := ""
var focus_fn: Callable                  # -> Vector3 (player focus)
var ground_fn: Callable                 # (x, z) -> float
var phase_fn: Callable                  # -> "dawn" | "day" | "dusk"
var enabled := true

var _npcs: Dictionary = {}              # id -> record Dictionary
var _order: Array = []                  # ids in file order
var _pairs: Array = []
var _registry: Dictionary = {}
var _station_pos: Dictionary = {}
var _ambient: Array = []
var _amb_t := 20.0
var _cur := ""
var hide_fn: Callable             # (npc id) -> bool: hide this NPC right now (e.g. its rival form is on the field)
var _bubbles: Array = []
var _bark_t := 5.0
var _pair_t := 25.0
var _pair: Dictionary = {}
var _phase := ""
var _phase_t := 0.0
var _tag_t := 0.0
var _bark_range := 13.0
var _rng := RandomNumberGenerator.new()
var _ctx: Dictionary = {}               # npc id -> Array of action arrays of the dialogue being shown
var _pend_quest := ""
var _pend_event := ""
var _focus := Vector3.ZERO

func setup(parent3d: Node3D, data_path: String, canon_path: String, region_runner: Object, dlg: DialogueRunner, focus_cb: Callable, ground_cb: Callable, phase_cb: Callable, region: String) -> void:
	host = parent3d
	quest_api = region_runner
	runner = dlg
	focus_fn = focus_cb
	ground_fn = ground_cb
	phase_fn = phase_cb
	region_id = region
	_rng.randomize()
	var d: Variant = _read_json(data_path)
	var canon: Variant = _read_json(canon_path)
	if not (d is Dictionary) or not (canon is Dictionary):
		enabled = false
		return
	_bark_range = float(d.get("bark_range", 13.0))
	_station_pos = d.get("stations", {})
	var reg: Variant = _read_json(REGISTRY)
	if reg is Dictionary:
		_registry = (reg as Dictionary).get("npcs", {})
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 6
	ui_layer.name = "NpcBubbles"
	add_child(ui_layer)
	_bubble_root = Control.new()
	_bubble_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bubble_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_bubble_root)
	var cmap: Dictionary = {}
	for c in canon.get("npcs", []):
		cmap[str(c["id"])] = c
	for entry in d.get("npcs", []):
		var cid := str(entry["id"])
		if not cmap.has(cid):
			push_warning("NpcLife: %s is not in the canon NPC file" % cid)
			continue
		var spec: Dictionary = (cmap[cid] as Dictionary).duplicate()
		spec.merge(entry, true)
		_compose(spec)
		_spawn(spec)
	_pairs = d.get("pairs", [])
	var amb: Variant = _read_json(str(d.get("ambient", "")))
	if amb is Dictionary:
		for l in (amb as Dictionary).get("lines", []):
			var sp := _station_spot(str(l.get("station", "")), 0)
			if not sp.is_empty():
				var li: Dictionary = (l as Dictionary).duplicate()
				li["pos"] = Vector3(sp["pos"].x, 0.0, sp["pos"].z)
				_ambient.append(li)
	for i in 2:
		_bubbles.append(_make_bubble())
	if runner and not runner.finished.is_connected(_on_finished):
		runner.finished.connect(_on_finished)

func _station_spot(station: String, slot: int) -> Dictionary:
	var arr: Array = _station_pos.get(station, [])
	if arr.is_empty():
		return {}
	var e: Array = arr[slot % arr.size()]
	return {"pos": Vector3(float(e[0]), 0.0, float(e[1])), "face": Vector3(float(e[2]), 0.0, float(e[3])).normalized()}

## Canon schedule (dawn|day|dusk|night + station) -> stations list + phase->station index; palette -> placeholder colours.
func _compose(spec: Dictionary) -> void:
	var sts: Array = []
	var names: Array = []
	var slot := int(spec.get("slot", 0))
	var acts: Dictionary = spec.get("acts", {})
	for sc in spec.get("schedule", []):
		var st := str(sc["station"])
		if names.has(st):
			continue
		var spot := _station_spot(st, slot)
		if spot.is_empty():
			push_warning("NpcLife: no station position for %s" % st)
			continue
		names.append(st)
		sts.append({"pos": spot["pos"], "act": str(acts.get(st, "idle")), "face": spot["face"]})
	spec["stations"] = sts
	var by_when: Dictionary = {}
	for sc in spec.get("schedule", []):
		var i := names.find(str(sc["station"]))
		if i >= 0:
			by_when[str(sc["when"])] = i
	var sched: Dictionary = {}
	sched["day"] = by_when.get("day", 0)
	sched["dawn"] = by_when.get("dawn", sched["day"])
	sched["dusk"] = by_when.get("dusk", by_when.get("night", sched["day"]))
	spec["schedule_idx"] = sched
	var pal: Array = spec.get("look", {}).get("palette", ["#6b5a4a", "#d9a43a", "#c9a07a"])
	spec["body"] = pal[0]
	spec["acc"] = pal[1 % pal.size()]
	spec["head"] = pal[2 % pal.size()]
	spec["hotspot"] = {"label": "Talk to " + str(spec["name"]).replace("Mother ", "").replace("Warden ", "").replace("Clerk ", "").replace("Master ", ""), "r": 3.4}

static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

# ------------------------------------------------------------------ build
func _spawn(spec: Dictionary) -> void:
	var id := str(spec["id"])
	var sts: Array = spec.get("stations", [])
	if sts.is_empty():
		return
	UiKit.npc_names[id] = str(spec.get("name", id))
	UiKit.npc_colors[id] = Color(str(spec.get("body", "#c9a05a"))).lightened(0.15)
	var reg: Dictionary = _registry.get(id, {})
	var root := Node3D.new()
	root.name = "NPC_" + id
	host.add_child(root)
	var body: Node3D = null
	var proc := true
	var scene_path := str(reg.get("scene", ""))
	if scene_path != "" and ResourceLoader.exists(scene_path):
		var ps: Variant = load(scene_path)
		if ps is PackedScene:
			var inst: Node = (ps as PackedScene).instantiate()
			if inst is Node3D:
				body = inst
				body.scale = Vector3.ONE * float(reg.get("scale", 1.0))
				proc = false
			else:
				inst.free()
	if body == null:
		body = _bake_placeholder(id, spec)
	root.add_child(body)
	var h := float(reg.get("height_m", spec.get("h", 1.8)))
	var tag := Label3D.new()
	tag.text = str(spec.get("name", id))
	tag.font_size = 44
	tag.pixel_size = 0.0009
	tag.fixed_size = true
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.outline_size = 10
	tag.modulate = Color(UiKit.PARCHMENT, 0.92)
	tag.position = Vector3(0, h + 0.55, 0)
	tag.visible = false
	var f := UiKit.font("bold")
	if f:
		tag.font = f
	root.add_child(tag)
	var anim: AnimationPlayer = null
	if not proc:
		for c in body.find_children("*", "AnimationPlayer", true, false):
			anim = c as AnimationPlayer
			break
	var sched: Dictionary = spec.get("schedule_idx", {})
	var start := int(sched.get(phase_fn.call() if phase_fn.is_valid() else "day", 0))
	start = clampi(start, 0, sts.size() - 1)
	var sp: Vector3 = sts[start]["pos"]
	root.position = Vector3(sp.x, float(ground_fn.call(sp.x, sp.z)), sp.z)
	var n := {"id": id, "node": root, "body": body, "tag": tag, "spec": spec, "stations": sts, "sched": sched,
		"cur": start, "state": "idle", "target": root.position, "wait": _rng.randf_range(1.5, 6.0), "yaw": 0.0,
		"act": str(sts[start]["act"]), "t": _rng.randf() * 10.0, "proc": proc, "anim": anim, "anim_cur": "", "h": h,
		"reg_anim": reg.get("anim", {}), "tag_on": false, "active": true, "talk_t": 0.0, "move": 0.0, "hidden": false}
	_npcs[id] = n
	_order.append(id)
	_face(n, sts[start]["face"])
	body.rotation.y = float(n["yaw"])
	_play(n, "idle")

## Bakes a FallbackVisual into ONE vertex-coloured mesh (one draw call) and wraps it in a plain Node3D.
func _bake_placeholder(id: String, spec: Dictionary) -> Node3D:
	FallbackVisual.extra_specs[id] = {"h": float(spec.get("h", 1.8)), "r": float(spec.get("r", 0.4)), "body": str(spec.get("body", "#6b5a4a")),
		"acc": str(spec.get("acc", "#d9a43a")), "head": str(spec.get("head", "#c9a07a")), "shape": str(spec.get("shape", "human"))}
	var fv := FallbackVisual.new()
	fv.setup(id, "character")
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for mi in fv.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null or m.mesh is PlaneMesh:
			continue
		var xf := Transform3D.IDENTITY
		var p: Node = m
		while p != null and p != fv:
			if p is Node3D:
				xf = (p as Node3D).transform * xf
			p = p.get_parent()
		var col := Color(0.6, 0.5, 0.4)
		var mat := m.material_override as StandardMaterial3D
		if mat:
			col = mat.albedo_color
			if mat.emission_enabled:
				col = (col + mat.emission * 0.5).clamp()
		var nb := xf.basis.inverse().transposed()
		for s in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nn: Variant = arr[Mesh.ARRAY_NORMAL]
			var ii: Variant = arr[Mesh.ARRAY_INDEX]
			var base := verts.size()
			for k in v.size():
				verts.append(xf * v[k])
				norms.append((nb * (nn[k] if nn != null else Vector3.UP)).normalized())
				cols.append(col)
			if ii != null and (ii as PackedInt32Array).size() > 0:
				for k in (ii as PackedInt32Array):
					idx.append(base + k)
			else:
				for k in v.size():
					idx.append(base + k)
	fv.free()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi2 := MeshInstance3D.new()
	mi2.mesh = am
	mi2.material_override = _baked_material()
	mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var holder := Node3D.new()
	holder.name = "Placeholder"
	holder.add_child(mi2)
	return holder

static func _baked_material() -> StandardMaterial3D:
	if _bake_mat == null:
		_bake_mat = StandardMaterial3D.new()
		_bake_mat.vertex_color_use_as_albedo = true
		_bake_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		_bake_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		_bake_mat.roughness = 0.85
		_bake_mat.rim_enabled = true
		_bake_mat.rim = 0.35
		_bake_mat.rim_tint = 0.4
	return _bake_mat

func _make_bubble() -> Dictionary:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCHMENT, 0.94), UiKit.PARCHMENT_DARK.darkened(0.3), 16, 3, 14))
	var l := UiKit.label("", 22, UiKit.INK, "dialogue")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(250, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(l)
	panel.visible = false
	_bubble_root.add_child(panel)
	return {"panel": panel, "label": l, "who": "", "t": 0.0, "node": null, "h": 2.0}

# ------------------------------------------------------------------ queries
func has_npc(id: String) -> bool:
	return _npcs.has(id)

func ids() -> Array:
	return _order

func npc_position(id: String) -> Vector3:
	var n: Dictionary = _npcs.get(id, {})
	return (n["node"] as Node3D).position if not n.is_empty() else Vector3.ZERO

func npc_node(id: String) -> Node3D:
	var n: Dictionary = _npcs.get(id, {})
	return n["node"] if not n.is_empty() else null

## Quest ids given by NPCs (the level hides their stand-alone quest sites).
func owned_quests() -> Array:
	var out: Array = []
	for id in _order:
		for q in _npcs[id]["spec"].get("quests", {}).get("gives", []):
			out.append(str(q))
	return out

func _gives(spec: Dictionary) -> String:
	var g: Array = spec.get("quests", {}).get("gives", [])
	return str(g[0]) if not g.is_empty() else ""

func quest_state(qid: String) -> String:
	if qid == "":
		return "none"
	if bool(GameState.flags.get("_quest_" + qid, false)):
		return "done"
	if quest_api and quest_api.has_method("quest_available") and quest_api.quest_available(qid):
		return "open"
	return "locked"

## Interactable dictionaries in the level's own format, plus pos_fn (NPCs move) and hot (open quest -> bright marker).
func interactables() -> Array:
	var out: Array = []
	for id in _order:
		var n: Dictionary = _npcs[id]
		var hs: Dictionary = n["spec"].get("hotspot", {})
		var node: Node3D = n["node"]
		var qid := _gives(n["spec"])
		out.append({"id": "npc_" + str(id), "pos": node.position, "pos_fn": func() -> Vector3: return node.position,
			"r": float(hs.get("r", 3.4)), "label": str(hs.get("label", "Talk")), "y_off": h_of(n) + 1.0,
			"cond": func() -> bool: return enabled and not bool(n["hidden"]),
			"hot": func() -> bool: return qid != "" and quest_state(qid) == "open",
			"act": talk.bind(str(id))})
	return out

func h_of(n: Dictionary) -> float:
	return float(n["h"])

# ------------------------------------------------------------------ per frame
func _process(delta: float) -> void:
	if not enabled:
		return
	_focus = focus_fn.call()
	_phase_t -= delta
	if _phase_t <= 0.0:
		_phase_t = 0.5
		_check_phase()
	_tag_t -= delta
	var tag_tick := false
	if _tag_t <= 0.0:
		_tag_t = 0.15
		tag_tick = true
	for id in _order:
		var n: Dictionary = _npcs[id]
		var node: Node3D = n["node"]
		var dx := node.position.x - _focus.x
		var dz := node.position.z - _focus.z
		var d2 := dx * dx + dz * dz
		var act := d2 < ACTIVE_RANGE * ACTIVE_RANGE
		if act != bool(n["active"]):
			n["active"] = act
			node.visible = d2 < FADE_RANGE * FADE_RANGE
		if not act:
			continue
		if tag_tick:
			var hid: bool = hide_fn.is_valid() and bool(hide_fn.call(id))
			if hid != bool(n["hidden"]):
				n["hidden"] = hid
				node.visible = not hid
			var on := d2 < TAG_RANGE * TAG_RANGE
			if on != bool(n["tag_on"]):
				n["tag_on"] = on
				(n["tag"] as Label3D).visible = on
		_tick_npc(n, delta)
	_tick_bubbles(delta)
	_amb_t -= delta
	if _amb_t <= 0.0:
		_amb_t = 6.0
		_ambient_tick()
	_bark_t -= delta
	if _bark_t <= 0.0:
		_bark_t = _rng.randf_range(6.0, 11.0)
		_bark()
	_pair_t -= delta
	if _pair_t <= 0.0 and _pair.is_empty():
		_pair_t = _rng.randf_range(35.0, 60.0)
		_start_pair()
	if not _pair.is_empty():
		_tick_pair(delta)

func _check_phase() -> void:
	var ph: String = phase_fn.call() if phase_fn.is_valid() else "day"
	if ph == _phase:
		return
	_phase = ph
	for id in _order:
		var n: Dictionary = _npcs[id]
		var sched: Dictionary = n["sched"]
		if not sched.has(ph):
			continue
		var si := clampi(int(sched[ph]), 0, (n["stations"] as Array).size() - 1)
		if si != int(n["cur"]) and n["state"] != "talk" and (_pair.is_empty() or not (_pair.get("ids", []) as Array).has(id)):
			n["cur"] = si
			_goto_station(n, si)

func _goto_station(n: Dictionary, si: int) -> void:
	var st: Dictionary = n["stations"][si]
	var p: Vector3 = st["pos"]
	n["act"] = "walk"
	walk_to(n, Vector3(p.x, 0.0, p.z))
	n["arrive"] = si

func walk_to(n: Dictionary, p: Vector3) -> void:
	n["target"] = p
	n["state"] = "walk"
	n["move"] = 1.0
	_play(n, "walk")
	var b: Node = n["body"]
	if b.has_method("set_move_amount"):
		b.set_move_amount(1.0)

func _tick_npc(n: Dictionary, delta: float) -> void:
	var node: Node3D = n["node"]
	var body: Node3D = n["body"]
	n["t"] = float(n["t"]) + delta
	match n["state"]:
		"walk":
			var tp: Vector3 = n["target"]
			var dx := tp.x - node.position.x
			var dz := tp.z - node.position.z
			var dist := sqrt(dx * dx + dz * dz)
			if dist < 0.12:
				_arrive(n)
			else:
				var step := minf(dist, WALK_SPEED * delta)
				node.position.x += dx / dist * step
				node.position.z += dz / dist * step
				node.position.y = float(ground_fn.call(node.position.x, node.position.z))
				_face_dir(n, dx, dz)
		"talk":
			n["talk_t"] = float(n["talk_t"]) - delta
			if float(n["talk_t"]) <= 0.0:
				n["state"] = "idle"
				n["wait"] = _rng.randf_range(3.0, 7.0)
				_resume_act(n)
		"idle":
			n["wait"] = float(n["wait"]) - delta
			if float(n["wait"]) <= 0.0:
				n["wait"] = _rng.randf_range(5.0, 12.0)
				var sts: Array = n["stations"]
				var cs: Dictionary = sts[int(n["cur"])]
				var roll := _rng.randf()
				if roll < 0.3 and _pair.is_empty():
					# a short stroll around the station, then back to work
					var a := _rng.randf() * TAU
					var c: Vector3 = cs["pos"]
					n["arrive"] = int(n["cur"])
					n["act"] = "walk"
					walk_to(n, Vector3(c.x + cos(a) * 1.8, 0.0, c.z + sin(a) * 1.8))
				elif roll < 0.55:
					_face(n, (cs["face"] as Vector3).rotated(Vector3.UP, _rng.randf_range(-1.4, 1.4)))
				else:
					_face(n, cs["face"])
	if bool(n["proc"]):
		_animate(n, body)
	else:
		var yw := float(n["yaw"])
		if not body.has_method("set_facing"):
			body.rotation.y = lerp_angle(body.rotation.y, yw, minf(1.0, delta * 8.0))

func _arrive(n: Dictionary) -> void:
	n["state"] = "idle"
	n["wait"] = _rng.randf_range(3.0, 9.0)
	n["move"] = 0.0
	var b: Node = n["body"]
	if b.has_method("set_move_amount"):
		b.set_move_amount(0.0)
	_resume_act(n)

func _resume_act(n: Dictionary) -> void:
	var st: Dictionary = n["stations"][int(n["cur"])]
	n["act"] = str(st["act"])
	_face(n, st["face"])
	var a: String = n["act"]
	_play(n, "work" if a in ["crank", "pluck", "sketch", "write", "haul"] else ("rest" if a == "rest" else "idle"))

func _animate(n: Dictionary, body: Node3D) -> void:
	var a: Dictionary = ACTS.get(n["act"], ACTS["idle"])
	var ph := float(n["t"]) * float(a["hz"]) * TAU
	var s := sin(ph)
	body.position.y = absf(s) * float(a["bob"]) if n["act"] == "walk" else s * float(a["bob"])
	body.rotation.x = float(a["lean"]) + s * float(a["nod"])
	body.rotation.z = sin(ph + 1.3) * float(a["sway"])
	var yw := float(n["yaw"])
	body.rotation.y = lerp_angle(body.rotation.y, yw + sin(float(n["t"]) * 0.35) * float(a["sweep"]), 0.12)

func _face(n: Dictionary, dir: Vector3) -> void:
	_face_dir(n, dir.x, dir.z)

func _face_dir(n: Dictionary, dx: float, dz: float) -> void:
	if dx * dx + dz * dz < 0.0001:
		return
	n["yaw"] = atan2(-dx, -dz)
	var b: Node = n["body"]
	if b.has_method("set_facing"):
		b.set_facing(Vector3(dx, 0, dz))

func _play(n: Dictionary, state: String) -> void:
	var ap: AnimationPlayer = n["anim"]
	if ap == null or n["anim_cur"] == state:
		return
	var m: Dictionary = n["reg_anim"]
	var clip := str(m.get(state, state))
	if not ap.has_animation(clip):
		clip = str(m.get("idle", "idle"))
		if not ap.has_animation(clip):
			return
	n["anim_cur"] = state
	ap.play(clip)

# ------------------------------------------------------------------ talk
const REACT_FLAGS := ["rr_act1_done", "rr_act2_done", "rr_act3_done", "boss_defeated"]

## Player pressed Interact on an NPC: face the player, then play (canon dialogue order) meet -> quest offer -> quest -> turn-in ->
## react (an act / quest flag changed since last time) -> repeat.
func talk(id: String) -> void:
	var n: Dictionary = _npcs.get(id, {})
	if n.is_empty() or runner == null or runner.active:
		return
	hide_all()
	var node: Node3D = n["node"]
	_face_dir(n, _focus.x - node.position.x, _focus.z - node.position.z)
	n["state"] = "talk"
	n["talk_t"] = 2.5
	n["move"] = 0.0
	n["act"] = "idle"
	_play(n, "idle")
	_cur = id
	var spec: Dictionary = n["spec"]
	var dl: Dictionary = spec.get("dialogue", {})
	var did := ""
	var qid := _gives(spec)
	if not _flag(str(spec.get("flag_met", "rrn_%s_met" % id))):
		did = str(dl.get("meet", ""))
	else:
		var qs := quest_state(qid)
		if qid != "" and qs == "open":
			if not _flag("rrn_%s_offered" % qid):
				did = str(dl.get("quest", ""))
			elif quest_api:
				quest_api.play_quest(qid)
				return
		elif qid != "" and qs == "done" and not bool(GameState.flags.get("_seen_" + str(dl.get("turnin", "")), false)):
			did = str(dl.get("turnin", ""))
		if did == "":
			var sig := _react_sig(spec)
			if sig != "" and sig != str(GameState.flags.get("_npc_react_" + id, "")):
				GameState.flags["_npc_react_" + id] = sig
				did = str(dl.get("react", ""))
		if did == "":
			did = str(dl.get("repeat", ""))
	if did == "" or not runner.play(did):
		Events.toast.emit("%s nods and says nothing." % str(spec.get("name", id)), "info")

func _react_sig(spec: Dictionary) -> String:
	var parts: Array = []
	for f in REACT_FLAGS:
		if _flag(f):
			parts.append(f)
	for q in spec.get("quests", {}).get("reacts", []):
		if bool(GameState.flags.get("_quest_" + str(q), false)):
			parts.append(str(q))
	return ",".join(parts)

func _flag(f: String) -> bool:
	if f.begins_with("ledger_"):
		return Ledger.exists({"tag": f.substr(7)})
	var v: Variant = GameState.get_flag(f, false)
	if v is bool:
		return v
	if v is String:
		return v != ""
	return v != null and v != 0

## Dialogue event hook: the level forwards every event string; returns true when it was ours.
##   rec:<id>  -> Ledger.record from the current NPC's canon records{}      offer:<quest id> -> hand off to the quest after the line
##   lead:<id> -> a journal lead toast
func handle_event(ev: String) -> bool:
	if ev.begins_with("rec:"):
		var recs: Dictionary = _npcs.get(_cur, {}).get("spec", {}).get("records", {})
		var r: Dictionary = recs.get(ev.substr(4), {})
		if not r.is_empty():
			Ledger.record(str(r["type"]), "player", str(r.get("target", "")), r.get("tags", []), {}, int(r.get("weight", 1)), region_id)
			GameState.save_game()
		return true
	if ev.begins_with("offer:"):
		_pend_quest = ev.substr(6)
		return true
	if ev.begins_with("lead:"):
		Events.toast.emit("New lead: %s" % ev.substr(5).replace("rr_", "").replace("_", " "), "info")
		return true
	return false

func _on_finished(did: String) -> void:
	if not did.begins_with("rrn_"):
		return
	if _pend_quest != "":
		var q := _pend_quest
		_pend_quest = ""
		if quest_api:
			quest_api.play_quest.call_deferred(q)

# ------------------------------------------------------------------ barks
func _near(node: Node3D) -> bool:
	return Vector2(node.global_position.x - _focus.x, node.global_position.z - _focus.z).length() < _bark_range

func _eligible(line: Dictionary, _ph: String) -> bool:
	if line.has("if") and not _flag(str(line["if"])):
		return false
	if line.has("if_not") and _flag(str(line["if_not"])):
		return false
	return true

func _bark() -> void:
	if not _pair.is_empty() or runner == null or runner.active:
		return
	var ids_s: Array = _order.duplicate()
	ids_s.shuffle()
	for id in ids_s:
		var n: Dictionary = _npcs[id]
		if not _near(n["node"]) or _speaking(n["node"]) or n["state"] == "talk":
			continue
		var pool: Array = []
		for l in n["spec"].get("barks", []):
			if _eligible(l, _phase):
				pool.append(l)
		if pool.is_empty():
			continue
		say(id, str(pool[_rng.randi() % pool.size()]["text"]))
		return

func _speaking(node: Node3D) -> bool:
	for b in _bubbles:
		if b["node"] == node and (b["panel"] as Control).visible:
			return true
	return false

func say(id: String, text: String) -> void:
	var n: Dictionary = _npcs.get(id, {})
	if n.is_empty():
		return
	var slot: Dictionary = {}
	for b in _bubbles:
		if not (b["panel"] as Control).visible:
			slot = b
			break
	if slot.is_empty():
		slot = _bubbles[0]
	slot["who"] = id
	slot["node"] = n["node"]
	slot["h"] = float(n["h"]) + 0.9
	slot["t"] = clampf(1.8 + text.length() * 0.05, 2.4, 5.5)
	(slot["label"] as Label).text = text
	var p: Control = slot["panel"]
	p.reset_size()
	p.modulate.a = 1.0
	p.visible = true
	_place_bubble(slot)

func _tick_bubbles(delta: float) -> void:
	for b in _bubbles:
		var p: Control = b["panel"]
		if not p.visible:
			continue
		b["t"] = float(b["t"]) - delta
		if float(b["t"]) <= 0.0:
			p.visible = false
			continue
		p.modulate.a = clampf(float(b["t"]) / 0.4, 0.0, 1.0)
		_place_bubble(b)

func _place_bubble(b: Dictionary) -> void:
	var node: Node3D = b["node"]
	var p: Control = b["panel"]
	var cam := get_viewport().get_camera_3d()
	var wp := node.global_position + Vector3(0, float(b["h"]), 0)
	if cam == null or cam.is_position_behind(wp):
		p.visible = false
		return
	var sp := cam.unproject_position(wp)
	var vs := get_viewport().get_visible_rect().size
	if sp.x < -60.0 or sp.x > vs.x + 60.0 or sp.y < 60.0 or sp.y > vs.y:
		p.visible = false
		b["t"] = 0.0
		return
	p.position = Vector2(clampf(sp.x - p.size.x * 0.5, 8.0, vs.x - p.size.x - 8.0), clampf(sp.y - p.size.y - 6.0, 70.0, vs.y - p.size.y - 60.0))

func hide_all() -> void:
	for b in _bubbles:
		(b["panel"] as Control).visible = false
		b["t"] = 0.0

# ------------------------------------------------------------------ pairs
func _start_pair() -> void:
	if _pairs.is_empty() or runner == null or runner.active:
		return
	var cand: Array = _pairs.duplicate()
	cand.shuffle()
	for pr in cand:
		var a: Dictionary = _npcs.get(str(pr["a"]), {})
		var b: Dictionary = _npcs.get(str(pr["b"]), {})
		if a.is_empty() or b.is_empty() or not _near(b["node"]):
			continue
		if a["state"] != "idle" or b["state"] != "idle":
			continue
		var bp: Vector3 = (b["node"] as Node3D).position
		var meet := Vector3(bp.x + 1.5, 0.0, bp.z + 0.6)
		_pair = {"a": a, "b": b, "lines": pr["lines"], "i": 0, "t": 0.0, "phase": "go", "ids": [str(pr["a"]), str(pr["b"])],
			"home": Vector3((a["node"] as Node3D).position.x, 0.0, (a["node"] as Node3D).position.z)}
		a["act"] = "walk"
		walk_to(a, meet)
		return

func _tick_pair(delta: float) -> void:
	var a: Dictionary = _pair["a"]
	var b: Dictionary = _pair["b"]
	if a["state"] == "talk" or b["state"] == "talk":
		_pair = {}
		return
	match _pair["phase"]:
		"go":
			if a["state"] == "idle":
				_pair["phase"] = "talk"
				_pair["t"] = 0.3
				_face_dir(a, b["node"].position.x - a["node"].position.x, b["node"].position.z - a["node"].position.z)
				_face_dir(b, a["node"].position.x - b["node"].position.x, a["node"].position.z - b["node"].position.z)
				a["act"] = "idle"
				b["act"] = "idle"
		"talk":
			_pair["t"] = float(_pair["t"]) - delta
			if float(_pair["t"]) <= 0.0:
				var ls: Array = _pair["lines"]
				var i: int = _pair["i"]
				if i >= ls.size():
					_pair["phase"] = "return"
					a["act"] = "walk"
					walk_to(a, _pair["home"])
					return
				say(str(ls[i][0]), str(ls[i][1]))
				_pair["i"] = i + 1
				_pair["t"] = clampf(1.6 + str(ls[i][1]).length() * 0.05, 2.6, 5.0)
		"return":
			if a["state"] == "idle":
				_resume_act(b)
				_pair = {}

# ------------------------------------------------------------------ ambient environment lines (canon red_reaches_ambient.json)
var _amb_last: Dictionary = {}

func _ambient_tick() -> void:
	var now := Time.get_ticks_msec()
	for l in _ambient:
		var k := str(l.get("kind", ""))
		if k != "wind" and k != "overheard":
			continue
		var p: Vector3 = l["pos"]
		if Vector2(p.x - _focus.x, p.z - _focus.z).length() > 12.0 or not _eligible(l, ""):
			continue
		if now - int(_amb_last.get(l["id"], -999999)) < 150000:
			continue
		_amb_last[l["id"]] = now
		Events.toast.emit(str(l["text"]), "info")
		return

## Readable signs / placards as marker-less hotspots (level interactable format).
func ambient_interactables() -> Array:
	var out: Array = []
	for l in _ambient:
		var k := str(l.get("kind", ""))
		if k != "sign" and k != "placard":
			continue
		var lc: Dictionary = l
		var p: Vector3 = lc["pos"] + Vector3(2.0 + float(out.size() % 3), 0, 1.5)
		out.append({"id": "amb_" + str(lc["id"]), "pos": p, "r": 2.6, "label": "Read", "nomark": true,
			"cond": func() -> bool: return _eligible(lc, ""),
			"act": func() -> void: Events.toast.emit(str(lc["text"]), "codex")})
	return out

## QA: line every NPC up in a row (two rows) at `origin` for model / animation screenshots.
func qa_lineup(origin: Vector3) -> void:
	var i := 0
	for id in _order:
		var n: Dictionary = _npcs[id]
		var node: Node3D = n["node"]
		var x := origin.x + (float(i % 6) - 2.5) * 2.6
		var z := origin.z + 5.0 + float(i / 6) * 3.6
		node.position = Vector3(x, float(ground_fn.call(x, z)), z)
		node.visible = true
		n["state"] = "talk"
		n["talk_t"] = 9999.0
		n["active"] = true
		_face_dir(n, 0.0, 1.0)
		i += 1
