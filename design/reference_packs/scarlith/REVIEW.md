# Scarlith - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- Turnaround figures are small (about 130 px wide), so x4 output is soft; the hero art (ortho/scarlith_hero_x4.png) is the better detail source.
- Landmarks are approximate; do not take limb ratios from this pack.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 3293x4096 | 1 | 8 | front turnaround (tiny) |
| side | 2999x4096 | 1 | 9 | side, faces screen-right |
| back | 4641x4096 | 2 | 18 | back (cheese carapace) |
| hero | 2328x1890 | 1 | 0 | hero with halberd (not aligned) (NOT ortho) |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
