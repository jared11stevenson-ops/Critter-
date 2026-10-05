# Solmara - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- Rembg kept the parchment panel background on this dark sheet; fixed with colour-key background removal (alpha edges on the thin spikes are soft).
- Left-bottom corner debris in FRONT (panel frame corner) removed by component filtering where possible.
- Sources are 150-px wide on the sheet; fine spike lines are approximations by the upscaler.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 3242x4096 | 3 | 43 | front |
| side | 3356x4096 | 3 | 22 | side |
| back | 2735x4096 | 4 | 19 | back |
| top | 259x692 | 1 | 31 | top view (NOT ortho) |
| bottom | 348x699 | 1 | 24 | bottom view (NOT ortho) |
| hero | 50x27 | 1 | 0 | hero (not aligned) (NOT ortho) |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
