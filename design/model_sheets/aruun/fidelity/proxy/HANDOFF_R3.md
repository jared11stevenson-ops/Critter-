# HANDOFF R3 (Primary Modeler). Not a grade; compare.py numbers only. Start = LOCKED_BASELINE_02 (side 0.877 / back 0.885). Final: side 0.876 / back 0.884. No ticket rolled back (largest single-ticket drop 0.004).

## Ticket 1: shoulder/neck ramp + chest front (commit "R3 ticket 1")
Neck-base ellipsoid lowered 0.015, mantle and trunk ramp tops lowered 0.02-0.03, trunk chest radius at 1.62-1.70 m trimmed 0.015-0.02. (A first try with the full 0.035 lowering over-narrowed the ramp and cost back IoU 0.004; halved.)
Outer width, ref / before / after:
| view, height | ref | before | after |
|---|---|---|---|
| side 1.84 | 0.133 | 0.176 | 0.137 |
| side 1.82 | 0.212 | 0.255 | 0.211 |
| side 1.80 | 0.276 | 0.298 | 0.268 |
| side 1.65 (chest) | 0.391 | 0.421 | 0.407 |
| back 1.84 | 0.229 | 0.246 | 0.195 |
| back 1.82 | 0.310 | 0.310 | 0.263 |
| back 1.80 | 0.365 | 0.362 | 0.340 |
IoU side/back: 0.877/0.885 -> 0.879/0.885. Shoulder width (1.63-1.68 m back) unchanged (0.624 vs ref 0.633). Cost: back ramp at 1.80-1.84 m is now 0.03-0.05 too narrow where it was right/slightly wide before.

## Ticket 2: head + snout (commit "R3 ticket 2")
Cranium upper part pulled forward and in depth (occiput), snout root ru 0.055 -> 0.075, mid 0.048 -> 0.052, distal 0.036 -> 0.030. Skull width, snout tip and head length unchanged (head length 0.304 vs 0.307).
| measurement (side) | before | after | ref |
|---|---|---|---|
| back-edge error at 2.13 m | -0.036 | -0.029 | 0 |
| back-edge error at 2.08 m | -0.027 | -0.022 | 0 |
| front-edge error at 2.04 m | +0.020 | +0.018 | 0 |
| head length | 0.303 | 0.304 | 0.307 |
IoU: 0.879/0.885 -> 0.880/0.884. The occiput overhang (~0.03 m at 2.08-2.13 m) is only reduced to ~0.025: more of it may come from the horn A/B bases (r 0.029 at F -0.02, 2.13 m). The front depth at 2.04 m barely moved (+0.018): the snout root cannot be both thickened and cut forward without opening the jaw gap.

## Ticket 3: horns (commit "R3 ticket 3")
Horn A back (L) thickness reduced about 0.5 cm radius (side thickness kept), A tip lowered (end point 2.385 -> 2.36, mid 2.36 -> 2.335), B tooth bar (loop top) lowered a further 0.02 and pulled inward. Horn B shaft and side horn thickness untouched.
| measurement | before | after | ref |
|---|---|---|---|
| back horn A tip height | 2.393 | 2.367 | 2.362 |
| side horn A tip height | 2.391 | 2.367 | 2.400 |
| back horns.solid_width | 0.123 | 0.111 | 0.113 / 0.119 |
| side horns.solid_width | 0.121 | 0.116 | 0.119 |
| back horn A span | 0.115 | 0.111 | 0.103 |
IoU: 0.880/0.884 -> 0.876/0.884. Loop negative-space area is not output by compare.py, so I could not measure the 77%/41% figures; I tightened it geometrically only. The A tip drop worsens side A tip height by 0.033 (ticket asked for the back).
