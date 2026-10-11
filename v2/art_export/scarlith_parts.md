# scarlith - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 1.79 / 1.81 / 1.70 | 530 | (0.00, 0.55, 0.00) |
| head | 1.59 / 1.18 / 2.04 | 496 | (0.75, 1.00, 0.00) |
| face | 0.35 / 0.64 / 0.90 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 2.24 / 3.03 / 0.39 | 272 | (0.40, 0.45, 0.82) |
| arm_b | 0.63 / 0.78 / 0.46 | 158 | (0.40, 0.45, -0.82) |
| weapon | 0.20 / 0.67 / 0.20 | 52 | (0.75, 1.65, 0.62) |
| extra | 1.07 / 1.35 / 0.96 | 380 | (-0.65, 0.55, 0.00) |
| leg_f | 0.97 / 0.85 / 1.72 | 352 | (0.35, 0.55, 0.00) |
| leg_b | 1.00 / 0.85 / 1.72 | 352 | (-0.40, 0.55, 0.00) |

**Total fill tris: 2752 (x2 with the outline hull = 5504; budget 6000).** Draw calls in engine: see test_art_build.
