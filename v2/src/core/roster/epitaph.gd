class_name Epitaph
extends RefCounted
## Auto-generated Epitaph for the Wall of the Fallen: built from the chapters read and the critter's best moment.
## Deterministic (template picked from the uid), so it can be regenerated and tested.

const OPENERS := [
	"Here rests %s the %s.",
	"%s the %s is gone, and the Under is quieter.",
	"They called it %s, the %s.",
]
const CLOSERS := [
	"It was kept for %d bouts.",
	"It stood through %d bouts before the last.",
	"It lived through %d bouts.",
]


static func generate(c: CritterInstance, species_title: String) -> String:
	var h: int = absi(c.uid.hash())
	var read := c.chapters_unlocked.size()
	var lost := 7 - read
	var parts := PackedStringArray()
	parts.append(OPENERS[h % OPENERS.size()] % [c.name, species_title])
	parts.append(CLOSERS[(h / 3) % CLOSERS.size()] % c.bouts_survived)
	if read >= 7:
		parts.append("Its whole story was read.")
	elif lost == 6:
		parts.append("Only one chapter was ever read; six stay sealed forever.")
	else:
		parts.append("%d of 7 chapters were read; %d stay sealed forever." % [read, lost])
	var best := c.best_moment()
	if best != "":
		parts.append("Best remembered: %s." % best)
	if c.cause_of_death != "":
		parts.append("Fell to %s." % c.cause_of_death)
	return " ".join(parts)
