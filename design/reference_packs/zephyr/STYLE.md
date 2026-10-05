# Zephyr - style guide

Everything here is read off the original sheet art (see ortho/ and head/); `[measured]` = computed by tools/refsheets, the rest is the artist's reading and is the checklist for matching the look in 3D.

## Line weight
- [measured] outline stroke is about 2.0 px on a 1500-px-tall figure = 0.13% of height = 2 mm at canon height.
- Dark brown-black ink, medium weight, broken on foliage; wings have thin black outer edge only.

## Colour blocking
- [measured] dominant colours (share of opaque pixels): #131010 18%, #352926 16%, #554137 11%, #94754d 10%, #bc976f 9%, #c17455 9%
- Pink/crimson/olive/orange gradients on wings and cloak against a dark brown body; pink glass accents.

## Shading style
- Painterly cel: wing gradients pink to olive; flat dark body.
- For 3D: use a toon/stepped ramp or very low-frequency baked AO; do NOT bake photographic soft shadows into albedo.

## Shape language / silhouette
- Tall, thin, hunched bird/insect; huge wing cloak makes a triangle; long antennae loops and proboscis extend the silhouette; digitigrade talon legs.

## Design locks (must never change)
- Hawk-moth proboscis + bird-skull mask
- Crest of pointed crimson/olive feathers; two drooping antennae ending in red tassels
- 4 wings pink-to-olive with pale spots, folded down the back
- Nectar vials on the belt (pink)
- Tattered cloak + flowers
- Height 165 cm

## Views and authority
- Proportions and heights: side/back views (orthographic where marked in metadata.json). Costume/colour: all views. 3/4 'front' views are NOT orthographic - never snap to them for widths without checking the side/back.
