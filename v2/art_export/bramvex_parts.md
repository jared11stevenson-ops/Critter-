# bramvex - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 1.11 / 1.30 / 0.62 | 616 | (0.00, 1.50, 0.00) |
| head | 1.13 / 2.22 / 0.75 | 436 | (0.12, 1.15, 0.00) |
| face | 0.21 / 0.39 / 0.45 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 2.13 / 4.15 / 0.53 | 918 | (0.05, 0.80, 0.34) |
| arm_b | 0.42 / 1.58 / 0.26 | 230 | (0.05, 0.80, -0.34) |
| weapon | 0.30 / 1.20 / 0.25 | 114 | (0.00, 0.70, 0.36) |
| extra | 0.36 / 1.29 / 0.98 | 252 | (-0.15, 0.80, 0.00) |
| leg_f | 0.53 / 1.66 / 0.24 | 180 | (0.10, 1.50, 0.20) |
| leg_b | 0.53 / 1.66 / 0.24 | 180 | (-0.12, 1.50, -0.20) |

**Total fill tris: 3086 (x2 with the outline hull = 6172; budget 6000).** Draw calls in engine: see test_art_build.
