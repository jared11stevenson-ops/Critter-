class_name DeathsLedger
extends RefCounted
## Append-only deaths ledger (see SAVE.md). One JSON line per death: {"profile", "rec" (JSON text), "sum"}.
## It is NEVER rewritten, truncated or pruned by game code, so deleting or restoring an older save cannot resurrect a critter:
## on load the ledger is merged into the save. Written to two files (main + mirror); reads take the union and skip torn / tampered lines.

var paths: PackedStringArray


func _init(dir: String = "user://v2_saves") -> void:
	paths = PackedStringArray([dir.path_join("deaths_ledger.jsonl"), dir.path_join("deaths_ledger.mirror.jsonl")])


## The record is stored as JSON text inside the line so the checksum is over exact bytes (no int/float round-trip drift).
static func checksum(profile: String, rec_text: String) -> String:
	return (profile + "|" + rec_text).sha256_text().substr(0, 16)


## Appends the death (idempotent per profile+uid). Returns true when the entry is durable in at least one file.
func append(profile: String, rec: Dictionary) -> bool:
	var uid := str(rec.get("uid", ""))
	if uid == "":
		return false
	if has(profile, uid):
		return true
	var rec_text := JSON.stringify(rec, "", true)
	var line := JSON.stringify({"profile": profile, "rec": rec_text, "sum": checksum(profile, rec_text)})
	var ok := false
	for p in paths:
		DirAccess.make_dir_recursive_absolute(p.get_base_dir())
		var f := FileAccess.open(p, FileAccess.READ_WRITE if FileAccess.file_exists(p) else FileAccess.WRITE)
		if f == null:
			continue
		f.seek_end()
		f.store_string("\n" + line + "\n")    # leading newline isolates us from a previous torn write
		f.flush()
		f.close()
		ok = true
	return ok


## All valid records for a profile, in file order, de-duplicated by uid.
func entries(profile: String) -> Array:
	var out: Array = []
	var seen := {}
	for p in paths:
		if not FileAccess.file_exists(p):
			continue
		for raw in FileAccess.get_file_as_string(p).split("\n", false):
			var j := JSON.new()
			if j.parse(raw) != OK or not (j.data is Dictionary):
				continue
			var e: Dictionary = j.data
			if not (e.get("rec") is String) or str(e.get("profile", "")) != profile:
				continue
			if str(e.get("sum", "")) != checksum(profile, e["rec"]):
				continue
			var rj := JSON.new()
			if rj.parse(e["rec"]) != OK or not (rj.data is Dictionary):
				continue
			var uid := str(rj.data.get("uid", ""))
			if uid != "" and not seen.has(uid):
				seen[uid] = true
				out.append(rj.data)
	return out


func has(profile: String, uid: String) -> bool:
	for rec in entries(profile):
		if str(rec.get("uid", "")) == uid:
			return true
	return false
