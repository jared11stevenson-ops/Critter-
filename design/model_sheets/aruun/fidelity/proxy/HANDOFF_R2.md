# HANDOFF R2 (Primary Modeler). Not a grade; compare.py numbers only. Before = LOCKED_BASELINE_01 (side 0.871 / back 0.881).
Final: see the IoU line below. One commit per ticket.

## Ticket 1: horn thickness + A tip (commit "R2 ticket 1")
Radii restored to about 0.9-1.3x the round-0 values (A 0.029 base, B 0.027, B tooth 0.016); A path end raised to (F 0.19, U 2.385).
| measurement | before | after | ref |
|---|---|---|---|
| horns.solid_width side | 0.092 | 0.121 | 0.119 |
| horns.solid_width back | 0.093 | 0.123 | 0.119 |
| horn A tip height (side) | 2.362 | 2.391 | 2.400 |
| horn A span (side) | 0.189 | 0.216 | 0.217 |
| IoU side / back | 0.871 / 0.881 | 0.874 / 0.881 | |

## Ticket 2: horn B path and loop (commit "R2 ticket 2")
B mid-shaft points moved forward 0.02-0.025 m in F; the tooth bar (the loop's top) lowered 0.025 m (2.385 -> 2.36 at the crest, ending lower and further inward: end point 2.27).
| measurement | before | after | ref |
|---|---|---|---|
| side horn B span | 0.231 | 0.202 | 0.183 (lower bound) |
| back horn B span | 0.278 | 0.278 | 0.290 |
| back total spread | 0.393 | 0.393 | 0.393 |
| IoU side / back | 0.874 / 0.881 | 0.877 / 0.885 | |

## Ticket 3: crotch / leg gap (back) (commit "R2 ticket 3")
Applied: trunk bottom raised (0.87 -> 0.93 start, narrower cone), leg tops moved up (0.90 -> 0.92), right calf/inner thigh widened at 0.40-0.60 m (center -0.325 -> -0.30, rl 0.085 -> 0.10 at 0.50 m). IoU side 0.877 / back 0.886 at the first attempt.
Tried and ROLLED BACK: raising the gap ceiling to 0.95 m with wider, closer thighs (left/right thigh rl 0.12/0.175 at the hip). It narrowed the gap at 0.80 m (188 -> 134 px, ref 94) but made the 0.76 m solid width worse (0.637 -> 0.671, ref 0.556) and dropped back IoU 0.885 -> 0.881. Not kept.
Remaining: model gap ceiling is about 0.87-0.90 m (ref apex 0.95 m, sloping); the model's gap at 0.80-0.60 m is wider than the reference's inner-thigh wedge allows; right thigh/strip region at 0.74-0.76 m is still about +0.06-0.08 m wide in solid width. The strip mass was not reduced (any further reduction lowered IoU in round 1).
