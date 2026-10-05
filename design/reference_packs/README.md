# CRITTER reference packs (3D-production reference sheets)

New, 3D-oriented reference sheets for every character, built ONLY from our own sheet art (design/ASSET_SOURCES.md: no unlicensed generative
models; tools are Pillow/numpy/scipy/scikit-image, rembg (isnet-anime), Real-ESRGAN anime_6B (BSD-3, torch CPU), Blender 5 bpy (output ours)).
Nothing in a pack changes a character's design: views are the original paint, cleaned, scaled and aligned. Anything that is NOT directly in the
art is marked (green / yellow / red, see below) and asked in the pack's `QUESTIONS.md`. See `INDEX.md` for status (a pack is NOT modelling authority until the
Lead sets it to `approved`) and for which source art exists per character.

## Pack layout (`design/reference_packs/<id>/`)
| path | what |
|---|---|
| `review/<id>_pack_overview.png` | ONE phone-friendly overview (2400 px wide): ortho lineup on landmark lines, proportions, head turnaround, expressions, face callouts, detail + material sheets, clay greybox, derivation legend, numbered open questions. Plus `<id>_<view>_view_2048_landmarks.jpg` full views with landmark lines. |
| `ortho/<id>_<view>_4096.png` | transparent PNG, 4096 px tall, ALL views of a character at the SAME scale (`metadata.json: px_per_m`) and with every measured landmark on the same pixel row. `ortho/<id>_ortho_lineup_{clean,landmarks}.png`, `_proportion_chart.png` (head count, limb ratios, canon height). `ortho/<id>_hero*.png` = extra non-aligned hero/variant art where the sheet has it. |
| `head/` | head crops at the same scale as ortho (front / side / back turnaround, with and without landmark lines), expression sheet, eye/nose/mouth callouts, face close-up panels. |
| `details/` | hands, feet, costume layers, props, equipment panels (x4 upscaled originals), `<id>_detail_sheet.png`, `<id>_materials.png` (numbered PBR callouts + costume layer order). |
| `swatches/<id>_palette.png`, `palette.json`, `materials.json` | art-sampled palette (k-means over the cut views) + canon.json game palette + per-surface base colour / roughness / metalness / emissive suggestions (hex sampled from the art). |
| `greybox/` | clay greybox (`.glb`, visual hull of the aligned side+back silhouettes) and clay orthographic renders (front, side, back, 3/4 front, 3/4 back). Shape only, no colour. |
| `metadata.json` | px_per_m, ground row, per-view axis column, landmark heights in metres, which views are NOT orthographic. Read by the Blender importer. |
| `STYLE.md`, `QUESTIONS.md`, `REVIEW.md` | style guide + design locks; open questions for the Lead; the artist's critique against the originals. |

## Derivation colours (when a view/region is not directly in the art)
**green** = directly from the original art (1:1 pixels); **yellow** = inferred from another view (row-remapped, never redrawn); **red** = unknown - NOT invented, asked in QUESTIONS.md.
Currently every ortho view is original art (green). Views the sheet does not contain (Dexter side, true orthographic fronts) are listed in QUESTIONS.md, not painted.

## Blender
`blender --python tools/refsheets/blender_refplanes.py -- design/reference_packs/aruun` builds REF_front / REF_side / REF_back at true scale
(1 BU = 1 m, origin on the ground under the body centre line, character faces -Y) plus a `REF_landmarks` collection (one named edge per landmark:
crown, eyes, chin, shoulder, elbow, wrist, waist, crotch, knee, ankle). Image empties are only visible when looking straight at them (numpad 1 / ctrl+3 / ctrl+1).
`--mesh` makes textured planes instead. The clay `.glb` imports at the same scale.

## Rebuilding (tools/refsheets/)
`cast.py` (+ `cast2.py`, `cast3.py`) = per-character source boxes, measured landmarks, materials, questions.
`stage1_cuts.py <id>` (ESRGAN x4 + rembg cut, cache in .claude/refsheet_cache; `up <id>` = optional second ESRGAN pass for small cuts) ->
`ortho.py <id>` -> `packs.py <id> [palette materials prop head details]` -> `greybox.py <id>` (bpy) -> `docs.py <id>` -> `overview.py <id>`.
Helper views for reading boxes/landmarks: `fracgrid.py`, `gridview.py`, `gridcrop.py`.

## Honest limits
* Source sheets are 1280-1536 px; a figure in a turnaround is only 50-150 px wide, so "4096 tall" means ESRGAN x4 (+ optional second pass) then downsample: clean lines, NOT new detail.
* Most sheets' FRONT is a 3/4 hero pose, not orthographic; those views are flagged `orthographic:false` in metadata.json. Use side/back for widths and depths.
* Landmarks are measured/read to about +-1-1.5 % of height (aruun: landmarks.json). Posed arms make elbow/wrist rows valid for the hanging arm only.
