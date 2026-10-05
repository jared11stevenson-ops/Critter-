# Reference packs - index

Only the Lead sets `approved` / `changes requested` (after the creator answers). The artist sets `draft` / `ready for review`. **No pack is modelling authority until it is `approved`.**

| character | status | date | creator's notes |
|---|---|---|---|
| [aruun](aruun/review/aruun_pack_overview.png) | ready for review | 2026-10-05 |  |
| [cigarra](cigarra/review/cigarra_pack_overview.png) | ready for review | 2026-10-05 |  |
| [mara](mara/review/mara_pack_overview.png) | ready for review | 2026-10-05 |  |
| [dexter](dexter/review/dexter_pack_overview.png) | ready for review | 2026-10-05 |  |
| [zephyr](zephyr/review/zephyr_pack_overview.png) | ready for review | 2026-10-05 |  |
| [bramvex](bramvex/review/bramvex_pack_overview.png) | ready for review | 2026-10-05 |  |
| [scarlith](scarlith/review/scarlith_pack_overview.png) | ready for review | 2026-10-05 |  |
| [solmara](solmara/review/solmara_pack_overview.png) | ready for review | 2026-10-05 |  |
| [mollusk](mollusk/review/mollusk_pack_overview.png) | ready for review | 2026-10-05 |  |
| [nerit](nerit/review/nerit_pack_overview.png) | ready for review | 2026-10-05 |  |
| [nyxaris](nyxaris/review/nyxaris_pack_overview.png) | ready for review | 2026-10-05 |  |
| [pharilux](pharilux/review/pharilux_pack_overview.png) | ready for review | 2026-10-05 |  |

## Source art inventory (what exists per character)

Legend: **S** = original sheet in `tools/source_art/` (1400-1536 px), **T** = turnaround views (front/side/back) on that sheet, **hd** = existing Real-ESRGAN cut in `design/model_sheets/<id>/hires/`, **E** = expression panel(s), **P** = in-game portraits `game/art/portraits/<id>/`, **B** = also in the lore bible docx (`tools/source_art/bible_media/imageN.jpg`, extracted from `design/*.docx`), **D** = detail panels on the sheet (head details, equipment, props).

| id | sheet (S) | turnaround views on sheet | existing hires/board | expressions | portraits (P) | bible images (B) | notes |
|---|---|---|---|---|---|---|---|
| aruun | aruun_nerit_sheet.jpg (left half) | front (3/4, with mace), side, back | hd front/side/back, detail_*.png, landmarks.json | 5 on sheet (calm focused rage amused aggressive) | 6 | image37 | front is a 3/4 pose with head in profile; mace states panel |
| cigarra | cigarra_sheet.jpg (+ _1280, comic) | front (3/4), side, back | hd front/side/back/head/crown | 7 on sheet | yes | image1, image34 (+ comic/20/32 story pages) | existing hd cuts clipped at crop edges: re-cut |
| mara | mara_sheet.jpg | front, side, back | hd f/s/b, expressions.png | 6 | yes | image5, image6 (photoreal concept - different style), image17 | image5/6 are NOT the in-game art style |
| dexter | dexter_sheet.jpg | front (3/4), back; **no side** | hd front/back, expressions.png | 6 | yes | image19 | side view missing |
| zephyr | zephyr_sheet.png | front, side, back | hd f/s/b, expressions.png | 5 | yes | image12 | |
| bramvex | bramvex_sheet.png | front, side, back | hd f/s/b | none (head studies only) | 1 | image4, image7 | height 2.3 m unconfirmed |
| scarlith | scarlith_sheet.jpg | front (hero), side, back | hd f/s/b, expressions.png | 5 | yes | image26 | 12 cm tall |
| solmara | solmara_sheet.png | front, side, back (+top/bottom not cut) | hd f/s/b, expressions.png | 5 | yes | image14, image15 | 5.5 m sea spider |
| mollusk | mollusk_sheet.png | front, back, side | none | 6 | 6 | image10, image22, image23 (variants) | check which bible variant is canon |
| nerit | aruun_nerit_sheet.jpg (right half) | front, back, side | none | 6 | no (check) | image37 | |
| nyxaris | nyxaris_sheet.png | front, side, back | none | none (head studies) | yes | image3, 8, 9, 24, 27, 29 | |
| pharilux | pharilux_sheet.png | front, side, back | none | 5 (poses & expressions) | yes | image2, 13, 21, 33 | |

Bible sheets that exist for characters outside this task's list (not packed here, listed so nothing is lost): Vaesii (image11), Brixel (image30), Solthrin (image18, 31, 36), Scambril (image35). `game/canon/npcs/*.json` contain only Red Reaches ambient NPC data, no model sheets, so no NPC packs exist.

Pack layout: `<id>/ortho/` (4096-px transparent PNGs, lineups, proportion chart), `head/`, `details/`, `swatches/`, `greybox/`, `review/` (phone-friendly overview + per-view images), `metadata.json`, `QUESTIONS.md`, `STYLE.md`, `REVIEW.md`.
