extends Node
## Graphics quality presets (Agent 2, v0.7.1 perf pass). Autoload `Quality`.
##
## Settings (GameState.settings, persisted):
##   "gfx_quality": "auto" | "low" | "medium" | "high"   (default "auto")
##   "fps_cap":     30 | 60                                (default 60)
## "auto" starts at Medium on phones / High on desktop, then measures real frame time once a 3D scene has been
## running ~5 s and steps down one level (remembered in "gfx_auto_level") when the game misses its frame budget.
##
## What each level changes (see design/AGENT2_NOTES.md "Graphics quality"):
##   LOW    3D render scale 0.7, no MSAA, no real-time shadows (blob shadows only), no glow / colour grading,
##          light fog, no dust motes, scatter 30 %, particles halved, aniso off, cheapest shader variants
##          (terrain 3 texture samples, props 1 sample, Lambert / no specular).
##   MEDIUM 3D render scale 0.85, no MSAA, 1024 single-split sun shadow (short range), glow, 60 % scatter,
##          75 % particles, reduced shader variants (terrain ~7 samples, props biplanar albedo only).
##   HIGH   the authored v0.7 look (MSAA 2x, 2048 two-split soft shadows, full PBR terrain / tri-planar props).
## World code reads `Quality.level` (or the helpers below) when it builds, and listens to `changed` to adapt live.
## Shaders that have cheaper variants are created through `Quality.shader()`: the code gets a
## `#define QUALITY_LOW` / `QUALITY_MEDIUM` line injected and is recompiled in place when the level changes.

signal changed(level: int)

enum { LOW, MEDIUM, HIGH }
const NAMES := ["low", "medium", "high"]
const LABELS := ["Low", "Medium", "High"]
const RENDER_SCALE := [0.7, 0.85, 1.0]
## ...but never render 3D taller than this many pixels (high-DPI phones render 3D at native resolution with the
## canvas_items stretch mode: a 2400x1080 screen is 2.8x the pixels of 720p). Scale is clamped to >= 0.5.
const MAX_3D_HEIGHT := [620.0, 860.0, 1440.0]
const SCATTER := [0.3, 0.6, 1.0]
const PARTICLES := [0.5, 0.75, 1.0]
## Visibility range multiplier for scatter / small structure detail.
const VIS_RANGE := [0.6, 0.8, 1.0]

var level := HIGH
var is_auto := true

var _shaders: Dictionary = {}   # key -> [Shader, base code]
var _lights: Array = []         # [WeakRef(Light3D), min level]
# auto probe
var _probe_frames := 0
var _probe_ms := 0.0
var _probe_warm := 0.0
var _probe_last_us := 0
var _probe_done_for := -1
var _probe_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	# QA runs are CPU-rendered (llvmpipe): never auto-downgrade there unless asked to test the probe.
	if args.has("qa") and not args.has("qa_autoprobe"):
		_probe_enabled = false
	apply_settings()


## Current setting string ("auto", "low", "medium", "high").
func setting() -> String:
	return str(GameState.settings.get("gfx_quality", "auto"))


func fps_cap() -> int:
	return 30 if int(GameState.settings.get("fps_cap", 60)) <= 30 else 60


func auto_default() -> int:
	return MEDIUM if OS.has_feature("mobile") or OS.has_feature("web") else HIGH


## Re-read GameState.settings and apply (call after changing gfx_quality / fps_cap).
func apply_settings() -> void:
	var s := setting()
	is_auto = not (s in NAMES)
	var lv: int
	if is_auto:
		lv = int(GameState.settings.get("gfx_auto_level", auto_default()))
		lv = clampi(lv, LOW, auto_default())
	else:
		lv = NAMES.find(s)
	Engine.max_fps = fps_cap()
	_reset_probe()
	set_level(lv)


func set_level(lv: int) -> void:
	lv = clampi(lv, LOW, HIGH)
	var first := _shaders.is_empty() and level == lv
	level = lv
	_apply_viewport()
	_apply_shadow_atlas()
	for key in _shaders:
		var e: Array = _shaders[key]
		(e[0] as Shader).code = _inject(e[1])
	_apply_lights()
	if not first:
		changed.emit(level)


## 3D resolution scale for the current level and window size.
func render_scale() -> float:
	var h := float(get_tree().root.size.y)
	var sc: float = RENDER_SCALE[level]
	if h > 1.0:
		sc = minf(sc, MAX_3D_HEIGHT[level] / h)
	return clampf(sc, 0.5, 1.0)


func level_name() -> String:
	return LABELS[level]


func scatter_density() -> float:
	return SCATTER[level]


func particle_mult() -> float:
	return PARTICLES[level]


func vis_range_mult() -> float:
	return VIS_RANGE[level]


func shadows_enabled() -> bool:
	return level >= MEDIUM


## Scales a particle count for the current level (never below 1).
func particles(n: int) -> int:
	return maxi(1, int(round(n * PARTICLES[level])))


## Extra (omni / spot) lights are a whole additional render pass of every object they touch in the Compatibility
## renderer. Register decorative ones here: they are hidden below `min_level`.
func track_light(l: Light3D, min_level: int = MEDIUM) -> void:
	_lights.append([weakref(l), min_level])
	l.visible = level >= min_level


