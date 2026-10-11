# aruun - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 1.33 / 2.30 / 1.29 | 978 | (0.00, 1.00, 0.00) |
| head | 2.35 / 2.38 / 1.71 | 306 | (0.50, 1.95, 0.00) |
| face | 0.32 / 0.45 / 0.57 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 0.90 / 1.28 / 0.77 | 298 | (0.00, 0.78, 0.74) |
| weapon | 2.43 / 1.37 / 1.11 | 668 | (0.25, -0.88, 0.06) |
| arm_b | 0.90 / 1.28 / 0.76 | 298 | (0.00, 0.78, -0.74) |
| extra | 0.91 / 1.55 / 1.18 | 192 | (-0.10, 1.00, 0.00) |
| leg_f | 1.09 / 1.16 / 0.51 | 164 | (0.10, 1.00, 0.30) |
| leg_b | 1.09 / 1.16 / 0.51 | 164 | (-0.12, 1.00, -0.30) |

**Total fill tris: 3228 (x2 with the outline hull = 6456; budget 6000).** Draw calls in engine: see test_art_build.
