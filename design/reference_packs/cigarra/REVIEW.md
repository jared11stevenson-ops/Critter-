# Cigarra - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- FIDELITY: front, side and back were RE-CUT from the original sheet because the older hires cuts were clipped at their crop edges (front: crown sphere + right boot cut flat; side: hood/sphere cut). All three are now complete except at the neighbour-overlap edges noted below. Nothing redrawn.
- ALIGNMENT: crown (hair top), eyes, chin, neck, shoulder, waist, crotch, knee, ankle, sole on identical rows in all views (row warp max about 3 % of height). Elbow/wrist rows are valid for the hanging arm only: the hip-hand pose puts the other wrist about 15 % higher.
- KNOWN CLIPPING: the FRONT's viewer-right wing and the BACK's viewer-left wing end in a straight vertical edge because the two figures overlap on the sheet (Q4). The SIDE view's far hood edge is intact.
- CLEANLINESS: background removal is clean on the pale hair; thin yellow-green hair tips lose a little alpha. Face markings and eye details survive the x4 pass; the small leaf/charm details are slightly smoothed.
- HEAD PACK: face callouts come from the sheet's HEAD DETAILS panel (best resolution available, 120 px wide on the sheet); expression sheet = 7 original panels. No true open-mouth view except UNHINGED (shouting) and HAPPY (grin, teeth).
- GREYBOX: crude hull, wings make the back silhouette a block. Use for volume only.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 2526x4096 | 1 | 0 | 3/4 front, wing cloak spread, hero pose (not orthographic) (NOT ortho) |
| side | 1223x4096 | 1 | 0 | side, faces screen-right |
| back | 1890x4096 | 1 | 0 | back, wing cloak folded |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
