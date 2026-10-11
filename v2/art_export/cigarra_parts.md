# cigarra - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 0.91 / 1.27 / 1.12 | 384 | (0.00, 0.62, 0.00) |
| head | 1.46 / 1.94 / 1.68 | 748 | (0.05, 0.68, 0.00) |
| weapon | 1.00 / 0.77 / 1.44 | 408 | (0.10, 0.90, 0.00) |
| face | 0.26 / 0.59 / 0.70 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 0.48 / 0.96 / 0.35 | 146 | (0.00, 0.38, 0.40) |
| arm_b | 0.48 / 0.96 / 0.35 | 146 | (0.00, 0.38, -0.40) |
| extra | 0.64 / 1.13 / 1.08 | 1068 | (-0.20, 0.48, 0.00) |
| leg_f | 0.57 / 0.77 / 0.47 | 194 | (0.10, 0.62, 0.20) |
| leg_b | 0.57 / 0.77 / 0.47 | 194 | (-0.08, 0.62, -0.20) |

**Total fill tris: 3448 (x2 with the outline hull = 6896; budget 6000).** Draw calls in engine: see test_art_build.
