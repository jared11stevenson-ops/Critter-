extends RefCounted
## Critter palettes for the lore cast (see DATA). Gate: test_art_palette.gd.

const IDS := ["aruun", "cigarra", "bramvex", "scarlith", "mollusk", "zephyr", "nyxaris"]

## Palettes are sampled from the approved reference sheets (tools/source_art/*_sheet.*), NOT invented.
## main = dominant body color, accent = second identity color, glow = emissive/rim color from the art, belly = light tone,
## sig = the one color that carries the character at a glance (used by the palette gate and UI tinting).
const DATA := {
	"aruun": {"main": "30262f", "accent": "b8321f", "glow": "e8582a", "sig": "e8582a", "belly": "d3b48c"},
	"cigarra": {"main": "3b2f4d", "accent": "a9c83c", "glow": "c9e04a", "sig": "7a4fc0", "belly": "e2dcc4"},
	"bramvex": {"main": "55603a", "accent": "7a1f24", "glow": "ff4a2a", "sig": "7b8a2a", "belly": "c9b078"},
	"scarlith": {"main": "b01c2c", "accent": "e0a53a", "glow": "ffc24a", "sig": "b01c2c", "belly": "ecd49a"},
	"mollusk": {"main": "d9a46c", "accent": "6b3326", "glow": "e8603c", "sig": "3aa86a", "belly": "f0d8a8"},
	"zephyr": {"main": "7d8442", "accent": "c43a5e", "glow": "ff5fa0", "sig": "d63a9c", "belly": "e8b5a0"},
	"nyxaris": {"main": "25202e", "accent": "ee4fa8", "glow": "7fd2ea", "sig": "6cc4e6", "belly": "efe8dc"},
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
