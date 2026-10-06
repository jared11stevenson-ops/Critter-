# Aruun lookdev log (shader layer + lighting rigs)

Owner: lookdev/lighting artist. Scope: `game/art/shaders/character_pop*` (shader layer), `game/art/models/_qa_aruun_look.*` (board scene),
`tools/qa/scripts/aruun_lookdev.json`. The model itself is untouched.

Board: `tools/shot.sh res://game/art/models/_qa_aruun_look.tscn /tmp/x <times> <quit> - qa_seq=rig:cam,...`
rigs: hub reaches dusk boss ice green noon; cams: close (10 m, -33), hero (7.2 m, -26), wide (14 m, -40) = the real follow-camera presets, plus head.
`qa_pal=key=val;key=val` overrides the Aruun palette live, `qa_amb=x` scales world ambient (used to find the navy-chitin cause).
Images: `design/model_sheets/aruun/lookdev/`.

## Iteration 0 - baseline (`v0_baseline_cams.png`)
Critique: legacy pop shader: flat lit, no spec, near-black chitin reads **navy/violet** (sheet is warm brown-black), 2 px outline is thick and
jagged on the cape and eats the face at head distance, red plates are one flat orange-red (sheet: deep oxblood lacquer with hard highlights),
teal rim is a uniform glow all around so it flattens the form.

## Iteration 1 - painted shader written, but not active (`v1_toon_active_head.png`)
Added `character_pop_toon.gdshader` (2-band soft ramp with per-material shadow tints, zone masks from the sheet albedo: lacquer / chitin / bone / cloth,
stylised hard-edged spec on lacquer, faint sheen on chitin, baked-AO from ORM.r, painted edge darkening on down-facing silhouettes, teal rim only on
upper/outer edges) and a screen-constant outline whose ink colour is the local albedo darkened. Finding: the GLB material is `doubleSided`, so
`CharacterPop` was silently picking the 2-sided wing shader and none of the zone grading ran. Fixed (toon shader is cull_disabled).
Critique after fix: bone now bands nicely, but chitin was STILL navy even with warm albedo -> `qa_amb=0` proved it is the world's cool sky ambient.

## Iteration 2 - warm authored fill (`v2_warm_ambient_head.png`)
Toon shader uses `ambient_light_disabled` + a warm `char_ambient` term, so Aruun's chitin is brown-black on every ground. Critique: chitin right, but
reds were coral/orange and flat, too much fill; teal rim made the back arm look cyan.

## Iteration 3 - crimson lacquer, thinner rim (`rigs_hero_board.png`, `head_crops_2x.png`)
Red zone multiplied toward oxblood (0.98,0.62,0.70), shade tint crimson, fill reduced, val_lift 0.98, rim strength 0.8 / power 3.2.
Result: plates read as glossy crimson discs with a hard highlight, chitin warm near-black, bone cream; he separates from desert, dusk, boss red,
ice white-blue and green grounds (hub dark floor too). Outline 1.5 px at 720p, ink-coloured, no longer swamps the face.

## Head / face check (2x crops, `head_crops_2x.png`)
* Hero camera (7.2 m): eye (yellow with dark pupil) and the red open jaw / tongue read at 2x. Good.
* Close camera (10 m, default): eye reads as a yellow dot; the jaw/mouth is ~3 px of red and does NOT read as a mouth. This is a model/animation
  scale issue (head is ~25 px tall); shader can't fix it. Suggest to the model owner: bigger eye whites + a darker mouth cavity, and a head scale
  bump of ~10 % for the close preset, or let the camera rig lerp to hero distance during dialogue.

## Cost
* Scene with Aruun alone: 12 draw calls (unchanged: the outline hull was already a second pass); full-flow unaffected (<=150 gate from the earlier pass).
* `character_pop_toon` fragment: 1 albedo + 1 normal(optional) + 1 ORM + 1 emissive sample (same as before) + ~35 ALU for zones/grade; `light()` runs
  for the sun and rim directional lights only (~25 ALU each). Outline fragment adds 1 texture sample (was 0). No screen reads, no loops, no
  extra passes: mobile-safe. Cigarra and NPCs keep the legacy path (`zone_grade` 0, no toon shader) so their look and cost are unchanged.

## Open items
Face crop at the default close camera (above); hub rig is just the existing hub preset on a dark floor, a dedicated hub showcase set is still to do;
boss rig needs a stronger teal rim to separate from dark red ground (rim is intentionally modest); ground contact shadow is the engine one.
