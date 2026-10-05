# Aruun - artist's review of this pack against the originals

Pack built 2026-10-05. Critique written after opening every output image next to the source sheet.

## Findings
- FIDELITY: all three views are the original paint; nothing redrawn. FRONT was re-cut from the sheet (the older hires cut clipped the viewer-right foot and claws flat at the crop edge; they are complete now). Morrow was removed with the audited mask from design/model_sheets/aruun/hires/front_morrow_mask.png, re-registered to the new cut (shift -46,+10 px); a short brown haft stub remains in the viewer-left hand (it is the grip, not invented).
- ALIGNMENT: crown, eyes, chin, neck base, shoulder, elbow, waist, crotch, knee, ankle and sole are on identical pixel rows in all three views by construction (piecewise-linear row warp from landmarks.json; max warp about 2.5 % of height). The FRONT is drawn larger/from a lower camera, so it is wider than side/back at the same height - never take widths from it.
- CLEANLINESS: rembg left a hard 1-px dark edge on some outlines (inherits the sheet's black ink, acceptable); a few cream star dots are smoothed by the upscaler. Side horn tips touch the sheet edge (Q3). Second ESRGAN pass (side/back) makes flat colour fields slightly posterised - lines are cleaner than a plain Lanczos stretch.
- EXPRESSIONS: sheet heads touch their neighbours, so rembg isolates one head per tile and its far edges are clipped by the neighbour (FOCUSED, AMUSED). Open-mouth views for the jaw: RAGE and AGGRESSIVE show fangs/tongue/lower jaw hinge.
- GREYBOX: a silhouette visual hull, deliberately crude (boxy torso because the back silhouette includes the cloak). Use it only for volume/pose checks, not as a sculpt base.
- FIXED during review: horn tips clipped in the side cut (box widened), duplicate detail exports removed, expression tiles re-cut with centre-component isolation, head-detail panel title removed.

## Automatic checks (tools/refsheets/docs.py)
| view | size px | alpha components >200px | specks <=200px | pose |
|---|---|---|---|---|
| front | 1891x4096 | 1 | 0 | 3/4 torso, head in profile, Morrow (mace) erased (NOT orthographic) (NOT ortho) |
| side | 947x4096 | 1 | 0 | side, faces screen-right |
| back | 1459x4096 | 1 | 0 | back |

Landmark rows are shared by construction (see metadata.json: landmarks_m). Components >200 px other than 1 are detached art such as horns tips, dangling charms or wing tips.
