extends RefCounted
## Critter palettes for the lore cast (see DATA). Gate: test_art_palette.gd.

const IDS := ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris", "pharilux"]

## Palettes are sampled from the approved reference sheets (tools/source_art/*_sheet.*), NOT invented.
## main = dominant body color, accent = second identity color, glow = emissive/rim color from the art, belly = light tone,
## sig = the one color that carries the character at a glance (used by the palette gate and UI tinting).
const DATA := {
	"aruun": {"main": "2a2428", "accent": "a82a22", "glow": "e8502a", "sig": "e8582a", "belly": "d3b48c"},
	"cigarra": {"main": "3b2f4d", "accent": "a9c83c", "glow": "c9e04a", "sig": "7a4fc0", "belly": "e2dcc4"},
	"bramvex": {"main": "6a5238", "accent": "b0322a", "glow": "ffa845", "sig": "7b8a2a", "belly": "cbb98c"},
	"scarlith": {"main": "b01c2c", "accent": "e3b04a", "glow": "ffc24a", "sig": "b01c2c", "belly": "d98a3a"},
	"mollusk": {"main": "8f946a", "accent": "ff7a1a", "glow": "ffb347", "sig": "3aa86a", "belly": "d7d3a8"},
	"zephyr": {"main": "7a6a3e", "accent": "d63a9c", "glow": "ffd24a", "sig": "d63a9c", "belly": "ecd9b0"},
	"nyxaris": {"main": "2a2650", "accent": "ee4fa8", "glow": "7fd2ea", "sig": "6cc4e6", "belly": "e8eaf2"},
	"pharilux": {"main": "4f7a72", "accent": "a8602e", "glow": "ffb83a", "sig": "ffb83a", "belly": "cfd6b0"},
}

static func get_pal(id: String) -> Dictionary:
	var d: Dictionary = DATA.get(id, DATA["aruun"])
	var out := {}
	for k in d:
		out[k] = Color.html(d[k])
	var main: Color = out["main"]
	# "darkest tone": hue-shifted toward blue-violet, never pure black
	out["ink"] = Color.from_hsv(fposmod(main.h + 0.04, 1.0), minf(main.s + 0.15, 1.0), 0.12)
	out["deep"] = main.darkened(0.35)
	out["light"] = main.lightened(0.25)
	out["id"] = id
	return out
