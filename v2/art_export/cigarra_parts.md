# cigarra - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 0.79 / 1.48 / 1.06 | 328 | (0.00, 0.62, 0.00) |
| head | 1.10 / 2.01 / 1.81 | 524 | (0.05, 0.68, 0.00) |
| face | 0.26 / 0.59 / 0.70 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 0.46 / 0.97 / 0.37 | 110 | (0.00, 0.38, 0.42) |
| arm_b | 0.46 / 0.97 / 0.37 | 110 | (0.00, 0.38, -0.42) |
| extra | 0.88 / 1.59 / 1.24 | 1596 | (-0.05, 0.88, 0.00) |
| leg_f | 0.59 / 0.78 / 0.44 | 160 | (0.10, 0.62, 0.20) |
| leg_b | 0.59 / 0.78 / 0.44 | 160 | (-0.08, 0.62, -0.20) |

**Total fill tris: 3148 (x2 with the outline hull = 6296; budget 6000).** Draw calls in engine: see test_art_build.
