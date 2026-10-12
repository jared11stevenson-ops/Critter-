extends RefCounted
## Save system: atomic write, backup, migrations, and the never-revert-a-death rule.

const DIR := "user://test_tmp_save"


func _clean() -> void:
	var g := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(g):
		for f in DirAccess.get_files_at(g):
			DirAccess.remove_absolute(g.path_join(f))


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func run() -> Array:
	var fails: Array = []
	_clean()
	var sys := SaveSystem.new(DIR)
	sys.min_autosave_interval_ms = 0
	var st := sys.new_game("a")
	var h := st.seal("aruun", "Hal")
	var z := st.seal("zephyr", "Zee")
	st.economy.add("scrap", 42)
	# --- round trip + atomic + backup ---
	QaCheck.is_true(fails, sys.save("a", st)["ok"], "first save")
	QaCheck.is_true(fails, not FileAccess.file_exists(sys.slot_path("a") + ".tmp"), "no tmp left behind")
	QaCheck.is_true(fails, not FileAccess.file_exists(sys.slot_path("a") + ".bak"), "no backup on first save")
	var old_text := FileAccess.get_file_as_string(sys.slot_path("a"))   # snapshot while both alive
	st.economy.add("scrap", 1)
	sys.save("a", st)
	QaCheck.is_true(fails, FileAccess.file_exists(sys.slot_path("a") + ".bak"), "backup after second save")
	var r := SaveSystem.new(DIR).load_slot("a")
	QaCheck.is_true(fails, r["ok"], "load ok")
	QaCheck.eq(fails, r["state"].economy.scrap, 43, "scrap persisted")
	QaCheck.eq(fails, r["state"].rack.count(), 2, "rack persisted")
	QaCheck.eq(fails, r["state"].rack.get_by_uid(h.uid).name, "Hal", "names persisted")
	QaCheck.eq(fails, r["state"].rack.get_by_uid(h.uid).chapters_unlocked, [1], "chapters persisted as ints")
	QaCheck.eq(fails, r["source"], "main", "loaded from main")
	# --- corrupt main falls back to backup ---
	_write(sys.slot_path("a"), "{ truncated")
	r = SaveSystem.new(DIR).load_slot("a")
	QaCheck.is_true(fails, r["ok"] and r["source"] == "backup", "corrupt main -> backup")
	QaCheck.eq(fails, r["state"].economy.scrap, 42, "backup is the previous save")
	sys.save("a", st)
	# --- death commits immediately: no explicit save call ---
	sys.bind(st, "a")
	var bo := BoutOutcome.make(h.uid, StakesTier.BLOOD, "killed", "nyxaris", 0.0, 0.0)
	bo.cause = "a bad read"
	st.apply_bout(bo)
	QaCheck.is_true(fails, sys.ledger.has(st.profile_id, h.uid), "ledger has the death")
	var after := SaveSystem.new(DIR).load_slot("a")
	QaCheck.eq(fails, after["state"].rack.count(), 1, "death already on disk (rack)")
	QaCheck.is_true(fails, after["state"].is_fallen(h.uid), "death already on disk (wall)")
	# --- restoring an OLDER save cannot resurrect ---
	_write(sys.slot_path("a"), old_text)
	var dir_g := ProjectSettings.globalize_path(DIR)
	DirAccess.remove_absolute(dir_g.path_join("slot_a.json.bak"))
	var old := SaveSystem.new(DIR).load_slot("a")
	QaCheck.is_true(fails, old["ok"], "old save loads")
	QaCheck.eq(fails, old["deaths_merged"], 1, "ledger merged into old save")
	QaCheck.is_true(fails, old["state"].rack.get_by_uid(h.uid) == null, "dead critter not on rack")
	QaCheck.is_true(fails, old["state"].is_fallen(h.uid), "dead critter on the wall again")
	QaCheck.eq(fails, old["state"].wall[0]["cause"] if old["state"].wall.size() > 0 else "", "a bad read", "wall record from ledger")
	QaCheck.eq(fails, old["state"].legacy["relics"].size(), 1, "relic restored")
	QaCheck.is_true(fails, old["state"].rack.get_by_uid(z.uid) != null, "other critter alive")
	# --- main deleted, only an old backup remains ---
	DirAccess.remove_absolute(dir_g.path_join("slot_a.json"))
	_write(sys.slot_path("a") + ".bak", old_text)
	var bk := SaveSystem.new(DIR).load_slot("a")
	QaCheck.is_true(fails, bk["ok"] and bk["state"].is_fallen(h.uid), "deleted main + old backup still dead")
	# --- stale in-memory state cannot overwrite a death ---
	var s2 := SaveSystem.new(DIR)
	var stale: RosterState = s2.load_slot("a")["state"]
	stale.rack.add(CritterInstance.from_dict(h.to_dict()))    # force a resurrection in memory
	QaCheck.is_true(fails, stale.rack.get_by_uid(h.uid) != null, "(setup) stale state has it alive")
	s2.save("a", stale)
	QaCheck.is_true(fails, stale.rack.get_by_uid(h.uid) == null, "save() strips a resurrected critter")
	QaCheck.is_true(fails, SaveSystem.new(DIR).load_slot("a")["state"].is_fallen(h.uid), "disk still says dead")
	# uid never reused after merge
	var nu: CritterInstance = stale.seal("cigarra")
	QaCheck.is_true(fails, nu.uid != h.uid and nu.uid != z.uid, "fresh uid after merge")
	# --- ledger robustness: torn line, tampering, other profile ---
	var led := sys.ledger
	var lp: String = led.paths[0]
	var f := FileAccess.open(lp, FileAccess.READ_WRITE)
	f.seek_end()
	f.store_string("\n{\"profile\":\"" + st.profile_id + "\",\"rec\":\"{\\\"uid\\\":\\\"c9999\\\"}\",\"sum\":\"bad\"}\n{\"profile\":\"x\",\"rec\":{\"ui")
	f.close()
	QaCheck.eq(fails, led.entries(st.profile_id).size(), 1, "tampered/torn lines ignored")
	QaCheck.is_true(fails, led.append("other_profile", {"uid": "c0001"}), "append other profile")
	QaCheck.eq(fails, led.entries(st.profile_id).size(), 1, "profiles are isolated")
	QaCheck.is_true(fails, led.append(st.profile_id, {"uid": "c0042", "name": "n"}), "append after torn tail")
	QaCheck.eq(fails, led.entries(st.profile_id).size(), 2, "append after torn tail is readable")
	QaCheck.is_true(fails, led.append(st.profile_id, {"uid": "c0042"}), "idempotent append")
	QaCheck.eq(fails, led.entries(st.profile_id).size(), 2, "no duplicates")
	# mirror survives loss of the main ledger file
	DirAccess.remove_absolute(ProjectSettings.globalize_path(led.paths[0]))
	QaCheck.eq(fails, led.entries(st.profile_id).size(), 2, "mirror ledger covers main loss")
	# --- migrations ---
	var v1 := {"version": 1, "profile": "pv1", "next_id": 3, "money": {"scrap": 7, "amber": 2, "rep": 5},
		"critters": [{"uid": "c0001", "species": "cigarra", "name": "S", "bouts": 4, "hp": 0.5}], "fallen": [{"uid": "c0002", "species": "bramvex", "name": "W"}]}
	var m := SaveMigrations.migrate(v1)
	QaCheck.is_true(fails, m["ok"], "v1 migrates")
	QaCheck.eq(fails, m["data"]["version"], SaveMigrations.CURRENT, "migrated to current")
	QaCheck.eq(fails, m["from"], 1, "from version reported")
	var rs := RosterState.new()
	rs.load_dict(m["data"]["roster"])
	QaCheck.eq(fails, rs.rack.get_by_uid("c0001").bouts_survived, 4, "v1 bouts -> bouts_survived")
	QaCheck.near(fails, rs.rack.get_by_uid("c0001").vitality, 0.5, "v1 hp -> vitality")
	QaCheck.eq(fails, rs.economy.reputation, 5, "v1 rep -> reputation")
	QaCheck.eq(fails, rs.profile_id, "pv1", "v1 profile")
	QaCheck.eq(fails, rs.next_uid, 3, "v1 next id")
	QaCheck.is_true(fails, rs.is_fallen("c0002"), "v1 fallen -> wall")
	QaCheck.eq(fails, v1["version"], 1, "migrate does not mutate input")
	QaCheck.is_true(fails, not SaveMigrations.migrate({"version": 99})["ok"], "future version refused")
	QaCheck.is_true(fails, not SaveMigrations.migrate({"roster": {}})["ok"], "missing version refused")
	QaCheck.is_true(fails, not SaveMigrations.migrate({"version": 0})["ok"], "version 0 refused")
	QaCheck.is_true(fails, SaveMigrations.migrate({"version": 2, "roster": {}})["ok"], "current passes through")
	# v1 file on disk loads through load_slot, and a newer-version file is never overwritten
	_write(sys.slot_path("old"), JSON.stringify(v1))
	var lv := SaveSystem.new(DIR).load_slot("old")
	QaCheck.is_true(fails, lv["ok"] and lv["migrated_from"] == 1, "v1 file loads via load_slot")
	var fut := JSON.stringify({"version": 99, "roster": {}})
	_write(sys.slot_path("fut"), fut)
	QaCheck.is_true(fails, not SaveSystem.new(DIR).load_slot("fut")["ok"], "future file not loaded")
	QaCheck.is_true(fails, not sys.save("fut", RosterState.new())["ok"], "future file not overwritten")
	QaCheck.eq(fails, FileAccess.get_file_as_string(sys.slot_path("fut")), fut, "future file untouched")
	# --- autosave debounce ---
	var d := SaveSystem.new(DIR)
	d.min_autosave_interval_ms = 60000
	var ds := d.new_game("deb")
	d.save("deb", ds)
	ds.economy.add("scrap", 5)
	QaCheck.is_true(fails, not d.autosave("care"), "autosave deferred inside the interval")
	QaCheck.is_true(fails, d.flush(), "flush writes deferred state")
	QaCheck.eq(fails, SaveSystem.new(DIR).load_slot("deb")["state"].economy.scrap, 5, "flush persisted")
	ds.seal("mollusk")
	var mr := ds.seal("nyxaris")
	ds.kill(mr.uid, "test")    # death bypasses the debounce
	QaCheck.is_true(fails, SaveSystem.new(DIR).load_slot("deb")["state"].is_fallen(mr.uid), "death ignores debounce")
	QaCheck.eq(fails, SaveSystem.new(DIR).load_slot("nope")["ok"], false, "missing slot")
	_clean()
	return fails
