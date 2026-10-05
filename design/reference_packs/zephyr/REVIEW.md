# Zephyr - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- FRONT: the sheet title 'ZEPHYR' overlapped the figure; the title area was erased by hand-defined rectangles (0-21% x 0-26% and 0-30% x 0-6.5% of the cut). Colour-keyed removal (near-black + cream pixels left of the head) also removed the front's left antenna loop: documented RED area. Nothing was redrawn.
- SIDE faces right (mirrored by the sheet already). Landmarks are approximate (+-2%) due to the cloak.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 2476x4096 | 1 | 0 | front, standing with proboscis spear (hero = turnaround front) |
| side | 2497x4096 | 1 | 0 | side, faces screen-right (cloak/wings spread) |
| back | 2231x4096 | 1 | 0 | back |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
