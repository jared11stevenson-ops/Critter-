extends RefCounted

const SettingsScript := preload("res://src/core/settings.gd")
const TMP := "user://test_tmp_settings.json"

func run() -> Array:
	var fails: Array = []
	var s = SettingsScript.new()
	s.path = TMP
	QaCheck.eq(fails, s.get_value("quality"), 2, "default quality (High)")
	QaCheck.is_true(fails, s.set_value("quality", 2), "set quality")
	QaCheck.eq(fails, s.quality_name(), "High", "quality name")
	s.set_value("quality", 99)
	QaCheck.eq(fails, s.get_value("quality"), 2, "quality clamped to max")
	QaCheck.is_true(fails, not s.set_value("quality", "high"), "string quality rejected")
	QaCheck.is_true(fails, not s.set_value("fps_cap", 45), "invalid fps cap rejected")
	QaCheck.is_true(fails, s.set_value("fps_cap", 30), "valid fps cap")
	QaCheck.is_true(fails, not s.set_value("nonsense", true), "unknown key rejected")
	QaCheck.is_true(fails, not s.set_value("left_handed", 1), "wrong type rejected")
	s.set_value("left_handed", true)
	s.set_value("reduce_flashing", true)
	s.set_value("master_volume", 5.0)
	QaCheck.near(fails, s.get_value("master_volume"), 1.0, "volume clamped")
	QaCheck.is_true(fails, s.save(), "save")
	var s2 = SettingsScript.new()
	s2.path = TMP
	QaCheck.is_true(fails, s2.load_settings(), "load")
	QaCheck.eq(fails, s2.get_value("fps_cap"), 30, "fps persisted")
	QaCheck.eq(fails, s2.get_value("left_handed"), true, "left-handed persisted")
	QaCheck.eq(fails, s2.get_value("reduce_flashing"), true, "flashing persisted")
	# assists: not in Blood Bouts
	s2.set_value("assist_wide_parry", true)
	s2.set_value("assist_slow_tells", true)
	QaCheck.eq(fails, s2.parry_window_bonus_frames(StakesTier.SPARRING), 4, "assist parry sparring")
	QaCheck.eq(fails, s2.parry_window_bonus_frames(StakesTier.BLOOD), 0, "no assist in blood")
	QaCheck.near(fails, s2.tell_slow_factor(StakesTier.BLOOD), 1.0, "no slow tells in blood")
	QaCheck.near(fails, s2.tell_slow_factor(StakesTier.CONTEST), 1.5, "slow tells in contest")
	# corrupt file falls back to defaults
	var f := FileAccess.open(TMP, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	QaCheck.is_true(fails, not s2.load_settings(), "corrupt file rejected")
	QaCheck.eq(fails, s2.get_value("fps_cap"), 60, "defaults after corrupt")
	# forward compat: junk keys ignored
	s2.from_dict({"values": {"quality": 0, "bogus": 3, "fps_cap": "x"}})
	QaCheck.eq(fails, s2.get_value("quality"), 0, "partial merge")
	QaCheck.eq(fails, s2.get_value("fps_cap"), 60, "bad value ignored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))
	s.free()
	s2.free()
	return fails
