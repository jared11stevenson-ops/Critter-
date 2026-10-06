# Lead correction tickets, round 1 (confirmed by Forensics against the reference; fix ONLY these three, then re-render)
Scorecard after round 1 (inspector, proxy stage): Silhouette 19/25, Proportions 15.5/20, Head-Neck-Horns 7/15 -> G1 FAIL.

TICKET 1 (sev 9) HORNS A and B. Confirmed with corrections: horn limbs are ~45-52% too thick (reference ~65-70 px = 4.0-4.3 cm in 4096 px frame; model ~100-108 px).
  Thin them to the reference thickness along their length (knobbed joints may be slightly thicker). The closed loop already exists, but its negative space is 0.022 vs
  0.014 m2 (57% too big): tighten the loop. Back view horn B span is 0.041 m TOO SHORT (0.250 vs 0.290): extend B outward. Horn tips: +-0.03 m is noise (views disagree by 0.04 m),
  keep the current compromise. Reference horn B is clipped in the side view: do not shrink it. Tip hooks should be thin (top slice is +0.186 m too wide at the tip row).
TICKET 2 (sev 8) HEAD. (a) The brim band at 2.10-2.11 m is a 4 cm tall excess: remove the hat-brim/flat disc effect; the model is 0.097 m NARROWER than the reference at 2.13 m, so the crown plates/cranium
  at 2.13 m must be wider (horn cups and temple tines live there). (b) The muzzle underside is filled by +0.085 m at 2.00 m: open the jaw-to-neck gap as in the reference (hooked mandible and drooping
  muzzle). DO NOT lower the snout tip (it is correct to 0.004 m) and do not change head/snout length (correct to 0.004 m).
TICKET 3 (sev 6, tie T6/T4/T3) BACK LEGS. Inter-leg gap is -40% at 0.738 m, +63% at 0.615 m, +30% at 0.37 m; back width +0.106 m at 0.738 m; calves -0.06 to -0.09 m too narrow; ankles +40% at 0.246 m.
  Reshape the legs/pelvis in the back view to the reference width profile (width_error_back.csv shows the signed error per slice). The strip-mass volume (+0.078 m at 0.76-0.80 m) may be reduced
  in the same pass. If the shoulder band (T4: back width at 1.844 m is 217 vs 377 px, +74% needed) is easy to fix in the same pass because it shares the 1.80-1.85 m band with the neck, include it; otherwise it is next round.
REJECTED / DEFERRED (do not act): arms elbow bend and hooked hand (T5: the 'hook' is the red fringe tail, detail stage), foot instep/heel profile (detail stage), waist/seat (T9 rejected), front 3/4 taper (T10 rejected).
RULES: change only the three tickets; keep everything else bit-identical; save as LOCKED_BASELINE_00 the current proxy before editing (copy proxy.blend/glb to proxy/LOCKED_BASELINE_00/); rerender; run compare.py; hand off; do not grade yourself.
