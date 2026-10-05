# Nerit - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- Translucent lantern and thin antenna arcs came through background removal; the faint antenna tip lines may lose alpha at 1-px thickness.
- Landmark rows are approximate under the cloak.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 1965x4096 | 1 | 0 | front, lantern abdomen at viewer-left (hero turnaround front) (NOT ortho) |
| back | 1546x4096 | 1 | 0 | back |
| side | 1150x4096 | 1 | 0 | side, faces screen-left on sheet; MIRRORED here to face screen-right |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
