class_name RrSettlements
extends Node3D
## Red Reaches settlements, camps, landmarks and wayfinding as real 3D geometry (no cards, no sprites).
## Data: game/world/red_reaches/world_extra.json -> "settlements" [{id, center, props:[{k, p:[dx,dz], r(deg), s, c, n}]}],
## "cairn_trail". Every settlement is merged into ONE vertex-coloured ArrayMesh (one draw call; frustum-culled as a unit),
## built on a WorkerThreadPool task and attached on the main thread when ready (no load hitch). The few solid props
## (tents, carts, wells, stalls) get cheap box colliders.

const STONE := Color(0.62, 0.50, 0.42)
const STONE_DARK := Color(0.48, 0.38, 0.32)
const SURVEY := Color(0.70, 0.60, 0.48)
const WOOD := Color(0.42, 0.29, 0.20)
const WOOD_LIGHT := Color(0.58, 0.42, 0.28)
const ROPE := Color(0.78, 0.66, 0.44)
const CLOTH_RED := Color(0.70, 0.28, 0.20)
const CLOTH_OCHRE := Color(0.80, 0.56, 0.26)
const CLOTH_SAND := Color(0.82, 0.72, 0.54)
const CLOTH_GREEN := Color(0.28, 0.44, 0.30)
const CLOTH_GREY := Color(0.36, 0.38, 0.42)
const DOM_RED := Color(0.72, 0.12, 0.10)
const IRON := Color(0.30, 0.31, 0.35)
const SALT := Color(0.94, 0.92, 0.86)
const BONE := Color(0.86, 0.80, 0.68)
const FLAME := Color(1.0, 0.62, 0.20)
const LAMP := Color(1.0, 0.86, 0.45)
const THOUGHT := Color(0.58, 0.86, 1.0)
const WATER := Color(0.07, 0.11, 0.15)

signal finished

var ground_fn: Callable
var _jobs: Array = []            # [{task, id, data(result dict)}]
var _mat: Material
var _pending := 0
var built := false
var colliders: Array = []
var tri_count := 0

## specs: Array of settlement dictionaries with props already resolved to world y (see _prepare).
func build(extra: Dictionary, ground_cb: Callable) -> void:
	ground_fn = ground_cb
	_mat = ToonKit.material({"roughness": 0.85, "detail": 0.3, "outline": 0.0})
	for s in extra.get("settlements", []):
		var spec := _prepare(s)
		var job := {"id": str(s.get("id", "?")), "spec": spec, "out": {}}
		job["task"] = WorkerThreadPool.add_task(_build_job.bind(job), false, "rr_settlement_" + job["id"])
		_jobs.append(job)
		_pending += 1
	var tr: Dictionary = extra.get("cairn_trail", {})
	if not tr.is_empty():
		var spec2 := {"items": _trail_items(tr)}
		var job2 := {"id": "cairn_trail", "spec": spec2, "out": {}}
		job2["task"] = WorkerThreadPool.add_task(_build_job.bind(job2), false, "rr_cairn_trail")
		_jobs.append(job2)
		_pending += 1
	if _pending == 0:
		built = true
		finished.emit()

func _prepare(s: Dictionary) -> Dictionary:
	var c: Array = s["center"]
	var items: Array = []
	for p in s.get("props", []):
		var po: Array = p["p"]
		var x := float(c[0]) + float(po[0])
		var z := float(c[1]) + float(po[1])
		items.append({"k": str(p["k"]), "pos": Vector3(x, float(ground_fn.call(x, z)), z), "r": float(p.get("r", 0.0)), "s": float(p.get("s", 1.0)),
			"c": str(p.get("c", "")), "n": int(p.get("n", 1)), "len": float(p.get("len", 4.0)), "seed": int(p.get("seed", 1))})
	return {"items": items}

func _trail_items(tr: Dictionary) -> Array:
	var items: Array = []
	var path: Array = tr["path"]
	var step := float(tr.get("step", 16.0))
	var side := float(tr.get("side", 3.2))
	var carry := 0.0
	var k := 0
	for i in path.size() - 1:
		var a := Vector2(float(path[i][0]), float(path[i][1]))
		var b := Vector2(float(path[i + 1][0]), float(path[i + 1][1]))
		var len := a.distance_to(b)
		var dir := (b - a) / maxf(len, 0.001)
		var nrm := Vector2(-dir.y, dir.x)
		var t := step - carry
		while t <= len:
			var p := a + dir * t + nrm * side * (1.0 if k % 2 == 0 else -1.0)
			items.append({"k": "cairn", "pos": Vector3(p.x, float(ground_fn.call(p.x, p.y)), p.y), "r": float(k * 53 % 360), "s": 0.8, "c": "", "n": 1, "len": 0.0, "seed": k})
			k += 1
			t += step
		carry = len - (t - step)
	return items

