class_name UiSfx
extends RefCounted
## Menu click sound for every Button (hooked once in boot.gd via node_added). Uses the generated ui_tap SFX; 4 pooled voices.
static var _pool: Array[AudioStreamPlayer] = []
static var _i := 0
static var _snd: AudioStream

static func tap() -> void:
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return
	if _snd == null:
		_snd = load("res://audio/sfx/ui_tap.ogg") if ResourceLoader.exists("res://audio/sfx/ui_tap.ogg") else null
		if _snd == null:
			return
	if _pool.is_empty():
		for k in 4:
			var p := AudioStreamPlayer.new()
			p.stream = _snd
			p.volume_db = -4.0
			(loop as SceneTree).root.add_child(p)
			_pool.append(p)
	var pl := _pool[_i]
	_i = (_i + 1) % _pool.size()
	pl.pitch_scale = randf_range(0.96, 1.06)
	pl.play()

static func hook(tree: SceneTree) -> void:
	tree.node_added.connect(func(n: Node): if n is Button: (n as Button).pressed.connect(UiSfx.tap))
