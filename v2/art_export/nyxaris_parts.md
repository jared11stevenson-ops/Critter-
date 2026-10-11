# nyxaris - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 2.68 / 1.54 / 0.99 | 736 | (0.00, 1.45, 0.00) |
| head | 1.01 / 1.86 / 1.03 | 560 | (0.45, 0.80, 0.00) |
| face | 0.23 / 0.46 / 0.69 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 1.85 / 1.26 / 0.28 | 178 | (0.30, 0.50, 0.40) |
| arm_b | 0.67 / 1.10 / 0.30 | 134 | (0.30, 0.50, -0.40) |
| weapon | 0.11 / 0.66 / 0.32 | 78 | (0.55, 0.05, 0.45) |
| extra | 1.33 / 2.53 / 2.17 | 126 | (-2.00, 0.00, 0.00) |
| leg_f | 0.92 / 2.12 / 3.19 | 408 | (0.35, 1.45, 0.00) |
| leg_b | 0.83 / 2.12 / 3.19 | 408 | (-0.30, 1.45, 0.00) |

**Total fill tris: 2788 (x2 with the outline hull = 5576; budget 6000).** Draw calls in engine: see test_art_build.
