class_name HudFlow
extends RefCounted
## Pure, unit-tested rules for the field HUD's "one thing at a time" layer: the toast queue (1 visible, priorities,
## short text), the first-time tips (each shown once, persisted as flags), and the progressive reveal of controls.

# ------------------------------------------------------------------ text
const TOAST_MAX_CHARS := 56

## Trim a toast to one short line: drop known verbose prefixes, cut at a word boundary with an ellipsis.
static func shorten(text: String, max_chars: int = TOAST_MAX_CHARS) -> String:
	var t := text.strip_edges().replace("\n", " ")
	for pair in [["Codex updated: ", "Codex: "], ["You sense something: ", "Sensed: "], ["Evidence logged: ", "Evidence: "]]:
		if t.begins_with(pair[0]):
			t = pair[1] + t.substr(pair[0].length())
	if t.length() <= max_chars:
		return t
	var cut := t.substr(0, max_chars - 1)
	var sp := cut.rfind(" ")
	if sp > max_chars / 2:
		cut = cut.substr(0, sp)
	return cut.rstrip(" ,;:.-") + "…"

static func priority(kind: String) -> int:
	match kind:
		"warning": return 4
		"tip": return 3
		"trust": return 2
		"item": return 1
		"codex": return 1
	return 0

# ------------------------------------------------------------------ toast queue
## One toast on screen at a time; a backlog of at most MAX_QUEUE waits, best priority first. A higher-priority arrival
## cuts in after the current one has been readable for MIN_SHOW seconds. Time is injected so tests are deterministic.
class ToastQueue extends RefCounted:
	const MAX_QUEUE := 3
	const MIN_SHOW := 0.9
	var current: Dictionary = {}
	var queue: Array = []
	var dropped := 0

	func push(text: String, kind: String, now: float) -> void:
		var t := HudFlow.shorten(text)
		if t == "":
			return
		if not current.is_empty() and current["text"] == t:
			return
		for q in queue:
			if q["text"] == t:
				return
		queue.append({"text": t, "kind": kind, "pri": HudFlow.priority(kind), "dur": 0.0})
		while queue.size() > MAX_QUEUE:
			var worst := 0
			for i in queue.size():
				if queue[i]["pri"] < queue[worst]["pri"]:
					worst = i
			queue.remove_at(worst)
			dropped += 1

	## Advance to `now`; returns true when `current` changed (the HUD then re-renders it).
	func tick(now: float) -> bool:
		var changed := false
		if not current.is_empty():
			var age: float = now - float(current["at"])
			var cut: bool = not queue.is_empty() and age >= MIN_SHOW and _best_pri() > int(current["pri"])
			if age >= float(current["dur"]) or cut:
				current = {}
				changed = true
		if current.is_empty() and not queue.is_empty():
			var bi := 0
			for i in queue.size():
				if queue[i]["pri"] > queue[bi]["pri"]:
					bi = i
			current = queue[bi]
			queue.remove_at(bi)
			var base: float = 2.0 + 0.025 * str(current["text"]).length()
			if current["kind"] == "tip":
				base += 1.2
			if not queue.is_empty():
				base *= 0.7
			current["dur"] = clampf(base, 1.6, 4.0)
			current["at"] = now
			changed = true
		return changed

	func _best_pri() -> int:
		var b := -1
		for q in queue:
			b = maxi(b, int(q["pri"]))
		return b

# ------------------------------------------------------------------ first-time tips
## id -> {text, target (HUD control to pulse)}. Shown once ever (flag "_tip_<id>"), only when they start to matter.
const TIPS := {
	"move": {"text": "Drag on the left to move", "target": "joystick"},
	"attack": {"text": "Enemy ahead: tap ATTACK", "target": "attack"},
	"abilities": {"text": "Abilities unlocked: tap one", "target": "ability"},
	"dash": {"text": "Tap DASH to dodge", "target": "dash"},
	"swap": {"text": "Tap your partner's portrait to SWAP", "target": "swap"},
	"scan": {"text": "Tap SCAN to read the area", "target": "scan"},
	"contain": {"text": "Tap CONTAIN to rescue it", "target": "contain"},
}

static func tip_seen(flags: Dictionary, id: String) -> bool:
	return bool(flags.get("_tip_" + id, false))

static func tip_text(id: String) -> String:
	return str(TIPS.get(id, {}).get("text", ""))

## Marks the tip seen and returns its text, or "" if it was already shown (or unknown).
static func take_tip(flags: Dictionary, id: String) -> String:
	if not TIPS.has(id) or tip_seen(flags, id):
		return ""
	flags["_tip_" + id] = true
	return tip_text(id)

# ------------------------------------------------------------------ progressive reveal
const REVEAL_DIST_M := 24.0

## Which control groups the HUD shows. `combat`/`scan` latch (persisted flags), so a returning player never loses them.
## Core (always): joystick, attack, pause, minimap, objective, leader portrait.
static func reveal(flags: Dictionary, enemy_dist: float, ability_used: bool, scan_started: bool) -> Dictionary:
	var veteran := bool(flags.get("rr_complete", false)) or int(flags.get("descents", 0)) >= 3
	var combat := veteran or bool(flags.get("_hud_combat", false)) or ability_used or enemy_dist <= REVEAL_DIST_M
	var scan := veteran or bool(flags.get("_hud_scan", false)) or scan_started or bool(flags.get("valley_clear", false)) or bool(flags.get("first_scan_done", false))
	return {"combat": combat, "scan": scan}
