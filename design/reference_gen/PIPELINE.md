# Aruun reference-gen pipeline (CPU box: 4 cores, 15 GB, no GPU; box shared with other agents, load avg 10-15 during tests so timings are pessimistic)

| Component | Source / license | Status |
|---|---|---|
| diffusers 0.40 + SD 1.5 (stable-diffusion-v1-5/stable-diffusion-v1-5) | CreativeML OpenRAIL-M | works (fp32, 3.4 GB unet) |
| LCM-LoRA SD1.5 (latent-consistency/lcm-lora-sdv1-5) | OpenRAIL++-M | works, 8 steps |
| ControlNet lineart / depth v1.1 (lllyasviel) | OpenRAIL | lineart loaded; depth downloaded, not yet used |
| IP-Adapter plus sd15 + ViT-H encoder (h94) | Apache-2.0 | works |
| Real-ESRGAN x4plus_anime_6B | BSD-3 | works: 520x520 -> 2080x2080 in ~4 min under load (tile 200) |
| SD-Turbo / Hunyuan / other non-commercial | excluded | - |

Disk is tight (about 4 GB free after models); no LoRA training attempted yet.

## A/B on the CALM face (512 px, 8 LCM steps, CPU, under contention)
| Run | Settings | Result | Time |
|---|---|---|---|
| A img2img only | strength .45, no CN, no IP | face-like but flattened cartoon; snout shape, fringe, plate layering lost | ~2 min incl. model load |
| B + IP-Adapter(self) | strength .55, ip .8 | similar cartoon drift, helmet-like, fringe lost | ~5 min (load 10+) |
| C/D + lineart CN | cancelled (box saturated) | not evaluated | - |
| Real-ESRGAN anime-6B only | x4 | faithful, clean, in-style flat cel | ~4 min |

Finding: the source sheet is only 1280x853; each expression face is ~60 px. Diffusion at strength >= .45 changes the design (rejected, see rejected/). Upscale + compositing of original paint keeps the design locked, so it is the default; diffusion is reserved for low-strength cleanup and for regions that must be invented (marked yellow in derivation overlays).

## Later timings (box less loaded)
- Real-ESRGAN anime-6B x4: small panels 3-25 s, 840x840 turnaround crop ~35 s, 1224x532 mace panel 130 s.
- SD1.5+LCM 8 steps (strength x steps effective), CN+IP: 512x512 s30 127 s (loaded) / s70 40 s (unloaded); 544x768 s80 73 s. Model load ~30 s.
- A/B on RAGE face (CN lineart 1.0 + IP .6): strength .3 holds design but gains nothing over plain upscale; .5/.7 drift palette (see aruun/rejected/REASONS.md).
- Greybox clay as condition: fails (rejected/body_front_try1). Depth ControlNet downloaded but not worth testing on that clay.
- LoRA training: not attempted (CPU contention, 4 GB free disk, source art is only 1280x853 so ~5 usable face crops).

## Chosen method
Original paint -> Real-ESRGAN -> placed on shared landmark rows (tools/refgen/place.py). Diffusion is NOT used in any shipped image; derivation overlays are therefore all green.

## Open questions
1. Expression-tile horns are short notched columns; turnaround horns are long lyre horns. Which is the straight-on design? A straight-on face with the long horns needs invention.
2. True ortho FRONT body, 3/4 body and A-pose are not producible on-model with SD1.5 CPU; need either the creator/an artist, or a stronger model. Do you want the current Blender model rendered as a lineart base for a paint-over?
3. Original sheet is 1280x853 so all faces are ~60 px source; any extra facial detail beyond the upscale would be invented.
