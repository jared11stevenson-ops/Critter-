# zephyr - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 1.81 / 1.26 / 0.91 | 1188 | (0.00, 0.80, 0.00) |
| head | 0.81 / 1.53 / 1.51 | 464 | (0.12, 0.85, 0.00) |
| face | 0.23 / 0.49 / 0.62 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 0.94 / 1.50 / 0.22 | 158 | (0.05, 0.65, 0.34) |
| arm_b | 0.39 / 1.08 / 0.22 | 106 | (0.05, 0.65, -0.34) |
| weapon | 0.44 / 0.62 / 0.22 | 222 | (-0.10, 0.15, 0.38) |
| extra | 1.05 / 1.82 / 1.76 | 552 | (-0.20, 0.60, 0.00) |
| leg_f | 0.21 / 0.75 / 0.13 | 102 | (0.10, 0.80, 0.14) |
| leg_b | 0.21 / 0.75 / 0.13 | 102 | (-0.08, 0.80, -0.14) |

**Total fill tris: 3054 (x2 with the outline hull = 6108; budget 6000).** Draw calls in engine: see test_art_build.
