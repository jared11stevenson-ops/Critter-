# Nyxaris - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- The sheet's ground shadow stays as a thin dark band under the legs (not removed to avoid eating leg tips).
- Heavy overlapping of fur/petals: ESRGAN smoothing merges some thin petal edges.
- Side cut is clipped at the right edge.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 2345x4096 | 2 | 0 | front |
| side | 2430x4096 | 2 | 0 | side |
| back | 1671x4096 | 1 | 0 | back |
| hero | 20x43 | 1 | 0 | hero (not aligned) (NOT ortho) |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
