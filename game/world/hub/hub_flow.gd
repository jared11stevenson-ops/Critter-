class_name HubFlow
extends RefCounted
## Pure rules for the hub's "what do I do now" layer (no nodes, unit-tested): the current objective, the one primary
## action button, which places are worth showing yet, and the "what changed" recap after a descent.
## Flags are passed in as a Dictionary (GameState.flags) so tests can feed any state.

const SECONDARY := ["lab", "codex", "habitat", "board", "stores", "ledger"]

static func _f(flags: Dictionary, k: String) -> bool:
	return bool(flags.get(k, false))

## The place the story wants next: "table", "gate", "habitat" or "" (free roam).
static func objective_id(flags: Dictionary) -> String:
	if not _f(flags, "briefed"):
		return "table"
	if not _f(flags, "rr_complete"):
		return "gate"
	if not _f(flags, "debriefed"):
		return "table"
	if not _f(flags, "habitat_built"):
		return "habitat"
	if not _f(flags, "slice_complete"):
		return "table"
	return ""

static func objective_text(flags: Dictionary) -> String:
	match objective_id(flags):
		"table":
			if not _f(flags, "briefed"):
				return "Meet Mara at the Common Table"
			if not _f(flags, "debriefed"):
				return "Debrief at the Common Table"
			return "Talk at the Common Table"
		"gate":
			return "Descend through the Gate to the Red Reaches"
		"habitat":
			return "Build a Habitat in the Habitat Wing"
	return "Free roam. The Terrarium remembers."

## Label of the big primary button; "" when there is nothing pressing.
static func primary_label(flags: Dictionary) -> String:
	match objective_id(flags):
		"table":
			if not _f(flags, "briefed"):
				return "Meet Mara"
			if not _f(flags, "debriefed"):
				return "Debrief"
			return "Talk"
		"gate":
			return "Descend"
		"habitat":
			return "Build Habitat"
	return "Descend" if _f(flags, "briefed") else ""

## Spot id the primary button acts on (free roam falls back to the Gate once briefed).
static func primary_spot(flags: Dictionary) -> String:
	var o := objective_id(flags)
	if o != "":
		return o
	return "gate" if _f(flags, "briefed") else ""

static func went_down(flags: Dictionary) -> bool:
	return int(flags.get("descents", 0)) > 0 or _f(flags, "rr_complete")

## Should this place be shown at all right now? (People are handled separately.)
static func spot_visible(id: String, flags: Dictionary) -> bool:
	match id:
		"table":
			return true
		"gate":
			return _f(flags, "briefed")
		"lab", "codex":
			return _f(flags, "briefed")
		"habitat":
			return _f(flags, "debriefed") or _f(flags, "habitat_built") or objective_id(flags) == "habitat"
		"board", "stores", "ledger":
			return went_down(flags)
	return true

static func show_gear_bonds(flags: Dictionary) -> bool:
	return went_down(flags)

## Places for the "Places" list (everything visible that is not the current objective).
static func places_list(flags: Dictionary) -> Array:
	var out: Array = []
	var obj := primary_spot(flags)
	for id in ["gate"] + SECONDARY:
		if spot_visible(id, flags) and id != obj:
			out.append(id)
	return out

## "What changed" lines from two snapshots {items:{id:n}, specimens:int, codex:int, standing:int}.
static func recap_lines(before: Dictionary, after: Dictionary, item_name: Callable = Callable()) -> Array:
	var out: Array = []
	var bi: Dictionary = before.get("items", {})
	var ai: Dictionary = after.get("items", {})
	var parts: Array = []
	for k in ai:
		var d := int(ai[k]) - int(bi.get(k, 0))
		if d > 0:
			var nm: String = str(item_name.call(str(k))) if item_name.is_valid() else str(k)
			parts.append("+%d %s" % [d, nm])
	if not parts.is_empty():
		out.append("Gathered: " + ", ".join(parts))
	var ds := int(after.get("specimens", 0)) - int(before.get("specimens", 0))
	if ds > 0:
		out.append("%d new specimen%s for the Habitat" % [ds, "" if ds == 1 else "s"])
	var dc := int(after.get("codex", 0)) - int(before.get("codex", 0))
	if dc > 0:
		out.append("%d new Codex entr%s" % [dc, "y" if dc == 1 else "ies"])
	var dd := int(after.get("standing", 0)) - int(before.get("standing", 0))
	if dd != 0:
		out.append("Dominion standing %s%d" % ["+" if dd > 0 else "", dd])
	return out

## The "NEXT:" line closing the return card.
static func next_line(flags: Dictionary) -> String:
	return "Next: " + objective_text(flags)
