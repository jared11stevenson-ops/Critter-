extends RefCounted
## BoutScene: fixed 60 Hz sim independent of render FPS, camera fit, event routing, intro hold, completion, determinism across frame rates.

func _bout(a: String, b: String, seed_value := 5, intro := false, profile := "standard") -> BoutScene:
	var cfg := BoutConfig.new()
	cfg.a_id = a
	cfg.b_id = b
	cfg.human_a = false
	cfg.profile_a = profile
	cfg.profile_b = profile
	cfg.seed_value = seed_value
	cfg.intro = intro
	var tree := Engine.get_main_loop() as SceneTree
	var s := BoutScene.new()
	tree.root.add_child(s)
	s.start(cfg)
	return s

func _run_hashes(frame_dt: float, upto: int) -> Dictionary:
	var s := _bout("aruun", "zephyr", 11)
	var hashes := {}
	s.on_tick = func(sim: CombatSim): if sim.tick % 60 == 0: hashes[sim.tick] = sim.state_hash()
	var guard := 0
	while s.sim.tick < upto and guard < 100000:
		s._process(frame_dt)
		guard += 1
	s.free()
	return hashes

func run() -> Array:
	var fails: Array = []
	# --- fixed timestep: ticks follow wall time, not frames
	var s := _bout("aruun", "cigarra")
	for i in 120:
		s._process(1.0 / 60.0)
	QaCheck.is_true(fails, absi(s.sim.tick - 120) <= 1, "60 fps: 120 frames = ~120 ticks (got %d)" % s.sim.tick)
	s.free()
	s = _bout("aruun", "cigarra")
	for i in 288:
		s._process(1.0 / 144.0)
	QaCheck.is_true(fails, absi(s.sim.tick - 120) <= 1, "144 fps: 2 s = ~120 ticks (got %d)" % s.sim.tick)
	s.free()
	s = _bout("aruun", "cigarra")
	s._process(0.5)
	QaCheck.is_true(fails, s.sim.tick <= 8, "a long hitch is clamped to <= 8 ticks (got %d)" % s.sim.tick)
	QaCheck.is_true(fails, s.stats["max_ticks_frame"] <= 8, "stats track max ticks per frame")
	s.free()
	# --- same ticks => same state at 60 fps, 144 fps and 30 fps
	var h60 := _run_hashes(1.0 / 60.0, 421)
	var h144 := _run_hashes(1.0 / 144.0, 421)
	var h30 := _run_hashes(1.0 / 30.0, 421)
	QaCheck.is_true(fails, h60.size() >= 6, "hashes recorded")
	for k in h60:
		QaCheck.is_true(fails, h144.has(k) and h144[k] == h60[k], "tick %d identical at 144 fps" % k)
		QaCheck.is_true(fails, h30.has(k) and h30[k] == h60[k], "tick %d identical at 30 fps" % k)
	# --- intro holds the sim; rigs follow sim positions; events routed
	s = _bout("bramvex", "scarlith", 3, true)
	for i in 60:
		s._process(1.0 / 60.0)
	QaCheck.eq(fails, s.sim.tick, 0, "no sim ticks during the intro")
	QaCheck.eq(fails, s.phase, "intro", "still in intro after 1 s")
	for i in 150:
		s._process(1.0 / 60.0)
	QaCheck.eq(fails, s.phase, "fight", "intro ends")
	var n_events := [0]
	s.fight_event.connect(func(_e): n_events[0] += 1)
	for i in 600:
		s._process(1.0 / 60.0)
	for i in 2:
		var p: Vector2 = s.sim.state()["fighters"][i]["pos"]
		QaCheck.is_true(fails, Vector2(s.holders[i].position.x, s.holders[i].position.z).distance_to(p) < 0.6, "rig %d tracks the sim" % i)
	QaCheck.is_true(fails, n_events[0] > 0, "sim events reach the presentation (got %d)" % n_events[0])
	# camera keeps both fighters in a narrow-to-wide frame: distance grows with separation, shrinks with aspect
	var cam: BoutCamera = s.cam
	cam.aspect_override = 1.78
	var d_near := cam.fit_distance(Vector3(-1, 0, 0), Vector3(1, 0, 0), 2.0)
	var d_far := cam.fit_distance(Vector3(-6, 0, 0), Vector3(6, 0, 0), 12.0)
	QaCheck.is_true(fails, d_far > d_near, "camera backs off as the fighters separate")
	cam.aspect_override = 1.0
	var d_sq := cam.fit_distance(Vector3(-6, 0, 0), Vector3(6, 0, 0), 12.0)
	cam.aspect_override = 2.5
	var d_wide := cam.fit_distance(Vector3(-6, 0, 0), Vector3(6, 0, 0), 12.0)
	QaCheck.is_true(fails, d_sq > d_wide, "narrower aspect needs more distance (%.1f vs %.1f)" % [d_sq, d_wide])
	s.free()
	# --- a complete AI vs AI bout finishes with a result, for each profile
	for prof in ["novice", "standard", "expert"]:
		s = _bout("nyxaris", "mollusk", 21, false, prof)
		var box: Array = []
		s.finished.connect(func(r): box.append(r))
		var g := 0
		while box.is_empty() and g < 40000:
			s._process(1.0 / 30.0)
			g += 1
		var res: Dictionary = box[0] if not box.is_empty() else {}
		QaCheck.is_true(fails, not res.is_empty(), "%s bout finished (frames %d)" % [prof, g])
		QaCheck.is_true(fails, res.has("winner") and res.has("reason") and res.get("a_id", "") == "nyxaris", "%s result keys" % prof)
		s.free()
	# --- training: nobody dies
	var cfg := BoutConfig.new()
	cfg.training = true
	QaCheck.eq(fails, cfg.stakes(), 0, "training stakes")
	cfg.training = false
	QaCheck.eq(fails, cfg.stakes(), 2, "real bouts are Blood Bouts")
	return fails
