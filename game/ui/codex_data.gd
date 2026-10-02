class_name CodexData
extends RefCounted
## Field Codex content. Species / characters / places pull from canon.json; lore entries cite the bible.

const TABS := ["Species", "Characters", "Places", "Mysteries"]

const LORE := {
	"old_roads": {"tab": "Places", "title": "The Old Roads", "body": "Despite Critter's enormous size, evidence exists of ancient long-distance movement: ruined causeways, abandoned migration tunnels, stone markers whose symbols appear continents apart.\n\nThe marker at the Spanwright Waystation carries the same glyph family as stones recorded far beyond the Reaches.\n\nThese do not prove a lost global empire. They prove that Critter's civilizations have risen, connected, fragmented and forgotten one another many times. (Bible §9)"},
	"mystery_thoughtstone": {"tab": "Mysteries", "title": "Thoughtstone", "body": "Thoughtstone grows around deep subterranean biological-mineral networks. Most appears inert. Rare pieces respond to neural activity.\n\nAt the Ochre Span foundation, a fragment turned itself toward Morrow. Aruun refuses invasive experiments.\n\nIs it mineral, organism, network, memory medium, or something without a human category? (Bible §23, Book XIV)"},
	"mystery_pharilux_1897": {"tab": "Mysteries", "title": "Pharilux, 1897", "body": ""},
	"mystery_moon_question": {"tab": "Mysteries", "title": "The Moon Question", "body": ""},
	"mystery_blind_spots": {"tab": "Mysteries", "title": "Probability Blind Spots", "body": "Certain people, places and events produce almost no readable probability around them. Pharilux is one. Some Gate events are another. Cigarra does not know why. She hates unanswered questions enough to keep looking. (Bible §22)"},
	"burden_architecture": {"tab": "Places", "title": "Burden Architecture", "body": "Aruun answers that a structure should sacrifice itself before sacrificing the people inside it. This becomes the foundation of a cross-scale engineering school called Burden Architecture. (Bible Book XIV)"},
}

static func all_ids_for_tab(tab: String) -> Array:
	var out: Array = []
	match tab:
		"Species":
			for k in Canon.data.get("species", {}).keys():
				out.append("species_" + k)
		"Characters":
			for k in Canon.data.get("characters", {}).keys():
				out.append("char_" + k)
		"Places":
			for k in Canon.data.get("places", {}).keys():
				out.append("place_" + k)
			out.append("old_roads")
			out.append("burden_architecture")
		"Mysteries":
			for k in LORE:
				if LORE[k]["tab"] == "Mysteries":
					out.append(k)
	return out

static func title(id: String) -> String:
	if LORE.has(id):
		return LORE[id]["title"]
	if id.begins_with("species_"):
		return str(Canon.species(id.substr(8)).get("name", id))
	if id.begins_with("char_"):
		return Canon.display_name(id.substr(5))
	if id.begins_with("place_"):
		return str(Canon.place(id.substr(6)).get("name", id))
	return id.capitalize()

static func body(id: String) -> String:
	if LORE.has(id):
		var b: String = LORE[id]["body"]
		return b if b != "" else "An open question. The Codex will fill this page when you learn more."
	if id.begins_with("species_"):
		var s := Canon.species(id.substr(8))
		var t := "[b]%s[/b] · %s\n\n%s\n\n[b]Behaviour:[/b] %s" % [s.get("class", ""), "SAPIENT" if s.get("sapient", false) else "non-sapient", s.get("desc", ""), s.get("behavior", "")]
		var sp := id.substr(8)
		var n := 0
		for x in GameState.specimens:
			if x.get("species", "") == sp:
				n += 1
		if n > 0:
			t += "\n\n[b]In your Terrarium:[/b] %d" % n
		return t
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
		var cid := id.substr(5)
		if GameState.trust.has(cid):
			lines.append("\n[b]Trust:[/b] %d / 100" % GameState.get_trust(cid))
		return "\n".join(lines)
	if id.begins_with("place_"):
		var p := Canon.place(id.substr(6))
		var t2: String = p.get("desc", "")
		if id == "place_ochre_span":
			var st := str(GameState.get_flag("ochre_span", ""))
			if st == "braced":
				t2 += "\n\n[b]World state:[/b] BRACED. Aruun and the Handler reinforced the foundation with Thoughtstone. It will carry people for another generation."
			elif st == "failing":
				t2 += "\n\n[b]World state:[/b] FAILING. The Thoughtstone went to the Dominion contract. The Span still stands. For now."
		return t2
	return ""
