# Mollusk - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- Cleanest cut of all characters: strong silhouette and flat paint.
- Legs/arms estimated; do not use limb ratios.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 1603x4096 | 1 | 0 | front |
| back | 2352x4096 | 1 | 0 | back (shell) |
| side | 1353x4096 | 1 | 0 | side, faces screen-left (mirror for game) |
| hero | 2232x2012 | 1 | 0 | hero with time mace (not aligned) (NOT ortho) |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
