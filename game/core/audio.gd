extends Node
## Audio director. Sounds are addressed by name:
##   SFX:   res://game/audio/sfx/<name>.wav  (or .ogg)
##   Music: res://game/audio/music/<name>.ogg (or .wav), looped, crossfaded.
## Missing files are silently ignored so gameplay never blocks on audio.

const SFX_POOL := 16
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx3d_players: Array[AudioStreamPlayer3D] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current: String = ""
var _cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)
	for i in 12:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = 14.0
		p3.max_distance = 70.0
		add_child(p3)
		_sfx3d_players.append(p3)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)

func _load(path_no_ext: String) -> AudioStream:
	if _cache.has(path_no_ext):
		return _cache[path_no_ext]
	var s: AudioStream = null
	for ext in [".ogg", ".wav"]:
		if ResourceLoader.exists(path_no_ext + ext):
			s = load(path_no_ext + ext)
			break
	_cache[path_no_ext] = s
	return s

func _sfx_db() -> float:
	return linear_to_db(max(0.0001, float(GameState.settings.get("sfx_volume", 0.9))))

func _music_db() -> float:
	return linear_to_db(max(0.0001, float(GameState.settings.get("music_volume", 0.8))))

## Non-positional SFX (UI, player feedback).
func sfx(sfx_name: String, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	var s := _load("res://game/audio/sfx/" + sfx_name)
	if s == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = s
			p.volume_db = volume_db + _sfx_db()
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return

## Positional SFX in the 3D world.
func sfx_at(sfx_name: String, pos: Vector3, volume_db: float = 0.0, pitch_jitter: float = 0.08) -> void:
	var s := _load("res://game/audio/sfx/" + sfx_name)
	if s == null:
		return
	for p in _sfx3d_players:
		if not p.playing:
			p.stream = s
			p.global_position = pos
			p.volume_db = volume_db + _sfx_db()
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return

## Crossfade to a music track. Empty name fades out.
func music(track: String, fade: float = 1.5) -> void:
	if track == _music_current:
		return
	_music_current = track
	var incoming := _music_b if _music_a.playing else _music_a
	var outgoing := _music_a if incoming == _music_b else _music_b
	if outgoing.playing:
		var t := create_tween()
		t.tween_property(outgoing, "volume_db", -60.0, fade)
		t.tween_callback(outgoing.stop)
	if track == "":
		return
	var s := _load("res://game/audio/music/" + track)
	if s == null:
		return
	if s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	incoming.stream = s
	incoming.volume_db = -60.0
	incoming.play()
	var t2 := create_tween()
	t2.tween_property(incoming, "volume_db", _music_db(), fade)

func refresh_volumes() -> void:
	for p in [_music_a, _music_b]:
		if p.playing:
			p.volume_db = _music_db()
