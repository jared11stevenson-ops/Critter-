extends RefCounted
## Critter palettes (ROSTER.md: main / accent / glow). Hex values chosen by the Character Artist from the Lead's
## color names; `sig` is the signature hue used by the palette-distance gate and UI tinting.
## Warm hues crowd the wheel, so signatures are spread: brick 3, tangerine 26, gold 47, moss 90,
## cyan 190, violet 262, magenta 320 (min gap >= 20 degrees, enforced by test_art_palette).

const IDS := ["haldor", "sessa", "weft", "cinder", "marro", "zell", "kragg"]

const DATA := {
	"haldor": {"main": "3b3a46", "accent": "fbcf33", "glow": "ff6a1f", "sig": "fbcf33", "belly": "6a6676"},
	"sessa": {"main": "9be21f", "accent": "17141f", "glow": "ff2fb8", "sig": "ff2fb8", "belly": "d8f58a"},
	"weft": {"main": "7a45d8", "accent": "c8d3e6", "glow": "23e6cf", "sig": "7a45d8", "belly": "a98ae8"},
	"cinder": {"main": "ff7718", "accent": "2c2624", "glow": "ffe336", "sig": "ff7718", "belly": "ffc27a"},
	"marro": {"main": "b8362e", "accent": "d9a73c", "glow": "f5e8c6", "sig": "b8362e", "belly": "e0786a"},
	"zell": {"main": "17c4e8", "accent": "f4fbff", "glow": "2d5cff", "sig": "17c4e8", "belly": "b9f0fb"},
	"kragg": {"main": "8a3822", "accent": "ebdfc2", "glow": "74b535", "sig": "74b535", "belly": "b4654a"},
}

static func get_pal(id: String) -> Dictionary:
	var d: Dictionary = DATA.get(id, DATA["haldor"])
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
