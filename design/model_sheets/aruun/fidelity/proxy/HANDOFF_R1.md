# HANDOFF R1 (Primary Modeler, correction round 1). Not a grade; numbers are compare.py output.
Before = LOCKED_BASELINE_00 (`LOCKED_BASELINE_00/`, side IoU 0.874 / back 0.881). After = current `proxy.glb` (side 0.871 / back 0.881, front 0.580 qualitative).
Only the three tickets were edited in `tools/modeling/aruun/v4_proxy/build_proxy.py` (diff vs `LOCKED_BASELINE_00/build_proxy_baseline00.py`). One commit per ticket.
Regression check: no ticket reduced IoU by more than 0.003 (side, ticket 1 thinning: 0.874 -> 0.871; the silhouette loses area because the ticket asks for thinner limbs). Nothing rolled back; the one extra back-leg tweak that dropped back IoU to 0.878 was reverted.

## Ticket 1, horns (commit "R1 ticket 1")
Changed: horn A/B/B-tooth radii x ~0.65 (A 0.032->0.022 at base, B 0.030->0.021, tooth 0.018->0.012; hooks 0.004-0.005); B path extended outward (tip L 0.33->0.365).
| measurement | before | after | ref |
|---|---|---|---|
| back horn B span | 0.250 | 0.283 | 0.290 |
| back horns total spread | 0.363 | 0.387 | 0.393 |
| side horn B span | 0.237 | 0.223 | 0.183 (lower bound, clipped) |
| side horn A span | 0.198 | 0.189 | 0.217 |
| back horns.solid_width | 0.131 | 0.093 | 0.119 |
| side horns.solid_width | 0.133 | 0.092 | 0.119 |
| tip heights A/B (side) | 2.367 / 2.400 | 2.362 / 2.398 | 2.400 / 2.391 |
Note: the thinning overshoots the horns.solid_width metric (now about 22% under the ref on both views); the ticket's 4.0-4.3 cm target is met by radii 0.021-0.022 only near the base, tapering faster than the reference. Loop negative-space area was not measured by compare.py.

## Ticket 2, head (commit "R1 ticket 2")
Changed: removed the flat brow/tine ellipsoid at 2.10 m; cranium crown flared in width (rl 0.135 at 2.12 m) but kept shallow in depth; snout lower radii reduced (0.065->0.055 base, 0.06->0.048) and raised 0.005-0.01 to open the jaw-to-neck gap. Snout tip (2.0 m) and head length unchanged.
| measurement | before | after | ref |
|---|---|---|---|
| side head.run_width | 0.241 | 0.211 | 0.200 |
| side head.outer_width | 0.245 | 0.230 | 0.226 |
| back width at 2.13 m (slice 11 outer) | ~0.21 (0.097 under per ticket) | 0.239 | 0.232 |
| back head.extent | 0.320 | 0.275 | 0.331 |
| back snout.extent | 0.239 | 0.221 | 0.258 |
| side snout tip height / head length | 2.011 / 0.303 | 2.011 / 0.303 | 2.008 / 0.307 |
Side width at 1.99 m (jaw/neck gap row): 0.180 -> 0.143 (ref 0.156). Known cost: back head.extent got worse (the old brow band reached far in the back view; the reference tines/fringe there are detail-stage).

## Ticket 3, back legs (commit "R1 ticket 3")
Changed (legs only): left leg thigh/knee shifted outward and calf widened, right thigh rl 0.15->0.13 at hip, right calf widened, both ankles narrowed (rl 0.09/0.085 -> 0.075/0.065), strip-mass volume reduced (rl 0.10->0.09 at top, 0.08 at 0.82 m). Shoulder band at 1.84 m NOT changed (not easy: reference solid width there conflicts with the table; left for next round).
Back-view solid width (m), ref / before / after:
| height | ref | before | after |
|---|---|---|---|
| 0.76 | 0.556 | 0.673 | 0.638 |
| 0.74 | 0.533 | 0.635 | ~0.60 |
| 0.60 | 0.545 | 0.454 | 0.456 |
| 0.52 | 0.457 | 0.383 | 0.419 |
| 0.45 | 0.369 | 0.318 | 0.348 |
| 0.28 | 0.251 | 0.315 | 0.268 |
| 0.24 | 0.319 | 0.347 | 0.282 |
| 0.19 | 0.306 | 0.356 | 0.307 |
Back outer width at 0.76 m: 0.721 ref / 0.795 before / 0.787 after.

Still wrong in the back legs: the right-thigh/strip region at 0.74-0.76 m is still +0.05..0.08 solid (the strip mass cannot be removed without losing IoU; tried one more reduction: back IoU 0.878, reverted); ankles at 0.24 m now slightly narrow (0.282 vs 0.319).
