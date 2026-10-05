# Bramvex - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- Turnaround figures are about 120 px wide on the sheet; ESRGAN output is smooth but the thorn lines are slightly merged.
- SIDE cut contains a large pale cream triangle above the head: probably the bat wing seen edge-on (it matches the wing studies) but it could be sheet background kept by the segmenter - asked as Q7.
- Landmarks are inexact (+-3%) because the body is a thin frame under cloth.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 1945x4096 | 1 | 0 | front turnaround, standing, lantern staff at viewer-left |
| side | 1876x4096 | 2 | 0 | side, faces screen-left on sheet; MIRRORED here to face screen-right |
| back | 2310x4096 | 2 | 2 | back, banner cloak + lantern |
| hero | 19x15 | 0 | 1 | hero crouch with thorned polearm 'Diplomacy' (not aligned) (NOT ortho) |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
