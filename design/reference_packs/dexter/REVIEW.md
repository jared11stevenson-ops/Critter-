# Dexter Mane - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- Front head was cut off in the older hires; re-cut includes the head. The neighbouring lab-coat figure's sleeve touches the front figure on the right; removed by component filtering.
- Back view silhouettes are 4 small figures; the biggest (hero back, ~230 px) used. Landmarks inside the coat are guesses (flagged +-2%).

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 1115x4096 | 1 | 0 | hero 3/4 pose, hands in pockets, long coat (the only front) (NOT ortho) |
| back | 1340x4096 | 1 | 25 | back, coat with red lining |
| back_alt_jacket | 249x925 | 1 | 0 | back, jacket + harness outfit variant (no coat) (NOT ortho) |
| back_alt_coat | 264x913 | 1 | 0 | back, plain long coat variant (NOT ortho) |
| labcoat | 568x2183 | 1 | 0 | lab-coat outfit variant, 3/4 (NOT ortho) |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