func _process(_d: float) -> void:
	if _jobs.is_empty():
		set_process(false)
		return
	for j in _jobs.duplicate():
		if WorkerThreadPool.is_task_completed(j["task"]):
			WorkerThreadPool.wait_for_task_completion(j["task"])
			_attach(j)
			_jobs.erase(j)
			_pending -= 1
			break          # one attach per frame keeps the frame flat
	if _jobs.is_empty():
		built = true
		set_process(false)
		finished.emit()

func _ready() -> void:
	set_process(true)

func _attach(j: Dictionary) -> void:
	var out: Dictionary = j["out"]
	var mesh: Mesh = out.get("mesh")
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Settlement_" + str(j["id"])
	mi.mesh = mesh
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	tri_count += int(out.get("tris", 0))
	for c in out.get("colliders", []):
		var sb := ToonKit.static_box(self, c["xf"], c["size"])
		colliders.append(sb)

# ------------------------------------------------------------------ thread job
func _build_job(job: Dictionary) -> void:
	var st := ToonKit.begin()
	var cols: Array = []
	for it in job["spec"]["items"]:
		_prop(st, it, cols)
	var m := ToonKit.finish(st)
	job["out"] = {"mesh": m, "colliders": cols, "tris": m.get_faces().size() / 3 if m.get_surface_count() > 0 else 0}

static func _col(s: String, def: Color) -> Color:
	return Color(s) if s != "" else def

static func _prop(st: SurfaceTool, it: Dictionary, cols: Array) -> void:
	var pos: Vector3 = it["pos"]
	var s: float = it["s"]
	var T := Transform3D(Basis(Vector3.UP, deg_to_rad(float(it["r"]))).scaled(Vector3(s, s, s)), pos)
	var c: String = it["c"]
	match str(it["k"]):
		"tent": _tent(st, T, _col(c, CLOTH_SAND), cols, s)
		"awning": _awning(st, T, _col(c, CLOTH_RED))
		"cart": _cart(st, T, _col(c, WOOD), cols, s, int(it["n"]))
		"well": _well(st, T, cols, s)
		"crank_well": _well(st, T, cols, s * 0.62)
		"lantern": _lantern(st, T)
		"rack": _rack(st, T, _col(c, Color(0.52, 0.58, 0.30)))
		"crates": _crates(st, T, cols, s)
		"barrels": _barrels(st, T, int(it["n"]))
		"sacks": _sacks(st, T, int(it["n"]), _col(c, CLOTH_SAND), int(it["seed"]))
		"fire": _fire(st, T)
		"signpost": _signpost(st, T, _col(c, WOOD_LIGHT))
		"tripod": _tripod(st, T)
		"permit_board": _permit_board(st, T)
		"salt_basin": _salt_basin(st, T, int(it["seed"]))
		"salt_pile": _salt_pile(st, T)
		"rake": _rake(st, T)
		"rail": _rail(st, T, float(it["len"]), cols)
		"telescope": _telescope(st, T)
		"cairn": _cairn(st, T, int(it["seed"]))
		"banner": _banner(st, T, _col(c, CLOTH_RED))
		"stall": _stall(st, T, _col(c, CLOTH_OCHRE), cols)
		"glyph_wall": _glyph_wall(st, T, cols)
		"vault_door": _vault_door(st, T, cols)
		"pool": _pool(st, T)
		"plinth": _plinth(st, T)
		"stakes": _stakes(st, T, float(it["len"]))
		"terrace": _terrace(st, T)
		"stump": _stump(st, T, int(it["seed"]))
		"slate": _slate(st, T, int(it["seed"]))
		"hitch": _hitch(st, T, float(it["len"]))
		"trough": _trough(st, T)
		"bench": _bench(st, T)
		"table": _table(st, T)
		"spool": _spool(st, T)
		"cot": _cot(st, T, _col(c, CLOTH_GREEN))
		"mast": _mast(st, T)
		"flagline": _flagline(st, T, float(it["len"]))
		"standing_stone": _standing(st, T, int(it["seed"]))
		"broken_cart": _cart(st, T, _col(c, WOOD), cols, s, 1)
		_: pass

# ------------------------------------------------------------------ helpers
static func _xf(T: Transform3D, local: Vector3, basis: Basis = Basis()) -> Transform3D:
	return T * Transform3D(basis, local)

static func _sc(T: Transform3D) -> float:
	return T.basis.get_scale().x

static func _cyl(st: SurfaceTool, T: Transform3D, a: Vector3, b: Vector3, ra: float, rb: float, segs: int, col: Color, caps: bool = true) -> void:
	var sc := _sc(T)
	ToonKit.cylinder(st, T * a, T * b, ra * sc, rb * sc, segs, col, caps)

static func _box(st: SurfaceTool, T: Transform3D, center: Vector3, size: Vector3, col: Color, basis: Basis = Basis()) -> void:
	ToonKit.box(st, _xf(T, center, basis), size * _sc(T), col)

