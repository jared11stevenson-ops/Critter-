# scarlith - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 1.75 / 1.83 / 1.69 | 650 | (0.00, 0.55, 0.00) |
| head | 1.54 / 1.18 / 2.04 | 528 | (0.75, 1.00, 0.00) |
| face | 0.35 / 0.64 / 0.90 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 2.24 / 3.04 / 0.39 | 290 | (0.40, 0.45, 0.82) |
| arm_b | 0.63 / 0.78 / 0.46 | 158 | (0.40, 0.45, -0.82) |
| weapon | 0.20 / 0.67 / 0.20 | 52 | (0.75, 1.65, 0.62) |
| extra | 1.09 / 1.35 / 1.04 | 444 | (-0.65, 0.55, 0.00) |
| leg_f | 0.97 / 0.87 / 1.72 | 496 | (0.35, 0.55, 0.00) |
| leg_b | 1.00 / 0.87 / 1.72 | 496 | (-0.40, 0.55, 0.00) |

**Total fill tris: 3274 (x2 with the outline hull = 6548; budget 6000).** Draw calls in engine: see test_art_build.
