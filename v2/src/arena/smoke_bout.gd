extends Node
## Scripted bout for QA. Run (user args after `--`):
##   godot --headless --path v2 res://src/arena/smoke_bout.tscn --fixed-fps 60 -- --a=aruun --b=cigarra --profile=standard --speed=6
##   xvfb-run -a godot --path v2 --rendering-driver opengl3 --resolution 1280x720 res://src/arena/smoke_bout.tscn -- --shots=DIR --shot-at=0.5,3,7
## Prints one `SMOKE_RESULT {json}` line (winner, reason, ticks, wall time, draws/tris/hitch stats when rendered). Exit 0 unless the bout never ended.
## Options: --a --b --profile (both AIs) --arena --seed --speed (Engine.time_scale) --max-sec (sim-time cap) --shots --shot-at (comma sec) --touch (show controls)
##          --human (fighter 0 plays a scripted button-masher through PlayerInput) --layout=A|B

var args := {}
var bout: BoutScene
var t := 0.0
var shots: Array = []
var shot_dir := ""
var worst_ms := 0.0
var hitches := 0
var draws_max := 0
var draws_sum := 0
var tris_max := 0
var frames := 0
var started_us := 0
var rendered := false
var done := false
var mash := false
var _mash_t := 0.0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var p := a.trim_prefix("--").split("=", true, 1)
		args[p[0]] = p[1] if p.size() > 1 else "1"
	rendered = DisplayServer.get_name() != "headless"
	var cfg := BoutConfig.new()
	cfg.a_id = str(args.get("a", "aruun"))
	cfg.b_id = str(args.get("b", "cigarra"))
	cfg.human_a = args.has("human")
	mash = cfg.human_a
	cfg.profile_a = str(args.get("profile", "standard"))
	cfg.profile_b = str(args.get("profile", "standard"))
	cfg.arena_id = str(args.get("arena", "ring"))
	cfg.seed_value = int(args.get("seed", 7))
	cfg.intro = args.has("intro")
	cfg.training = args.has("training")
	UiPrefs.set_pref("layout", str(args.get("layout", "A")), false)
	if args.has("touch"):
		UiPrefs.set_pref("touch", "on", false)
	Engine.time_scale = float(args.get("speed", 1.0))
	if args.has("shots"):
		shot_dir = str(args["shots"])
		DirAccess.make_dir_recursive_absolute(shot_dir)
		for s in str(args.get("shot-at", "1,4")).split(","):
			shots.append(float(s))
	bout = BoutScene.new()
	if bout == null:
		get_tree().quit(2)
		return
	add_child(bout)
	bout.start(cfg)
	bout.finished.connect(_on_finished)
	started_us = Time.get_ticks_usec()

func _process(delta: float) -> void:
	if done or bout == null:
		return
	var real := delta / maxf(Engine.time_scale, 0.001)
	t += delta
	frames += 1
	if frames > 5:
		worst_ms = maxf(worst_ms, real * 1000.0)
		if real > 0.05:
			hitches += 1
	if rendered:
		var d := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		draws_max = maxi(draws_max, d)
		draws_sum += d
		tris_max = maxi(tris_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	if mash and bout.player != null and bout.phase == "fight":
		_mash_t += delta
		var p := bout.player
		p.stick = Vector2(0, -0.8) if fmod(_mash_t, 3.0) < 2.0 else Vector2(0.7, 0.4)
		p.guard_level = fmod(_mash_t, 2.3) > 1.9
		p.strike_level = fmod(_mash_t, 0.5) < 0.12 or fmod(_mash_t, 1.7) < 0.5
		match int(_mash_t * 2.0) % 9:
			3: p.press("dodge")
			5: p.press("a1")
			7: p.press("grab")
	if shots.size() > 0 and t >= float(shots[0]):
		_shot(float(shots.pop_front()))
	if t > float(args.get("max-sec", 200.0)):
		_finish(false)

func _shot(at: float) -> void:
	if not rendered:
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var vs := get_viewport().get_visible_rect().size
	var path := "%s/bout_%dx%d_t%03d.png" % [shot_dir, int(vs.x), int(vs.y), int(at * 10.0)]
	img.save_png(path)
	print("SHOT ", path)

func _on_finished(result: Dictionary) -> void:
	_finish(true, result)

func _finish(ended: bool, result := {}) -> void:
	if done:
		return
	done = true
	var wall := float(Time.get_ticks_usec() - started_us) / 1e6
	var out := {"ended": ended, "winner": result.get("winner", -2), "reason": result.get("reason", ""), "killed": result.get("killed", false),
		"ticks": bout.stats["ticks"], "events": bout.stats["events"], "sim_sec": snappedf(t, 0.01), "wall_sec": snappedf(wall, 0.01),
		"frames": frames, "worst_frame_ms": snappedf(worst_ms, 0.1), "hitches_50ms": hitches,
		"draws_max": draws_max, "draws_avg": (draws_sum / maxi(1, frames)) if rendered else 0, "tris_max": tris_max,
		"max_ticks_per_frame": bout.stats["max_ticks_frame"], "pair": "%s vs %s" % [bout.cfg.a_id, bout.cfg.b_id]}
	print("SMOKE_RESULT ", JSON.stringify(out))
	if shots.size() > 0 and rendered:
		await _shot(t)
	get_tree().quit(0 if ended else 1)
