# CRITTER look pass (lighting / look-dev)

Problem (creator feedback: "visually unappealing"): everything was one terracotta orange. Ground, cliffs, fog, sky horizon, enemy
mites and the plaza all sat within ~15 degrees of the same hue and value, so nothing separated, characters were small and
disappeared into the floor, and distance did not read as depth.

Lore palette is kept: red rock, ochre dust, the ringed lilac planet, gold sun, Keth teal water, lichen green. What changes is how
much of each, where, and the value / saturation ladder between them.

## 1. Contrast rules (these beat any colour choice)

1. **Characters are the highest-contrast, most saturated thing on screen.** Ground and cliffs are desaturated (about 78 % of the
   old saturation) and mid-value; props are mid-value; only party, enemies in combat, pickups and interactables get saturation
   and emission. If an environment colour competes with a character, the environment loses.
2. **Value ladder, near to far:** character (rim lit, brightest local) > ground at the party's feet > cliffs > props in shade >
   fog layers (lighter and cooler with distance) > sky. Far layers go LIGHTER and PINKER-LILAC, never darker orange.
3. **Warm / cool split:** light is warm gold, shadows are cool teal-violet. Never warm in both. Shade side of any rock or
   wall should read as slate-teal, not dark orange.
4. **Accents are rare and glow:** teal and lichen green appear as small emissive things (pickups, Thoughtstone, Keth water,
   glow colonies, spores) plus soft sage patches on the ground. Max one accent colour dominating a view.
5. **Nothing relies on shadows.** On Low (no shadows, no post pass) the look is carried by: ground colour patches, fog
   gradient, sky haze band, character rim, blob shadows. Shadows and the grade are polish on Medium / High.

## 2. Scene scripts

### Hub (the Common): warm gold hour, cool teal accents
| Element | Colour | Notes |
|---|---|---|
| Key sun | gold (1.0, 0.80, 0.52), low (-46 deg) | long soft shadows across the plaza |
| Fill / ambient | teal (0.58, 0.70, 0.76) | shade reads cool |
| Haze toward walls | dusty rose (0.52, 0.36, 0.38) | walls recede |
| Plaza flags | gold-sand (0.84, 0.68, 0.50) base, taupe, ~25 % slate-teal, ~15 % pale sand | per-stone tone + large warm/cool wash, mortar softened (0.55) |
| Pool, lamps, glyphs | teal / amber emissive | the accents |
| Character rim | cool teal-white (0.62, 0.92, 0.92) | pops NPCs off gold floor |

### Red Reaches
Zone moods keep their order (gate, valley, waystation, drill, Ochre Span, boss foundation) with the same structure; each gets:
* **Sky:** teal-blue zenith (0.16-0.26, 0.38-0.44, 0.58-0.70), peach horizon, rose-lilac haze band that equals the fog colour so
  distance fades INTO the sky with no seam. Ringed planet unchanged.
* **Haze depth layers (fog + height fog + aerial perspective):** fog colour lilac-rose (0.84, 0.66, 0.70) in valley/gate, dusty
  plum (0.70, 0.46, 0.52) at the drill site, gold (0.96, 0.66, 0.50) on the Ochre Span, mauve (0.74, 0.46, 0.50) at the boss
  foundation. Density up about 30 % so 3 to 4 layers of cliff separate clearly.
* **Ground:** desaturated rust base + very large sage-teal, pale-sand and plum-rust patches (third un-aligned macro sample,
  period ~230 m, so no repeat is visible) + the existing dust and ripples. Strata band 3 is plum-rust instead of dark red.
* **Light:** gold sun (1.0, 0.72-0.84, 0.38-0.58), cool teal-violet shade fill, golden character rim (1.0, 0.84, 0.56) at 1.2-1.4.
* **Grade (Medium / High):** 1D LUT split tone, shadows lean teal, highlights lean gold, plus a soft violet vignette.
* **Particles:** one existing dust-mote emitter (no extra draw call), per-particle random gold or pale teal-green spore tint.
* **Props / rocks:** per-instance warm/cool + light/dark nudge from the instance origin hash (kit props, scatter) or smooth world
  noise (merged ToonKit props). Creature and habitat materials are excluded so authored character colours stay put.
* **Interactables:** pickups use emissive above the glow threshold so they bloom.

### Title
Key art unchanged; a one-material grade (split tone, 0.9 saturation, warm glow from the planet side, vignette) is applied to its
TextureRect, no extra draw.

## 3. Quality ladder

| | Low | Medium | High |
|---|---|---|---|
| Sun shadows | off | 1 split | 2 split soft |
| Grade LUT | off | on | on |
| Glow | off | on | on |
| Sky haze band, fog gradient, ground patches, prop variation, rim | on | on | on |
| Ground patch cost | reuses an existing sample | +1 sample | +1 sample |

## 4. Where it lives

* `game/world/common/world_lighting.gd` (CritterLighting): mood table, LUT, vignette, mote tint.
* `game/art/shaders/terrain_pbr.gdshader` (`look_ground`), `terrain_toon.gdshader` (hub paving), `sky_reaches.gdshader` (`haze_color`),
  `kit_prop.gdshader` / `toon_prop.gdshader` (`inst_var`), `title_grade.gdshader`.
* Hub plaza lighting and floor colours: `_tune_lighting` / `_build_floor` in `hub_visual.gd` (colour parameters only).
* Tuning knobs: `look_sat`, `look_patch`, `patch_*` on the terrain material; `MOODS` in CritterLighting.
