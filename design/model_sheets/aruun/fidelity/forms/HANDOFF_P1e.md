# HANDOFF P1e (Gate 2 pass 1e: legs + shoulder blades, hands, feet). Primary Modeler; no self-grading, compare.py numbers only.
Base = LOCKED_P1e0 (= LOCKED_P1d). Head not touched. Each ticket has an env switch in build_forms2.py (LEGS_E, HANDS_E, FEET_E; default 1). One commit per ticket; per-ticket snapshots `p1e_legs/`, `p1e_hands/`, `p1e_feet/`; final `LOCKED_P1e/` (forms.blend/glb, compare_orig_ref, compare_v2_ref, scripts). Clay grey only.

## Whole IoU (orig reference; v2 within 0.001). Rule: roll back if whole IoU falls > 0.005 per ticket
| state | side | back |
|---|---|---|
| LOCKED_P1e0 (= P1d) | 0.903 | 0.897 |
| + legs / blades | 0.907 | 0.895 |
| + hands | 0.907 | 0.894 |
| + feet (final) | 0.903 | 0.893 |
No ticket rolled back (largest per-ticket drop: feet side -0.004). Cumulative: side +0.000, back -0.004.

## Ticket 1: LEGS + SHOULDER BLADES
Read the width-error CSVs first. Findings (P1d): back solid width deficit at 0.45-0.60 m (-0.026..-0.086, mass between the legs) with outer widths already within 0.01-0.02; calf too thick at 0.31-0.38 m (+0.04, shin should taper); side calf region: the reference extends 0.02 m further back at 0.48-0.57 m and the model front was 0.015 too far forward at 0.45-0.52 m. The back-view stance-width error the inspector quoted is NOT visible in the outer widths (model outer width 0.658 vs ref 0.649 at 0.60 m); it is the inner mass.
Changes: calf bow (radii 0.088/0.115 at 0.60 m, 0.078/0.112 at 0.50 m, path 0.015 further back at 0.50 m), shin taper (0.058/0.052 at 0.34 m), flush `knee_plate_L/R`. Blades: `shoulder_blade_L/R` sunk into the back and joined to the neck base by `trapezius_L/R` ridge tubes (no longer floating ovals).
Numbers: back shin solid width 0.350 vs ref 0.350 (was 0.350 but 0.043 too thick at 0.33-0.38 m); side IoU 0.903 -> 0.907, back 0.897 -> 0.895; side shin outer width +0.011 (ref 0.117); thigh outer back 0.757 (ref 0.755).

## Ticket 2: HANDS (limbs_e.hands)
Left hand: plated palm (`handL_palm`, `handL_knuckle_plate`), 3 long pointed claws `handL_claw1-3` (spaced along F, curved forward) and `handL_thumb` claw on the inner side, wrist cuff. Right hand: gloved fist `handR_fist` with 4 small knuckle claws `handR_knuckle_claw1-4` and a cuff. The two hands are different parts. First version (thin claws without a palm) lost hand mass (back IoU -0.005); the palm was enlarged to the reference fist width (0.16 m).
Numbers: back hand bottom height 0.772 vs ref 0.772 (model was 0.750); hand.outer_width back 0.771 vs 0.770; hand.solid 0.698 vs 0.696; hand.extent 0.876 vs 0.882; side hand.outer 0.305 vs 0.302. IoU 0.907 / 0.894.
Arms were left straight (compare.py arm numbers: arm.outer back 0.722 vs 0.712, no measured error needing a bend).

## Ticket 3: FEET (limbs_e.feet)
Banded sabaton: low foot body `foot_L/R`, flat `sole_L/R` (bottom on the ground row), three banded collars (ankle cuff + two bands) `sabaton_band0-2_L/R` whose width follows the ankle (narrower than the earlier 0.8x foot width), 3 toe claws `toe_claw1-3_L/R` (long centre claw) and a heel spur `heel_spur_L/R`.
Numbers: foot length 0.419 vs ref 0.416 (was 0.410); side foot.outer_width 0.252 (ref 0.235, was 0.250); back foot.outer 0.730 (ref 0.708, was 0.727); IoU side 0.907 -> 0.903, back 0.894 -> 0.893.
Not met: the inspector's "back-view foot 15-25% too wide at the ankle (0.12 m)": the first sabaton (bands rl x0.8-1.05 of the foot width, wider than the ankle) made it +0.05 at 0.19-0.24 m, so the bands were narrowed to the ankle width; at 0.12 m back width is now 0.759 vs ref 0.736 (+0.023, was +0.055); a faint excess remains at 0.12-0.14 m.

## Known wrong
- Foot outer width is still +0.017..+0.022 (both views) and the foot is flatter/shorter than the reference's ankle wrap block: back ref-only area grew by ~7k px.
- Toe claws are round cone tubes, not the banded plated claws of detail_hands_feet.png; no tan plate bands on the foot body itself.
- The reference thumb/finger arrangement (3 fingers + thumb, tan knuckle plates) is approximated; the right fist does not grip the Morrow haft (erased in the reference).
- Arm/forearm bracers and elbow discs are not built (not in this ticket).
- Back-view inner leg mass (strip wedge) is still short at 0.60-0.76 m (solid 0.459 vs 0.545 earlier; now 0.619 vs 0.627 for the thigh band, shin solid matches).