func _apply_lights() -> void:
	var keep: Array = []
	for e in _lights:
		var l: Light3D = (e[0] as WeakRef).get_ref()
		if l == null:
			continue
		l.visible = level >= int(e[1])
		keep.append(e)
	_lights = keep


# ------------------------------------------------------------------ shaders

## Returns a shader built from `code` (default: the file at `key`) with the quality define injected. The same
## Shader object is returned for a key, and its code is swapped (recompiled) when the level changes, so every
## material using it follows automatically.
func shader(key: String, code: String = "") -> Shader:
	if _shaders.has(key):
		return (_shaders[key] as Array)[0]
	if code == "":
		var base: Shader = load(key)
		code = base.code
	var sh := Shader.new()
	sh.code = _inject(code)
	_shaders[key] = [sh, code]
	return sh


func _inject(code: String) -> String:
	var def := ""
	if level == LOW:
		def = "#define QUALITY_LOW\n"
	elif level == MEDIUM:
		def = "#define QUALITY_MEDIUM\n"
	if def == "":
		return code
	var i := code.find("shader_type")
	if i < 0:
		return def + code
	var e := code.find(";", i)
	return code.substr(0, e + 1) + "\n" + def + code.substr(e + 1)


# ------------------------------------------------------------------ viewport / renderer

var _covers := 0

## A (nearly) opaque full-screen menu covers the world: stop rendering the 3D scene entirely while it is up, so the
## GPU/CPU time goes to the UI. Counted, so overlapping screens (pause over codex) nest correctly. This replaces the old
## render-scale trick: changing scaling_3d_scale reallocates the render targets, which was itself a hitch at the start
## and end of every dialogue.
func set_covered(on: bool) -> void:
	_covers = maxi(0, _covers + (1 if on else -1))
	get_tree().root.disable_3d = _covers > 0

## Dialogues keep the world visible, so they no longer touch the renderer (kept so older callers still work).
func set_modal(_on: bool) -> void:
	pass

func _apply_viewport() -> void:
	var vp := get_tree().root
	vp.msaa_3d = Viewport.MSAA_2X if level == HIGH else Viewport.MSAA_DISABLED
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = render_scale()
	if not vp.size_changed.is_connected(_apply_viewport):
		vp.size_changed.connect(_apply_viewport)
	vp.anisotropic_filtering_level = [Viewport.ANISOTROPY_DISABLED, Viewport.ANISOTROPY_2X,
		Viewport.ANISOTROPY_4X][level]


func _apply_shadow_atlas() -> void:
	RenderingServer.directional_shadow_atlas_set_size(2048 if level == HIGH else 1024, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_SOFT_LOW if level == HIGH else RenderingServer.SHADOW_QUALITY_HARD)


## Applies the level to a sun light (CritterLighting calls this; other scenes with their own sun may too).
func setup_sun(sun: DirectionalLight3D, max_distance: float = 46.0) -> void:
	if sun == null:
		return
	match level:
		LOW:
			sun.shadow_enabled = false
		MEDIUM:
			sun.shadow_enabled = true
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			sun.directional_shadow_max_distance = minf(max_distance, 30.0)
			sun.shadow_blur = 1.0
		_:
			sun.shadow_enabled = true
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun.directional_shadow_max_distance = max_distance
			sun.shadow_blur = 1.6


## Applies the level to an Environment (glow / adjustments / fog extras). Call after the mood is set.
func setup_environment(env: Environment) -> void:
	if env == null:
		return
	env.glow_enabled = level >= MEDIUM
	if level == LOW:
		env.fog_aerial_perspective = 0.0
		env.fog_sun_scatter = 0.0


# ------------------------------------------------------------------ auto probe

func _reset_probe() -> void:
	_probe_frames = 0
	_probe_ms = 0.0
	_probe_warm = 0.0
	_probe_last_us = 0


func _process(delta: float) -> void:
	if not (_probe_enabled and is_auto) or level == LOW or _probe_done_for == level:
		return
	var tree := get_tree()
	if tree.paused or get_viewport().get_camera_3d() == null:
		_reset_probe()
		return
	var now := Time.get_ticks_usec()
	var ms := (now - _probe_last_us) / 1000.0
	_probe_last_us = now
	_probe_warm += delta
	if _probe_warm < 5.0 or ms <= 0.0 or ms > 1000.0:
		return  # skip loading hitches + the first seconds of a scene
	_probe_frames += 1
	_probe_ms += ms
	if _probe_frames < 150 and _probe_warm < 9.0:
		return
	var avg := _probe_ms / maxf(1.0, _probe_frames)
	var budget := 1000.0 / float(fps_cap())
	_probe_done_for = level
	print("[Quality] auto probe: %.1f ms/frame at %s (budget %.1f)" % [avg, LABELS[level], budget])
	if avg > budget * 1.3:
		var nl := level - 1
		GameState.settings["gfx_auto_level"] = nl
		GameState.save_game()
		set_level(nl)
		_reset_probe()
		Events.toast.emit("Graphics set to %s for smoother play (Settings)" % LABELS[nl], "info")
