class_name SaveSystem
extends RefCounted
## Atomic, versioned, death-safe persistence for a RosterState. See v2/src/core/SAVE.md for the reasoning.
##  - save():      validate -> merge deaths ledger -> write .tmp -> verify -> copy previous to .bak -> rename over slot.
##  - load_slot(): main file, else .bak; migrate; merge deaths ledger (older/deleted/restored saves cannot resurrect anyone).
##  - A death is committed to the ledger FIRST and the slot is saved immediately (bind() wires this to RosterState.critter_died).

signal saved(slot: String)
signal save_failed(slot: String, reason: String)

var dir := "user://v2_saves"
var ledger: DeathsLedger
var min_autosave_interval_ms := 5000

var _state: RosterState
var _slot := ""
var _last_save_ms := -1000000
var _dirty := false


func _init(p_dir: String = "user://v2_saves") -> void:
	dir = p_dir
	ledger = DeathsLedger.new(dir)


func slot_path(slot: String) -> String:
	return dir.path_join("slot_%s.json" % slot)


func new_game(slot: String) -> RosterState:
	var s := RosterState.new()
	s.profile_id = "p%x%x" % [int(Time.get_unix_time_from_system()), randi() & 0xffffff]
	bind(s, slot)
	return s


## Makes `state` the live game for `slot`: its deaths commit immediately.
func bind(state: RosterState, slot: String) -> void:
	if _state != null and _state.critter_died.is_connected(_on_death):
		_state.critter_died.disconnect(_on_death)
	_state = state
	_slot = slot
	state.critter_died.connect(_on_death)


func _on_death(rec: Dictionary) -> void:
	# Ledger first: it is the source of truth for deaths. Then the slot, immediately, with no debounce.
	if not ledger.append(_state.profile_id, rec):
		push_error("SaveSystem: could not write the deaths ledger")
	save(_slot, _state)


## Applies ledger deaths to `state`. Returns how many records changed the state.
func merge_ledger(state: RosterState) -> int:
	var n := 0
	for rec in ledger.entries(state.profile_id):
		if state.merge_fallen(rec):
			n += 1
		elif state.rack.slot_of(str(rec.get("uid", ""))) >= 0:
			state.rack.remove(str(rec.get("uid", "")))
	return n


func serialize(state: RosterState) -> Dictionary:
	return {"version": SaveMigrations.CURRENT, "saved_at": int(Time.get_unix_time_from_system()), "roster": state.to_dict()}


## Returns {ok, error}. Never writes a state that disagrees with the deaths ledger.
func save(slot: String, state: RosterState) -> Dictionary:
	var res := _save(slot, state)
	if res["ok"]:
		saved.emit(slot)
	else:
		save_failed.emit(slot, res["error"])
	return res


func _save(slot: String, state: RosterState) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(dir)
	var path := slot_path(slot)
	if state.profile_id != "":
		merge_ledger(state)    # a stale in-memory state can never write a resurrection
	var existing := _read_json(path)
	if int(existing.get("version", 0)) > SaveMigrations.CURRENT:
		return {"ok": false, "error": "refusing to overwrite a save from a newer game version"}
	var text := JSON.stringify(serialize(state), "\t")
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error": "cannot open %s (error %d)" % [tmp, FileAccess.get_open_error()]}
	f.store_string(text)
	f.flush()
	f.close()
	if _read_json(tmp).is_empty():
		DirAccess.remove_absolute(tmp)
		return {"ok": false, "error": "verification of the written file failed"}
	if not existing.is_empty():
		DirAccess.copy_absolute(path, path + ".bak")
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:     # some platforms refuse to replace: fall back (the .bak above is still valid)
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		return {"ok": false, "error": "rename failed (error %d)" % err}
	_last_save_ms = Time.get_ticks_msec()
	_dirty = false
	return {"ok": true, "error": ""}


## Debounced autosave for non-lethal events (care, bout results, sessions). Deaths never wait (see _on_death).
## Returns true when it wrote now; false when deferred (call flush() at a safe moment or on app pause/quit).
func autosave(reason: String = "") -> bool:
	if _state == null:
		return false
	if Time.get_ticks_msec() - _last_save_ms < min_autosave_interval_ms:
		_dirty = true
		return false
	return bool(save(_slot, _state)["ok"])


func flush() -> bool:
	if _state != null and _dirty:
		return bool(save(_slot, _state)["ok"])
	return true


## Returns {ok, state, error, source ("main"|"backup"), migrated_from, deaths_merged}.
func load_slot(slot: String) -> Dictionary:
	var path := slot_path(slot)
	var last_err := "no save found"
	for src in [["main", path], ["backup", path + ".bak"]]:
		var raw := _read_json(src[1])
		if raw.is_empty():
			continue
		var mig := SaveMigrations.migrate(raw)
		if not mig["ok"]:
			last_err = mig["error"]
			if int(raw.get("version", 0)) > SaveMigrations.CURRENT:
				return {"ok": false, "error": last_err, "state": null}   # never fall back past a newer save
			continue
		var state := RosterState.new()
		state.load_dict(mig["data"].get("roster", {}))
		var merged := merge_ledger(state) if state.profile_id != "" else 0
		bind(state, slot)
		return {"ok": true, "state": state, "error": "", "source": src[0], "migrated_from": mig["from"], "deaths_merged": merged}
	return {"ok": false, "error": last_err, "state": null}


func slot_exists(slot: String) -> bool:
	return FileAccess.file_exists(slot_path(slot)) or FileAccess.file_exists(slot_path(slot) + ".bak")


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) == OK and j.data is Dictionary:
		return j.data
	return {}