static func _cloth(st: SurfaceTool, T: Transform3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	ToonKit.quad(st, T * a, T * b, T * c, T * d, col)
	ToonKit.quad(st, T * a, T * d, T * c, T * b, col.darkened(0.12))

static func _collider(cols: Array, T: Transform3D, center: Vector3, size: Vector3) -> void:
	var sc := _sc(T)
	var tb := Transform3D(T.basis.orthonormalized(), T * center)
	cols.append({"xf": tb, "size": size * sc})

# ------------------------------------------------------------------ props
static func _tent(st: SurfaceTool, T: Transform3D, col: Color, cols: Array, s: float) -> void:
	var w := 1.3
	var L := 2.4
	var h := 1.7
	_cloth(st, T, Vector3(-w, 0, -L * 0.5), Vector3(-w, 0, L * 0.5), Vector3(0, h, L * 0.5), Vector3(0, h, -L * 0.5), col)
	_cloth(st, T, Vector3(w, 0, L * 0.5), Vector3(w, 0, -L * 0.5), Vector3(0, h, -L * 0.5), Vector3(0, h, L * 0.5), col.lightened(0.05))
	ToonKit.tri(st, T * Vector3(-w, 0, L * 0.5), T * Vector3(w, 0, L * 0.5), T * Vector3(0, h, L * 0.5), col.darkened(0.28))
	ToonKit.tri(st, T * Vector3(w, 0, -L * 0.5), T * Vector3(-w, 0, -L * 0.5), T * Vector3(0, h, -L * 0.5), col.darkened(0.4))
	_cyl(st, T, Vector3(0, 0, L * 0.5), Vector3(0, h + 0.35, L * 0.5), 0.05, 0.04, 5, WOOD, false)
	_cyl(st, T, Vector3(0, 0, -L * 0.5), Vector3(0, h + 0.35, -L * 0.5), 0.05, 0.04, 5, WOOD, false)
	_collider(cols, T, Vector3(0, h * 0.5, 0), Vector3(w * 1.7, h, L))

static func _awning(st: SurfaceTool, T: Transform3D, col: Color) -> void:
	for x in [-1.2, 1.2]:
		for z in [-0.8, 0.8]:
			_cyl(st, T, Vector3(x, 0, z), Vector3(x, 2.0 if z < 0 else 1.6, z), 0.05, 0.05, 5, WOOD, false)
	_cloth(st, T, Vector3(-1.4, 2.05, -0.9), Vector3(1.4, 2.05, -0.9), Vector3(1.4, 1.65, 0.95), Vector3(-1.4, 1.65, 0.95), col)

static func _cart(st: SurfaceTool, T: Transform3D, col: Color, cols: Array, s: float, n: int) -> void:
	_box(st, T, Vector3(0, 0.75, 0), Vector3(2.0, 0.18, 1.1), col)
	_box(st, T, Vector3(0, 1.0, 0.55), Vector3(2.0, 0.34, 0.08), col.darkened(0.1))
	_box(st, T, Vector3(0, 1.0, -0.55), Vector3(2.0, 0.34, 0.08), col.darkened(0.1))
	_box(st, T, Vector3(-1.0, 1.0, 0), Vector3(0.08, 0.34, 1.1), col.darkened(0.1))
	for z in [-0.68, 0.68]:
		ToonKit.torus(st, _xf(T, Vector3(0.3, 0.55, z)), 0.52 * _sc(T), 0.06 * _sc(T), 10, 4, WOOD.darkened(0.15))
		_cyl(st, T, Vector3(0.3, 0.55, z - 0.08), Vector3(0.3, 0.55, z + 0.08), 0.1, 0.1, 6, IRON)
	_cyl(st, T, Vector3(1.0, 0.75, -0.4), Vector3(2.7, 0.55, -0.4), 0.05, 0.05, 5, WOOD, false)
	_cyl(st, T, Vector3(1.0, 0.75, 0.4), Vector3(2.7, 0.55, 0.4), 0.05, 0.05, 5, WOOD, false)
	if n > 1:
		_sacks(st, T * Transform3D(Basis(), Vector3(0, 0.95, 0)), 4, CLOTH_SAND, 7)
	_collider(cols, T, Vector3(0.2, 0.7, 0), Vector3(2.4, 1.2, 1.3))

static func _well(st: SurfaceTool, T: Transform3D, cols: Array, s: float) -> void:
	_cyl(st, T, Vector3(0, 0, 0), Vector3(0, 0.85, 0), 1.0, 0.95, 10, STONE)
	_cyl(st, T, Vector3(0, 0.84, 0), Vector3(0, 0.86, 0), 0.68, 0.68, 10, WATER)
	for x in [-0.95, 0.95]:
		_cyl(st, T, Vector3(x, 0.8, 0), Vector3(x, 2.5, 0), 0.07, 0.06, 5, WOOD, false)
	_cyl(st, T, Vector3(-1.05, 2.2, 0), Vector3(1.05, 2.2, 0), 0.06, 0.06, 5, WOOD_LIGHT, false)
	_cloth(st, T, Vector3(-1.2, 2.55, -0.9), Vector3(1.2, 2.55, -0.9), Vector3(1.2, 2.2, 0.95), Vector3(-1.2, 2.2, 0.95), CLOTH_SAND)
	_cyl(st, T, Vector3(1.05, 2.2, 0), Vector3(1.55, 1.9, 0.0), 0.04, 0.04, 4, IRON, false)
	_cyl(st, T, Vector3(0, 1.5, 0), Vector3(0, 1.1, 0), 0.22, 0.2, 6, WOOD_LIGHT)
	_collider(cols, T, Vector3(0, 0.7, 0), Vector3(2.0, 1.4, 2.0))

static func _lantern(st: SurfaceTool, T: Transform3D) -> void:
	_cyl(st, T, Vector3.ZERO, Vector3(0, 2.3, 0), 0.05, 0.04, 5, IRON, false)
	_box(st, T, Vector3(0, 2.45, 0), Vector3(0.3, 0.34, 0.3), LAMP)
	_box(st, T, Vector3(0, 2.68, 0), Vector3(0.4, 0.07, 0.4), IRON)

static func _rack(st: SurfaceTool, T: Transform3D, col: Color) -> void:
	for x in [-1.1, 1.1]:
		_cyl(st, T, Vector3(x, 0, 0), Vector3(x, 1.7, 0), 0.05, 0.05, 5, WOOD, false)
	_cyl(st, T, Vector3(-1.2, 1.65, 0), Vector3(1.2, 1.65, 0), 0.04, 0.04, 5, WOOD_LIGHT, false)
	for i in 7:
		var x := -0.9 + float(i) * 0.3
		_box(st, T, Vector3(x, 1.2, 0), Vector3(0.12, 0.8, 0.03), col.lerp(CLOTH_SAND, float(i % 3) * 0.25))

static func _crates(st: SurfaceTool, T: Transform3D, cols: Array, s: float) -> void:
	_box(st, T, Vector3(0, 0.4, 0), Vector3(1.0, 0.8, 0.9), WOOD_LIGHT)
	_box(st, T, Vector3(0.9, 0.3, 0.2), Vector3(0.7, 0.6, 0.7), WOOD)
	_box(st, T, Vector3(0.15, 1.05, 0.0), Vector3(0.7, 0.5, 0.7), WOOD.lightened(0.1), Basis(Vector3.UP, 0.4))
	_collider(cols, T, Vector3(0.4, 0.5, 0.1), Vector3(1.9, 1.0, 1.0))

static func _barrels(st: SurfaceTool, T: Transform3D, n: int) -> void:
	for i in maxi(1, n):
		var p := Vector3(float(i) * 0.75, 0, float(i % 2) * 0.5)
		_cyl(st, T, p, p + Vector3(0, 0.9, 0), 0.34, 0.34, 8, WOOD)
		_cyl(st, T, p + Vector3(0, 0.25, 0), p + Vector3(0, 0.3, 0), 0.355, 0.355, 8, IRON, false)
		_cyl(st, T, p + Vector3(0, 0.65, 0), p + Vector3(0, 0.7, 0), 0.355, 0.355, 8, IRON, false)

static func _sacks(st: SurfaceTool, T: Transform3D, n: int, col: Color, seed_v: int) -> void:
	var sc := _sc(T)
	for i in maxi(1, n):
		var p := Vector3(float(i % 3) * 0.55 - 0.4, 0.2 + float(i / 3) * 0.35, float(i % 2) * 0.45 - 0.2)
		ToonKit.rock(st, T * p, Vector3(0.3, 0.24, 0.26) * sc, col.darkened(float(i % 3) * 0.06), seed_v + i, 0)

static func _fire(st: SurfaceTool, T: Transform3D) -> void:
	for i in 7:
		var a := TAU * float(i) / 7.0
		ToonKit.rock(st, T * Vector3(cos(a) * 0.55, 0.1, sin(a) * 0.55), Vector3(0.18, 0.14, 0.18) * _sc(T), STONE_DARK, 300 + i, 0)
	_cyl(st, T, Vector3(0, 0, 0), Vector3(0, 0.1, 0), 0.45, 0.45, 8, Color(0.08, 0.06, 0.05))
	_cyl(st, T, Vector3(0, 0.08, 0), Vector3(0, 0.62, 0), 0.26, 0.0, 6, FLAME, false)
	_cyl(st, T, Vector3(0, 0.08, 0), Vector3(0, 0.38, 0), 0.14, 0.0, 5, Color(1.0, 0.9, 0.5), false)

static func _signpost(st: SurfaceTool, T: Transform3D, col: Color) -> void:
	_cyl(st, T, Vector3.ZERO, Vector3(0, 2.6, 0), 0.08, 0.07, 6, WOOD, false)
	# arrow plank pointing +X with a pointed tip
	_box(st, T, Vector3(0.55, 2.2, 0), Vector3(1.2, 0.36, 0.07), col)
	ToonKit.tri(st, T * Vector3(1.15, 2.38, 0.036), T * Vector3(1.15, 2.02, 0.036), T * Vector3(1.5, 2.2, 0.036), col)
	ToonKit.tri(st, T * Vector3(1.15, 2.02, -0.036), T * Vector3(1.15, 2.38, -0.036), T * Vector3(1.5, 2.2, -0.036), col)
	_box(st, T, Vector3(-0.35, 1.7, 0), Vector3(0.9, 0.3, 0.07), col.darkened(0.12))
	_box(st, T, Vector3(0.0, 0.1, 0), Vector3(0.5, 0.2, 0.5), STONE_DARK)

static func _tripod(st: SurfaceTool, T: Transform3D) -> void:
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.4
		_cyl(st, T, Vector3(cos(a) * 0.7, 0, sin(a) * 0.7), Vector3(0, 1.45, 0), 0.04, 0.035, 4, WOOD_LIGHT, false)
	_box(st, T, Vector3(0, 1.55, 0), Vector3(0.3, 0.2, 0.26), IRON)
	_cyl(st, T, Vector3(0, 1.58, -0.1), Vector3(0.0, 1.62, -0.55), 0.07, 0.09, 6, Color(0.18, 0.2, 0.24))
	_box(st, T, Vector3(0, 1.72, 0.0), Vector3(0.1, 0.1, 0.1), DOM_RED)

static func _permit_board(st: SurfaceTool, T: Transform3D) -> void:
	for x in [-0.85, 0.85]:
		_cyl(st, T, Vector3(x, 0, 0), Vector3(x, 2.1, 0), 0.06, 0.06, 5, CLOTH_GREY.darkened(0.2), false)
	_box(st, T, Vector3(0, 1.45, 0), Vector3(1.9, 1.15, 0.07), CLOTH_GREY.darkened(0.1))
	for i in 6:
		var x := -0.6 + float(i % 3) * 0.6
		var y := 1.7 - float(i / 3) * 0.5
		_box(st, T, Vector3(x, y, 0.06), Vector3(0.42, 0.34, 0.015), Color(0.9, 0.88, 0.8).darkened(float(i) * 0.03), Basis(Vector3.BACK, 0.05 * float(i % 3 - 1)))
	_box(st, T, Vector3(0, 2.1, 0.0), Vector3(2.0, 0.1, 0.12), DOM_RED)

static func _salt_basin(st: SurfaceTool, T: Transform3D, seed_v: int) -> void:
	_box(st, T, Vector3(0, 0.1, 0), Vector3(3.4, 0.22, 2.2), STONE_DARK)
	_box(st, T, Vector3(0, 0.2, 0), Vector3(3.0, 0.06, 1.8), SALT.darkened(0.04 * float(seed_v % 3)))
	_box(st, T, Vector3(-0.6, 0.24, 0.2), Vector3(0.9, 0.04, 0.5), SALT)

static func _salt_pile(st: SurfaceTool, T: Transform3D) -> void:
	_cyl(st, T, Vector3.ZERO, Vector3(0, 1.3, 0), 1.2, 0.0, 9, SALT)
	_cyl(st, T, Vector3(1.1, 0, 0.4), Vector3(1.1, 0.8, 0.4), 0.7, 0.0, 8, SALT.darkened(0.05))

static func _rake(st: SurfaceTool, T: Transform3D) -> void:
	_cyl(st, T, Vector3(0, 0.1, 0), Vector3(1.4, 1.5, 0), 0.03, 0.03, 4, WOOD, false)
	_box(st, T, Vector3(-0.1, 0.05, 0), Vector3(0.12, 0.06, 0.8), WOOD_LIGHT)

static func _rail(st: SurfaceTool, T: Transform3D, len: float, cols: Array) -> void:
	var n := int(len / 1.5)
	for i in n + 1:
		var x := -len * 0.5 + float(i) * len / float(maxi(n, 1))
		_cyl(st, T, Vector3(x, 0, 0), Vector3(x, 1.15, 0), 0.07, 0.06, 5, STONE)
	_box(st, T, Vector3(0, 1.1, 0), Vector3(len + 0.2, 0.1, 0.16), STONE.lightened(0.05))
	_box(st, T, Vector3(0, 0.62, 0), Vector3(len, 0.06, 0.08), STONE_DARK)
	_collider(cols, T, Vector3(0, 0.6, 0), Vector3(len, 1.2, 0.3))

static func _telescope(st: SurfaceTool, T: Transform3D) -> void:
	for i in 3:
		var a := TAU * float(i) / 3.0
		_cyl(st, T, Vector3(cos(a) * 0.6, 0, sin(a) * 0.6), Vector3(0, 1.3, 0), 0.035, 0.03, 4, WOOD_LIGHT, false)
	_cyl(st, T, Vector3(-0.3, 1.2, 0.25), Vector3(0.6, 1.55, -0.25), 0.07, 0.1, 7, Color(0.55, 0.42, 0.22))
	_cyl(st, T, Vector3(0.58, 1.54, -0.24), Vector3(0.7, 1.58, -0.29), 0.1, 0.1, 7, IRON)

static func _cairn(st: SurfaceTool, T: Transform3D, seed_v: int) -> void:
	var sc := _sc(T)
	var rs := [0.55, 0.42, 0.32, 0.22]
	var y := 0.0
	for i in 4:
		var r: float = rs[i] * sc
		ToonKit.rock(st, T * Vector3(float(i % 2) * 0.05, y + r * 0.35, 0), Vector3(r, r * 0.55, r * 0.9), SURVEY.darkened(float(i) * 0.05), 400 + seed_v * 7 + i, 0)
		y += r * 0.8 / sc
	ToonKit.rock(st, T * Vector3(0.0, y + 0.08, 0.0), Vector3(0.07, 0.05, 0.07) * sc, DOM_RED, 3, 0)

static func _banner(st: SurfaceTool, T: Transform3D, col: Color) -> void:
	_cyl(st, T, Vector3.ZERO, Vector3(0, 3.6, 0), 0.06, 0.05, 5, WOOD, false)
	_cloth(st, T, Vector3(0.05, 3.5, 0), Vector3(1.3, 3.4, 0), Vector3(1.3, 2.4, 0), Vector3(0.05, 2.5, 0), col)
	ToonKit.tri(st, T * Vector3(0.05, 2.5, 0.01), T * Vector3(1.3, 2.4, 0.01), T * Vector3(0.65, 1.95, 0.01), col.darkened(0.1))

static func _stall(st: SurfaceTool, T: Transform3D, col: Color, cols: Array) -> void:
	for x in [-1.3, 1.3]:
		_cyl(st, T, Vector3(x, 0, -0.8), Vector3(x, 2.3, -0.8), 0.06, 0.06, 5, WOOD, false)
		_cyl(st, T, Vector3(x, 0, 0.8), Vector3(x, 1.9, 0.8), 0.06, 0.06, 5, WOOD, false)
	_cloth(st, T, Vector3(-1.5, 2.35, -0.9), Vector3(1.5, 2.35, -0.9), Vector3(1.5, 1.95, 0.95), Vector3(-1.5, 1.95, 0.95), col)
	_box(st, T, Vector3(0, 0.55, 0.55), Vector3(2.4, 0.12, 0.8), WOOD_LIGHT)
	_box(st, T, Vector3(0, 0.27, 0.55), Vector3(2.2, 0.54, 0.7), WOOD.darkened(0.1))
	_collider(cols, T, Vector3(0, 0.5, 0.55), Vector3(2.4, 1.0, 0.8))

static func _glyph_wall(st: SurfaceTool, T: Transform3D, cols: Array) -> void:
	_box(st, T, Vector3(0, 1.7, 0), Vector3(7.0, 3.4, 0.7), Color(0.66, 0.46, 0.36))
	_box(st, T, Vector3(0, 3.5, 0), Vector3(7.3, 0.3, 0.9), STONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for r in 4:
		for k in 8:
			var x := -3.1 + float(k) * 0.88
			var y := 0.65 + float(r) * 0.72
			var w := rng.randf_range(0.18, 0.5)
			var h := rng.randf_range(0.08, 0.3)
			_box(st, T, Vector3(x, y, 0.37), Vector3(w, h, 0.04), Color(0.28, 0.17, 0.14))
			if rng.randf() < 0.5:
				_box(st, T, Vector3(x + 0.12, y + 0.18, 0.37), Vector3(0.05, 0.22, 0.04), Color(0.28, 0.17, 0.14))
	_collider(cols, T, Vector3(0, 1.7, 0), Vector3(7.0, 3.4, 0.8))

static func _vault_door(st: SurfaceTool, T: Transform3D, cols: Array) -> void:
	_box(st, T, Vector3(-2.0, 2.0, 0), Vector3(1.1, 4.0, 1.2), STONE)
	_box(st, T, Vector3(2.0, 2.0, 0), Vector3(1.1, 4.0, 1.2), STONE)
	_box(st, T, Vector3(0, 4.2, 0), Vector3(5.4, 0.8, 1.2), STONE.lightened(0.04))
	_box(st, T, Vector3(0, 1.9, -0.1), Vector3(3.0, 3.8, 0.7), Color(0.34, 0.32, 0.36))
	_box(st, T, Vector3(0, 1.9, 0.27), Vector3(0.08, 3.4, 0.05), THOUGHT)
	for i in 4:
		_box(st, T, Vector3(-0.9 + float(i % 2) * 1.8, 1.0 + float(i / 2) * 1.6, 0.27), Vector3(0.9, 0.05, 0.05), THOUGHT.darkened(0.2))
	_collider(cols, T, Vector3(0, 2.0, 0), Vector3(5.4, 4.0, 1.2))

static func _pool(st: SurfaceTool, T: Transform3D) -> void:
	var flat := Basis(Vector3.RIGHT, deg_to_rad(90.0))
	ToonKit.torus(st, _xf(T, Vector3(0, 0.4, 0), flat), 4.0 * _sc(T), 0.4 * _sc(T), 20, 5, STONE)
	_cyl(st, T, Vector3(0, 0.1, 0), Vector3(0, 0.32, 0), 3.9, 3.9, 20, WATER)
	for i in 3:
		_box(st, T, Vector3(0, 0.12 + float(i) * 0.12, 4.6 + float(2 - i) * 0.4), Vector3(2.2, 0.24, 0.5), STONE_DARK)

static func _plinth(st: SurfaceTool, T: Transform3D) -> void:
	_box(st, T, Vector3(0, 0.5, 0), Vector3(1.4, 1.0, 0.8), STONE)
	_box(st, T, Vector3(0, 1.05, 0), Vector3(1.55, 0.12, 0.95), STONE.lightened(0.06))
	for i in 5:
		_box(st, T, Vector3(-0.5 + float(i) * 0.25, 0.6, 0.41), Vector3(0.1, 0.05 + float(i % 3) * 0.08, 0.02), Color(0.25, 0.18, 0.15))

static func _stakes(st: SurfaceTool, T: Transform3D, len: float) -> void:
	var pts := [Vector3(0, 0, 0), Vector3(len, 0, 0.6), Vector3(len * 0.8, 0, len * 0.9), Vector3(-0.4, 0, len * 0.7)]
	for i in pts.size():
		var p: Vector3 = pts[i]
		_cyl(st, T, p, p + Vector3(0, 1.0, 0), 0.04, 0.03, 4, WOOD_LIGHT, false)
		_box(st, T, p + Vector3(0.1, 0.9, 0), Vector3(0.22, 0.14, 0.02), DOM_RED)
		var q: Vector3 = pts[(i + 1) % pts.size()]
		_cyl(st, T, p + Vector3(0, 0.75, 0), q + Vector3(0, 0.75, 0), 0.012, 0.012, 3, ROPE, false)

static func _terrace(st: SurfaceTool, T: Transform3D) -> void:
	for i in 3:
		_box(st, T, Vector3(float(i) * 0.9, 0.18 + float(i) * 0.3, 0), Vector3(3.0 - float(i) * 0.4, 0.36 + float(i) * 0.3, 7.0 - float(i) * 1.2), Color(0.52, 0.5, 0.3).lerp(STONE, float(i) * 0.3))
		_box(st, T, Vector3(float(i) * 0.9, 0.38 + float(i) * 0.3 + float(i) * 0.15, 0), Vector3(2.6 - float(i) * 0.4, 0.06, 6.6 - float(i) * 1.2), Color(0.5, 0.56, 0.3))

static func _stump(st: SurfaceTool, T: Transform3D, seed_v: int) -> void:
	var sc := _sc(T)
	ToonKit.cylinder(st, T * Vector3(0, -0.3, 0), T * Vector3(0, 2.4, 0), 0.9 * sc, 0.75 * sc, 8, STONE_DARK, true, 0.16, 500 + seed_v)
	ToonKit.rock(st, T * Vector3(0.7, 0.3, 0.5), Vector3(0.5, 0.4, 0.5) * sc, STONE, 510 + seed_v, 0)
	_cyl(st, T, Vector3(0.2, 2.3, 0.1), Vector3(1.6, 2.0, -0.4), 0.05, 0.04, 4, IRON, false)

static func _slate(st: SurfaceTool, T: Transform3D, seed_v: int) -> void:
	ToonKit.rock(st, T * Vector3(0, 0.1, 0), Vector3(1.0, 0.22, 0.8) * _sc(T), Color(0.4, 0.38, 0.42), 600 + seed_v, 1)

static func _hitch(st: SurfaceTool, T: Transform3D, len: float) -> void:
	for x in [-len * 0.5, len * 0.5]:
		_cyl(st, T, Vector3(x, 0, 0), Vector3(x, 1.1, 0), 0.07, 0.06, 5, WOOD, false)
	_cyl(st, T, Vector3(-len * 0.5, 0.95, 0), Vector3(len * 0.5, 0.95, 0), 0.05, 0.05, 5, WOOD_LIGHT, false)

static func _trough(st: SurfaceTool, T: Transform3D) -> void:
	_box(st, T, Vector3(0, 0.3, 0), Vector3(2.6, 0.6, 0.8), STONE_DARK)
	_box(st, T, Vector3(0, 0.55, 0), Vector3(2.3, 0.1, 0.55), WATER)

static func _bench(st: SurfaceTool, T: Transform3D) -> void:
	_box(st, T, Vector3(0, 0.45, 0), Vector3(1.8, 0.12, 0.5), STONE.lightened(0.04))
	_box(st, T, Vector3(-0.7, 0.2, 0), Vector3(0.2, 0.4, 0.45), STONE_DARK)
	_box(st, T, Vector3(0.7, 0.2, 0), Vector3(0.2, 0.4, 0.45), STONE_DARK)

static func _table(st: SurfaceTool, T: Transform3D) -> void:
	_box(st, T, Vector3(0, 0.85, 0), Vector3(1.8, 0.08, 0.9), WOOD_LIGHT)
	for x in [-0.8, 0.8]:
		for z in [-0.35, 0.35]:
			_cyl(st, T, Vector3(x, 0, z), Vector3(x, 0.85, z), 0.04, 0.04, 4, WOOD, false)
	_box(st, T, Vector3(-0.2, 0.9, 0.05), Vector3(0.6, 0.015, 0.45), Color(0.92, 0.9, 0.8), Basis(Vector3.UP, 0.15))
	_box(st, T, Vector3(0.5, 0.92, -0.1), Vector3(0.18, 0.03, 0.12), DOM_RED)

static func _spool(st: SurfaceTool, T: Transform3D) -> void:
	_cyl(st, T, Vector3(0, 0.0, 0), Vector3(0, 0.1, 0), 0.7, 0.7, 10, WOOD)
	_cyl(st, T, Vector3(0, 0.1, 0), Vector3(0, 0.75, 0), 0.5, 0.5, 10, ROPE.darkened(0.15))
	_cyl(st, T, Vector3(0, 0.75, 0), Vector3(0, 0.85, 0), 0.7, 0.7, 10, WOOD)

static func _cot(st: SurfaceTool, T: Transform3D, col: Color) -> void:
	_box(st, T, Vector3(0, 0.3, 0), Vector3(0.8, 0.12, 1.9), WOOD)
	_box(st, T, Vector3(0, 0.4, 0), Vector3(0.7, 0.1, 1.7), col)
	_box(st, T, Vector3(0, 0.48, -0.7), Vector3(0.5, 0.12, 0.3), CLOTH_SAND)

static func _mast(st: SurfaceTool, T: Transform3D) -> void:
	_cyl(st, T, Vector3.ZERO, Vector3(0, 7.5, 0), 0.14, 0.07, 6, IRON, false)
	for i in 3:
		var a := TAU * float(i) / 3.0
		_cyl(st, T, Vector3(cos(a) * 1.8, 0, sin(a) * 1.8), Vector3(0, 5.5, 0), 0.02, 0.02, 3, IRON, false)
	_box(st, T, Vector3(0, 7.6, 0), Vector3(0.4, 0.3, 0.4), DOM_RED)

static func _flagline(st: SurfaceTool, T: Transform3D, len: float) -> void:
	for x in [0.0, len]:
		_cyl(st, T, Vector3(x, 0, 0), Vector3(x, 3.0, 0), 0.06, 0.05, 5, WOOD, false)
	var n := int(len / 0.7)
	for i in n:
		var x0 := 0.3 + float(i) * 0.7
		var sag := 0.35 * sin(PI * x0 / len)
		_cloth(st, T, Vector3(x0, 2.95 - sag, 0), Vector3(x0 + 0.45, 2.95 - sag, 0), Vector3(x0 + 0.38, 2.45 - sag, 0), Vector3(x0 + 0.08, 2.45 - sag, 0), [CLOTH_RED, CLOTH_OCHRE, CLOTH_SAND, CLOTH_GREEN][i % 4])
	_cyl(st, T, Vector3(0, 3.0, 0), Vector3(len * 0.5, 2.6, 0), 0.012, 0.012, 3, ROPE, false)
	_cyl(st, T, Vector3(len * 0.5, 2.6, 0), Vector3(len, 3.0, 0), 0.012, 0.012, 3, ROPE, false)

static func _standing(st: SurfaceTool, T: Transform3D, seed_v: int) -> void:
	var sc := _sc(T)
	ToonKit.rock(st, T * Vector3(0, 1.2, 0), Vector3(0.45, 1.4, 0.35) * sc, Color(0.66, 0.46, 0.36), 700 + seed_v, 1)
	_box(st, T, Vector3(0, 1.3, 0.3), Vector3(0.25, 0.05, 0.03), Color(0.26, 0.16, 0.13))
