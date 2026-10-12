class_name CritterLore extends RefCounted
## Menu-facing text per critter: one-line identity, win line and epitaph. Written from design/v2/ROSTER.md + LORE_MOVES.md
## (identity anchors only; the Life Story chapters come with the roster milestone). Pure data, no engine calls.

const DATA := {
	"aruun": {
		"line": "Heavy bruiser. A psionic mace, a rising Rage and the strength to carry a bridge.",
		"win": "The mace remembers every blow, and so does the Reach.",
		"epitaph": "Aruun carried the Red Span for eleven minutes. Nobody was left to carry him.",
	},
	"cigarra": {
		"line": "Counter duelist. Sees the next blow before it lands, until too much future floods in.",
		"win": "A future seen is a future touched. She touched this one.",
		"epitaph": "Cigarra saw every branch of the future but this one. The crown spheres fell silent.",
	},
	"bramvex": {
		"line": "Zoner and tactician. Prepares the ground, hides, then strikes from long reach.",
		"win": "Diplomacy was offered. The thorned answer was louder.",
		"epitaph": "Bramvex held the line nineteen days and one more bout than he had. The line held without him.",
	},
	"scarlith": {
		"line": "Burst striker. Ferments decay and ripens it into a devastating rot burst.",
		"win": "Everything has value. This bout aged beautifully.",
		"epitaph": "Scarlith was sure everything had value. The Warrens set a price on that, and it was paid.",
	},
	"mollusk": {
		"line": "Shield tank. Delays every impact and borrows seconds, but each debt comes due.",
		"win": "Everything arrives at once, and it arrived for them.",
		"epitaph": "Mollusk borrowed one second too many. The shell keeps the marks of every bout it survived.",
	},
	"zephyr": {
		"line": "Aerial skirmisher. Wind, pollen and promises: rules are a game, promises are not.",
		"win": "A promise kept. The rest was weather.",
		"epitaph": "Zephyr kept every promise but the last. The Briarwild remembers it anyway.",
	},
	"pharilux": {
		"line": "Threshold keeper. Pressure, a guiding light and the tide hold the ground and mark the prey.",
		"win": "Closed is still working.",
		"epitaph": "Pharilux kept the watch for longer than anyone could say. The lamp is still lit; nobody will say who lit it.",
	},
	"nyxaris": {
		"line": "Grappler and binder. Frost silk and venom hold a rival where they stand.",
		"win": "Pattern, pulled tight. The cold archive keeps this one too.",
		"epitaph": "Nyxaris wove beautiful things to control danger. Danger, in the end, wove back.",
	},
}

static func line(id: String) -> String:
	return str(DATA.get(id, {}).get("line", ""))

static func win_line(id: String) -> String:
	return str(DATA.get(id, {}).get("win", "Victory."))

static func epitaph(id: String) -> String:
	return str(DATA.get(id, {}).get("epitaph", "Here rests a critter. It had one life."))

## The headline and sub lines for a result dictionary from BoutScene (`finished`). Returns {title, sub, tone: win|death|defeat|draw|spare}.
static func describe_result(res: Dictionary, name_of: Callable) -> Dictionary:
	var pi := int(res.get("player_idx", 0))
	var a_id := str(res.get("a_id", ""))
	var b_id := str(res.get("b_id", ""))
	var win := int(res.get("winner", -1))
	var reason := str(res.get("reason", ""))
	var training := bool(res.get("training", false))
	if pi < 0:
		var wid := a_id if win == 0 else b_id
		return {"title": "%s WINS" % str(name_of.call(wid)).to_upper() if win >= 0 else "DRAW", "sub": win_line(wid) if win >= 0 else "Time ran out.", "tone": "win" if win >= 0 else "draw"}
	var my_id := a_id if pi == 0 else b_id
	var foe_id := b_id if pi == 0 else a_id
	var my_name := str(name_of.call(my_id))
	var foe_name := str(name_of.call(foe_id))
	if win < 0:
		return {"title": "DRAW", "sub": "Neither of you could finish it. Both walk away.", "tone": "draw"}
	if win == pi:
		var sub := win_line(my_id)
		if reason == "yield":
			sub = "%s yielded and lives to fight again. %s" % [foe_name, sub]
		elif bool(res.get("killed", false)) and not training:
			sub = "%s has fallen. Death is permanent on CRITTER. %s" % [foe_name, sub]
		return {"title": "VICTORY", "sub": sub, "tone": "win"}
	if reason == "yield":
		return {"title": "YIELDED", "sub": "%s lives. The bout is lost, and so is the purse." % my_name, "tone": "spare"}
	if bool(res.get("killed", false)) and not training:
		return {"title": "DEATH", "sub": epitaph(my_id), "tone": "death"}
	return {"title": "DEFEAT", "sub": "%s is down, but training costs nothing." % my_name if training else "%s is down." % my_name, "tone": "defeat"}
