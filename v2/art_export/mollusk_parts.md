# mollusk - parts (exported A-pose, meters)

Pivots sit at the joints (node origin = joint). Materials: `*_toon_vertex_color` = vertex-colored flat toon (RGB = color, A = emissive mask; alpha 0.01/0.02/0.03 = crack tiers), `face_plate` = face plate (drawn procedurally in engine), `glass` = translucent.
Sockets are empty nodes named `socket_*`.

| part | size x/y/z (m) | tris (fill) | pivot in parent |
|---|---|---|---|
| torso | 3.43 / 1.49 / 1.23 | 386 | (0.00, 0.50, 0.00) |
| head | 0.66 / 1.96 / 0.71 | 392 | (0.40, 1.25, 0.00) |
| face | 0.20 / 0.46 / 0.54 | 160 | (0.00, 0.00, 0.00) |
| arm_f | 0.78 / 1.40 / 0.45 | 152 | (0.15, 1.00, 0.62) |
| arm_b | 0.78 / 1.40 / 0.47 | 152 | (0.15, 1.00, -0.62) |
| weapon | 0.29 / 0.76 / 0.25 | 90 | (0.35, 0.55, 0.50) |
| extra | 2.10 / 1.97 / 1.64 | 756 | (-0.60, 0.75, 0.00) |
| leg_f | 0.75 / 0.48 / 0.46 | 52 | (0.25, 0.50, 0.30) |
| leg_b | 0.75 / 0.48 / 0.46 | 52 | (-0.05, 0.50, -0.30) |

**Total fill tris: 2192 (x2 with the outline hull = 4384; budget 6000).** Draw calls in engine: see test_art_build.
