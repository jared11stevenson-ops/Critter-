"""P1e hands and feet (clay primary forms). Coordinates (F,U,L); his LEFT = +L. Reference: design/model_sheets/aruun/detail_hands_feet.png (parts 21,22,31,32).
HANDS: left hand = plated palm + 3 long pointed claws + thumb claw (hangs, claw tips at the measured hand bottom U 0.772); right hand = gloved fist with small knuckle claws.
FEET: banded sabatons: low foot body, ankle cuff + two tan bands, 3 forward toe claws, heel spur, flat sole on the ground row; ankle width reduced."""
import numpy as np
import build_forms as BF
from build_forms import P, tube, ell, nm, drop, FW, UP, LF

def hands(parts):
    for n in ('fistL', 'fistR'): drop(parts, n)
    add = []
    # ---- left hand: palm block + knuckle plate + 3 claws (spaced along F) + thumb claw (inner side)
    c = (-0.045, 0.925, 0.325)
    add.append(nm(ell('handL_palm', (c[0], 0.905, c[2]), (0.056, 0.082, 0.078)), 'handL_palm'))
    add.append(nm(ell('handL_knuckle_plate', (c[0], 0.860, c[2]), (0.060, 0.020, 0.074)), 'handL_knuckle_plate'))
    for k, df in enumerate((-0.036, 0.0, 0.036)):
        f0 = c[0] + df; add.append(nm(tube('handL_claw%d' % (k + 1), [(f0, 0.895, c[2]), (f0 + 0.008, 0.835, c[2] + 0.004), (f0 + 0.020, 0.772, c[2] + 0.004)],
                                           [(0.016, 0.014), (0.012, 0.011), (0.002, 0.002)], hint=FW, sub=3), 'handL_claw%d' % (k + 1)))
    add.append(nm(tube('handL_thumb', [(c[0] + 0.01, 0.91, c[2] - 0.040), (c[0] + 0.03, 0.865, c[2] - 0.050), (c[0] + 0.050, 0.825, c[2] - 0.048)], [(0.014, 0.014), (0.010, 0.010), (0.002, 0.002)], hint=FW, sub=3), 'handL_thumb'))
    # ---- right hand: gloved fist + knuckle claws
    r = (-0.175, 0.925, -0.31)
    add.append(nm(ell('handR_fist', (r[0], 0.915, r[2]), (0.080, 0.078, 0.072)), 'handR_fist'))
    for k, dl in enumerate((-0.036, -0.012, 0.012, 0.036)):
        add.append(nm(tube('handR_knuckle_claw%d' % (k + 1), [(r[0] + 0.060, 0.950, r[2] + dl), (r[0] + 0.082, 0.940, r[2] + dl), (r[0] + 0.098, 0.925, r[2] + dl)], [(0.010, 0.010), (0.007, 0.007), (0.0015, 0.0015)], hint=UP, sub=2), 'handR_knuckle_claw%d' % (k + 1)))
    add.append(nm(ell('handR_wrist_cuff', (-0.175, 1.0, -0.295), (0.075, 0.020, 0.075)), 'handR_wrist_cuff'))
    add.append(nm(ell('handL_wrist_cuff', (-0.050, 0.99, 0.325), (0.072, 0.020, 0.080)), 'handL_wrist_cuff'))
    parts.extend(add)

def feet(parts):
    for n in ('footL', 'footR', 'soleL', 'soleR'): drop(parts, n)
    add = []
    for s, c, rl, n in ((1, 0.21, 0.115, 'L'), (-1, -0.35, 0.10, 'R')):
        add.append(nm(tube('foot_' + n, [(-0.235, 0.070, c), (-0.14, 0.092, c), (-0.02, 0.072, c), (0.07, 0.046, c)], [(0.060, rl), (0.074, rl), (0.060, rl * 0.95), (0.036, rl * 0.8)], hint=UP), 'foot_' + n))
        add.append(nm(tube('sole_' + n, [(-0.245, 0.030, c), (-0.1, 0.030, c), (0.05, 0.026, c), (0.11, 0.020, c)], [(0.030, rl * 0.95), (0.030, rl * 0.95), (0.026, rl * 0.85), (0.018, rl * 0.6)], hint=UP), 'sole_' + n))
        # banded sabaton: ankle cuff + two bands (flat 8-sided collars)
        P.NSEG = 8
        for k, (u, rf, rr) in enumerate(((0.225, 0.074, 0.80), (0.185, 0.076, 0.84), (0.140, 0.080, 0.88))):
            add.append(nm(tube('sabaton_band%d_%s' % (k, n), [(-0.170, u - 0.011, c - s * 0.0), (-0.170, u + 0.011, c - s * 0.0)], [(rf, rl * rr), (rf, rl * rr)], hint=FW, sub=1), 'sabaton_band%d_%s' % (k, n)))
        P.NSEG = 16
        # 3 toe claws (long centre claw), heel spur
        for k, dl in enumerate((-0.045, 0.0, 0.045)):
            ln = 0.082 if k == 1 else 0.066
            add.append(nm(tube('toe_claw%d_%s' % (k + 1, n), [(0.050, 0.040, c + dl * (1 if s > 0 else 1)), (0.050 + ln * 0.6, 0.028, c + dl * 1.15), (0.152 - (0.0 if k == 1 else 0.012), 0.016, c + dl * 1.25)], [(0.020, 0.016), (0.014, 0.012), (0.003, 0.003)], hint=UP, sub=3), 'toe_claw%d_%s' % (k + 1, n)))
        add.append(nm(tube('heel_spur_' + n, [(-0.225, 0.095, c), (-0.248, 0.082, c), (-0.263, 0.062, c)], [(0.030, 0.026), (0.020, 0.018), (0.003, 0.003)], hint=UP, sub=3), 'heel_spur_' + n))
    parts.extend(add)
