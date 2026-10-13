class_name Tips extends RefCounted
## One-time teaching panels (shown once per install, remembered in UiPrefs.tips_seen). Creator law: the game teaches by showing, never by gating.
const TEXTS := {
	"shelf": ["YOUR SHELF", "Tap a jar to see the species inside: its role, its skill stars and, once it lives there, its family. Stars show how much thinking a critter asks of you. They never mean power: every critter is equally strong in different ways. MOVES in a jar shows its three abilities."],
	"approaches": ["HOW TO MEET IT", "STALK costs 5 scrap of bait: you study the prey and it starts weakened. DIRECT is a plain fight. PROVOKE wakes it angry: it fights one skill level harder, and the haul is bigger. Whoever you choose, the fight is the same fair duel."],
	"controls": ["LOCK-ON AND SPACE", "Bouts start LOCKED on your opponent. Tap LOCK to move freely and back away to think; tap it again to lock on. Guard right before a hit to parry: a parry cleanses burning, slows and other afflictions. Dodge out of a combo, then step back in."],
	"rules": ["RULES OF THE RING", "Each tournament rung can change the rules of the ring for BOTH fighters: Sudden Death (half Vitality), Hazard Ring (a burning zone), Ring-Out (stronger knockback), Endurance (long fight). Read the rule before you enter."],
}

static func seen(key: String) -> bool:
	return (str(UiPrefs.get_pref("tips_seen")).split(",") as PackedStringArray).has(key)

## Shows the tip as a modal notice if it has not been seen. Returns true when it was shown.
static func once(parent: Control, key: String) -> bool:
	if parent == null or not TEXTS.has(key) or seen(key):
		return false
	var cur := str(UiPrefs.get_pref("tips_seen"))
	UiPrefs.set_pref("tips_seen", key if cur == "" else cur + "," + key)
	var t: Array = TEXTS[key]
	CareerPanels.notice(parent, str(t[0]), str(t[1]))
	return true
