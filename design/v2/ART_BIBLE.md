# CRITTER v2 — Art Bible: "Cute-Grim Ink & Gold" (Lead, 2026-10-11)

The look is a blend of four references, each used for one thing:
| Reference | What we take | What we do NOT take |
|---|---|---|
| **Adventure Time** | Simple, rounded, expressive character shapes; dot eyes and wobbly mouths; bright flat color; whimsical props | Cartoon-network pacing; sitcom lighting |
| **Rick and Morty** | Thin confident outlines, deadpan faces, goofy-dark humor, sickly-neon accent glows, gross-cute biology | Crude humor; green-portal motif |
| **Naruto** | Action energy: speed lines, impact frames, dramatic poses, exaggerated attack stretch, chakra-like glow tied to abilities | Anime tropes; character designs |
| **Elden Ring** | Scale, melancholy, golden fog, colossal ruins, rim-lit silhouettes, restrained UI, dark fantasy mood | Realistic textures; grimdark everywhere |

**The juxtaposition is the identity:** goofy, lovable characters in a vast, mournful, beautiful world where fights are deadly.

## 1. Rendering recipe (Compatibility renderer, mobile-first)
- **Toon shading:** 2-band cel lighting (lit / shadow) plus a soft rim; no PBR textures on characters. One flat color per material with a 0.15 darker shadow tint.
- **Outlines:** inverted-hull outline (thick on characters, thin on props); width scales with screen size; outline color is the material's darkest tone, not pure black.
- **Characters** are assembled from rigid primitives (capsules, spheres, wedges, prisms) with exaggerated proportions: big head, tiny limbs, huge weapon.
- **Faces:** textured quads or tiny meshes (dot eyes, brow lines, mouth line) swapping among 6 expression sets.
- **FX:** hand-drawn feel: hit sparks as flat star-bursts, smear arcs along swings, dust puffs, speed lines, **impact frames** (a 2-frame black/white inversion on heavy hits and finishers), ink splats; all procedural GPU particles and quads.
- **Lighting:** golden low sun, cool teal shade, fog gradient; characters lit brighter than the ground; rim glow in the critter's accent color.
- **Contrast rule:** characters are the most saturated, highest-contrast things on screen; arenas are calmer and moodier.

## 2. Palettes
- **World:** ash, rust, bone, dusk gold, deep teal shadows; fog in warm grey-gold; occasional sickly neon accents (Rick and Morty) for hazards and magic.
- **Critters:** see ROSTER.md; each has *main / accent / glow* and must be distinct in hue from the others (checked automatically by a palette distance test).

## 3. Shape language
- **Critters:** round, soft shapes with one sharp feature (a blade, horn or nozzle). Heavy = square and wide, fast = thin and angular, trick = round with long thin limbs.
- **Environments:** colossal, simple masses (broken bridges, hollow statues, cathedral-sized shells) with tiny readable detail; Elden Ring composition: a distant landmark always visible.

## 4. Animation language (procedural pose keys)
- Each move has **Anticipation** (tell, exaggerated), **Strike** (fast smear plus stretch), **Recovery** (settle with squash). Durations come from the move's frame data so visuals and gameplay are always in sync.
- Impact: hit-stop (3-8 frames), screen shake along the blow, hit spark, optional impact frame (heavy/finisher).
- Idle: breathing squash, blink, weapon sway; one signature idle fidget per critter.
- Expressions change with state: hurt on hit, scared at low Vitality, determined on Last Stand.

## 5. UI language
- Thick outlined "sticker" panels, hand-lettered display font (open license, e.g., Bangers/Permanent Marker class; recorded in ASSET_LICENSES) plus a clean body font.
- Combat HUD is minimal: Vitality and Stamina bars beside each fighter's portrait, Poise ring around the critter, tell indicators, ability buttons with ink-wash cooldown.
- Colors follow the critter's palette so you always know whose bar is whose.

## 6. Quality gates for art
1. **Silhouette test:** each critter is identifiable as a flat black shape at 64 px.
2. **Color test:** the seven accent colors are pairwise distinguishable (a computed minimum hue distance).
3. **Pop test:** the critter's mean saturation exceeds the arena background's by a set margin.
4. **Style test:** side-by-side sheet reviewed by the creator.
5. **Perf:** a critter ≤ 20 draw calls, ≤ 6k triangles (rigid parts), outlines included; arena ≤ 80 draw calls; the whole bout ≤ 150.
