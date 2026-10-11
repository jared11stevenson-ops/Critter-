class_name PerfStats
extends RefCounted
## Pure frame-time statistics (no engine access): ring buffer, hitch log, per-scene and per-context stats, render peaks.
## Fed by the Perf autoload; unit-tested directly.

const RING := 3600
const HITCH_MS := [50.0, 100.0, 250.0]
const SLOW_30_MS := 33.4
const SLOW_60_MS := 16.8

var ft := PackedFloat32Array()
var ft_i := 0
var ft_n := 0
var session_t := 0.0
var hitches: Array = []                  # newest last: {t, ms, scene, ctx}
var hitch_counts := [0, 0, 0]
var peak := {"draws": 0, "prims": 0, "objs": 0, "nodes": 0}
var draw_sum := 0.0
var draw_n := 0
var scene_stats: Dictionary = {}         # scene -> {n, sum, worst, slow}
var ctx_stats: Dictionary = {}           # ctx -> {n, sum, worst, slow}
var live := {"draws": 0, "prims": 0, "objs": 0}


func _init() -> void:
	ft.resize(RING)
	reset()


func reset() -> void:
	ft_i = 0
	ft_n = 0
	session_t = 0.0
	hitches.clear()
	hitch_counts = [0, 0, 0]
	peak = {"draws": 0, "prims": 0, "objs": 0, "nodes": 0}
	draw_sum = 0.0
	draw_n = 0
	scene_stats.clear()
	ctx_stats = {"play": _blank(), "menu": _blank()}


static func _blank() -> Dictionary:
	return {"n": 0, "sum": 0.0, "worst": 0.0, "slow": 0}


static func _bump(d: Dictionary, ms: float) -> void:
	d["n"] += 1
	d["sum"] += ms
	d["worst"] = maxf(d["worst"], ms)
	if ms > SLOW_30_MS:
		d["slow"] += 1


func record_frame(ms: float, scene: String = "-", ctx: String = "play") -> void:
	session_t += ms / 1000.0
	ft[ft_i] = ms
	ft_i = (ft_i + 1) % RING
	ft_n = mini(ft_n + 1, RING)
	if not ctx_stats.has(ctx):
		ctx_stats[ctx] = _blank()
	_bump(ctx_stats[ctx], ms)
	if not scene_stats.has(scene):
		scene_stats[scene] = _blank()
	_bump(scene_stats[scene], ms)
	for i in 3:
		if ms >= HITCH_MS[i]:
			hitch_counts[i] += 1
	if ms >= HITCH_MS[0]:
		hitches.append({"t": snappedf(session_t, 0.1), "ms": snappedf(ms, 0.1), "scene": scene, "ctx": ctx})
		if hitches.size() > 60:
			hitches.pop_front()


func record_render(draws: int, prims: int, objs: int, nodes: int) -> void:
	live = {"draws": draws, "prims": prims, "objs": objs}
	peak["draws"] = maxi(peak["draws"], draws)
	peak["prims"] = maxi(peak["prims"], prims)
	peak["objs"] = maxi(peak["objs"], objs)
	peak["nodes"] = maxi(peak["nodes"], nodes)
	draw_sum += draws
	draw_n += 1


## Statistics over the last `n` recorded frames.
func frame_stats(n: int = RING) -> Dictionary:
	n = mini(n, ft_n)
	var out := {"n": n, "fps": 0.0, "avg": 0.0, "p50": 0.0, "p95": 0.0, "p99": 0.0, "worst": 0.0, "under30": 0.0, "under60": 0.0}
	if n <= 0:
		return out
	var a := PackedFloat32Array()
	a.resize(n)
	var sum := 0.0
	var slow30 := 0
	var slow60 := 0
	for k in n:
		var v := ft[(ft_i - 1 - k + RING * 2) % RING]
		a[k] = v
		sum += v
		if v > SLOW_30_MS:
			slow30 += 1
		if v > SLOW_60_MS:
			slow60 += 1
	a.sort()
	out["avg"] = sum / n
	out["fps"] = 1000.0 / maxf(out["avg"], 0.001)
	out["p50"] = a[n / 2]
	out["p95"] = a[mini(n - 1, int(n * 0.95))]
	out["p99"] = a[mini(n - 1, int(n * 0.99))]
	out["worst"] = a[n - 1]
	out["under30"] = 100.0 * slow30 / n
	out["under60"] = 100.0 * slow60 / n
	return out


## Last `n` frame times (ms), oldest first.
func recent_frames(n: int) -> PackedFloat32Array:
	n = mini(n, ft_n)
	var a := PackedFloat32Array()
	a.resize(n)
	for k in n:
		a[k] = ft[(ft_i - n + k + RING * 2) % RING]
	return a


static func _summ(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		var e: Dictionary = src[k]
		out[k] = {"frames": e["n"], "avg_ms": snappedf(e["sum"] / maxf(1.0, e["n"]), 0.1),
			"worst_ms": snappedf(e["worst"], 0.1), "slow_pct": snappedf(100.0 * e["slow"] / maxf(1.0, e["n"]), 0.1)}
	return out


## Engine-free part of the report (Perf adds device / memory / script timings).
func core_report() -> Dictionary:
	var fs := frame_stats()
	var fr := {}
	for k in fs:
		fr[k] = snappedf(fs[k], 0.1) if fs[k] is float else fs[k]
	return {
		"session_seconds": snappedf(session_t, 0.1),
		"frames": fr,
		"hitch_counts": {"over_50ms": hitch_counts[0], "over_100ms": hitch_counts[1], "over_250ms": hitch_counts[2]},
		"hitches_recent": hitches.slice(maxi(0, hitches.size() - 12)),
		"render": {
			"draws_now": live["draws"], "draws_avg": int(draw_sum / maxf(1.0, draw_n)), "draws_peak": peak["draws"],
			"primitives_now": live["prims"], "primitives_peak": peak["prims"], "objects_peak": peak["objs"],
			"nodes_peak": peak["nodes"],
		},
		"by_scene": _summ(scene_stats),
		"by_context": _summ(ctx_stats),
	}
