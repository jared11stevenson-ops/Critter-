extends Node
## Autoload `Music`: one looping background track at a time, cross-faded. Tracks are procedural (tools/gen/gen_music.py): "menu" and "bout".
## Volume = Settings.master_volume * Settings.music_volume. Does nothing in headless runs.
const TRACKS := {"menu": "res://audio/music/menu.wav", "bout": "res://audio/music/bout.wav"}
var _a: AudioStreamPlayer
var _cur := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = AudioStreamPlayer.new()
	_a.volume_db = -80.0
	add_child(_a)

func volume_linear() -> float:
	return clampf(float(Settings.get_value("master_volume")) * float(Settings.get_value("music_volume")), 0.0, 1.0)

## Starts `track` (no-op when it is already playing). Fades the old one out first.
func play(track: String) -> void:
	if DisplayServer.get_name() == "headless" or not TRACKS.has(track) or track == _cur:
		return
	_cur = track
	var tw := create_tween()
	if _a.playing:
		tw.tween_property(_a, "volume_db", -60.0, 0.4)
	tw.tween_callback(func():
		var st := load(TRACKS[track]) as AudioStreamWAV
		if st == null:
			return
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = st.data.size() / 2          # 16-bit mono
		_a.stream = st
		_a.volume_db = -60.0
		_a.play())
	tw.tween_property(_a, "volume_db", linear_to_db(maxf(volume_linear(), 0.0001)), 0.8)

func stop() -> void:
	_cur = ""
	if _a != null and _a.playing:
		var tw := create_tween()
		tw.tween_property(_a, "volume_db", -60.0, 0.5)
		tw.tween_callback(_a.stop)

## Re-applies the current volume setting to the playing track (Settings screen calls this).
func refresh() -> void:
	if _a != null and _a.playing:
		_a.volume_db = linear_to_db(maxf(volume_linear(), 0.0001))
