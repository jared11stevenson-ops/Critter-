# Dr. Mara Venn - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- Turnaround figures are small on the sheet (about 85 px wide) so the x4 views are smooth but soft; line weight is consistent.
- FRONT is a 3/4 turn (flagged non-ortho). Back is truly frontal; side is truly lateral.
- Photoreal concept images in the lore bible (image5/6) are a different style and were NOT used.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 988x4096 | 1 | 0 | front turnaround, standing, arms down, backpack at viewer-left (3/4-ish) (NOT ortho) |
| side | 950x4096 | 1 | 0 | side, faces screen-right |
| back | 1233x4096 | 1 | 15 | back |
| hero | 940x3081 | 1 | 0 | hero 3/4 pose with tablet (not aligned) (NOT ortho) |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
