class_name CodexData
extends RefCounted
## Field Codex content. Reads the Lead's res://game/canon/codex.json when present
## ({"entries": {id: {category, title, subtitle, body, portrait}}}); otherwise builds the same shape
## from canon.json + the LORE fallback below. Dynamic world-state notes are appended to bodies.

const CODEX_JSON := "res://game/canon/codex.json"
const TABS := ["Species", "Characters", "Places", "Lore", "Mysteries"]

const LORE := {
	"old_roads": {"tab": "Lore", "title": "The Old Roads", "body": "Despite Critter's enormous size, evidence exists of ancient long-distance movement: ruined causeways, abandoned migration tunnels, stone markers whose symbols appear continents apart.\n\nThe marker at the Spanwright Waystation carries the same glyph family as stones recorded far beyond the Reaches.\n\nThese do not prove a lost global empire. They prove that Critter's civilizations have risen, connected, fragmented and forgotten one another many times."},
	"mystery_thoughtstone": {"tab": "Mysteries", "title": "Thoughtstone", "body": "Thoughtstone grows around deep subterranean biological-mineral networks. Most appears inert. Rare pieces respond to neural activity.\n\nAt the Ochre Span foundation, a fragment turned itself toward Morrow. Aruun refuses invasive experiments.\n\nIs it mineral, organism, network, memory medium, or something without a human category?"},
	"mystery_pharilux_1897": {"tab": "Mysteries", "title": "Pharilux, 1897", "body": ""},
	"mystery_moon_question": {"tab": "Mysteries", "title": "The Moon Question", "body": ""},
	"mystery_blind_spots": {"tab": "Mysteries", "title": "Probability Blind Spots", "body": "Certain people, places and events produce almost no readable probability around them. Pharilux is one. Some Gate events are another. Cigarra does not know why. She hates unanswered questions enough to keep looking."},
	"lore_burden_architecture": {"tab": "Lore", "title": "Burden Architecture", "body": "Aruun answers that a structure should sacrifice itself before sacrificing the people inside it. This becomes the foundation of a cross-scale engineering school called Burden Architecture."},
}

static var _db: Dictionary = {}

static func db() -> Dictionary:
	if not _db.is_empty():
		return _db
	if FileAccess.file_exists(CODEX_JSON):
		var f := FileAccess.open(CODEX_JSON, FileAccess.READ)
		if f:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary and (d as Dictionary).get("entries") is Dictionary:
				_db = (d as Dictionary)["entries"]
	if _db.is_empty():
		for k in Canon.data.get("species", {}).keys():
			_db["species_" + k] = {"category": "species"}
		for k in Canon.data.get("characters", {}).keys():
			_db["char_" + k] = {"category": "characters", "portrait": k}
		for k in Canon.data.get("places", {}).keys():
			_db["place_" + k] = {"category": "places"}
		for k in LORE:
			_db[k] = {"category": str(LORE[k]["tab"]).to_lower(), "title": LORE[k]["title"], "body": LORE[k]["body"]}
	return _db

static func entry(id: String) -> Dictionary:
	var e: Variant = db().get(id, {})
	return e if e is Dictionary else {}

static func category_of(id: String) -> String:
	var e := entry(id)
	if e.has("category"):
		return str(e["category"]).to_lower()
	if id.begins_with("species_"):
		return "species"
	if id.begins_with("char_"):
		return "characters"
	if id.begins_with("place_"):
		return "places"
	if id.begins_with("mystery_"):
		return "mysteries"
	return "lore"

static func all_ids_for_tab(tab: String) -> Array:
	var cat := tab.to_lower()
	var out: Array = []
	for k in db():
		if category_of(k) == cat:
			out.append(k)
	# entries unlocked by the game but not in the data file still show up
	for k in GameState.codex:
		if not out.has(k) and category_of(k) == cat:
			out.append(k)
	return out

static func title(id: String) -> String:
	var e := entry(id)
	if e.has("title") and str(e["title"]) != "":
		return str(e["title"])
	if LORE.has(id):
		return LORE[id]["title"]
	if id.begins_with("species_"):
		return str(Canon.species(id.substr(8)).get("name", id))
	if id.begins_with("char_"):
		return Canon.display_name(id.substr(5))
	if id.begins_with("place_"):
		return str(Canon.place(id.substr(6)).get("name", id))
	return id.capitalize()

static func subtitle(id: String) -> String:
	var e := entry(id)
	if e.has("subtitle"):
		return str(e["subtitle"])
	if id.begins_with("char_"):
		return str(Canon.character(id.substr(5)).get("title", ""))
	if id.begins_with("species_"):
		return str(Canon.species(id.substr(8)).get("class", ""))
	return ""

## Portrait: a character id (for UiKit.portrait_control) or a res:// texture path; "" for none.
static func portrait(id: String) -> String:
	var e := entry(id)
	if e.has("portrait") and str(e["portrait"]) != "":
		return str(e["portrait"])
	if id.begins_with("char_"):
		return id.substr(5)
	return ""

## World-state notes appended to any body (data-file or fallback).
static func extras(id: String) -> String:
	var t := ""
	if id.begins_with("species_"):
		var sp := id.substr(8)
		var n := 0
		for x in GameState.specimens:
			if x is Dictionary and x.get("species", "") == sp:
				n += 1
		if n > 0:
			t += "\n\n[b]In your Terrarium:[/b] %d" % n
	elif id.begins_with("char_"):
		var cid := id.substr(5)
		if GameState.trust.has(cid):
			t += "\n\n[b]Trust:[/b] %d / 100" % GameState.get_trust(cid)
	elif id == "place_ochre_span":
		var st := str(GameState.get_flag("ochre_span", ""))
		if st == "braced":
			t += "\n\n[b]World state:[/b] BRACED. Aruun and the Handler reinforced the foundation with Thoughtstone. It will carry people for another generation."
		elif st == "failing":
			t += "\n\n[b]World state:[/b] FAILING. The Thoughtstone went to the Dominion contract. The Span still stands. For now."
	return t

static func body(id: String) -> String:
	var e := entry(id)
	if e.has("body") and str(e["body"]) != "":
		return str(e["body"]) + extras(id)
	return _fallback_body(id) + extras(id)

static func _fallback_body(id: String) -> String:
	if LORE.has(id):
		var b: String = LORE[id]["body"]
		return b if b != "" else "An open question. The Codex will fill this page when you learn more."
	if id.begins_with("species_"):
		var s := Canon.species(id.substr(8))
		return "[b]%s[/b] · %s\n\n%s\n\n[b]Behavior:[/b] %s" % [s.get("class", ""), "SAPIENT" if s.get("sapient", false) else "non-sapient", s.get("desc", ""), s.get("behavior", "")]
	if id.begins_with("char_"):
		var c := Canon.character(id.substr(5))
		var lines: Array = []
		lines.append("[b]%s[/b] — %s" % [c.get("name", ""), c.get("title", "")])
		for k in ["designation", "homeland", "knack", "role"]:
			if c.has(k):
				lines.append("[b]%s:[/b] %s" % [k.capitalize(), c[k]])
		if c.has("quote"):
			lines.append("\n“%s”" % c["quote"])
		if c.has("contradiction"):
			lines.append("\n[i]%s[/i]" % c["contradiction"])
		return "\n".join(lines)
	if id.begins_with("place_"):
		return str(Canon.place(id.substr(6)).get("desc", ""))
	return "An open question. The Codex will fill this page when you learn more."
