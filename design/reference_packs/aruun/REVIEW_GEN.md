# Generated Aruun references - fidelity review (quality gate)

Status 2026-10-06: `design/reference_gen/aruun/` does not exist yet, so no image has been reviewed. Nothing generated is approved or usable.
This file is filled in per image as they land (candid: what changed vs the originals, what to reject).

## Method (per image)
1. `python3 tools/refsheets/review_gen.py <image> <front|side|back|head_front|head_side|head_back|hands|feet>` -> side-by-side original | generated | difference, silhouette IoU, colour drift.
2. Open both images at the same scale and tick the checklist below with a pixel/region reference.
3. Verdict: ACCEPT (as reference) / ACCEPT WITH NOTES / REJECT, with reasons.

## Reject if any of these is true (design locks from design/ARUUN_BRIEF.md section 4)
- Horns symmetric, shortened, straightened, or different count/tines; horn A thick + B thin/long relationship lost.
- Head shape drifts: snout shorter/blunter, eyes frontal like a human, no fang, human nose/lips/teeth, fur or hair on the face, extra eyes.
- Pauldron/elbow discs angular instead of round glossy ladybug discs; spot colour or black pits missing.
- Neck shortened or upright; trunk no longer hunched; proportions leave 13.5 heads +-0.7.
- Palette drifts (any plate more than ~25 RGB units from the original; saturation boosted; painterly/photoreal rendering instead of ink + flat cel).
- Invented parts (armour, jewellery, weapons, tattoos) not present in the original views; missing parts from the parts list (#1-33).
- Mantle on the wrong shoulder vs the creator's ruling for C1; hands/feet with a different finger/claw count than ruling C5.
- Outline style changed (soft/airbrushed, no black ink contour) or background baked in.
## Accept-with-notes if
- Only the unknown regions (true front face) are new, they follow the side+RAGE evidence, and every other pixel stays within tolerance of the original.
