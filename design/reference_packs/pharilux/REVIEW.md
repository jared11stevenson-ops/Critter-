# Pharilux - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- All three views are original paint, rembg-cut; the side has the largest head-row warp of any pack (about 12% of height) because of the stooped pose: head crops in head/ are therefore on shared rows but differently posed.
- Landmarks approximate; do not read limb ratios.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 2811x4096 | 1 | 2 | front |
| side | 2789x4096 | 1 | 0 | side |
| back | 2250x4096 | 2 | 1 | back |
| hero | 2025x2031 | 1 | 0 | hero (not aligned) (NOT ortho) |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
