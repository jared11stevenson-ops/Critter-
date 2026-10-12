extends RefCounted
## Presentation proportions (creator: "a little taller and a little less cartoony in size and stature"). Applied on top of each design:
##   size    : uniform size multiplier
##   stretch : extra height (y only), so the body reads longer-limbed and leaner
##   head_k  : head scale about the neck (smaller head = less chibi)
## Pure presentation: hitboxes and reach live in data, never here.
const DEFAULT := {"size": 1.0, "stretch": 1.1, "head_k": 0.9}
const TABLE := {
	"aruun": {"size": 1.08, "stretch": 1.16, "head_k": 0.78},
	"cigarra": {"size": 1.3, "stretch": 1.28, "head_k": 0.72},
	"bramvex": {"size": 1.0, "stretch": 1.06, "head_k": 0.9},
	"scarlith": {"size": 1.1, "stretch": 1.1, "head_k": 0.9},
	"mollusk": {"size": 1.08, "stretch": 1.12, "head_k": 0.88},
	"zephyr": {"size": 1.3, "stretch": 1.12, "head_k": 0.74},
	"nyxaris": {"size": 1.08, "stretch": 1.08, "head_k": 0.9},
	"pharilux": {"size": 1.0, "stretch": 1.1, "head_k": 0.95},
}

static func of(id: String) -> Dictionary:
	var d: Dictionary = DEFAULT.duplicate()
	d.merge(TABLE.get(id, {}), true)
	return d
